
#import <AppMetricaStorageUtils/AppMetricaStorageUtils.h>
#import "AMAStartupStorageProvider.h"
#import "AMAMetricaConfiguration.h"
#import "AMADatabaseProtocol.h"
#import "AMADatabaseFactory.h"

@interface AMAStartupStorageProvider ()

@property (nonatomic, strong, readonly) AMAMetricaConfiguration *configuration;

@end

@implementation AMAStartupStorageProvider

- (instancetype)init
{
    return [self initWithConfiguration:[AMAMetricaConfiguration sharedInstance]];
}

- (instancetype)initWithConfiguration:(AMAMetricaConfiguration *)configuration
{
    self = [super init];
    if (self != nil) {
        _configuration = configuration;
    }
    return self;
}

- (id<AMAKeyValueStoring>)startupStorageForKeys:(NSArray<NSString *> *)keys
{
    NSError *error = nil;
    id<AMAKeyValueStoring> storage = [self.configuration.storageProvider nonPersistentStorageForKeys:keys
                                                                                               error:&error];
    if (error != nil) {
        AMALogAssert(@"Failed to load startup parameters: %@ for keys: %@", error, keys);
        storage = self.configuration.storageProvider.emptyNonPersistentStorage;
    }
    return storage;
}

- (void)saveStorage:(id<AMAKeyValueStoring>)storage
{
    NSError *__block error = nil;
    [self.configuration.storageProvider saveStorage:storage error:&error];
    if (error != nil) {
        AMALogError(@"Failed to save extra startup parameters");
    }
}

@end
