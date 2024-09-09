
#import "AppMetricaConfigForAnonymousActivationProvider.h"
#import "AppMetricaDefaultAnonymousConfigProvider.h"
#import "AMAMetricaPersistentConfiguration.h"
#import "AMAFirstActivationDetector.h"

@interface AppMetricaConfigForAnonymousActivationProvider ()

@property (nonatomic, strong, readwrite) AppMetricaDefaultAnonymousConfigProvider *defaultProvider;
@property (nonatomic, strong, readwrite) AMAMetricaPersistentConfiguration *persistent;

@end

@implementation AppMetricaConfigForAnonymousActivationProvider

- (instancetype)initWithStorage:(AMAMetricaPersistentConfiguration *)persistent
{
    return [self initWithStorage:persistent
                 defaultProvider:[[AppMetricaDefaultAnonymousConfigProvider alloc] init]];
}

- (instancetype)initWithStorage:(AMAMetricaPersistentConfiguration *)persistent
                defaultProvider:(AppMetricaDefaultAnonymousConfigProvider *)defaultProvider
{
    self = [super init];
    if (self != nil) {
        _defaultProvider = defaultProvider;
        _persistent = persistent;
    }
    return self;
}

- (AMAAppMetricaConfiguration *)configuration
{
    AMAAppMetricaConfiguration *configuration = self.persistent.appMetricaClientConfiguration;
    
    if (configuration == nil) {
        configuration = [self.defaultProvider configuration];
        if ([AMAFirstActivationDetector isFirstLibraryReporterActivation] == NO) {
            configuration.handleFirstActivationAsUpdate = true;
        }
    }
    return configuration;
}

@end
