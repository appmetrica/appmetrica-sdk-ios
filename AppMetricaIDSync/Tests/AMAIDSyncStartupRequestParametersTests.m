
#import <XCTest/XCTest.h>
#import "AMAIDSyncStartupRequestParameters.h"

@interface AMAIDSyncStartupRequestParametersTests : XCTestCase

@end

@implementation AMAIDSyncStartupRequestParametersTests

- (void)testFeatureParameters
{
    NSDictionary *parameters = [AMAIDSyncStartupRequestParameters parameters];
    NSString *expectedFeatures = @"is";
    
    XCTAssertEqualObjects(parameters[@"features"], expectedFeatures, @"Should contain valid features");
}

- (void)testBlockParameters
{
    NSDictionary *parameters = [AMAIDSyncStartupRequestParameters parameters];
    
    XCTAssertEqualObjects(parameters[@"is"], @"1", @"Should contain id sync block");
}

- (void)testUnexpectedValues
{
    NSMutableDictionary *parameters = [[AMAIDSyncStartupRequestParameters parameters] mutableCopy];
    
    [parameters removeObjectsForKeys:@[@"features", @"is"]];
    
    XCTAssertEqualObjects(parameters, @{}, @"Should not contain any other parameters");
}

@end
