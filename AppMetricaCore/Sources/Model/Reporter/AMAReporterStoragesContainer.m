
#import "AMACore.h"
#import "AMAReporterStoragesContainer.h"
#import "AMAReporterStorage.h"
#import "AMAMetricaConfiguration.h"

@interface AMAReporterStoragesContainer ()

@property (nonatomic, strong, readonly) NSCondition *condition;
@property (nonatomic, strong, readonly) id<AMAAsyncExecuting> executor;
@property (nonatomic, strong, readonly) NSMutableDictionary *storages;
@property (nonatomic, strong, readonly) NSMutableSet *migratedKeys;
@property (nonatomic, assign) BOOL migrated;
@property (nonatomic, assign) BOOL forcedMigration;

@end

@implementation AMAReporterStoragesContainer

- (instancetype)init
{
    self = [super init];
    if (self != nil) {
        _eventEnvironment = [[AMAEnvironmentContainer alloc] init];
        _condition = [[NSCondition alloc] init];
        _executor = [[AMAExecutor alloc] initWithIdentifier:self];
        _storages = [NSMutableDictionary dictionary];
        _migratedKeys = [NSMutableSet set];
        _migrated = NO;
    }
    return self;
}

- (AMAReporterStorage *)storageForApiKey:(NSString *)apiKey
{
    [self.condition lock];
    AMAReporterStorage *storage = self.storages[apiKey];
    if (storage == nil) {
        storage = [[AMAReporterStorage alloc] initWithApiKey:apiKey
                                            eventEnvironment:self.eventEnvironment];
        self.storages[apiKey] = storage;
    }
    [self.condition unlock];
    return storage;
}

- (void)completeMigrationForApiKey:(NSString *)apiKey
{
    if (self.migrated) {
        AMALogAssert(@"Somebody did complete migration for %@, but over all migration is already complete.", apiKey);
        return;
    }
    [self.condition lock];
    [self.migratedKeys addObject:apiKey];
    [self.condition broadcast];
    [self.condition unlock];
}

- (void)waitMigrationForApiKey:(NSString *)apiKey
{
    if (self.migrated) {
        return;
    }
    [self forceMigration];
    [self.condition lock];
    while (self.migrated == NO && [self.migratedKeys containsObject:apiKey] == NO) {
        [self.condition wait];
    }
    [self.condition unlock];
}

- (void)forceMigration
{
    if (self.forcedMigration == NO) {
        [self.executor execute:^{
            if (self.forcedMigration == NO) {
                self.forcedMigration = YES;
                [[AMAMetricaConfiguration sharedInstance] ensureMigrated];
                [self completeAllMigrations];
            }
        }];
    }
}

- (void)completeAllMigrations
{
    if (self.migrated) {
        return;
    }
    [self.condition lock];
    self.migrated = YES;
    [self.condition broadcast];
    [self.condition unlock];
}

+ (instancetype)sharedInstance
{
    static AMAReporterStoragesContainer *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[AMAReporterStoragesContainer alloc] init];
    });
    return instance;
}

@end
