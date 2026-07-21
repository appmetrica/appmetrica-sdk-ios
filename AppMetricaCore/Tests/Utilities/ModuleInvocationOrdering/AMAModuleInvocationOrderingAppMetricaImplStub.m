#import "AMAModuleInvocationOrderingAppMetricaImplStub.h"
#import "AMAModuleInvocationOrderingEntryPoints.h"
#import "../AMAModuleInvocationRecorder.h"
#import "AMAAppMetricaConfiguration.h"
#import "AMAAppMetricaConfigurationManager.h"
#import "AMAModuleEntryPointDiscoverer.h"
#import "AMAModulesController.h"
#import "AMAReporter.h"

NSString *const kAMAModuleCoreActivationInvocation = @"core.activation";
NSString *const kAMAModuleInvocationOrderingTestAPIKey = @"550e8400-e29b-41d4-a716-446655440000";

@interface AMAAppMetricaImpl (ModuleInvocationOrderingTests)
@property (nonatomic, strong) AMAModulesController *modulesController;
- (void)initializeModulesController;
@end

@interface AMAModuleInvocationOrderingConfigurationManager : NSObject
@property (nonatomic, strong) AMAAppMetricaConfiguration *anonymousConfigurationValue;
@end

@implementation AMAModuleInvocationOrderingConfigurationManager

- (void)updateMainConfiguration:(AMAAppMetricaConfiguration *)configuration
            activatedAnonymously:(BOOL)activatedAnonymously
{
}

- (AMAAppMetricaConfiguration *)anonymousConfiguration
{
    return self.anonymousConfigurationValue;
}

@end

@implementation AMAModuleInvocationOrderingAppMetricaImplStub

- (void)initializeModulesController
{
    AMAModuleEntryPointDiscoverer *discoverer = [[AMAModuleEntryPointDiscoverer alloc]
        initWithCandidateClassNames:@[ @"public-activation-entry-point" ]
        classLookup:^Class(NSString *className) {
            return AMAModuleInvocationOrderingPublicActivationEntryPoint.class;
        }];
    AMAModulesController *modulesController = [[AMAModulesController alloc]
        initWithExecutor:self.executor
        discoverer:discoverer
        registrationCoordinator:nil
        startupParametersHandler:nil];
    self.modulesController = modulesController;
    [modulesController startLoading];
}

- (void)initializeModulesControllerUsingProductionImplementation
{
    [super initializeModulesController];
}

- (instancetype)initWithHostStateProvider:(nullable id<AMAHostStateProviding>)hostStateProvider
                                 executor:(id<AMAAsyncExecuting, AMASyncExecuting>)executor
{
    self = [super initWithHostStateProvider:hostStateProvider executor:executor];
    if (self != nil) {
        AMAModuleInvocationOrderingConfigurationManager *configurationManager =
            [AMAModuleInvocationOrderingConfigurationManager new];
        configurationManager.anonymousConfigurationValue =
            [[AMAAppMetricaConfiguration alloc] initWithAPIKey:kAMAModuleInvocationOrderingTestAPIKey];
        self.configurationManager = (AMAAppMetricaConfigurationManager *)configurationManager;
    }
    return self;
}

- (void)scheduleAnonymousActivationWithDelay:(__unused NSTimeInterval)delay
{
    __weak typeof(self) weakSelf = self;
    self.scheduledAnonymousActivationBlock = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf.apiKey == nil) {
            [strongSelf activateAnonymously];
        }
    };
}

- (void)initializeStartupController
{
}

- (void)initializeIdentifierChangedNotifier
{
}

- (void)reportExtensionsReportIfNeeded
{
}

- (void)startReachability
{
}

- (void)migrate
{
}

- (AMAReporter *)setupMainReporterWithConfiguration:(AMAAppMetricaConfiguration *)configuration
{
    return nil;
}

- (void)activateCommonComponents:(AMAAppMetricaConfiguration *)configuration
                        reporter:(AMAReporter *)reporter
{
    [AMAModuleInvocationOrderingRecorder() recordInvocationWithName:kAMAModuleCoreActivationInvocation];
}

- (void)logMetricaStart:(NSString *)apiKey
{
}

@end
