
#import <XCTest/XCTest.h>
#import "AMAIDSyncExecutionConditionProvider.h"
#import "AMAIDSyncLastExecutionStateProviderMock.h"
#import "AMAIDSyncRequest.h"
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>
#import "AMAIDSyncRequestsConverter.h"

static NSInteger const kAMATestValidResendInterval = 15;
static NSInteger const kAMATestInvalidResendInterval = 45;

@interface AMAIDSyncExecutionConditionProviderTests : XCTestCase

@property (nonatomic, strong) AMAIDSyncExecutionConditionProvider *conditionProvider;
@property (nonatomic, strong) AMAIDSyncLastExecutionStateProviderMock *mockLastExecutionProvider;

@end

@implementation AMAIDSyncExecutionConditionProviderTests

- (void)setUp
{
    [super setUp];
    self.mockLastExecutionProvider = [[AMAIDSyncLastExecutionStateProviderMock alloc] init];
    self.conditionProvider = [[AMAIDSyncExecutionConditionProvider alloc] initWithLastExecutionStateProvider:self.mockLastExecutionProvider];
}

- (void)tearDown
{
    self.mockLastExecutionProvider = nil;
    self.conditionProvider = nil;
    [super tearDown];
}

- (AMAIDSyncRequest *)validRequest
{
    return [[AMAIDSyncRequest alloc] initWithType:@"hyper_id"
                                              url:@""
                                          headers:@{}
                                    preconditions:@{}
                              validResendInterval:@(kAMATestValidResendInterval)
                            invalidResendInterval:@(kAMATestInvalidResendInterval)
                               validResponseCodes:@[@204]];
}

- (AMAIDSyncRequest *)invalidRequest
{
    return [[AMAIDSyncRequest alloc] initWithType:@"hyper_id"
                                              url:@""
                                          headers:@{}
                                    preconditions:@{}
                              validResendInterval:nil
                            invalidResendInterval:nil
                               validResponseCodes:@[@204]];
}

#pragma mark - Request interval -
- (void)testConditionPassedIntervalWithValidStatus
{
    AMAIDSyncRequest *request = [self validRequest];
    self.mockLastExecutionProvider.stubLastExecutionStatus = YES;
    self.mockLastExecutionProvider.stubLastExecutionDate = [[NSDate date] dateByAddingTimeInterval:-kAMATestValidResendInterval-1];

    id<AMAExecutionCondition> condition = [self.conditionProvider executionConditionWithRequest:request];

    XCTAssertTrue([condition isKindOfClass:[AMAIntervalExecutionCondition class]]);
    AMAIntervalExecutionCondition *intervalCondition = (AMAIntervalExecutionCondition *)condition;
    
    XCTAssertTrue([condition shouldExecute]);
}

- (void)testConditionNotPassedIntervalWithValidStatus
{
    AMAIDSyncRequest *request = [self validRequest];
    self.mockLastExecutionProvider.stubLastExecutionStatus = YES;
    self.mockLastExecutionProvider.stubLastExecutionDate = [[NSDate date] dateByAddingTimeInterval:-kAMATestValidResendInterval+1];

    id<AMAExecutionCondition> condition = [self.conditionProvider executionConditionWithRequest:request];

    XCTAssertTrue([condition isKindOfClass:[AMAIntervalExecutionCondition class]]);
    AMAIntervalExecutionCondition *intervalCondition = (AMAIntervalExecutionCondition *)condition;
    
    XCTAssertFalse([condition shouldExecute]);
}

- (void)testConditionNotPassedIntervalWithNotValidStatus
{
    AMAIDSyncRequest *request = [self validRequest];
    self.mockLastExecutionProvider.stubLastExecutionStatus = NO;
    self.mockLastExecutionProvider.stubLastExecutionDate = [[NSDate date] dateByAddingTimeInterval:-kAMATestInvalidResendInterval-1];

    id<AMAExecutionCondition> condition = [self.conditionProvider executionConditionWithRequest:request];

    XCTAssertTrue([condition isKindOfClass:[AMAIntervalExecutionCondition class]]);
    AMAIntervalExecutionCondition *intervalCondition = (AMAIntervalExecutionCondition *)condition;
    
    XCTAssertTrue([condition shouldExecute]);
}

- (void)testConditionPassedIntervalWithNotValidStatus
{
    AMAIDSyncRequest *request = [self validRequest];
    self.mockLastExecutionProvider.stubLastExecutionStatus = NO;
    self.mockLastExecutionProvider.stubLastExecutionDate = [[NSDate date] dateByAddingTimeInterval:-kAMATestInvalidResendInterval+1];

    id<AMAExecutionCondition> condition = [self.conditionProvider executionConditionWithRequest:request];

    XCTAssertTrue([condition isKindOfClass:[AMAIntervalExecutionCondition class]]);
    AMAIntervalExecutionCondition *intervalCondition = (AMAIntervalExecutionCondition *)condition;
    
    XCTAssertFalse([condition shouldExecute]);
}

#pragma mark - Default interval -
- (void)testConditionPassedDefaultIntervalWithValidStatus
{
    AMAIDSyncRequest *request = [self invalidRequest];
    self.mockLastExecutionProvider.stubLastExecutionStatus = YES;
    self.mockLastExecutionProvider.stubLastExecutionDate = [[NSDate date]
                                                            dateByAddingTimeInterval:-((NSTimeInterval)kAMAIDSyncDefaultValidResendInterval)-1];

    id<AMAExecutionCondition> condition = [self.conditionProvider executionConditionWithRequest:request];

    XCTAssertTrue([condition isKindOfClass:[AMAIntervalExecutionCondition class]]);
    AMAIntervalExecutionCondition *intervalCondition = (AMAIntervalExecutionCondition *)condition;
    
    XCTAssertTrue([condition shouldExecute]);
}

- (void)testConditionNotPassedDefaultIntervalWithValidStatus
{
    AMAIDSyncRequest *request = [self invalidRequest];
    self.mockLastExecutionProvider.stubLastExecutionStatus = YES;
    self.mockLastExecutionProvider.stubLastExecutionDate = [[NSDate date]
                                                            dateByAddingTimeInterval:-((NSTimeInterval)kAMAIDSyncDefaultValidResendInterval)+1];

    id<AMAExecutionCondition> condition = [self.conditionProvider executionConditionWithRequest:request];

    XCTAssertTrue([condition isKindOfClass:[AMAIntervalExecutionCondition class]]);
    AMAIntervalExecutionCondition *intervalCondition = (AMAIntervalExecutionCondition *)condition;
    
    XCTAssertFalse([condition shouldExecute]);
}

- (void)testConditionNotPassedDefaultIntervalWithNotValidStatus
{
    AMAIDSyncRequest *request = [self invalidRequest];
    self.mockLastExecutionProvider.stubLastExecutionStatus = NO;
    self.mockLastExecutionProvider.stubLastExecutionDate = [[NSDate date]
                                                            dateByAddingTimeInterval:-((NSTimeInterval)kAMAIDSyncDefaultInvalidResendInterval)-1];

    id<AMAExecutionCondition> condition = [self.conditionProvider executionConditionWithRequest:request];

    XCTAssertTrue([condition isKindOfClass:[AMAIntervalExecutionCondition class]]);
    AMAIntervalExecutionCondition *intervalCondition = (AMAIntervalExecutionCondition *)condition;
    
    XCTAssertTrue([condition shouldExecute]);
}

- (void)testConditionPassedDefaultIntervalWithNotValidStatus
{
    AMAIDSyncRequest *request = [self invalidRequest];
    self.mockLastExecutionProvider.stubLastExecutionStatus = NO;
    self.mockLastExecutionProvider.stubLastExecutionDate = [[NSDate date]
                                                            dateByAddingTimeInterval:-((NSTimeInterval)kAMAIDSyncDefaultInvalidResendInterval)+1];

    id<AMAExecutionCondition> condition = [self.conditionProvider executionConditionWithRequest:request];

    XCTAssertTrue([condition isKindOfClass:[AMAIntervalExecutionCondition class]]);
    AMAIntervalExecutionCondition *intervalCondition = (AMAIntervalExecutionCondition *)condition;
    
    XCTAssertFalse([condition shouldExecute]);
}

- (void)testExecuteRequest
{
    AMAIDSyncRequest *request = [self validRequest];
    NSNumber *statusCode = @200;
    
    [self.conditionProvider execute:request statusCode:statusCode];
    
    XCTAssertEqualObjects(self.mockLastExecutionProvider.capturedRequest, request);
    XCTAssertEqualObjects(self.mockLastExecutionProvider.capturedStatusCode, statusCode);
}

@end
