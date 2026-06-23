
#import <XCTest/XCTest.h>
#import "AMAAppLovinStartupRequestParameters.h"

@interface AMAAppLovinStartupRequestParametersTests : XCTestCase
@end

@implementation AMAAppLovinStartupRequestParametersTests

- (void)testParametersContainAramFeature
{
    NSDictionary *params = [AMAAppLovinStartupRequestParameters parameters];
    XCTAssertEqualObjects(params[@"features"], @"aram");
}

- (void)testParametersIsNonEmpty
{
    XCTAssertGreaterThan([AMAAppLovinStartupRequestParameters parameters].count, 0u);
}

@end
