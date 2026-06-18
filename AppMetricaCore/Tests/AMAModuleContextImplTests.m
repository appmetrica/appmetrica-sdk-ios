
#import <XCTest/XCTest.h>
#import "AMAModuleContextImpl.h"
#import "AMACore.h"
#import "Mocks/AMAAdProvidingMock.h"
#import "Mocks/AMAModuleContextMocks.h"
#import "Utilities/AMAEventPollingDelegateMock.h"

@interface AMAModuleContextImplTests : XCTestCase
@property (nonatomic, strong) AMAModuleContextImpl *ctx;
@property (nonatomic, strong) AMAModuleActivationConfiguration *config;
@end

@implementation AMAModuleContextImplTests

- (void)setUp
{
    self.ctx = [[AMAModuleContextImpl alloc] init];
    self.config = [[AMAModuleActivationConfiguration alloc] initWithApiKey:@"test-key"];
    [AMAModuleActivationDelegateMock reset];
    [AMAEventFlushableDelegateMock reset];
}

// MARK: - Initial state

- (void)testInitialState_adProviderIsNil
{
    XCTAssertNil(self.ctx.adProvider);
}

- (void)testInitialState_eventPollingDelegatesIsEmpty
{
    XCTAssertEqual(self.ctx.eventPollingDelegates.count, 0u);
}

- (void)testInitialState_startupObserversIsEmpty
{
    XCTAssertEqual(self.ctx.startupObservers.count, 0u);
}

- (void)testInitialState_reporterStorageControllersIsEmpty
{
    XCTAssertEqual(self.ctx.reporterStorageControllers.count, 0u);
}

// MARK: - addActivationDelegate + notifyWillActivateWithConfiguration

- (void)testNotifyWillActivate_callsAddedDelegate
{
    [self.ctx addActivationDelegate:[AMAModuleActivationDelegateMock class]];
    [self.ctx notifyWillActivateWithConfiguration:self.config];

    XCTAssertEqual([AMAModuleActivationDelegateMock willActivateCallCount], 1);
}

- (void)testNotifyWillActivate_passesConfiguration
{
    [self.ctx addActivationDelegate:[AMAModuleActivationDelegateMock class]];
    [self.ctx notifyWillActivateWithConfiguration:self.config];

    XCTAssertEqualObjects([AMAModuleActivationDelegateMock lastConfiguration], self.config);
}


- (void)testNotifyWillActivate_addSameDelegateTwice_callsOnce
{
    [self.ctx addActivationDelegate:[AMAModuleActivationDelegateMock class]];
    [self.ctx addActivationDelegate:[AMAModuleActivationDelegateMock class]];
    [self.ctx notifyWillActivateWithConfiguration:self.config];

    XCTAssertEqual([AMAModuleActivationDelegateMock willActivateCallCount], 1);
}

// MARK: - addActivationDelegate + notifyDidActivateWithConfiguration

- (void)testNotifyDidActivate_callsAddedDelegate
{
    [self.ctx addActivationDelegate:[AMAModuleActivationDelegateMock class]];
    [self.ctx notifyDidActivateWithConfiguration:self.config];

    XCTAssertEqual([AMAModuleActivationDelegateMock didActivateCallCount], 1);
}


// MARK: - addEventFlushableDelegate + notifySendEventsBuffer

- (void)testNotifySendEventsBuffer_callsAddedDelegate
{
    [self.ctx addEventFlushableDelegate:[AMAEventFlushableDelegateMock class]];
    [self.ctx notifySendEventsBuffer];

    XCTAssertEqual([AMAEventFlushableDelegateMock sendEventsBufferCallCount], 1);
}


- (void)testNotifySendEventsBuffer_addSameDelegateTwice_callsOnce
{
    [self.ctx addEventFlushableDelegate:[AMAEventFlushableDelegateMock class]];
    [self.ctx addEventFlushableDelegate:[AMAEventFlushableDelegateMock class]];
    [self.ctx notifySendEventsBuffer];

    XCTAssertEqual([AMAEventFlushableDelegateMock sendEventsBufferCallCount], 1);
}

// MARK: - addEventPollingDelegate + eventPollingDelegates

- (void)testAddEventPollingDelegate_isInEventPollingDelegates
{
    [self.ctx addEventPollingDelegate:[AMAEventPollingDelegateMock class]];
    XCTAssertTrue([self.ctx.eventPollingDelegates containsObject:[AMAEventPollingDelegateMock class]]);
}

- (void)testAddSamePollingDelegateTwice_containsOnce
{
    [self.ctx addEventPollingDelegate:[AMAEventPollingDelegateMock class]];
    [self.ctx addEventPollingDelegate:[AMAEventPollingDelegateMock class]];
    XCTAssertEqual(self.ctx.eventPollingDelegates.count, 1u);
}

// MARK: - registerExternalService + startupObservers

- (void)testRegisterExternalService_withStartupObserver_isInStartupObservers
{
    AMAExtendedStartupObservingMock *observer = [AMAExtendedStartupObservingMock new];
    AMAServiceConfiguration *config = [[AMAServiceConfiguration alloc]
        initWithStartupObserver:observer reporterStorageController:nil];

    [self.ctx registerExternalService:config];

    XCTAssertTrue([self.ctx.startupObservers containsObject:observer]);
}

- (void)testRegisterExternalService_nilStartupObserver_notAddedToStartupObservers
{
    AMAReporterStorageControllingMock *controller = [AMAReporterStorageControllingMock new];
    AMAServiceConfiguration *config = [[AMAServiceConfiguration alloc]
        initWithStartupObserver:nil reporterStorageController:controller];

    [self.ctx registerExternalService:config];

    XCTAssertEqual(self.ctx.startupObservers.count, 0u);
}

- (void)testRegisterTwoExternalServicesWithObservers_bothInStartupObservers
{
    AMAExtendedStartupObservingMock *obs1 = [AMAExtendedStartupObservingMock new];
    AMAExtendedStartupObservingMock *obs2 = [AMAExtendedStartupObservingMock new];

    [self.ctx registerExternalService:[[AMAServiceConfiguration alloc]
        initWithStartupObserver:obs1 reporterStorageController:nil]];
    [self.ctx registerExternalService:[[AMAServiceConfiguration alloc]
        initWithStartupObserver:obs2 reporterStorageController:nil]];

    XCTAssertTrue([self.ctx.startupObservers containsObject:obs1]);
    XCTAssertTrue([self.ctx.startupObservers containsObject:obs2]);
    XCTAssertEqual(self.ctx.startupObservers.count, 2u);
}

// MARK: - registerExternalService + reporterStorageControllers

- (void)testRegisterExternalService_withStorageController_isInReporterStorageControllers
{
    AMAReporterStorageControllingMock *controller = [AMAReporterStorageControllingMock new];
    AMAServiceConfiguration *config = [[AMAServiceConfiguration alloc]
        initWithStartupObserver:nil reporterStorageController:controller];

    [self.ctx registerExternalService:config];

    XCTAssertTrue([self.ctx.reporterStorageControllers containsObject:controller]);
}

- (void)testRegisterExternalService_nilStorageController_notAddedToReporterStorageControllers
{
    AMAExtendedStartupObservingMock *observer = [AMAExtendedStartupObservingMock new];
    AMAServiceConfiguration *config = [[AMAServiceConfiguration alloc]
        initWithStartupObserver:observer reporterStorageController:nil];

    [self.ctx registerExternalService:config];

    XCTAssertEqual(self.ctx.reporterStorageControllers.count, 0u);
}

- (void)testRegisterExternalServiceWithBoth_addsToBothSets
{
    AMAExtendedStartupObservingMock *observer = [AMAExtendedStartupObservingMock new];
    AMAReporterStorageControllingMock *controller = [AMAReporterStorageControllingMock new];
    AMAServiceConfiguration *config = [[AMAServiceConfiguration alloc]
        initWithStartupObserver:observer reporterStorageController:controller];

    [self.ctx registerExternalService:config];

    XCTAssertTrue([self.ctx.startupObservers containsObject:observer]);
    XCTAssertTrue([self.ctx.reporterStorageControllers containsObject:controller]);
}

// MARK: - registerAdProvider + adProvider

- (void)testRegisterAdProvider_beforeActivation_setsAdProvider
{
    AMAAdProvidingMock *provider = [AMAAdProvidingMock new];
    [self.ctx registerAdProvider:provider];

    XCTAssertEqualObjects(self.ctx.adProvider, provider);
}

- (void)testRegisterAdProvider_secondCall_overwritesPreviousProvider
{
    AMAAdProvidingMock *first = [AMAAdProvidingMock new];
    AMAAdProvidingMock *second = [AMAAdProvidingMock new];
    [self.ctx registerAdProvider:first];
    [self.ctx registerAdProvider:second];

    XCTAssertEqualObjects(self.ctx.adProvider, second);
}

@end
