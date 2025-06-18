
#import "AMACachingStorageProvider.h"
#import "AMAMetricaConfiguration.h"

@interface AMACachingStorageProvider ()

@property (nonatomic, strong, readonly) AMAMetricaConfiguration *configuration;

@end

@implementation AMACachingStorageProvider

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

- (id<AMAKeyValueStoring>)cachingStorage
{
    return [[self.configuration storageProvider] cachingStorage];
}

@end
