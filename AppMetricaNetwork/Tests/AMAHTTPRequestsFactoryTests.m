
#import <XCTest/XCTest.h>
#import <AppMetricaNetwork/AppMetricaNetwork.h>

@interface AMAHTTPRequestsFactoryTests : XCTestCase

@end

@implementation AMAHTTPRequestsFactoryTests

- (void)testRequestorForRequest
{
    AMAHTTPRequestsFactory *factory = [[AMAHTTPRequestsFactory alloc] init];
    AMAGenericRequest *request = [[AMAGenericRequest alloc] init];
    
    AMAHTTPRequestor *requestor = [factory requestorForRequest:request];
    AMAHTTPRequestor *expected = [[AMAHTTPRequestor alloc] initWithRequest:request];
    
    XCTAssertEqualObjects(requestor.request, expected.request, @"Should create valid requestor");
}

@end
