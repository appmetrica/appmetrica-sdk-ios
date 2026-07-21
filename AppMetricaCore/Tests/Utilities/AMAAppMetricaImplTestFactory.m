
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMAAppMetricaImplTestFactory.h"
#import "AMAAdProviderProxy.h"
#import "AMADispatchStrategiesContainer.h"
#import "AMAEventCountDispatchStrategy+Private.h"
#import "AMAInternalEventsReporter.h"
#import "AMAReporter.h"
#import "AMAReporterTestHelper.h"
#import "AMAEventBuilder.h"
#import "AMAModulesController.h"
#import "Mocks/AMAModuleEntryPointDiscovererMock.h"

@interface AMAAppMetricaImpl ()

@property (nonatomic, strong, readonly) AMAEnvironmentContainer *eventEnvironment;
@property (nonatomic, strong, readonly) AMAAdProviderProxy *adProviderProxy;
@property (nonatomic, strong, readonly) AMAModulesController *modulesController;

- (void)shutdown;
- (void)initializeModulesController;
- (void)addAdditionalStartupParameters:(NSDictionary *)parameters;
- (void)applyModuleAdProvider:(nullable id<AMAAdProviding>)moduleAdProvider;

@end

@interface AMAAppMetricaImplStub ()

@property (nonatomic, strong, readonly) AMAReporterTestHelper *reporterTestHelper;
@property (nonatomic, strong) AMAAdProviderProxy *stubbedAdProviderProxy;
@property (nonatomic, strong) AMAModulesController *stubbedModulesController;
@property (nonatomic, strong, readwrite) AMAModuleEntryPointDiscovererMock *moduleEntryPointDiscoverer;

@end

@implementation AMAAppMetricaImplStub

- (instancetype)initWithHostStateProvider:(nullable id<AMAHostStateProviding>)hostStateProvider
                                 executor:(id<AMAAsyncExecuting, AMASyncExecuting>)executor
                       reporterTestHelper:(AMAReporterTestHelper *)reporterTestHelper
{
    self = [super initWithHostStateProvider:hostStateProvider 
                                   executor:executor];
    if (self != nil) {
        _reporterTestHelper = reporterTestHelper;
        _stubbedAdProviderProxy = [super adProviderProxy];
    }
    return self;
}

- (AMAAdProviderProxy *)adProviderProxy
{
    return self.stubbedAdProviderProxy;
}

- (void)initializeModulesController
{
    self.moduleEntryPointDiscoverer = [[AMAModuleEntryPointDiscovererMock alloc] init];
    __weak typeof(self) weakSelf = self;
    AMAModulesController *modulesController = [[AMAModulesController alloc]
        initWithExecutor:self.executor
        discoverer:self.moduleEntryPointDiscoverer
        registrationCoordinator:nil
        startupParametersHandler:nil];
    modulesController.startupParametersHandler = ^(NSDictionary *parameters) {
        [weakSelf addAdditionalStartupParameters:parameters];
    };
    self.stubbedModulesController = modulesController;
    [modulesController startLoading];
}

- (AMAModulesController *)modulesController
{
    return self.stubbedModulesController;
}

- (void)setModulesController:(AMAModulesController *)modulesController
{
    self.stubbedModulesController = modulesController;
}

- (void)setAdProviderProxy:(AMAAdProviderProxy *)adProviderProxy
{
    self.stubbedAdProviderProxy = adProviderProxy;
}

- (void)dealloc
{
    // Unsubscribe from notifications
    // (because unit tests creates multiple instances of AMAAppMetricaImpl)
    [self shutdown];
}

- (void)startReachability
{
    // skip testing Reachability
}

- (void)shutdownReachability
{
   // skip testing Reachability
}

- (void)startLocationManager
{
   // skip testing Location
}

- (void)performStartup
{
    //skip testing Startup
}

- (void)didAddEventNotification:(NSNotification *)notification
{
    // skip testing
}

- (void)initializeSearchAdsController
{
    // skip testing Search Ads requests
}

- (void)triggerSearchAdsRequest
{
    // skip testing Search Ads requests
}

- (void)updateStrategiesContainer:(NSArray *)strategies
{
    for (AMADispatchStrategy *strategy in strategies) {
        AMATestDelayedManualExecutor *executor = [AMATestDelayedManualExecutor new];
        strategy.executor = executor;
    }

    [self.strategiesContainer addStrategies:strategies];
    [self.strategiesContainer startStrategies:strategies];
}

- (AMAReporter *)createReporterWithApiKey:(NSString *)apiKey
                                     main:(BOOL)main
                             eventBuilder:(AMAEventBuilder *)eventBuilder
                          reporterStorage:(AMAReporterStorage *)reporterStorage
                         internalReporter:(AMAInternalEventsReporter *)internalReporter
{
    return [self.reporterTestHelper appReporterForApiKey:apiKey
                                                    main:main
                                                   async:NO
                                                inMemory:YES
                                             preloadInfo:eventBuilder.preloadInfo];
}

@end

@implementation AMAAppMetricaImplTestFactory

+ (AMAAppMetricaImpl *)createCurrentQueueImplWithReporterHelper:(AMAReporterTestHelper *)reporterTestHelper
                                              hostStateProvider:(id<AMAHostStateProviding>)hostStateProvider
{
    AMACurrentQueueExecutor *executor = [AMACurrentQueueExecutor new];
    AMAAppMetricaImpl *impl = [[AMAAppMetricaImplStub alloc] initWithHostStateProvider:hostStateProvider
                                                                              executor:executor
                                                                    reporterTestHelper:reporterTestHelper];
    return impl;
}

+ (AMAAppMetricaImpl *)createCurrentQueueImplWithReporterHelper:(AMAReporterTestHelper *)reporterTestHelper
{
    AMAStubHostAppStateProvider *hostStateProvider = [AMAStubHostAppStateProvider new];
    hostStateProvider.hostState = AMAHostAppStateBackground;
    return [self createCurrentQueueImplWithReporterHelper:reporterTestHelper
                                        hostStateProvider:hostStateProvider];
}

+ (AMAAppMetricaImpl *)createNoQueueImplWithReporterHelper:(AMAReporterTestHelper *)reporterTestHelper
{
    AMAManualCurrentQueueExecutor *executor = [AMAManualCurrentQueueExecutor new];
    AMAStubHostAppStateProvider *hostStateProvider = [AMAStubHostAppStateProvider new];
    hostStateProvider.hostState = AMAHostAppStateBackground;
    
    AMAAppMetricaImpl *impl = [[AMAAppMetricaImplStub alloc] initWithHostStateProvider:hostStateProvider
                                                                              executor:executor
                                                                    reporterTestHelper:reporterTestHelper];
    return impl;
}

@end
