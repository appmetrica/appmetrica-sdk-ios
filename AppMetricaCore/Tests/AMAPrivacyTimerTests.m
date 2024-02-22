#import <XCTest/XCTest.h>
#import "AMAPrivacyTimer.h"
#import "AMAPrivacyTimerStorage.h"
#import "AMAAdProvider.h"
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMAPrivacyTimerStorageMock.h"
#import "AMAPrivacyTimerDelegateMock.h"
#import "AMAPrivacyTimerMock.h"
#import <Kiwi/Kiwi.h>

@interface AMAPrivacyTimerTests : XCTestCase

@property (nonnull, nonatomic, strong) NSArray<NSNumber *> *rertyNumbers;
@property (nonnull, nonatomic, strong) id<AMAAsyncExecuting> executor;
@property (nonnull, nonatomic, strong) AMAPrivacyTimerStorageMock *timerStorage;
@property (nonnull, nonatomic, strong) AMAAdProvider *adProvider;
@property (nonnull, nonatomic, strong) AMAPrivacyTimerDelegateMock *delegateMock;


@end

@implementation AMAPrivacyTimerTests

- (void)setUp 
{
    self.rertyNumbers = @[@(1), @(2), @(3)];
    
    self.executor = [[AMAExecutor alloc] initWithQueue:dispatch_get_main_queue()];
    
    self.timerStorage = [AMAPrivacyTimerStorageMock new];
    self.timerStorage.retryPeriod = self.rertyNumbers;
    self.timerStorage.isResendPeriodOutdated = YES;
    
    //TODO: remove shared instance
    self.adProvider = [AMAAdProvider mock];
    
    self.delegateMock = [AMAPrivacyTimerDelegateMock new];
    
    
}

- (void)tearDown 
{

}

- (void)testFireNotCalledAfterInit
{
    AMATestExpectationsBag *bag = [AMATestExpectationsBag expectationBagWithTestCase:self];
    
    self.delegateMock.fireExpectation = [bag expectationWithDescription:@"Fire not called" inverted:YES];
    self.timerStorage.retryPeriodExpectation = [bag expectationWithDescription:@"Retry not called" inverted:YES];
    self.timerStorage.privacyEventSentExpectation = [bag expectationWithDescription:@"Privacy event sent not called" inverted:YES];
    self.timerStorage.isResendPeriodOutdatedExpection = [bag expectationWithDescription:@"Outdated not called" inverted:YES];
    
    AMAPrivacyTimer *privacyTimer = [[AMAPrivacyTimer alloc] initWithTimerStorage:self.timerStorage
                                                     delegateExecutor:self.executor
                                                           adProvider:self.adProvider];
    privacyTimer.delegate = self.delegateMock;
    
    [bag waitForExpectationsWithTimeout:2];
}

- (void)testNotFireIfAdversingDisabled
{
    AMATestExpectationsBag *bag = [AMATestExpectationsBag expectationBagWithTestCase:self];
    
    [self.adProvider stub:@selector(isAdvertisingTrackingEnabled) andReturn:theValue(NO)];
    self.delegateMock.fireExpectation = [bag expectationWithDescription:@"Fire not called" inverted:YES];
    
    AMAPrivacyTimer * privacyTimer = [[AMAPrivacyTimer alloc] initWithTimerStorage:self.timerStorage
                                                                  delegateExecutor:self.executor
                                                                        adProvider:self.adProvider];
    privacyTimer.delegate = self.delegateMock;
    
    [privacyTimer start];
    
    [bag waitForExpectationsWithTimeout:10];
}

- (void)testMultitimerDidFireCount
{
    AMATestExpectationsBag *bag = [AMATestExpectationsBag expectationBagWithTestCase:self];
    
    [self.adProvider stub:@selector(isAdvertisingTrackingEnabled) andReturn:theValue(NO)];
    self.delegateMock.fireExpectation = [bag expectationWithDescription:@"Fire not called" inverted:YES];
    
    AMAPrivacyTimerMock *privacyTimer = [[AMAPrivacyTimerMock alloc] initWithTimerStorage:self.timerStorage
                                                                         delegateExecutor:self.executor
                                                                               adProvider:self.adProvider];
    privacyTimer.delegate = self.delegateMock;
    privacyTimer.onTimerExpectation = [bag expectationWithDescription:@"onTimer called" inverted:NO count:3];
    
    [privacyTimer start];
    
    [bag waitForExpectationsWithTimeout:10];
}

- (void)testNotFireIfOutdated
{
    AMATestExpectationsBag *bag = [AMATestExpectationsBag expectationBagWithTestCase:self];
    
    [self.adProvider stub:@selector(isAdvertisingTrackingEnabled) andReturn:theValue(YES)];
    self.timerStorage.isResendPeriodOutdated = NO;
    self.timerStorage.isResendPeriodOutdatedExpection = [bag expectationWithDescription:@"isOutdatedPeriod called"];
    self.delegateMock.fireExpectation = [bag expectationWithDescription:@"Fire not called" inverted:YES];
    
    AMAPrivacyTimer * privacyTimer = [[AMAPrivacyTimer alloc] initWithTimerStorage:self.timerStorage
                                                                  delegateExecutor:self.executor
                                                                        adProvider:self.adProvider];
    privacyTimer.delegate = self.delegateMock;
    
    [privacyTimer start];
    
    [bag waitForExpectationsWithTimeout:2];
}

- (void)testNotCalledFireWhenStopped
{
    AMATestExpectationsBag *bag = [AMATestExpectationsBag expectationBagWithTestCase:self];
    
    [self.adProvider stub:@selector(isAdvertisingTrackingEnabled) andReturn:theValue(NO)];
    self.delegateMock.fireExpectation = [bag expectationWithDescription:@"Fire not called" inverted:YES];
    
    AMAPrivacyTimerMock *privacyTimer = [[AMAPrivacyTimerMock alloc] initWithTimerStorage:self.timerStorage
                                                                         delegateExecutor:self.executor
                                                                               adProvider:self.adProvider];
    privacyTimer.delegate = self.delegateMock;
    privacyTimer.onTimerExpectation = [bag expectationWithDescription:@"onTimer not called" inverted:YES count:3];
    
    [privacyTimer start];
    [privacyTimer stop];
    
    [bag waitForExpectationsWithTimeout:10];
}

- (void)testFireCalledAfterFirstTimer
{
    NSLock *lock = [[NSLock alloc] init];
    AMATestExpectationsBag *bag = [AMATestExpectationsBag expectationBagWithTestCase:self];
    
    [self.adProvider stub:@selector(isAdvertisingTrackingEnabled) andReturn:theValue(NO)];
    self.delegateMock.fireExpectation = [bag expectationWithDescription:@"Fire called"];
    
    AMAPrivacyTimerMock *privacyTimer = [[AMAPrivacyTimerMock alloc] initWithTimerStorage:self.timerStorage
                                                                         delegateExecutor:self.executor
                                                                               adProvider:self.adProvider];
    privacyTimer.delegate = self.delegateMock;
    privacyTimer.onTimerLock = lock;
    privacyTimer.onTimerExpectation = [bag expectationWithDescription:@"onTimer called" inverted:NO count:1];
    
    [lock lock];
    [privacyTimer start];
    [self.adProvider stub:@selector(isAdvertisingTrackingEnabled) andReturn:theValue(YES)];
    [lock unlock];
    
    [bag waitForExpectationsWithTimeout:10];
}


@end
