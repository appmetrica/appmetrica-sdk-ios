
@import XCTest;
#import "AMAIDSyncReportRequest.h"
#import "AMAIDSyncRequestResponse.h"
#import "AMAIDSyncRequest.h"

@interface AMAIDSyncReportRequestTests : XCTestCase

@property (nonatomic, strong) AMAIDSyncRequest *syncRequest;
@property (nonatomic, strong) AMAIDSyncRequestResponse *response;

@end

@implementation AMAIDSyncReportRequestTests

- (void)setUp
{
    [super setUp];

    self.syncRequest = [[AMAIDSyncRequest alloc] initWithType:@"test_type"
                                                           url:@"https://example.com/sync"
                                                       headers:@{@"X-Custom": @[@"value"]}
                                                 preconditions:@{}
                                           validResendInterval:@(60)
                                         invalidResendInterval:@(30)
                                            validResponseCodes:@[@(200)]
                                            reportEventEnabled:YES
                                                     reportUrl:@"https://example.com/report"];

    self.response = [[AMAIDSyncRequestResponse alloc] initWithRequest:self.syncRequest
                                                                 code:200
                                                                 body:@"{\"status\":\"ok\"}"
                                                              headers:@{@"Content-Type": @[@"application/json"]}
                                                          responseURL:@"https://example.com/sync?id=123"];
}

- (void)testRequestMethod
{
    AMAIDSyncReportRequest *request = [[AMAIDSyncReportRequest alloc] initWithResponse:self.response];

    XCTAssertEqualObjects(request.method, @"POST");
}

- (void)testHeaderComponentsIncludesContentType
{
    AMAIDSyncReportRequest *request = [[AMAIDSyncReportRequest alloc] initWithResponse:self.response];

    NSDictionary *headers = [request headerComponents];

    XCTAssertEqualObjects(headers[@"Content-Type"], @"application/json");
}

- (void)testBodyContainsType
{
    AMAIDSyncReportRequest *request = [[AMAIDSyncReportRequest alloc] initWithResponse:self.response];

    NSData *bodyData = [request body];
    XCTAssertNotNil(bodyData);

    NSDictionary *bodyDict = [NSJSONSerialization JSONObjectWithData:bodyData options:0 error:nil];

    XCTAssertEqualObjects(bodyDict[@"type"], @"test_type");
}

- (void)testBodyContainsURL
{
    AMAIDSyncReportRequest *request = [[AMAIDSyncReportRequest alloc] initWithResponse:self.response];

    NSData *bodyData = [request body];
    XCTAssertNotNil(bodyData);

    NSDictionary *bodyDict = [NSJSONSerialization JSONObjectWithData:bodyData options:0 error:nil];

    XCTAssertEqualObjects(bodyDict[@"url"], @"https://example.com/sync?id=123");
}

- (void)testBodyContainsResponseCode
{
    AMAIDSyncReportRequest *request = [[AMAIDSyncReportRequest alloc] initWithResponse:self.response];

    NSData *bodyData = [request body];
    XCTAssertNotNil(bodyData);

    NSDictionary *bodyDict = [NSJSONSerialization JSONObjectWithData:bodyData options:0 error:nil];

    XCTAssertEqualObjects(bodyDict[@"responseCode"], @(200));
}

- (void)testBodyContainsResponseBody
{
    AMAIDSyncReportRequest *request = [[AMAIDSyncReportRequest alloc] initWithResponse:self.response];

    NSData *bodyData = [request body];
    XCTAssertNotNil(bodyData);

    NSDictionary *bodyDict = [NSJSONSerialization JSONObjectWithData:bodyData options:0 error:nil];

    XCTAssertEqualObjects(bodyDict[@"responseBody"], @"{\"status\":\"ok\"}");
}

- (void)testBodyContainsResponseHeaders
{
    AMAIDSyncReportRequest *request = [[AMAIDSyncReportRequest alloc] initWithResponse:self.response];

    NSData *bodyData = [request body];
    XCTAssertNotNil(bodyData);

    NSDictionary *bodyDict = [NSJSONSerialization JSONObjectWithData:bodyData options:0 error:nil];
    NSDictionary *expectedHeaders = @{@"Content-Type": @[@"application/json"]};

    XCTAssertEqualObjects(bodyDict[@"responseHeaders"], expectedHeaders);
}

- (void)testBodyWithZeroResponseCode
{
    AMAIDSyncRequestResponse *responseWithZeroCode =
        [[AMAIDSyncRequestResponse alloc] initWithRequest:self.syncRequest
                                                      code:0
                                                      body:nil
                                                   headers:nil
                                               responseURL:@"https://example.com"];

    AMAIDSyncReportRequest *request = [[AMAIDSyncReportRequest alloc] initWithResponse:responseWithZeroCode];

    NSData *bodyData = [request body];
    XCTAssertNotNil(bodyData);

    NSDictionary *bodyDict = [NSJSONSerialization JSONObjectWithData:bodyData options:0 error:nil];

    XCTAssertNil(bodyDict[@"responseCode"], @"responseCode should not be included when code is 0");
}

- (void)testBodyWithNilResponseBody
{
    AMAIDSyncRequestResponse *responseWithNilBody =
        [[AMAIDSyncRequestResponse alloc] initWithRequest:self.syncRequest
                                                      code:200
                                                      body:nil
                                                   headers:@{}
                                               responseURL:@"https://example.com"];

    AMAIDSyncReportRequest *request = [[AMAIDSyncReportRequest alloc] initWithResponse:responseWithNilBody];

    NSData *bodyData = [request body];
    XCTAssertNotNil(bodyData);

    NSDictionary *bodyDict = [NSJSONSerialization JSONObjectWithData:bodyData options:0 error:nil];

    XCTAssertNil(bodyDict[@"responseBody"], @"responseBody should not be included when body is nil");
}

- (void)testBodyWithNilResponseHeaders
{
    AMAIDSyncRequestResponse *responseWithNilHeaders =
        [[AMAIDSyncRequestResponse alloc] initWithRequest:self.syncRequest
                                                      code:200
                                                      body:@"response"
                                                   headers:nil
                                               responseURL:@"https://example.com"];

    AMAIDSyncReportRequest *request = [[AMAIDSyncReportRequest alloc] initWithResponse:responseWithNilHeaders];

    NSData *bodyData = [request body];
    XCTAssertNotNil(bodyData);

    NSDictionary *bodyDict = [NSJSONSerialization JSONObjectWithData:bodyData options:0 error:nil];

    XCTAssertNil(bodyDict[@"responseHeaders"], @"responseHeaders should not be included when headers is nil");
}

- (void)testHostIsSetFromReportUrl
{
    AMAIDSyncReportRequest *request = [[AMAIDSyncReportRequest alloc] initWithResponse:self.response];

    XCTAssertEqualObjects(request.host, @"https://example.com/report");
}

- (void)testGETParametersReturnsNonNilDictionary
{
    AMAIDSyncReportRequest *request = [[AMAIDSyncReportRequest alloc] initWithResponse:self.response];

    NSDictionary *parameters = [request GETParameters];

    XCTAssertNotNil(parameters, @"GETParameters should return a non-nil dictionary");
}

- (void)testGETParametersIncludesIFVIfAvailable
{
    AMAIDSyncReportRequest *request = [[AMAIDSyncReportRequest alloc] initWithResponse:self.response];

    NSDictionary *parameters = [request GETParameters];

    if (parameters[@"ifv"] != nil) {
        XCTAssertTrue([parameters[@"ifv"] isKindOfClass:[NSString class]],
                     @"ifv parameter should be a string");
        XCTAssertTrue([parameters[@"ifv"] length] > 0,
                     @"ifv parameter should not be empty");
    }
}

- (void)testGETParametersIncludesDeviceIDIfAvailable
{
    AMAIDSyncReportRequest *request = [[AMAIDSyncReportRequest alloc] initWithResponse:self.response];

    NSDictionary *parameters = [request GETParameters];

    if (parameters[@"deviceid"] != nil) {
        XCTAssertTrue([parameters[@"deviceid"] isKindOfClass:[NSString class]],
                     @"deviceid parameter should be a string");
        XCTAssertTrue([parameters[@"deviceid"] length] > 0,
                     @"deviceid parameter should not be empty");
    }
}

- (void)testGETParametersIncludesUUIDIfAvailable
{
    AMAIDSyncReportRequest *request = [[AMAIDSyncReportRequest alloc] initWithResponse:self.response];

    NSDictionary *parameters = [request GETParameters];

    if (parameters[@"uuid"] != nil) {
        XCTAssertTrue([parameters[@"uuid"] isKindOfClass:[NSString class]],
                     @"uuid parameter should be a string");
        XCTAssertTrue([parameters[@"uuid"] length] > 0,
                     @"uuid parameter should not be empty");
    }
}

@end
