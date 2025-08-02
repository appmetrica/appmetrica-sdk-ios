
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMAAppMetricaImplTestFactory.h"
#import "AMADispatchStrategiesContainer.h"
#import "AMAEventCountDispatchStrategy+Private.h"
#import "AMAInternalEventsReporter.h"
#import "AMAReporter.h"
#import "AMAReporterTestHelper.h"
#import "AMAEventBuilder.h"

@interface AMAAppMetricaImpl ()

@property (nonatomic, strong, readonly) AMAEnvironmentContainer *eventEnvironment;

- (void)shutdown;

@end

@interface AMAAppMetricaImplStub ()

@property (nonatomic, strong, readonly) AMAReporterTestHelper *reporterTestHelper;

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
    }
    return self;
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

