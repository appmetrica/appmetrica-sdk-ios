#import <XCTest/XCTest.h>
#import <AppMetricaCoreExtension/AppMetricaCoreExtension.h>
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMAAppMetrica.h"
#import "AMAAppMetricaConfiguration.h"
#import "AMAEnvironmentContainer.h"
#import "AMAMetricaConfiguration.h"
#import "AMAModuleEntryPointDiscoverer.h"
#import "AMAModulesController.h"
#import "AMAReporter.h"
#import "Mocks/AMAAppMetricaMock.h"
#import "Mocks/AMAModuleRegistrarMocks.h"
#import "Utilities/AMAModuleInvocationRecorder.h"
#import "Mocks/AMAReporterMock.h"
#import "Utilities/AMAEventPollingDelegateMock.h"
#import "Utilities/AMAMetricaConfigurationTestUtilities.h"
#import "Utilities/ModuleInvocationOrdering/AMAModuleInvocationOrderingAppMetricaImplStub.h"
#import "Utilities/ModuleInvocationOrdering/AMAModuleInvocationOrderingEntryPoints.h"

@interface AMAAppMetricaImpl (ModuleInvocationOrderingTests)
@property (nonatomic, strong) AMAModulesController *modulesController;
@end

@interface AMAAppMetricaModulesIntegrationOrderingTests : XCTestCase
@property (nonatomic, strong) AMAModuleInvocationRecorder *invocationRecorder;
@end


@implementation AMAAppMetricaModulesIntegrationOrderingTests

- (void)setUp
{
    [super setUp];
    self.invocationRecorder = [AMAModuleInvocationRecorder new];
    [self resetInvocationTracking];
}

- (void)resetInvocationTracking
{
    [AMAModuleActivationDelegateMock reset];
    [AMAEventFlushableDelegateMock reset];
    [AMAEventPollingDelegateMock reset];
    [self.invocationRecorder reset];
    AMAModuleInvocationOrderingConfigureRecorder(self.invocationRecorder);
    AMAModuleActivationDelegateMock.invocationRecorder = self.invocationRecorder;
    AMAEventFlushableDelegateMock.invocationRecorder = self.invocationRecorder;
    AMAEventPollingDelegateMock.invocationRecorder = self.invocationRecorder;
}

- (void)tearDown
{
    [AMAModuleActivationDelegateMock reset];
    [AMAEventFlushableDelegateMock reset];
    [AMAEventPollingDelegateMock reset];
    AMAModuleInvocationOrderingReset();
    self.invocationRecorder = nil;
    [AMAAppMetricaMock resetSharedDependencies];
    [AMAMetricaConfigurationTestUtilities destubConfiguration];
    [super tearDown];
}

- (void)testPublicActivationRunsCoreSynchronouslyAndModuleCallbacksAfterDiscovery
{
    // Public activation must run the core synchronously, but its module lifecycle must wait for discovery.
    // A reentrant public activation from will must not create an additional activation cycle.
    [AMAMetricaConfigurationTestUtilities stubConfiguration];

    AMAManualCurrentQueueExecutor *executor = [AMAManualCurrentQueueExecutor new];
    AMAModuleInvocationOrderingAppMetricaImplStub *impl =
        [[AMAModuleInvocationOrderingAppMetricaImplStub alloc]
        initWithHostStateProvider:nil
        executor:executor];

    XCTAssertNotNil(impl.modulesController);
    AMAAppMetricaMock.sharedImpl = impl;
    AMAAppMetricaMock.metricaConfiguration = [AMAMetricaConfiguration sharedInstance];

    AMAAppMetricaConfiguration *configuration =
        [[AMAAppMetricaConfiguration alloc] initWithAPIKey:kAMAModuleInvocationOrderingTestAPIKey];
    AMAModuleActivationDelegateMock.willActivateHandler = ^(AMAModuleActivationConfiguration *moduleConfiguration) {
        [AMAAppMetricaMock activateWithConfiguration:configuration];
    };
    [AMAAppMetricaMock activateWithConfiguration:configuration];
    XCTAssertEqualObjects(self.invocationRecorder.invocations,
                          (@[ kAMAModuleCoreActivationInvocation ]));

    [executor execute];

    XCTAssertEqualObjects(self.invocationRecorder.invocations,
                          (@[
                              kAMAModuleCoreActivationInvocation,
                              AMAModuleInvocation(AMAModuleInvocationOrderingPublicActivationEntryPoint.class,
                                                  @selector(registerComponentsWithRegistrar:)),
                              AMAModuleInvocation(AMAModuleActivationDelegateMock.class,
                                                  @selector(willActivateWithConfiguration:)),
                              AMAModuleInvocation(AMAModuleActivationDelegateMock.class,
                                                  @selector(didActivateWithConfiguration:)),
                          ]));
}

- (void)testActivationFromDifferentCallerQoSQueuesLifecycleAfterDiscovery
{
    // Hold the SDK executor stopped while initialization and activation run on both relevant caller QoS classes.
    // This deterministically reproduces the original race window and proves that caller QoS cannot move will/did
    // ahead of discovery and entry-point registration.
    [AMAMetricaConfigurationTestUtilities stubConfiguration];
    NSArray<NSNumber *> *qosClasses = @[ @(QOS_CLASS_BACKGROUND), @(QOS_CLASS_USER_INITIATED) ];

    for (NSNumber *qosValue in qosClasses) {
        [self resetInvocationTracking];
        qos_class_t qos = (qos_class_t)qosValue.unsignedIntValue;
        AMAManualCurrentQueueExecutor *executor = [AMAManualCurrentQueueExecutor new];
        AMAAppMetricaConfiguration *configuration = [[AMAAppMetricaConfiguration alloc]
            initWithAPIKey:kAMAModuleInvocationOrderingTestAPIKey];
        XCTestExpectation *activationReturned = [self expectationWithDescription:@"activation returned"];
        __block BOOL activationRanOnMainThread = YES;
        __block AMAModuleInvocationOrderingAppMetricaImplStub *impl = nil;

        dispatch_async(dispatch_get_global_queue(qos, 0), ^{
            activationRanOnMainThread = NSThread.isMainThread;
            impl = [[AMAModuleInvocationOrderingAppMetricaImplStub alloc]
                initWithHostStateProvider:nil
                executor:executor];
            [impl activateWithConfiguration:configuration];
            [activationReturned fulfill];
        });
        [self waitForExpectations:@[ activationReturned ] timeout:2.0];

        XCTAssertFalse(activationRanOnMainThread, @"QoS: %u", qos);
        XCTAssertNotNil(impl.modulesController, @"QoS: %u", qos);
        XCTAssertEqualObjects(self.invocationRecorder.invocations,
                              (@[ kAMAModuleCoreActivationInvocation ]),
                              @"QoS: %u", qos);

        [executor execute];

        XCTAssertEqualObjects(self.invocationRecorder.invocations,
                              (@[
                                  kAMAModuleCoreActivationInvocation,
                                  AMAModuleInvocation(
                                      AMAModuleInvocationOrderingPublicActivationEntryPoint.class,
                                      @selector(registerComponentsWithRegistrar:)),
                                  AMAModuleInvocation(AMAModuleActivationDelegateMock.class,
                                                      @selector(willActivateWithConfiguration:)),
                                  AMAModuleInvocation(AMAModuleActivationDelegateMock.class,
                                                      @selector(didActivateWithConfiguration:)),
                              ]),
                              @"QoS: %u", qos);
    }
}

- (void)testActivationFromDifferentCallerQoSWithRealExecutorPreservesModuleOrdering
{
    // Exercise the production serial executor from background and user-initiated callers. Core activation may race
    // with discovery, so only module invariants are asserted: registration precedes will, will precedes did, and
    // every event is delivered exactly once.
    [AMAMetricaConfigurationTestUtilities stubConfiguration];
    NSArray<NSNumber *> *qosClasses = @[ @(QOS_CLASS_BACKGROUND), @(QOS_CLASS_USER_INITIATED) ];

    for (NSNumber *qosValue in qosClasses) {
        [self resetInvocationTracking];
        qos_class_t qos = (qos_class_t)qosValue.unsignedIntValue;
        AMAExecutor *executor = [[AMAExecutor alloc]
            initWithIdentifier:[NSString stringWithFormat:@"module-ordering-%u", qos]];
        AMAAppMetricaConfiguration *configuration = [[AMAAppMetricaConfiguration alloc]
            initWithAPIKey:kAMAModuleInvocationOrderingTestAPIKey];
        XCTestExpectation *activationReturned = [self expectationWithDescription:@"activation returned"];
        XCTestExpectation *didActivate = [self expectationWithDescription:@"did activate"];
        AMAModuleActivationDelegateMock.didActivateHandler = ^(AMAModuleActivationConfiguration *moduleConfiguration) {
            [didActivate fulfill];
        };
        __block BOOL activationRanOnMainThread = YES;
        __block AMAModuleInvocationOrderingAppMetricaImplStub *impl = nil;

        dispatch_async(dispatch_get_global_queue(qos, 0), ^{
            activationRanOnMainThread = NSThread.isMainThread;
            impl = [[AMAModuleInvocationOrderingAppMetricaImplStub alloc]
                initWithHostStateProvider:nil
                executor:executor];
            [impl activateWithConfiguration:configuration];
            [activationReturned fulfill];
        });
        [self waitForExpectations:@[ activationReturned, didActivate ] timeout:2.0];

        NSString *registration = AMAModuleInvocation(
            AMAModuleInvocationOrderingPublicActivationEntryPoint.class,
            @selector(registerComponentsWithRegistrar:));
        NSString *will = AMAModuleInvocation(AMAModuleActivationDelegateMock.class,
                                             @selector(willActivateWithConfiguration:));
        NSString *did = AMAModuleInvocation(AMAModuleActivationDelegateMock.class,
                                            @selector(didActivateWithConfiguration:));
        NSArray<NSString *> *invocations = self.invocationRecorder.invocations;
        NSCountedSet<NSString *> *invocationCounts = [[NSCountedSet alloc] initWithArray:invocations];

        XCTAssertFalse(activationRanOnMainThread, @"QoS: %u", qos);
        XCTAssertNotNil(impl.modulesController, @"QoS: %u", qos);
        XCTAssertEqual(invocations.count, 4u, @"QoS: %u", qos);
        XCTAssertEqual([invocationCounts countForObject:kAMAModuleCoreActivationInvocation], 1u,
                       @"QoS: %u", qos);
        XCTAssertEqual([invocationCounts countForObject:registration], 1u, @"QoS: %u", qos);
        XCTAssertEqual([invocationCounts countForObject:will], 1u, @"QoS: %u", qos);
        XCTAssertEqual([invocationCounts countForObject:did], 1u, @"QoS: %u", qos);
        XCTAssertLessThan([invocations indexOfObject:registration], [invocations indexOfObject:will],
                          @"QoS: %u", qos);
        XCTAssertLessThan([invocations indexOfObject:will], [invocations indexOfObject:did],
                          @"QoS: %u", qos);
        XCTAssertLessThan([invocations indexOfObject:kAMAModuleCoreActivationInvocation],
                          [invocations indexOfObject:did], @"QoS: %u", qos);
    }
}

- (void)testAnonymousThenMainActivationQueuesTwoModuleLifecycleCyclesAfterSingleDiscovery
{
    // Anonymous and subsequent main activation run their core work immediately, then enqueue two
    // lifecycle cycles in submission order behind a single module discovery.
    [AMAMetricaConfigurationTestUtilities stubConfiguration];
    AMAManualCurrentQueueExecutor *executor = [AMAManualCurrentQueueExecutor new];
    AMAModuleInvocationOrderingAppMetricaImplStub *impl =
        [[AMAModuleInvocationOrderingAppMetricaImplStub alloc]
        initWithHostStateProvider:nil
        executor:executor];
    [impl activateAnonymously];
    AMAAppMetricaConfiguration *mainConfiguration =
        [[AMAAppMetricaConfiguration alloc] initWithAPIKey:kAMAModuleInvocationOrderingTestAPIKey];
    [impl activateWithConfiguration:mainConfiguration];
    XCTAssertEqualObjects(self.invocationRecorder.invocations,
                          (@[ kAMAModuleCoreActivationInvocation,
                              kAMAModuleCoreActivationInvocation ]));
    [executor execute];

    NSString *entryPoint =
        AMAModuleInvocation(AMAModuleInvocationOrderingPublicActivationEntryPoint.class,
                                                @selector(registerComponentsWithRegistrar:));
    NSString *will = AMAModuleInvocation(AMAModuleActivationDelegateMock.class,
                                         @selector(willActivateWithConfiguration:));
    NSString *did = AMAModuleInvocation(AMAModuleActivationDelegateMock.class,
                                        @selector(didActivateWithConfiguration:));
    XCTAssertEqualObjects(self.invocationRecorder.invocations,
                          (@[
                              kAMAModuleCoreActivationInvocation,
                              kAMAModuleCoreActivationInvocation,
                              entryPoint,
                              will,
                              did,
                              will,
                              did,
                          ]));
}

- (void)testDelayedAnonymousActivationQueuesModuleLifecycleAfterDiscovery
{
    // Scheduling anonymous activation alone must do no work. Once the delayed block fires, its core
    // runs synchronously and its module lifecycle remains ordered after discovery.
    [AMAMetricaConfigurationTestUtilities stubConfiguration];
    AMAManualCurrentQueueExecutor *executor = [AMAManualCurrentQueueExecutor new];
    AMAModuleInvocationOrderingAppMetricaImplStub *impl =
        [[AMAModuleInvocationOrderingAppMetricaImplStub alloc]
        initWithHostStateProvider:nil
        executor:executor];
    [impl scheduleAnonymousActivationWithDelay:100.0];
    XCTAssertNotNil(impl.scheduledAnonymousActivationBlock);
    XCTAssertEqualObjects(self.invocationRecorder.invocations, (@[]));

    impl.scheduledAnonymousActivationBlock();
    XCTAssertEqualObjects(self.invocationRecorder.invocations,
                          (@[ kAMAModuleCoreActivationInvocation ]));

    [executor execute];

    XCTAssertEqualObjects(self.invocationRecorder.invocations,
                          (@[
                              kAMAModuleCoreActivationInvocation,
                              AMAModuleInvocation(AMAModuleInvocationOrderingPublicActivationEntryPoint.class,
                                                  @selector(registerComponentsWithRegistrar:)),
                              AMAModuleInvocation(AMAModuleActivationDelegateMock.class,
                                                  @selector(willActivateWithConfiguration:)),
                              AMAModuleInvocation(AMAModuleActivationDelegateMock.class,
                                                  @selector(didActivateWithConfiguration:)),
                          ]));
}

- (void)testAllModuleCallbacksWaitForDiscoveryAndKeepSubmissionOrder
{
    // Submit every module-facing operation before discovery executes. Both entry points must register
    // first, and all callbacks must then be delivered in their original submission order.
    AMAManualCurrentQueueExecutor *executor = [AMAManualCurrentQueueExecutor new];
    AMAModuleEntryPointDiscoverer *discoverer = [[AMAModuleEntryPointDiscoverer alloc]
        initWithCandidateClassNames:@[
            @"AMAAppMetricaCrashesEntryPoint",
            @"AMAAdSupportModuleEntryPoint",
        ]
        classLookup:^Class(NSString *className) {
            if ([className isEqualToString:@"AMAAppMetricaCrashesEntryPoint"]) {
                return AMAModuleInvocationOrderingEntryPoint.class;
            }
            if ([className isEqualToString:@"AMAAdSupportModuleEntryPoint"]) {
                return AMAModuleInvocationOrderingSecondEntryPoint.class;
            }
            return Nil;
        }];
    AMAModulesController *controller = [[AMAModulesController alloc]
        initWithExecutor:executor
        discoverer:discoverer
        registrationCoordinator:nil
        startupParametersHandler:^(NSDictionary *parameters) {
            [AMAModuleInvocationOrderingRecorder() recordInvocationWithName:kAMAModuleStartupForwardInvocation];
        }];

    AMAAppMetricaConfiguration *configuration =
        [[AMAAppMetricaConfiguration alloc] initWithAPIKey:kAMAModuleInvocationOrderingTestAPIKey];
    NSError *error = [NSError errorWithDomain:@"test" code:1 userInfo:nil];
    NSObject *storageProvider = [NSObject new];
    AMAEnvironmentContainer *environment = [AMAEnvironmentContainer new];
    AMAReporter *reporter = [[AMAReporterMock alloc] init];

    [controller startLoading];
    [controller resolveModuleAdProviderWithHandler:^(id<AMAAdProviding> moduleAdProvider) {
        XCTAssertTrue(moduleAdProvider == AMAModuleInvocationOrderingAdProvider());
        [AMAModuleInvocationOrderingRecorder() recordInvocationWithName:kAMAModuleAdProviderInvocation];
    }];
    [controller performActivationWithAppMetricaConfiguration:configuration activationBlock:nil];
    [controller notifyStartupUpdatedWithParameters:@{ @"key" : @"value" }];
    [controller notifyStartupFailedWithError:error];
    [controller setupReporterStorageWithProvider:(id<AMAKeyValueStorageProviding>)storageProvider
                                            main:YES
                                          apiKey:@"test-key"];
    [controller setupAppEnvironmentWithContainer:environment];
    [controller addPollingEventsToReporter:reporter];
    [controller notifySendEventsBuffer];

    NSArray<NSString *> *expectedInvocations = @[
                              AMAModuleInvocation(AMAModuleInvocationOrderingEntryPoint.class,
                                                  @selector(registerComponentsWithRegistrar:)),
                              AMAModuleInvocation(AMAModuleInvocationOrderingSecondEntryPoint.class,
                                                  @selector(registerComponentsWithRegistrar:)),
                              AMAModuleInvocation(AMAExtendedStartupObservingMock.class,
                                                  @selector(setupStartupProvider:cachingStorageProvider:)),
                              AMAModuleInvocation(AMAExtendedStartupObservingMock.class,
                                                  @selector(startupParameters)),
                              kAMAModuleStartupForwardInvocation,
                              kAMAModuleAdProviderInvocation,
                              AMAModuleInvocation(AMAModuleActivationDelegateMock.class,
                                                  @selector(willActivateWithConfiguration:)),
                              AMAModuleInvocation(AMAModuleActivationDelegateMock.class,
                                                  @selector(didActivateWithConfiguration:)),
                              AMAModuleInvocation(AMAExtendedStartupObservingMock.class,
                                                  @selector(startupUpdatedWithParameters:)),
                              AMAModuleInvocation(AMAExtendedStartupObservingMock.class,
                                                  @selector(startupUpdateFailedWithError:)),
                              AMAModuleInvocation(AMAReporterStorageControllingMock.class,
                                                  @selector(setupWithReporterStorage:main:forAPIKey:)),
                              AMAModuleInvocation(AMAEventPollingDelegateMock.class,
                                                  @selector(setupAppEnvironment:)),
                              AMAModuleInvocation(AMAEventPollingDelegateMock.class,
                                                  @selector(pollingEvents)),
                              AMAModuleInvocation(AMAEventFlushableDelegateMock.class,
                                                  @selector(sendEventsBuffer)),
                          ];
    XCTAssertEqualObjects(self.invocationRecorder.invocations, (@[]));

    [executor execute];
    XCTAssertEqualObjects(self.invocationRecorder.invocations, expectedInvocations);
}

@end
