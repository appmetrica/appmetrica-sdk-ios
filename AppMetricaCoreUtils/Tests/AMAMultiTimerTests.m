#import <XCTest/XCTest.h>
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>
#import "AMACancellableExecutorMock.h"
#import "AMAMultiTimerDelegateMock.h"
#import "AMAAsyncCancellableExecutorMock.h"

static const NSTimeInterval defaultTimeout = 20;

@interface AMAMultiTimerTests : XCTestCase

@property (nonnull, nonatomic, strong) NSArray<NSNumber *> *delays;
@property (nonnull, nonatomic, strong) AMACancellableExecutorMock *mockExecutor;
@property (nonnull, nonatomic, strong) AMAAsyncCancellableExecutorMock *asyncMockExecutor;
@property (nonnull, nonatomic, strong) AMAMultiTimer *multitimer;
@property (nonnull, nonatomic, strong) AMAMultiTimerDelegateMock *delegateMock;

@end

@implementation AMAMultiTimerTests

- (void)setUp 
{
    self.delays = @[@(1), @(2), @(3)];
    self.mockExecutor = [[AMACancellableExecutorMock alloc] init];
    self.asyncMockExecutor = [[AMAAsyncCancellableExecutorMock alloc] init];
    self.delegateMock = [[AMAMultiTimerDelegateMock alloc] init];
    
}

- (void)tearDown 
{
}

- (void)testStart 
{
    self.multitimer = [[AMAMultiTimer alloc] initWithDelays:self.delays
                                                   executor:self.mockExecutor
                                                   delegate:self.delegateMock];
    
    self.delegateMock.fireCalledExpectation = [self expectationWithDescription:@"Fire called"];
    self.delegateMock.fireCalledExpectation.expectedFulfillmentCount = 3;
    
    [self.multitimer start];
    XCTAssertEqualObjects(self.mockExecutor.receivedDelays, self.delays);
    
    [self waitForExpectations:@[self.delegateMock.fireCalledExpectation] timeout:defaultTimeout];
    XCTAssertEqual(self.multitimer.status, AMAMultitimerStatusNotStarted);
}

- (void)testIfDelegateInvalidate
{
    self.multitimer = [[AMAMultiTimer alloc] initWithDelays:self.delays
                                                   executor:self.mockExecutor
                                                   delegate:self.delegateMock];
    
    XCTAssertEqual(self.multitimer.status, AMAMultitimerStatusNotStarted);
    
    self.delegateMock.fireCalledExpectation = [self expectationWithDescription:@"Fire called only once"];
    self.delegateMock.invalidateTimer = YES;
    
    [self.multitimer start];
    XCTAssertEqualObjects(self.mockExecutor.receivedDelays, @[self.delays.firstObject]);
    
    [self waitForExpectations:@[self.delegateMock.fireCalledExpectation] timeout:defaultTimeout];
    XCTAssertEqual(self.multitimer.status, AMAMultitimerStatusNotStarted);
}

- (void)testAsyncStart
{
    self.multitimer = [[AMAMultiTimer alloc] initWithDelays:self.delays
                                                   executor:self.asyncMockExecutor
                                                   delegate:self.delegateMock];
    NSMutableArray<XCTestExpectation *> *expectations = [NSMutableArray array];
    
    self.asyncMockExecutor.executeExpectation = [self expectationWithDescription:@"First execute"];
    [expectations addObject:self.asyncMockExecutor.executeExpectation];
    
    [self.multitimer start];
    XCTAssertEqual(self.multitimer.status, AMAMultitimerStatusStarted);
    [self waitForExpectations:expectations timeout:0];
    [expectations removeAllObjects];
    
    
    self.delegateMock.fireCalledExpectation = [self expectationWithDescription:@"Fire should be called"];
    [expectations addObject:self.delegateMock.fireCalledExpectation];
    
    self.asyncMockExecutor.executeExpectation = [self expectationWithDescription:@"Second execute"];
    [expectations addObject:self.asyncMockExecutor.executeExpectation];
    
    [self waitForExpectations:expectations timeout:defaultTimeout];
    XCTAssertEqual(self.multitimer.status, AMAMultitimerStatusStarted);
    [expectations removeAllObjects];
    
    
    self.delegateMock.fireCalledExpectation = [self expectationWithDescription:@"Fire should be called"];
    [expectations addObject:self.delegateMock.fireCalledExpectation];
    
    self.asyncMockExecutor.executeExpectation = [self expectationWithDescription:@"Third execute"];
    [expectations addObject:self.asyncMockExecutor.executeExpectation];
    
    [self waitForExpectations:expectations timeout:defaultTimeout];
    XCTAssertEqual(self.multitimer.status, AMAMultitimerStatusStarted);
    [expectations removeAllObjects];
    
    
    self.delegateMock.fireCalledExpectation = [self expectationWithDescription:@"Fire should be called"];
    [expectations addObject:self.delegateMock.fireCalledExpectation];
    
    [self waitForExpectations:expectations timeout:defaultTimeout];
    XCTAssertEqual(self.multitimer.status, AMAMultitimerStatusNotStarted);
}

- (void)testAsyncStartAndInvalidate
{
    self.multitimer = [[AMAMultiTimer alloc] initWithDelays:self.delays
                                                   executor:self.asyncMockExecutor
                                                   delegate:self.delegateMock];
    NSMutableArray<XCTestExpectation *> *expectations = [NSMutableArray array];
    self.delegateMock.fireCalledExpectation = [self expectationWithDescription:@"Fire should be called"];
    self.delegateMock.fireCalledExpectation.expectedFulfillmentCount = 1; // second fire is scheduled, but not called in waitForExpectations
    [expectations addObject:self.delegateMock.fireCalledExpectation];
    
    self.asyncMockExecutor.executeExpectation = [self expectationWithDescription:@"Execute(2) expectation"];
    self.asyncMockExecutor.executeExpectation.expectedFulfillmentCount = 2;
    [expectations addObject:self.asyncMockExecutor.executeExpectation];
    
    [self.multitimer start];
    [self waitForExpectations:expectations timeout:defaultTimeout];
    XCTAssertEqual(self.multitimer.status, AMAMultitimerStatusStarted);
    [expectations removeAllObjects];
    
    self.delegateMock.fireCalledExpectation = [self expectationWithDescription:@"Fire should not be called"];
    self.delegateMock.fireCalledExpectation.inverted = YES;
    [expectations addObject:self.delegateMock.fireCalledExpectation];
    
    self.asyncMockExecutor.cancelExpectation = [self expectationWithDescription:@"Cancel should be called"];
    [expectations addObject:self.asyncMockExecutor.cancelExpectation];
    self.asyncMockExecutor.executeExpectation = [self expectationWithDescription:@"Execute should not be called"];
    self.asyncMockExecutor.executeExpectation.inverted = YES;
    [expectations addObject:self.asyncMockExecutor.executeExpectation];
    
    [self.multitimer invalidate];
    XCTAssertEqual(self.multitimer.status, AMAMultitimerStatusNotStarted);
    
    [self waitForExpectations:expectations timeout:10];
    
    XCTAssertEqual(self.multitimer.status, AMAMultitimerStatusNotStarted);
}

@end
