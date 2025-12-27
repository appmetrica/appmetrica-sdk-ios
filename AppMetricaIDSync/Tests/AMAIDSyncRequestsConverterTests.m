
#import <XCTest/XCTest.h>
#import "AMAIDSyncRequestsConverter.h"
#import "AMAIDSyncRequest.h"
#import "AMAIDSyncKeys.h"

@interface AMAIDSyncRequestsConverterTests : XCTestCase
@property (nonatomic, strong) AMAIDSyncRequestsConverter *converter;
@end

@implementation AMAIDSyncRequestsConverterTests

- (void)setUp
{
    [super setUp];
    self.converter = [[AMAIDSyncRequestsConverter alloc] init];
}

- (void)tearDown
{
    self.converter = nil;
    [super tearDown];
}

#pragma mark - Helpers

- (NSDictionary *)validRequestDictionary
{
    return @{
        AMAIDSyncRequestTypeKey: @"novatiq_hyper_id",
        AMAIDSyncRequestUrlKey: @"https://ya.ru",
        AMAIDSyncRequestHeadersKey: @{ @"key" : @[@"value"] },
        AMAIDSyncRequestPreconditionsKey: @{ @"network": @"cell" },
        AMAIDSyncRequestResendIntervalForValidResponseKey: @999,
        AMAIDSyncRequestResendIntervalForInvalidResponseKey: @777,
        AMAIDSyncRequestValidResponseCodesKey: @[@404, @502],
        AMAIDSyncRequestReportEventEnabledKey: @NO,
        AMAIDSyncRequestReportUrlKey: @"report_url",
    };
}

#pragma mark - Tests

- (void)testConvertDictToRequestsWithValidData
{
    NSDictionary *validDict = [self validRequestDictionary];
    
    NSArray<AMAIDSyncRequest *> *result = [self.converter convertDictToRequests:@[validDict, validDict]];
    
    XCTAssertEqual(result.count, 2);
    
    AMAIDSyncRequest *req = result.firstObject;
    XCTAssertEqualObjects(req.type, validDict[AMAIDSyncRequestTypeKey]);
    XCTAssertEqualObjects(req.url, validDict[AMAIDSyncRequestUrlKey]);
    XCTAssertEqualObjects(req.headers, validDict[AMAIDSyncRequestHeadersKey]);
    XCTAssertEqualObjects(req.preconditions, validDict[AMAIDSyncRequestPreconditionsKey]);
    XCTAssertEqual(req.resendIntervalForValidResponse,
                   validDict[AMAIDSyncRequestResendIntervalForValidResponseKey]);
    XCTAssertEqual(req.resendIntervalForNotValidResponse,
                   validDict[AMAIDSyncRequestResendIntervalForInvalidResponseKey]);
    XCTAssertEqualObjects(req.validResponseCodes,
                          validDict[AMAIDSyncRequestValidResponseCodesKey]);
    XCTAssertEqual(req.reportEventEnabled,
                   [validDict[AMAIDSyncRequestReportEventEnabledKey] boolValue]);
    XCTAssertEqual(req.reportUrl,
                   validDict[AMAIDSyncRequestReportUrlKey]);
}

- (void)testConvertDictToRequestsWithInvalidData
{
    NSMutableDictionary *firstInvalidDict = [[self validRequestDictionary] mutableCopy];
    NSMutableDictionary *secondInvalidDict = [[self validRequestDictionary] mutableCopy];
    firstInvalidDict[AMAIDSyncRequestUrlKey] = nil;
    secondInvalidDict[AMAIDSyncRequestTypeKey] = @123;
    
    NSArray<AMAIDSyncRequest *> *result = [self.converter convertDictToRequests:@[firstInvalidDict, secondInvalidDict]];
    XCTAssertEqual(result.count, 0);
}

- (void)testConvertDictToRequestsWithDefaultValues
{
    NSDictionary *input = @{
        AMAIDSyncRequestTypeKey: @"sync",
        AMAIDSyncRequestUrlKey: @"https://example.com"
    };
    
    NSArray<AMAIDSyncRequest *> *result = [self.converter convertDictToRequests:@[input]];
    
    XCTAssertEqual(result.count, 1);
    
    AMAIDSyncRequest *req = result.firstObject;
    
    XCTAssertEqualObjects(req.headers, @{});
    XCTAssertEqualObjects(req.preconditions, @{});
    XCTAssertEqualObjects(req.resendIntervalForValidResponse, @86400);
    XCTAssertEqualObjects(req.resendIntervalForNotValidResponse, @3600);
    XCTAssertEqualObjects(req.validResponseCodes, (@[@200]));
    XCTAssertTrue(req.reportEventEnabled);
    XCTAssertNil(req.reportUrl);
}

- (void)testConvertDictToRequestsWithMultipleValidRequests
{
    NSArray *input = @[
        [self validRequestDictionary],
        @{
            AMAIDSyncRequestTypeKey: @"sync2",
            AMAIDSyncRequestUrlKey: @"https://ya.ru",
        }
    ];

    NSArray<AMAIDSyncRequest *> *result = [self.converter convertDictToRequests:input];
    XCTAssertEqual(result.count, 2);
    XCTAssertEqualObjects(result[0].type, @"novatiq_hyper_id");
    XCTAssertEqualObjects(result[1].type, @"sync2");
}

@end
