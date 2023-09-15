
#import "AMACore.h"
#import "AMAKeychain.h"
#import "AMAKeychainQueryBuilder.h"
#import "AMAKeychainBridge.h"

NSString *const kAMAKeychainErrorDomain = @"kAMAKeychainErrorDomain";
NSString *const kAMAKeychainErrorKeyCode = @"kAMAKeychainErrorKeyCode";

static NSString *const AMAKeychainAvailabilityCheckObjectKey = @"AMAKeychainAvailabilityCheckObjectKey";
static NSString *const AMAKeychainAvailabilityCheckObject = @"AMAKeychainAvailabilityCheckObject";

@interface AMAKeychain ()

@property (nonatomic, strong) AMAKeychainQueryBuilder *queryBuilder;
@property (nonatomic, strong) AMAKeychainBridge *bridge;

@end

@implementation AMAKeychain

- (instancetype)initWithService:(NSString *)service
{
    return [self initWithService:service accessGroup:@""];
}

- (nullable instancetype)initWithService:(NSString *)service accessGroup:(NSString *)accessGroup
{
    return [self initWithService:service accessGroup:accessGroup bridge:[[AMAKeychainBridge alloc] init]];
}

- (instancetype)initWithService:(NSString *)service accessGroup:(NSString *)accessGroup bridge:(AMAKeychainBridge *)bridge
{
    NSParameterAssert(service.length);
    if (service.length == 0) {
        return nil;
    }

    self = [super init];
    if (self != nil) {
        NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithDictionary:@{
                (__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword,
                (__bridge id)kSecAttrAccessible : (__bridge id)kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
                (__bridge id)kSecAttrService : service,
        }];

        // Apps that are built for the simulator aren't signed, so there's no keychain access group
        // for the simulator to check. This means that all apps can see all keychain items when run
        // on the simulator.
#if !TARGET_IPHONE_SIMULATOR
        if (accessGroup.length != 0) {
            parameters[(__bridge id)kSecAttrAccessGroup] = accessGroup;
        }
#endif

        _bridge = bridge;
        _queryBuilder = [[AMAKeychainQueryBuilder alloc] initWithQueryParameters:parameters];
    }
    return self;
}

- (void)resetKeychain
{
    NSDictionary *entriesQuery = [self.queryBuilder entriesQuery];
    if (entriesQuery == nil) {
        return;
    }

    [self.bridge deleteEntryWithQuery:entriesQuery];
}

- (BOOL)isAvailable
{
    NSError *error = nil;
    NSString *savedValue = nil;

    [self setStringValue:AMAKeychainAvailabilityCheckObject forKey:AMAKeychainAvailabilityCheckObjectKey error:&error];
    if (error == nil) {
        savedValue = [self stringValueForKey:AMAKeychainAvailabilityCheckObjectKey error:&error];
        [self removeStringValueForKey:AMAKeychainAvailabilityCheckObjectKey error:nil];
    }

    return error == nil && [savedValue isEqual:AMAKeychainAvailabilityCheckObject];
}

- (void)setStringValue:(NSString *)value forKey:(NSString *)key error:(NSError **)error
{
    if (value == nil) {
        return;
    }

    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:value];
    if ([self dataForKey:key error:nil] == nil) {
        [self addData:data forKey:key error:error];
    }
    else {
        [self updateData:data forKey:key error:error];
    }
}

- (void)addStringValue:(NSString *)value forKey:(NSString *)key error:(NSError **)error
{
    if (value == nil) {
        return;
    }

    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:value];
    if ([self dataForKey:key error:nil] == nil) {
        [self addData:data forKey:key error:error];
    }
}

- (void)updateData:(NSData *)data forKey:(NSString *)key error:(NSError **)error
{
    NSDictionary *updateQuery = [self.queryBuilder updateEntryQueryWithData:data];
    NSDictionary *entryQuery = [self.queryBuilder entryQueryForKey:key];
    if (updateQuery == nil || entryQuery == nil) {
        [self fillError:error wtithErrorCode:kAMAKeychainErrorCodeQueryCreation];
        return;
    }

    OSStatus result = [self.bridge updateEntryWithQuery:entryQuery attributesToUpdate:updateQuery];
    if (result != noErr) {
        AMALogError(@"Failed to update object for key %@ with osstatus %ld", key, (long)result);
        [self fillError:error wtithErrorCode:kAMAKeychainErrorCodeUpdate statusCode:result];
    }
}

- (void)addData:(NSData *)data forKey:(NSString *)key error:(NSError **)error
{
    NSDictionary *dataQuery = [self.queryBuilder addEntryQueryWithData:data forKey:key];
    if (dataQuery == nil) {
        return;
    }

    OSStatus result = [self.bridge addEntryWithAttributes:dataQuery];
    if (result != noErr) {
        AMALogError(@"Failed to add object for key %@ with osstatus %ld", key, (long)result);
        [self fillError:error wtithErrorCode:kAMAKeychainErrorCodeAdd statusCode:result];
    }
}

- (NSString *)stringValueForKey:(NSString *)key error:(NSError **)error
{
    NSData *data = [self dataForKey:key error:error];
    if (data == nil) {
        return nil;
    }

    NSString *value = nil;
    @try {
        value = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    } @catch (NSException *exception) {
        [self fillError:error wtithErrorCode:kAMAKeychainErrorCodeDecode statusCode:0];
    }
    if ([value isKindOfClass:[NSString class]] == NO) {
        value = nil;
        [self fillError:error wtithErrorCode:kAMAKeychainErrorCodeInvalidType statusCode:0];
    }
    return value;
}

- (nullable NSData *)dataForKey:(NSString *)key error:(NSError **)error
{
    NSDictionary *dataQuery = [self.queryBuilder dataQueryForKey:key];
    if (dataQuery == nil) {
        return nil;
    }

    NSData *data = nil;
    OSStatus result = [self.bridge copyMatchingEntryWithQuery:dataQuery resultData:&data];
    if (result != noErr && result != errSecItemNotFound) {
        AMALogError(@"Failed to retrieve data for key %@, osstatus %ld", key, (long)result);
        [self fillError:error wtithErrorCode:kAMAKeychainErrorCodeGet statusCode:result];
    }

    return data;
}

- (void)removeStringValueForKey:(id)key error:(NSError **)error
{
    if ([self dataForKey:key error:nil] == nil) {
        return;
    }
    
    NSDictionary *entryQuery = [self.queryBuilder entryQueryForKey:key];
    if (entryQuery == nil) {
        [self fillError:error wtithErrorCode:kAMAKeychainErrorCodeQueryCreation];
        return;
    }
    
    OSStatus result = [self.bridge deleteEntryWithQuery:entryQuery];
    if (result != noErr && result != errSecItemNotFound) {
        AMALogError(@"Failed to delete data for key %@, osstatus %ld", key, (long)result);
        [self fillError:error wtithErrorCode:kAMAKeychainErrorCodeRemove statusCode:result];
    }
}
- (void)fillError:(NSError **)error wtithErrorCode:(kAMAKeychainErrorCode)errorCode
{
    [self fillError:error wtithErrorCode:errorCode statusCode:0];
}

- (void)fillError:(NSError **)error wtithErrorCode:(kAMAKeychainErrorCode)errorCode statusCode:(OSStatus)status
{
    NSError *internalError = [NSError errorWithDomain:kAMAKeychainErrorDomain code:errorCode userInfo:@{
        kAMAKeychainErrorKeyCode: @(status),
    }];
    [AMAErrorUtilities fillError:error withError:internalError];
}

@end
