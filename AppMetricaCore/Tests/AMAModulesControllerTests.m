
#import <XCTest/XCTest.h>
#import "AMAModulesController.h"
#import "AMAModuleContextImpl.h"
#import "AMACoreModuleComponentsInitializer.h"
#import <AppMetricaCoreExtension/AppMetricaCoreExtension.h>
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "Mocks/AMAModuleContextMocks.h"

// MARK: - Tests

@interface AMAModulesControllerTests : XCTestCase
@property (nonatomic, strong) AMAModulesController *controller;
@end

@implementation AMAModulesControllerTests

- (void)setUp
{
    [AMACoreModuleComponentsInitializer stub:@selector(discoverAndRegisterInController:classLookup:)];
    AMACurrentQueueExecutor *executor = [AMACurrentQueueExecutor new];
    self.controller = [[AMAModulesController alloc] initWithExecutor:executor
                                              startupParametersHandler:nil];
    [AMAModuleActivationDelegateMock reset];
    [AMAEventFlushableDelegateMock reset];
}

- (void)tearDown
{
    [AMACoreModuleComponentsInitializer clearStubs];
}

// MARK: - Initial state

- (void)testContext_notNilAfterInit
{
    XCTAssertNotNil(self.controller.context);
}

- (void)testAdProvider_nilWhenNotRegistered
{
    XCTAssertNil(self.controller.adProvider);
}

// MARK: - registerModule

- (void)testRegisterModule_callsInitModuleWithContext
{
    AMAFakeEntryPoint *ep = [AMAFakeEntryPoint new];
    [self.controller registerModule:ep];
    XCTAssertEqual(ep.initCallCount, 1);
}

- (void)testRegisterModule_passesControllerContext
{
    AMAFakeEntryPoint *ep = [AMAFakeEntryPoint new];
    [self.controller registerModule:ep];
    XCTAssertTrue(ep.receivedContext == self.controller.context);
}

- (void)testRegisterMultipleModules_allInitialized
{
    AMAFakeEntryPoint *ep1 = [AMAFakeEntryPoint new];
    AMAFakeEntryPoint *ep2 = [AMAFakeEntryPoint new];
    [self.controller registerModule:ep1];
    [self.controller registerModule:ep2];
    XCTAssertEqual(ep1.initCallCount, 1);
    XCTAssertEqual(ep2.initCallCount, 1);
}

// MARK: - notifyWillActivateWithConfiguration

- (void)testNotifyWillActivate_notifiesActivationDelegates
{
    [self.controller.context addActivationDelegate:[AMAModuleActivationDelegateMock class]];
    AMAModuleActivationConfiguration *config =
        [[AMAModuleActivationConfiguration alloc] initWithApiKey:@"test-key"];
    [self.controller notifyWillActivateWithConfiguration:config];
    XCTAssertEqual([AMAModuleActivationDelegateMock willActivateCallCount], 1);
}

- (void)testNotifyWillActivate_passesConfiguration
{
    [self.controller.context addActivationDelegate:[AMAModuleActivationDelegateMock class]];
    AMAModuleActivationConfiguration *config =
        [[AMAModuleActivationConfiguration alloc] initWithApiKey:@"test-key"];
    [self.controller notifyWillActivateWithConfiguration:config];
    XCTAssertEqualObjects([AMAModuleActivationDelegateMock lastConfiguration], config);
}

// MARK: - notifyDidActivateWithConfiguration

- (void)testNotifyDidActivate_notifiesActivationDelegates
{
    [self.controller.context addActivationDelegate:[AMAModuleActivationDelegateMock class]];
    AMAModuleActivationConfiguration *config =
        [[AMAModuleActivationConfiguration alloc] initWithApiKey:@"test-key"];
    [self.controller notifyDidActivateWithConfiguration:config];
    XCTAssertEqual([AMAModuleActivationDelegateMock didActivateCallCount], 1);
}

// MARK: - Startup observers

- (void)testNotifyStartupUpdated_callsObservers
{
    AMAExtendedStartupObservingMock *obs = [AMAExtendedStartupObservingMock new];
    [self.controller.context registerExternalService:[[AMAServiceConfiguration alloc]
        initWithStartupObserver:obs reporterStorageController:nil]];

    [self.controller notifyStartupUpdatedWithParameters:@{@"k": @"v"}];

    XCTAssertEqual(obs.updatedCallCount, 1);
    XCTAssertEqualObjects(obs.lastParameters[@"k"], @"v");
}

- (void)testNotifyStartupFailed_callsObservers
{
    AMAExtendedStartupObservingMock *obs = [AMAExtendedStartupObservingMock new];
    [self.controller.context registerExternalService:[[AMAServiceConfiguration alloc]
        initWithStartupObserver:obs reporterStorageController:nil]];

    NSError *error = [NSError errorWithDomain:@"test" code:42 userInfo:nil];
    [self.controller notifyStartupFailedWithError:error];

    XCTAssertEqual(obs.failedCallCount, 1);
    XCTAssertEqualObjects(obs.lastError, error);
}

// MARK: - startupParametersHandler

- (void)testStartupParametersHandler_calledWithObserverParameters
{
    AMAExtendedStartupObservingMock *obs = [AMAExtendedStartupObservingMock new];
    obs.stubbedStartupParameters = @{@"p": @"v"};
    [self.controller.context registerExternalService:[[AMAServiceConfiguration alloc]
        initWithStartupObserver:obs reporterStorageController:nil]];

    NSMutableArray *received = [NSMutableArray array];
    self.controller.startupParametersHandler = ^(NSDictionary *params) {
        [received addObject:params];
    };
    [self.controller ensureLoaded];

    XCTAssertEqual(received.count, 1u);
    XCTAssertEqualObjects(received.firstObject[@"p"], @"v");
}

- (void)testStartupParametersHandler_notCalledForEmptyParameters
{
    AMAExtendedStartupObservingMock *obs = [AMAExtendedStartupObservingMock new];
    [self.controller.context registerExternalService:[[AMAServiceConfiguration alloc]
        initWithStartupObserver:obs reporterStorageController:nil]];

    __block NSInteger callCount = 0;
    self.controller.startupParametersHandler = ^(NSDictionary *params) { callCount++; };
    [self.controller ensureLoaded];

    XCTAssertEqual(callCount, 0);
}

- (void)testStartupParametersHandler_calledPerObserverWithParameters
{
    AMAExtendedStartupObservingMock *obs1 = [AMAExtendedStartupObservingMock new];
    obs1.stubbedStartupParameters = @{@"a": @"1"};
    AMAExtendedStartupObservingMock *obs2 = [AMAExtendedStartupObservingMock new];
    obs2.stubbedStartupParameters = @{@"b": @"2"};

    [self.controller.context registerExternalService:[[AMAServiceConfiguration alloc]
        initWithStartupObserver:obs1 reporterStorageController:nil]];
    [self.controller.context registerExternalService:[[AMAServiceConfiguration alloc]
        initWithStartupObserver:obs2 reporterStorageController:nil]];

    __block NSInteger callCount = 0;
    self.controller.startupParametersHandler = ^(NSDictionary *params) { callCount++; };
    [self.controller ensureLoaded];

    XCTAssertEqual(callCount, 2);
}

// MARK: - Reporter storage

- (void)testSetupReporterStorage_callsStorageControllers
{
    AMAReporterStorageControllingMock *ctrl = [AMAReporterStorageControllingMock new];
    [self.controller.context registerExternalService:[[AMAServiceConfiguration alloc]
        initWithStartupObserver:nil reporterStorageController:ctrl]];

    [self.controller setupReporterStorageWithProvider:nil main:YES apiKey:@"key"];

    XCTAssertEqual(ctrl.setupCallCount, 1);
}

// MARK: - Event flushing

- (void)testNotifySendEventsBuffer_callsFlushableDelegates
{
    [self.controller.context addEventFlushableDelegate:[AMAEventFlushableDelegateMock class]];
    [self.controller notifySendEventsBuffer];
    XCTAssertEqual([AMAEventFlushableDelegateMock sendEventsBufferCallCount], 1);
}

// MARK: - ensureLoaded

- (void)testEnsureLoaded_isIdempotent
{
    AMAFakeEntryPoint *ep = [AMAFakeEntryPoint new];
    [self.controller registerModule:ep];
    NSInteger countAfterRegister = ep.initCallCount;

    [self.controller ensureLoaded];
    [self.controller ensureLoaded];

    XCTAssertEqual(ep.initCallCount, countAfterRegister);
}

@end
