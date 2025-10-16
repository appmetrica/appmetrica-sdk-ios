@
import XCTest;
#import "AMAIDSyncNetworkRequest.h"

@interface AMAIDSyncNetworkRequestTests : XCTestCase
@end

@implementation AMAIDSyncNetworkRequestTests

- (void)testHeaderComponentsJoinsHeaderValues
{
    NSDictionary *headers = @{
        @"Accept": @[@"application/json", @"text/html"],
        @"User-Agent": @[@"AppMetricaSDK"]
    };
    AMAIDSyncNetworkRequest *request =
        [[AMAIDSyncNetworkRequest alloc] initWithURL:@"https://example.com"
                                              headers:headers];

    NSDictionary *result = [request headerComponents];

    XCTAssertEqualObjects(result[@"Accept"], @"application/json, text/html");
    XCTAssertEqualObjects(result[@"User-Agent"], @"AppMetricaSDK");
}

@end
