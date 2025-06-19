
#import "AMAConfigForAnonymousActivationProvider.h"
#import "AMADefaultAnonymousConfigProvider.h"
#import "AMAMetricaPersistentConfiguration.h"
#import "AMAFirstActivationDetector.h"
#import "AMAFirstActivationDetector.h"

@interface AMAConfigForAnonymousActivationProvider ()

@property (nonatomic, strong, readwrite) AMADefaultAnonymousConfigProvider *defaultProvider;
@property (nonatomic, strong, readwrite) AMAMetricaPersistentConfiguration *persistent;
@property (nonatomic, strong, readwrite) AMAFirstActivationDetector *firstActivationDetector;

@end

@implementation AMAConfigForAnonymousActivationProvider

- (instancetype)initWithStorage:(AMAMetricaPersistentConfiguration *)persistent
{
    return [self initWithStorage:persistent
                 defaultProvider:[[AMADefaultAnonymousConfigProvider alloc] init]
         firstActivationDetector:[[AMAFirstActivationDetector alloc] init]];
}

- (instancetype)initWithStorage:(AMAMetricaPersistentConfiguration *)persistent
                defaultProvider:(AMADefaultAnonymousConfigProvider *)defaultProvider
        firstActivationDetector:(AMAFirstActivationDetector *)firstActivationDetector
{
    self = [super init];
    if (self != nil) {
        _defaultProvider = defaultProvider;
        _persistent = persistent;
        _firstActivationDetector = firstActivationDetector;
    }
    return self;
}

- (AMAAppMetricaConfiguration *)configuration
{
    AMAAppMetricaConfiguration *configuration = self.persistent.appMetricaClientConfiguration;
    
    if (configuration == nil) {
        configuration = [self.defaultProvider configuration];
        if ([self.firstActivationDetector isFirstLibraryReporterActivation] == NO) {
            configuration.handleFirstActivationAsUpdate = true;
        }
    }
    return configuration;
}

@end
