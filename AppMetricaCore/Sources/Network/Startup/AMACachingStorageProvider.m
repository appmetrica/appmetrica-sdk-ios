
#import "AMACachingStorageProvider.h"
#import "AMAMetricaConfiguration.h"
#import "AMAMetricaPersistentConfiguration.h"
#import "AMAStartupParametersConfiguration.h"
#import "AMADatabaseProtocol.h"
#import "AMADatabaseFactory.h"

@interface AMACachingStorageProvider ()

@property (nonatomic, strong, readonly) id<AMADatabaseProtocol> database;

@end

@implementation AMACachingStorageProvider

- (instancetype)init
{
    self = [super init];
    if (self != nil) {
        _database = AMADatabaseFactory.configurationDatabase;
    }
    return self;
}

- (id<AMAKeyValueStoring>)cachingStorage
{
    return self.database.storageProvider.cachingStorage;
}

@end
