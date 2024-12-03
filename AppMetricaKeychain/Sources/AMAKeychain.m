
#import <AppMetricaKeychain/AppMetricaKeychain.h>
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>
#import "AMAKeychainLog.h"
#import "AMAKeychainQueryBuilder.h"
#import "AMAKeychainBridge.h"

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

        if (accessGroup.length != 0) {
            parameters[(__bridge id)kSecAttrAccessGroup] = accessGroup;
        }
        
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

- (BOOL)setStringValue:(NSString *)value forKey:(NSString *)key error:(NSError **)error
{
    if (value == nil) {
        return NO;
    }

    NSError *archiveError = nil;
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:value requiringSecureCoding:YES error:&archiveError];
    if (archiveError) {
        AMALogError(@"Error archiving data: %@", archiveError);
        [self fillError:error withErrorCode:AMAKeychainErrorCodeDecode statusCode:0 underlyingError:archiveError];
        return NO;
    }

    if ([self dataForKey:key error:nil] == nil) {
        return [self addData:data forKey:key error:error];
    }
    else {
        return [self updateData:data forKey:key error:error];
    }
}

- (BOOL)addStringValue:(NSString *)value forKey:(NSString *)key error:(NSError **)error
{
    if (value == nil) {
        return NO;
    }

    NSError *archiveError = nil;
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:value requiringSecureCoding:YES error:&archiveError];
    if (archiveError) {
        AMALogError(@"Error archiving data: %@", archiveError);
        [self fillError:error withErrorCode:AMAKeychainErrorCodeDecode statusCode:0 underlyingError:archiveError];
        return NO;
    }

    return [self addData:data forKey:key error:error];
}

- (BOOL)updateData:(NSData *)data forKey:(NSString *)key error:(NSError **)error
{
    NSDictionary *updateQuery = [self.queryBuilder updateEntryQueryWithData:data];
    NSDictionary *entryQuery = [self.queryBuilder entryQueryForKey:key];
    if (updateQuery == nil || entryQuery == nil) {
        [self fillError:error wtithErrorCode:AMAKeychainErrorCodeDecode];
        return NO;
    }

    OSStatus result = [self.bridge updateEntryWithQuery:entryQuery attributesToUpdate:updateQuery];
    if (result != errSecSuccess) {
        AMALogError(@"Failed to update object for key %@ with osstatus %ld", key, (long)result);
        [self fillError:error statusCode:result];
        return NO;
    }
    return YES;
}

- (BOOL)addData:(NSData *)data forKey:(NSString *)key error:(NSError **)error
{
    NSDictionary *dataQuery = [self.queryBuilder addEntryQueryWithData:data forKey:key];
    if (dataQuery == nil) {
        return NO;
    }

    OSStatus result = [self.bridge addEntryWithAttributes:dataQuery];
    if (result != errSecSuccess) {
        AMALogError(@"Failed to add object for key %@ with osstatus %ld", key, (long)result);
        [self fillError:error statusCode:result];
        return NO;
    }
    return YES;
}

- (NSString *)stringValueForKey:(NSString *)key error:(NSError **)error
{
    NSData *data = [self dataForKey:key error:error];
    if (data == nil) {
        return nil;
    }

    NSString *value = nil;
    NSError *unarchiveError = nil;
    value = [NSKeyedUnarchiver unarchivedObjectOfClass:NSString.class fromData:data error:&unarchiveError];
    if (unarchiveError != nil) {
        AMALogError(@"Error unarchiving data: %@", unarchiveError);
        [self fillError:error withErrorCode:AMAKeychainErrorCodeDecode statusCode:0 underlyingError:unarchiveError];
        return nil;
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
    if (result != errSecSuccess && result != errSecItemNotFound) {
        AMALogError(@"Failed to retrieve data for key %@, osstatus %ld", key, (long)result);
        [self fillError:error statusCode:result];
        return nil;
    }

    return data;
}

- (BOOL)removeStringValueForKey:(NSString*)key error:(NSError **)error
{
    if ([self dataForKey:key error:nil] == nil) {
        return YES;
    }
    
    NSDictionary *entryQuery = [self.queryBuilder entryQueryForKey:key];
    if (entryQuery == nil) {
        [self fillError:error wtithErrorCode:AMAKeychainErrorCodeQueryCreation];
        return NO;
    }
    
    OSStatus result = [self.bridge deleteEntryWithQuery:entryQuery];
    if (result != errSecSuccess && result != errSecItemNotFound) {
        AMALogError(@"Failed to delete data for key %@, osstatus %ld", key, (long)result);
        [self fillError:error statusCode:result];
        return NO;
    }
    return YES;
}

- (void)fillError:(NSError **)error wtithErrorCode:(AMAKeychainErrorCode)errorCode
{
    [self fillError:error withErrorCode:errorCode statusCode:0 underlyingError:nil];
}

- (void)fillError:(NSError **)error statusCode:(OSStatus)status
{
    AMAKeychainErrorCode code = AMAKeychainErrorCodeGeneral;
    switch (status) {
        case errSecDuplicateItem:
            code = AMAKeychainErrorCodeDuplicate;
            break;
        case errSecDatabaseLocked:
        case errSecInteractionNotAllowed:
            code = AMAKeychainErrorCodeLocked;
            break;
        default:
            break;
    }
    [self fillError:error withErrorCode:code statusCode:status underlyingError:nil];
}

- (void)fillError:(NSError **)error 
    withErrorCode:(AMAKeychainErrorCode)errorCode
       statusCode:(OSStatus)status
  underlyingError:(NSError *)underlyingError
{
    NSMutableDictionary *userInfo = NSMutableDictionary.dictionary;
    userInfo[kAMAKeychainErrorKeyCode] = @(status);
    userInfo[NSUnderlyingErrorKey] = underlyingError;
    
    NSError *internalError = [NSError errorWithDomain:kAMAKeychainErrorDomain
                                                 code:errorCode
                                             userInfo:userInfo];
    [AMAErrorUtilities fillError:error withError:internalError];
}


@end
