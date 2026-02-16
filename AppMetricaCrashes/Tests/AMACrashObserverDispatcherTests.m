
#import <XCTest/XCTest.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMACrashObserverDispatcher.h"
#import "AMACrashObserverConfiguration.h"
#import "AMACrashObserving.h"
#import "AMACrashEvent.h"
#import "AMADecodedCrash.h"
#import "MockCrashObserverDelegate.h"
#import "MockCrashObserverDelegateMinimal.h"

@interface AMACrashObserverDispatcherTests : XCTestCase

@property (nonatomic, strong) AMACrashObserverDispatcher *manager;
@property (nonatomic, strong) dispatch_queue_t callbackQueue;

@end

@implementation AMACrashObserverDispatcherTests

- (void)setUp
{
    [super setUp];

    self.manager = [[AMACrashObserverDispatcher alloc] init];
    [self.manager setValue:[[AMACurrentQueueExecutor alloc] init] forKey:@"executor"];
    self.callbackQueue = dispatch_queue_create("test.callback", DISPATCH_QUEUE_SERIAL);
}

- (void)tearDown
{
    self.manager = nil;
    self.callbackQueue = nil;

    [super tearDown];
}

- (AMADecodedCrash *)sampleDecodedCrash
{
    return [[AMADecodedCrash alloc] initWithAppState:nil
                                         appBuildUID:nil
                                    errorEnvironment:nil
                                      appEnvironment:nil
                                                info:nil
                                        binaryImages:nil
                                              system:nil
                                               crash:nil];
}

#pragma mark - Registration

- (void)testRegisterConfiguration
{
    MockCrashObserverDelegate *delegate = [[MockCrashObserverDelegate alloc] init];
    AMACrashObserverConfiguration *config =
        [[AMACrashObserverConfiguration alloc] initWithDelegate:delegate callbackQueue:self.callbackQueue];

    [self.manager registerObserverConfiguration:config];

    XCTAssertEqual([self.manager registeredConfigurations].count, 1u);
}

- (void)testRegisterSameConfigurationTwice
{
    MockCrashObserverDelegate *delegate = [[MockCrashObserverDelegate alloc] init];
    AMACrashObserverConfiguration *config =
        [[AMACrashObserverConfiguration alloc] initWithDelegate:delegate callbackQueue:self.callbackQueue];

    [self.manager registerObserverConfiguration:config];
    [self.manager registerObserverConfiguration:config];

    XCTAssertEqual([self.manager registeredConfigurations].count, 1u);
}

- (void)testUnregisterConfiguration
{
    MockCrashObserverDelegate *delegate = [[MockCrashObserverDelegate alloc] init];
    AMACrashObserverConfiguration *config =
        [[AMACrashObserverConfiguration alloc] initWithDelegate:delegate callbackQueue:self.callbackQueue];

    [self.manager registerObserverConfiguration:config];
    [self.manager unregisterObserverConfiguration:config];

    XCTAssertEqual([self.manager registeredConfigurations].count, 0u);
}

#pragma mark - Crash Notification

- (void)testNotifyCrash
{
    MockCrashObserverDelegate *delegate = [[MockCrashObserverDelegate alloc] init];
    delegate.didDetectCrashExpectation = [self expectationWithDescription:@"crash"];
    AMACrashObserverConfiguration *config =
        [[AMACrashObserverConfiguration alloc] initWithDelegate:delegate callbackQueue:self.callbackQueue];
    [self.manager registerObserverConfiguration:config];

    [self.manager notifyCrash:[self sampleDecodedCrash]];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
    XCTAssertNotNil(delegate.lastCrashEvent);
}

#pragma mark - ANR Notification

- (void)testNotifyANR
{
    MockCrashObserverDelegate *delegate = [[MockCrashObserverDelegate alloc] init];
    delegate.didDetectANRExpectation = [self expectationWithDescription:@"anr"];
    AMACrashObserverConfiguration *config =
        [[AMACrashObserverConfiguration alloc] initWithDelegate:delegate callbackQueue:self.callbackQueue];
    [self.manager registerObserverConfiguration:config];

    [self.manager notifyANR:[self sampleDecodedCrash]];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
    XCTAssertNotNil(delegate.lastCrashEvent);
}

- (void)testNotifyANRSkipsMinimalDelegate
{
    MockCrashObserverDelegateMinimal *delegate = [[MockCrashObserverDelegateMinimal alloc] init];
    AMACrashObserverConfiguration *config =
        [[AMACrashObserverConfiguration alloc] initWithDelegate:delegate callbackQueue:self.callbackQueue];
    [self.manager registerObserverConfiguration:config];

    [self.manager notifyANR:[self sampleDecodedCrash]];

    // Dispatch a barrier block to ensure any pending async work on callbackQueue has finished
    XCTestExpectation *barrierExpectation = [self expectationWithDescription:@"barrier"];
    dispatch_async(self.callbackQueue, ^{
        [barrierExpectation fulfill];
    });
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
    XCTAssertNil(delegate.lastCrashEvent);
}

#pragma mark - Probable Unhandled Crash Notification

- (void)testNotifyProbableUnhandledCrash
{
    MockCrashObserverDelegate *delegate = [[MockCrashObserverDelegate alloc] init];
    delegate.didDetectProbableUnhandledCrashExpectation = [self expectationWithDescription:@"unhandled"];
    AMACrashObserverConfiguration *config =
        [[AMACrashObserverConfiguration alloc] initWithDelegate:delegate callbackQueue:self.callbackQueue];
    [self.manager registerObserverConfiguration:config];

    [self.manager notifyProbableUnhandledCrash:@"test error"];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
    XCTAssertEqualObjects(delegate.lastErrorMessage, @"test error");
}

- (void)testNotifyProbableUnhandledCrashEmptyStringDoesNotCallDelegate
{
    MockCrashObserverDelegate *delegate = [[MockCrashObserverDelegate alloc] init];
    delegate.didDetectProbableUnhandledCrashExpectation = [self expectationWithDescription:@"unhandled"];
    delegate.didDetectProbableUnhandledCrashExpectation.inverted = YES;
    AMACrashObserverConfiguration *config =
        [[AMACrashObserverConfiguration alloc] initWithDelegate:delegate callbackQueue:self.callbackQueue];
    [self.manager registerObserverConfiguration:config];

    [self.manager notifyProbableUnhandledCrash:@""];

    [self waitForExpectationsWithTimeout:0.1 handler:nil];
}

- (void)testNotifyProbableUnhandledCrashSkipsMinimalDelegate
{
    MockCrashObserverDelegateMinimal *delegate = [[MockCrashObserverDelegateMinimal alloc] init];
    AMACrashObserverConfiguration *config =
        [[AMACrashObserverConfiguration alloc] initWithDelegate:delegate callbackQueue:self.callbackQueue];
    [self.manager registerObserverConfiguration:config];

    [self.manager notifyProbableUnhandledCrash:@"test error"];

    XCTestExpectation *barrierExpectation = [self expectationWithDescription:@"barrier"];
    dispatch_async(self.callbackQueue, ^{
        [barrierExpectation fulfill];
    });
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
    XCTAssertNil(delegate.lastCrashEvent);
}

#pragma mark - Multiple Observers

- (void)testMultipleObserversReceiveCrash
{
    MockCrashObserverDelegate *delegateA = [[MockCrashObserverDelegate alloc] init];
    delegateA.didDetectCrashExpectation = [self expectationWithDescription:@"crashA"];
    MockCrashObserverDelegate *delegateB = [[MockCrashObserverDelegate alloc] init];
    delegateB.didDetectCrashExpectation = [self expectationWithDescription:@"crashB"];

    AMACrashObserverConfiguration *configA =
        [[AMACrashObserverConfiguration alloc] initWithDelegate:delegateA callbackQueue:self.callbackQueue];
    AMACrashObserverConfiguration *configB =
        [[AMACrashObserverConfiguration alloc] initWithDelegate:delegateB callbackQueue:self.callbackQueue];
    [self.manager registerObserverConfiguration:configA];
    [self.manager registerObserverConfiguration:configB];

    [self.manager notifyCrash:[self sampleDecodedCrash]];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
    XCTAssertNotNil(delegateA.lastCrashEvent);
    XCTAssertNotNil(delegateB.lastCrashEvent);
}

- (void)testUnregisteredObserverDoesNotReceiveCrash
{
    MockCrashObserverDelegate *delegate = [[MockCrashObserverDelegate alloc] init];
    delegate.didDetectCrashExpectation = [self expectationWithDescription:@"crash"];
    delegate.didDetectCrashExpectation.inverted = YES;
    AMACrashObserverConfiguration *config =
        [[AMACrashObserverConfiguration alloc] initWithDelegate:delegate callbackQueue:self.callbackQueue];
    [self.manager registerObserverConfiguration:config];
    [self.manager unregisterObserverConfiguration:config];

    [self.manager notifyCrash:[self sampleDecodedCrash]];

    [self waitForExpectationsWithTimeout:0.1 handler:nil];
}

@end
