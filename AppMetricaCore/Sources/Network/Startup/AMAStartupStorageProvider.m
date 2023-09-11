
#import <AppMetricaStorageUtils/AppMetricaStorageUtils.h>
#import "AMAStartupStorageProvider.h"
#import "AMAMetricaConfiguration.h"
#import "AMADatabaseProtocol.h"
#import "AMADatabaseFactory.h"

@interface AMAStartupStorageProvider ()

@property (nonatomic, strong, readonly) id<AMADatabaseProtocol> database;

@end

@implementation AMAStartupStorageProvider

- (instancetype)init
{
    self = [super init];
    if (self != nil) {
        _database = AMADatabaseFactory.configurationDatabase;
    }
    return self;
}

- (id<AMAKeyValueStoring>)startupStorageForKeys:(NSArray<NSString *> *)keys
{
    NSError *error = nil;
    id<AMAKeyValueStoring> storage = [self.database.storageProvider nonPersistentStorageForKeys:keys
                                                                                          error:&error];
    if (error != nil) {
        AMALogAssert(@"Failed to load startup parameters: %@ for keys: %@", error, keys);
        storage = self.database.storageProvider.emptyNonPersistentStorage;
    }
    return storage;
}

- (void)saveStorage:(id<AMAKeyValueStoring>)storage
{
    NSError *__block error = nil;
    [self.database.storageProvider saveStorage:storage error:&error];
    if (error != nil) {
        AMALogError(@"Failed to save extra startup parameters");
    }
}

@end
