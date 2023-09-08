
#import "AMAInstantFeaturesConfiguration.h"
#import "AMAStorageKeys.h"
#import "AMAStartupParametersConfiguration.h"
#import "AMAJSONFileKVSDataProvider.h"

@interface AMAInstantFeaturesConfiguration ()

@property (nonatomic, strong, readonly) AMAJSONFileKVSDataProvider *backingFileStorage;
@property (nonatomic, strong, readonly) NSHashTable *observersTable;

@end

@implementation AMAInstantFeaturesConfiguration

+ (instancetype)sharedInstance
{
    static dispatch_once_t pred;
    static AMAInstantFeaturesConfiguration *shared = nil;
    dispatch_once(&pred, ^{
        shared = [[self alloc] init];
    });
    return shared;
}

- (instancetype)init
{
    NSString *filePath = [AMAFileUtility.persistentPath stringByAppendingPathComponent:@"instant.json"];
    AMADiskFileStorageOptions options = AMADiskFileStorageOptionNoBackup | AMADiskFileStorageOptionCreateDirectory;
    AMADiskFileStorage *fileStorage = [[AMADiskFileStorage alloc] initWithPath:filePath options:options];
    return [self initWithJSONDataProvider:[[AMAJSONFileKVSDataProvider alloc] initWithFileStorage:fileStorage]];
}

- (instancetype)initWithJSONDataProvider:(AMAJSONFileKVSDataProvider *)provider
{
    self = [super init];
    if (self != nil) {
        _backingFileStorage = provider;
        _observersTable = [NSHashTable weakObjectsHashTable];
    }
    return self;
}

#pragma mark - Public -

#pragma mark dynamicLibraryCrashHookEnabled

- (void)setDynamicLibraryCrashHookEnabled:(BOOL)value
{
    BOOL shouldNotify = NO;
    NSNumber *number = [self.backingFileStorage objectForKey:AMAStorageStringKeyLibsDynamicCrashHookEnabled error:NULL];
    if (number == nil || number.boolValue != value) {
        [self.backingFileStorage saveObject:@(value) forKey:AMAStorageStringKeyLibsDynamicCrashHookEnabled error:NULL];
        shouldNotify = YES;
    }
    if (shouldNotify) {
        [self notify];
    }
}

- (BOOL)dynamicLibraryCrashHookEnabled
{
    return [[self.backingFileStorage objectForKey:AMAStorageStringKeyLibsDynamicCrashHookEnabled error:NULL] boolValue];
}

- (void)setUUID:(NSString *)value
{
    NSString *uuid = [self.backingFileStorage objectForKey:AMAStorageStringKeyUUID error:NULL];
    if (uuid.length == 0) {
        [self.backingFileStorage saveObject:value.copy forKey:AMAStorageStringKeyUUID error:NULL];
    }
}

- (NSString *)UUID
{
    return [self.backingFileStorage objectForKey:AMAStorageStringKeyUUID error:NULL];
}

#pragma mark - Private -

- (void)notify
{
    [self.observers makeObjectsPerformSelector:@selector(instantFeaturesConfigurationDidUpdate:) withObject:self];
}

#pragma mark - AMABroadcasting

- (NSArray *)observers
{
    @synchronized (self.observersTable) {
        return self.observersTable.allObjects;
    }
}

- (void)addAMAObserver:(id<AMAInstantFeaturesObserver>)observer
{
    @synchronized (self.observersTable) {
        [self.observersTable addObject:observer];
    }
}

- (void)removeAMAObserver:(id<AMAInstantFeaturesObserver>)observer
{
    @synchronized (self.observersTable) {
        [self.observersTable removeObject:observer];
    }
}

#pragma mark - AMAStartupCompletionObserving

- (void)startupUpdateCompletedWithConfiguration:(AMAStartupParametersConfiguration *)configuration
{
    self.dynamicLibraryCrashHookEnabled = configuration.dynamicLibraryCrashHookEnabled;
}

@end
