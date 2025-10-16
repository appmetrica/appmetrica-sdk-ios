
@import XCTest;
#import "AMAIDSyncLastExecutionStateProvider.h"
#import "AMAIDSyncRequest.h"
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>

@interface AMAIDSyncLastExecutionStateProviderTests : XCTestCase
@property (nonatomic, strong) AMAIDSyncLastExecutionStateProvider *provider;
@property (nonatomic, strong) AMAUserDefaultsMock *storageMock;
@property (nonatomic, strong) AMAIDSyncRequest *request;
@end

@implementation AMAIDSyncLastExecutionStateProviderTests

- (void)setUp
{
    [super setUp];
    self.storageMock = [[AMAUserDefaultsMock alloc] init];
    self.provider = [[AMAIDSyncLastExecutionStateProvider alloc] initWithStorage:self.storageMock];
    
    self.request = [[AMAIDSyncRequest alloc] initWithType:@"novatiq_id"
                                                      url:@""
                                                  headers:@{}
                                            preconditions:@{}
                                      validResendInterval:@(10)
                                    invalidResendInterval:@(20)
                                       validResponseCodes:@[@404]];
}

- (void)testRequestExecutedStoresDateAndCode
{
    NSNumber *statusCode = @200;
    [self.provider requestExecuted:self.request statusCode:statusCode];
    
    NSString *dateKey = [NSString stringWithFormat:@"id.sync.last_execution_date.%@", self.request.type];
    NSString *codeKey = [NSString stringWithFormat:@"id.sync.last_execution_code.%@", self.request.type];
    
    NSDate *storedDate = self.storageMock.store[dateKey];
    NSNumber *storedCode = self.storageMock.store[codeKey];
    
    XCTAssertNotNil(storedDate);
    XCTAssertNotNil(storedCode);
    XCTAssertEqualObjects(storedCode, statusCode);
}

- (void)testLastExecutionDateReturnsStoredDate
{
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:-100];
    NSString *key = [NSString stringWithFormat:@"id.sync.last_execution_date.%@", self.request.type];
    self.storageMock.store[key] = date;
    
    NSDate *result = [self.provider lastExecutionDateForRequest:self.request];
    XCTAssertEqualObjects(result, date);
}

- (void)testLastExecutionStatusReturnsYESIfCodeIsValid
{
    NSString *key = [NSString stringWithFormat:@"id.sync.last_execution_code.%@", self.request.type];
    self.storageMock.store[key] = @404;
    
    BOOL result = [self.provider lastExecutionStatusForRequest:self.request];
    XCTAssertTrue(result);
}

- (void)testLastExecutionStatusReturnsNOIfCodeIsInvalid
{
    NSString *key = [NSString stringWithFormat:@"id.sync.last_execution_code.%@", self.request.type];
    self.storageMock.store[key] = @500;
    
    BOOL result = [self.provider lastExecutionStatusForRequest:self.request];
    XCTAssertFalse(result);
}

- (void)testLastExecutionStatusReturnsYESIfCodeIsNil
{
    BOOL result = [self.provider lastExecutionStatusForRequest:self.request];
    XCTAssertTrue(result);
}

- (void)testDifferentRequestsStoredSeparately
{
    AMAIDSyncRequest *req1 = [[AMAIDSyncRequest alloc] initWithType:@"first"
                                                                url:@""
                                                            headers:@{}
                                                      preconditions:@{}
                                                validResendInterval:@(10)
                                              invalidResendInterval:@(20)
                                                 validResponseCodes:@[@200]];
    AMAIDSyncRequest *req2 = [[AMAIDSyncRequest alloc] initWithType:@"second"
                                                                url:@""
                                                            headers:@{}
                                                      preconditions:@{}
                                                validResendInterval:@(10)
                                              invalidResendInterval:@(20)
                                                 validResponseCodes:@[@201]];
    
    [self.provider requestExecuted:req1 statusCode:@200];
    [self.provider requestExecuted:req2 statusCode:@201];
    
    NSString *key1 = @"id.sync.last_execution_code.first";
    NSString *key2 = @"id.sync.last_execution_code.second";
    
    XCTAssertEqualObjects(self.storageMock.store[key1], @200);
    XCTAssertEqualObjects(self.storageMock.store[key2], @201);
}

@end
