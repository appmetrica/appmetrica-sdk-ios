
#import <XCTest/XCTest.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMANotificationsListener.h"

@interface AMANotificationsListenerTests : XCTestCase

@property (nonatomic, strong) AMANotificationsListener *listener;

@end

@implementation AMANotificationsListenerTests

- (void)setUp
{
    AMACurrentQueueExecutor *executor = [AMACurrentQueueExecutor new];
    self.listener = [[AMANotificationsListener alloc] initWithExecutor:executor];
}

- (void)testObjectNotificationOnSubscribe {
    id object = [NSObject new];
    __block BOOL callbackCalled = NO;
    [self.listener subscribeObject:object
                    toNotification:@"TestNotification"
                      withCallback:^(NSNotification *notification) {
                          callbackCalled = YES;
                      }];

    [[NSNotificationCenter defaultCenter] postNotificationName:@"TestNotification" object:nil];
    XCTAssertTrue(callbackCalled);
}

- (void)testPartialObjectUnsubscribe {
    id object = [NSObject new];
    __block BOOL firstCallback = NO;
    [self.listener subscribeObject:object
                    toNotification:@"TestNotification1"
                      withCallback:^(NSNotification *notification) {
                          firstCallback = YES;
                      }];
    __block BOOL secondCallback = NO;
    [self.listener subscribeObject:object
                    toNotification:@"TestNotification2"
                      withCallback:^(NSNotification *notification) {
                          secondCallback = YES;
                      }];

    [self.listener unsubscribeObject:object fromNotification:@"TestNotification1"];

    [[NSNotificationCenter defaultCenter] postNotificationName:@"TestNotification1" object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"TestNotification2" object:nil];
    XCTAssertFalse(firstCallback);
    XCTAssertTrue(secondCallback);
}

- (void)testNoNotificationsOnFullUnsubscribe {
    id object = [NSObject new];
    __block BOOL callbackCalled = NO;
    [self.listener subscribeObject:object
                    toNotification:@"TestNotification"
                      withCallback:^(NSNotification *notification) {
                          callbackCalled = YES;
                      }];
    [self.listener unsubscribeObject:object];

    [[NSNotificationCenter defaultCenter] postNotificationName:@"TestNotification" object:nil];
    XCTAssertFalse(callbackCalled);
}

- (void)testOneNotificationForEachSubscriber {
    id firstSubscriber = [NSObject new];
    __block NSUInteger firstCallbackCallCount = 0;
    [self.listener subscribeObject:firstSubscriber
                    toNotification:@"TestNotification"
                      withCallback:^(NSNotification *notification) {
                          ++firstCallbackCallCount;
                      }];

    id secondSubscriber = [NSObject new];
    __block NSUInteger secondCallbackCallCount = 0;
    [self.listener subscribeObject:secondSubscriber
                    toNotification:@"TestNotification"
                      withCallback:^(NSNotification *notification) {
                          ++secondCallbackCallCount;
                      }];


    [[NSNotificationCenter defaultCenter] postNotificationName:@"TestNotification" object:nil];
    XCTAssertTrue(firstCallbackCallCount == 1);
    XCTAssertTrue(secondCallbackCallCount == 1);
}

- (void)testOneNotificationAfterResubscribing {
    id object = [NSObject new];
    __block NSUInteger callbackCallCount = 0;
    [self.listener subscribeObject:object
                    toNotification:@"TestNotification"
                      withCallback:^(NSNotification *notification) {
                          ++callbackCallCount;
                      }];
    [self.listener unsubscribeObject:object];
    [self.listener subscribeObject:object
                    toNotification:@"TestNotification"
                      withCallback:^(NSNotification *notification) {
                          ++callbackCallCount;
                      }];

    [[NSNotificationCenter defaultCenter] postNotificationName:@"TestNotification" object:nil];
    XCTAssertTrue(callbackCallCount == 1);
}

@end
