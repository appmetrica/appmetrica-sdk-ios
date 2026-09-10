#import "AMACore.h"
#import "AMAConfigForAnonymousActivationProvider.h"
#import "AMADefaultAnonymousConfigProvider.h"
#import "AMAMetricaPersistentConfiguration.h"
#import "AMAFirstActivationDetector.h"
#import "AMAAppMetricaConfiguration+Internal.h"
#import "AMAAppMetricaLibraryAdapterConfiguration+Internal.h"
#import "AMASavedAppMetricaConfigRepository.h"

@interface AMAConfigForAnonymousActivationProvider ()

@property (nonatomic, strong, readwrite) AMADefaultAnonymousConfigProvider *defaultProvider;
@property (nonatomic, strong, readwrite) AMAMetricaPersistentConfiguration *persistent;
@property (nonatomic, strong, readwrite) AMAFirstActivationDetector *firstActivationDetector;
@property (nonatomic, strong, readwrite) AMASavedAppMetricaConfigRepository *repository;

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
    AMASavedAppMetricaConfigRepository *repository =
        [[AMASavedAppMetricaConfigRepository alloc] initWithPersistentConfiguration:persistent];
    return [self initWithStorage:persistent
                 defaultProvider:defaultProvider
         firstActivationDetector:firstActivationDetector
                      repository:repository];
}

- (instancetype)initWithStorage:(AMAMetricaPersistentConfiguration *)persistent
                defaultProvider:(AMADefaultAnonymousConfigProvider *)defaultProvider
        firstActivationDetector:(AMAFirstActivationDetector *)firstActivationDetector
                     repository:(AMASavedAppMetricaConfigRepository *)repository
{
    self = [super init];
    if (self != nil) {
        _defaultProvider = defaultProvider;
        _persistent = persistent;
        _firstActivationDetector = firstActivationDetector;
        _repository = repository;
    }
    return self;
}

- (AMAAppMetricaConfiguration *)configuration
{
    AMAAppMetricaConfiguration *configuration = [self.repository validSavedConfig];

    if (configuration == nil) {
        configuration = [self.defaultProvider configuration];
        if ([self.firstActivationDetector isFirstLibraryReporterActivation] == NO) {
            configuration.handleFirstActivationAsUpdate = true;
        }
    }

    return configuration;
}

@end
