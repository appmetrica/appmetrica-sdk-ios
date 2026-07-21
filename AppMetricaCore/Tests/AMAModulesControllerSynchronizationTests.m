#import <XCTest/XCTest.h>
#import <AppMetricaCoreExtension/AppMetricaCoreExtension.h>
#import "AMALegacyModuleRegistrationCoordinator.h"
#import "AMAModulesController.h"
#import "Mocks/AMAModuleRegistrarMocks.h"
#import "Mocks/AMAModuleEntryPointDiscovererMock.h"
#import "Utilities/AMAModuleInvocationRecorder.h"
#import "Utilities/AMAStepAsyncExecutor.h"

static NSString *const kAMADiscoveryStarted = @"discovery.started";
static NSString *const kAMADiscoveryCompleted = @"discovery.completed";
static NSString *const kAMACoreActivation = @"core.activation";
static NSString *const kAMARecursiveCoreActivation = @"core.recursive";
static NSString *const kAMATestAPIKey = @"550e8400-e29b-41d4-a716-446655440000";

@interface AMALegacyModuleRegistrationCoordinatorSpy : AMALegacyModuleRegistrationCoordinator
@property (nonatomic) NSUInteger beginRegistrationCallCount;
@end

@implementation AMALegacyModuleRegistrationCoordinatorSpy

- (void)beginRegistrationWithRegistrar:(AMAModuleRegistrarImpl *)registrar
{
    self.beginRegistrationCallCount += 1;
    [super beginRegistrationWithRegistrar:registrar];
}

@end

@interface AMAModulesControllerSynchronizationTests : XCTestCase
@property (nonatomic, strong) AMAModuleInvocationRecorder *recorder;
@end

@implementation AMAModulesControllerSynchronizationTests

- (void)setUp
{
    [super setUp];
    self.recorder = [[AMAModuleInvocationRecorder alloc] init];
    AMAModuleActivationDelegateMock.invocationRecorder = self.recorder;
    AMAEventFlushableDelegateMock.invocationRecorder = self.recorder;
}

- (void)tearDown
{
    [AMAModuleActivationDelegateMock reset];
    [AMAEventFlushableDelegateMock reset];
    self.recorder = nil;
    [super tearDown];
}

- (AMAModulesController *)controllerWithExecutor:(AMAStepAsyncExecutor *)executor
                                      discoverer:(AMAModuleEntryPointDiscovererMock *)discoverer
                            preActivationHandler:(AMAModulePreActivationHandlerMock * _Nullable)handler
{
    AMAFakeEntryPoint *entryPoint = [[AMAFakeEntryPoint alloc] init];
    entryPoint.invocationRecorder = self.recorder;
    entryPoint.registrationHandler = ^(id<AMAModuleRegistrar> registrar) {
        if (handler != nil) {
            [registrar registerPreActivationHandler:handler];
        }
        [registrar registerActivationDelegate:AMAModuleActivationDelegateMock.class];
        [registrar registerEventFlushableDelegate:AMAEventFlushableDelegateMock.class];
    };
    discoverer.entryPoints = @[ entryPoint ];
    return [[AMAModulesController alloc] initWithExecutor:executor
                                               discoverer:discoverer
                  registrationCoordinator:nil
                                 startupParametersHandler:nil];
}

- (AMAAppMetricaConfiguration *)activationConfiguration
{
    return [[AMAAppMetricaConfiguration alloc] initWithAPIKey:kAMATestAPIKey];
}

- (NSArray<NSString *> *)activationEventsWithCoreEvent:(NSString *)coreEvent
                           includingPreActivationHandler:(BOOL)includingHandler
{
    NSMutableArray<NSString *> *events = [NSMutableArray arrayWithObjects:
        coreEvent,
        [AMAModuleInvocationRecorder invocationNameForClass:AMAFakeEntryPoint.class
                                                  selector:@selector(registerComponentsWithRegistrar:)],
        nil];
    if (includingHandler) {
        [events addObject:[AMAModuleInvocationRecorder invocationNameForClass:AMAModulePreActivationHandlerMock.class
                                                                     selector:@selector(handlePreActivationWithConfiguration:)]];
    }
    [events addObjectsFromArray:@[
        [AMAModuleInvocationRecorder invocationNameForClass:AMAModuleActivationDelegateMock.class
                                                  selector:@selector(willActivateWithConfiguration:)],
        [AMAModuleInvocationRecorder invocationNameForClass:AMAModuleActivationDelegateMock.class
                                                  selector:@selector(didActivateWithConfiguration:)],
    ]];
    return events;
}

- (void)testCoreActivationRunsSynchronouslyAndModuleCallbacksRunAfterBackgroundLoading
{
    // Core activation must complete on the caller while discovery and all module lifecycle callbacks
    // remain queued on the background executor.
    AMAStepAsyncExecutor *executor = [[AMAStepAsyncExecutor alloc] init];
    AMAModuleEntryPointDiscovererMock *discoverer = [[AMAModuleEntryPointDiscovererMock alloc] init];
    AMAModulePreActivationHandlerMock *handler = [[AMAModulePreActivationHandlerMock alloc] init];
    handler.invocationRecorder = self.recorder;
    AMAModulesController *controller = [self controllerWithExecutor:executor
                                                         discoverer:discoverer
                                               preActivationHandler:handler];

    NSArray<id<AMAModuleEntryPoint>> *entryPoints = discoverer.entryPoints;
    __block BOOL discoveryRanOnMainThread = YES;
    discoverer.discoveryBlock = ^NSArray<id<AMAModuleEntryPoint>> *{
        discoveryRanOnMainThread = NSThread.isMainThread;
        return entryPoints;
    };

    [controller startLoading];
    [controller performActivationWithAppMetricaConfiguration:self.activationConfiguration
                                              activationBlock:^{
        [self.recorder recordInvocationWithName:kAMACoreActivation];
    }];

    XCTAssertTrue([executor waitForPendingBlockCount:3 timeout:2.0]);
    XCTAssertEqualObjects(self.recorder.invocations, (@[ kAMACoreActivation ]));

    XCTestExpectation *loadingCompleted = [self expectationWithDescription:@"loading completed"];
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        [executor runUntilIdle];
        [loadingCompleted fulfill];
    });
    [self waitForExpectations:@[ loadingCompleted ] timeout:2.0];

    XCTAssertEqual(discoverer.discoverCallCount, 1u);
    XCTAssertFalse(discoveryRanOnMainThread);
    XCTAssertEqual(handler.handleCallCount, 1);
    XCTAssertEqualObjects(self.recorder.invocations,
                          [self activationEventsWithCoreEvent:kAMACoreActivation
                                includingPreActivationHandler:YES]);
}

- (void)testModuleCallbacksSubmittedDuringDiscoveryRunAfterRegistryPublication
{
    // Suspend an in-flight discovery, submit activation, and then let discovery publish its registry.
    // The synchronous core block may run immediately, but will/did must wait and see the new delegates.
    AMAStepAsyncExecutor *executor = [[AMAStepAsyncExecutor alloc] init];
    AMAModuleEntryPointDiscovererMock *discoverer = [[AMAModuleEntryPointDiscovererMock alloc] init];
    AMAModulesController *controller = [self controllerWithExecutor:executor
                                                         discoverer:discoverer
                                               preActivationHandler:nil];

    dispatch_semaphore_t discoveryStarted = dispatch_semaphore_create(0);
    dispatch_semaphore_t allowDiscoveryToFinish = dispatch_semaphore_create(0);
    NSArray<id<AMAModuleEntryPoint>> *modules = discoverer.entryPoints;
    discoverer.discoveryBlock = ^NSArray<id<AMAModuleEntryPoint>> *{
        [self.recorder recordInvocationWithName:kAMADiscoveryStarted];
        dispatch_semaphore_signal(discoveryStarted);
        dispatch_semaphore_wait(allowDiscoveryToFinish, DISPATCH_TIME_FOREVER);
        [self.recorder recordInvocationWithName:kAMADiscoveryCompleted];
        return modules;
    };

    [controller startLoading];
    XCTestExpectation *loadingCompleted = [self expectationWithDescription:@"loading completed"];
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        [executor runNext];
        [loadingCompleted fulfill];
    });
    XCTAssertEqual(dispatch_semaphore_wait(discoveryStarted,
                                           dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC))), 0);

    [controller performActivationWithAppMetricaConfiguration:self.activationConfiguration
                                              activationBlock:^{
        [self.recorder recordInvocationWithName:kAMACoreActivation];
    }];

    XCTAssertTrue([executor waitForPendingBlockCount:2 timeout:2.0]);
    XCTAssertTrue([self.recorder.invocations containsObject:kAMACoreActivation]);

    dispatch_semaphore_signal(allowDiscoveryToFinish);
    [self waitForExpectations:@[ loadingCompleted ] timeout:2.0];
    [executor runUntilIdle];

    NSArray<NSString *> *expected = @[
        kAMADiscoveryStarted,
        kAMACoreActivation,
        kAMADiscoveryCompleted,
        [AMAModuleInvocationRecorder invocationNameForClass:AMAFakeEntryPoint.class
                                                  selector:@selector(registerComponentsWithRegistrar:)],
        [AMAModuleInvocationRecorder invocationNameForClass:AMAModuleActivationDelegateMock.class
                                                  selector:@selector(willActivateWithConfiguration:)],
        [AMAModuleInvocationRecorder invocationNameForClass:AMAModuleActivationDelegateMock.class
                                                  selector:@selector(didActivateWithConfiguration:)],
    ];
    XCTAssertEqualObjects(self.recorder.invocations, expected);
    XCTAssertEqual(discoverer.discoverCallCount, 1u);
}

- (void)testStartLoadingAndActivationDiscoverExactlyOnce
{
    AMAStepAsyncExecutor *executor = [[AMAStepAsyncExecutor alloc] init];
    AMAModuleEntryPointDiscovererMock *discoverer = [[AMAModuleEntryPointDiscovererMock alloc] init];
    AMAModulesController *controller = [self controllerWithExecutor:executor
                                                         discoverer:discoverer
                                               preActivationHandler:nil];

    [controller startLoading];
    [controller performActivationWithAppMetricaConfiguration:self.activationConfiguration
                                              activationBlock:^{
        [self.recorder recordInvocationWithName:kAMACoreActivation];
    }];

    XCTAssertTrue([executor waitForPendingBlockCount:3 timeout:2.0]);
    XCTAssertEqual(discoverer.discoverCallCount, 0u);
    XCTAssertTrue([self.recorder.invocations containsObject:kAMACoreActivation]);
    XCTestExpectation *loadingCompleted = [self expectationWithDescription:@"loading completed"];
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        [executor runUntilIdle];
        [loadingCompleted fulfill];
    });
    [self waitForExpectations:@[ loadingCompleted ] timeout:2.0];

    XCTAssertEqual(discoverer.discoverCallCount, 1u);
    XCTAssertEqual([AMAModuleActivationDelegateMock willActivateCallCount], 1);
    XCTAssertEqual([AMAModuleActivationDelegateMock didActivateCallCount], 1);
}

- (void)testConcurrentStartLoadingSubmitsDiscoveryExactlyOnce
{
    // Exercise startLoading's idempotence from multiple callers before the executor runs discovery.
    AMAStepAsyncExecutor *executor = [[AMAStepAsyncExecutor alloc] init];
    AMAModuleEntryPointDiscovererMock *discoverer = [[AMAModuleEntryPointDiscovererMock alloc] init];
    AMAModulesController *controller = [self controllerWithExecutor:executor
                                                         discoverer:discoverer
                                               preActivationHandler:nil];
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0);

    for (NSUInteger index = 0; index < 50; index++) {
        dispatch_group_async(group, queue, ^{
            [controller startLoading];
        });
    }

    XCTAssertEqual(dispatch_group_wait(group,
                                       dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC))),
                   0);
    XCTAssertEqual(executor.pendingBlockCount, 1u);

    [executor runUntilIdle];

    XCTAssertEqual(discoverer.discoverCallCount, 1u);
}

- (void)testExternalRegistrationsBeforeControllerCreationAndDuringDiscoveryReachPublishedRegistry
{
    // Legacy components can arrive both before loading starts and while discovery is in flight.
    // Both registration waves must be included in the single registry used by activation.
    AMALegacyModuleRegistrationCoordinator *coordinator =
        [[AMALegacyModuleRegistrationCoordinator alloc] init];
    [coordinator registerActivationDelegate:AMAModuleActivationDelegateMock.class];

    AMAStepAsyncExecutor *executor = [[AMAStepAsyncExecutor alloc] init];
    AMAModuleEntryPointDiscovererMock *discoverer = [[AMAModuleEntryPointDiscovererMock alloc] init];
    discoverer.entryPoints = @[];
    dispatch_semaphore_t discoveryStarted = dispatch_semaphore_create(0);
    dispatch_semaphore_t allowDiscoveryToFinish = dispatch_semaphore_create(0);
    discoverer.discoveryBlock = ^NSArray<id<AMAModuleEntryPoint>> *{
        dispatch_semaphore_signal(discoveryStarted);
        dispatch_semaphore_wait(allowDiscoveryToFinish, DISPATCH_TIME_FOREVER);
        return @[];
    };
    AMAModulesController *controller = [[AMAModulesController alloc]
        initWithExecutor:executor
        discoverer:discoverer
        registrationCoordinator:coordinator
        startupParametersHandler:nil];

    [controller startLoading];
    XCTestExpectation *loadingCompleted = [self expectationWithDescription:@"loading and activation completed"];
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        [executor runUntilIdle];
        [loadingCompleted fulfill];
    });
    XCTAssertEqual(dispatch_semaphore_wait(discoveryStarted,
                                           dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC))), 0);

    AMAExtendedStartupObservingMock *observer = [[AMAExtendedStartupObservingMock alloc] init];
    [coordinator registerServiceConfiguration:[[AMAServiceConfiguration alloc]
        initWithStartupObserver:observer reporterStorageController:nil]];
    [controller performActivationWithAppMetricaConfiguration:self.activationConfiguration
                                             activationBlock:nil];

    dispatch_semaphore_signal(allowDiscoveryToFinish);
    [self waitForExpectations:@[ loadingCompleted ] timeout:2.0];

    XCTAssertEqual(discoverer.discoverCallCount, 1u);
    XCTAssertEqual(observer.setupCallCount, 1);
    XCTAssertEqual(AMAModuleActivationDelegateMock.willActivateCallCount, 1);
    XCTAssertEqual(AMAModuleActivationDelegateMock.didActivateCallCount, 1);
}

- (void)testInitializationDoesNotStartExternalRegistrationUntilLoadingStarts
{
    AMALegacyModuleRegistrationCoordinatorSpy *coordinator =
        [[AMALegacyModuleRegistrationCoordinatorSpy alloc] init];
    AMAStepAsyncExecutor *executor = [[AMAStepAsyncExecutor alloc] init];
    AMAModuleEntryPointDiscovererMock *discoverer = [[AMAModuleEntryPointDiscovererMock alloc] init];
    discoverer.entryPoints = @[];

    AMAModulesController *controller = [[AMAModulesController alloc]
        initWithExecutor:executor
        discoverer:discoverer
        registrationCoordinator:coordinator
        startupParametersHandler:nil];
    [coordinator registerActivationDelegate:AMAModuleActivationDelegateMock.class];

    XCTAssertEqual(coordinator.beginRegistrationCallCount, 0u);

    [controller startLoading];

    XCTAssertEqual(coordinator.beginRegistrationCallCount, 0u);
    XCTAssertTrue([executor runNext]);
    XCTAssertEqual(coordinator.beginRegistrationCallCount, 1u);

    [controller performActivationWithAppMetricaConfiguration:self.activationConfiguration
                                             activationBlock:nil];
    [executor runUntilIdle];

    XCTAssertEqual(AMAModuleActivationDelegateMock.willActivateCallCount, 1);
    XCTAssertEqual(AMAModuleActivationDelegateMock.didActivateCallCount, 1);
}

- (void)testReentrantActivationKeepsModuleCallbacksInFIFOOrder
{
    // Submit a second activation from the first will callback. Its synchronous core block runs
    // immediately, while its will/did callbacks are appended after the first activation's did.
    AMAStepAsyncExecutor *executor = [[AMAStepAsyncExecutor alloc] init];
    AMAModuleEntryPointDiscovererMock *discoverer = [[AMAModuleEntryPointDiscovererMock alloc] init];
    AMAModulesController *controller = [self controllerWithExecutor:executor
                                                         discoverer:discoverer
                                               preActivationHandler:nil];
    AMAAppMetricaConfiguration *activationConfiguration = self.activationConfiguration;
    __block BOOL submittedRecursiveActivation = NO;
    AMAModuleActivationDelegateMock.willActivateHandler = ^(__unused AMAModuleActivationConfiguration *configuration) {
        if (submittedRecursiveActivation == NO) {
            submittedRecursiveActivation = YES;
            [controller performActivationWithAppMetricaConfiguration:activationConfiguration
                                                      activationBlock:^{
                [self.recorder recordInvocationWithName:kAMARecursiveCoreActivation];
            }];
        }
    };
    [controller startLoading];
    [executor runUntilIdle];
    [controller performActivationWithAppMetricaConfiguration:activationConfiguration
                                              activationBlock:^{
        [self.recorder recordInvocationWithName:kAMACoreActivation];
    }];
    [executor runUntilIdle];

    NSString *will = [AMAModuleInvocationRecorder invocationNameForClass:AMAModuleActivationDelegateMock.class
                                                                selector:@selector(willActivateWithConfiguration:)];
    NSString *did = [AMAModuleInvocationRecorder invocationNameForClass:AMAModuleActivationDelegateMock.class
                                                               selector:@selector(didActivateWithConfiguration:)];
    NSString *entryPoint = [AMAModuleInvocationRecorder invocationNameForClass:AMAFakeEntryPoint.class
                                                                      selector:@selector(registerComponentsWithRegistrar:)];
    XCTAssertEqualObjects(self.recorder.invocations,
                          (@[ entryPoint, kAMACoreActivation, will,
                              kAMARecursiveCoreActivation, did, will, did ]));
}

- (void)testDidActivationIsEnqueuedWhenSynchronousCoreActivationThrows
{
    AMAStepAsyncExecutor *executor = [[AMAStepAsyncExecutor alloc] init];
    AMAModuleEntryPointDiscovererMock *discoverer = [[AMAModuleEntryPointDiscovererMock alloc] init];
    AMAModulesController *controller = [self controllerWithExecutor:executor
                                                         discoverer:discoverer
                                               preActivationHandler:nil];
    NSException *expectedException = [NSException exceptionWithName:@"test"
                                                             reason:@"expected"
                                                           userInfo:nil];

    [controller startLoading];
    XCTAssertThrowsSpecificNamed(
        [controller performActivationWithAppMetricaConfiguration:self.activationConfiguration
                                                  activationBlock:^{
            @throw expectedException;
        }],
        NSException,
        expectedException.name);

    [executor runUntilIdle];

    XCTAssertEqual(AMAModuleActivationDelegateMock.willActivateCallCount, 1);
    XCTAssertEqual(AMAModuleActivationDelegateMock.didActivateCallCount, 1);
}

- (void)testReentrantAdProviderResolutionAndFlushFromWillRunAfterActivationCallbacks
{
    // Operations requested reentrantly from will must be appended to the executor and must not
    // overtake the did callback that was already scheduled for the current activation.
    AMAStepAsyncExecutor *executor = [[AMAStepAsyncExecutor alloc] init];
    AMAModuleEntryPointDiscovererMock *discoverer = [[AMAModuleEntryPointDiscovererMock alloc] init];
    AMAModulesController *controller = [self controllerWithExecutor:executor
                                                         discoverer:discoverer
                                               preActivationHandler:nil];
    AMAModuleActivationDelegateMock.willActivateHandler = ^(AMAModuleActivationConfiguration *configuration) {
        [controller resolveModuleAdProviderWithHandler:^(__unused id<AMAAdProviding> moduleAdProvider) {
        }];
        [controller notifySendEventsBuffer];
    };

    [controller startLoading];
    [executor runUntilIdle];
    [controller performActivationWithAppMetricaConfiguration:self.activationConfiguration
                                              activationBlock:^{
        [self.recorder recordInvocationWithName:kAMACoreActivation];
    }];
    [executor runUntilIdle];

    NSArray<NSString *> *expected = @[
        [AMAModuleInvocationRecorder invocationNameForClass:AMAFakeEntryPoint.class
                                                  selector:@selector(registerComponentsWithRegistrar:)],
        kAMACoreActivation,
        [AMAModuleInvocationRecorder invocationNameForClass:AMAModuleActivationDelegateMock.class
                                                  selector:@selector(willActivateWithConfiguration:)],
        [AMAModuleInvocationRecorder invocationNameForClass:AMAModuleActivationDelegateMock.class
                                                  selector:@selector(didActivateWithConfiguration:)],
        [AMAModuleInvocationRecorder invocationNameForClass:AMAEventFlushableDelegateMock.class
                                                  selector:@selector(sendEventsBuffer)],
    ];
    XCTAssertEqualObjects(self.recorder.invocations, expected);
    XCTAssertEqual(discoverer.discoverCallCount, 1u);
}

@end
