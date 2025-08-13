#import <XCTest/XCTest.h>
#import "AMAActivationTypeResolver.h"
#import "AMADefaultAnonymousConfigProvider.h"

@interface AMAActivisionTypeResolverTests : XCTestCase

@end

@implementation AMAActivisionTypeResolverTests

- (void)testAnonymousConfiguration
{
    AMAAppMetricaConfiguration *config = [[AMAAppMetricaConfiguration alloc] initWithAPIKey:@"629a824d-c717-4ba5-bc0f-3f3968554d01"];
    
    XCTAssertTrue([AMAActivationTypeResolver isAnonymousConfiguration:config]);
}

- (void)testNonAnonymousConfiguration
{
    AMAAppMetricaConfiguration *config = [[AMAAppMetricaConfiguration alloc] initWithAPIKey:@"129a824d-c717-4ba5-bc0f-3f3968554d01"];
    
    XCTAssertFalse([AMAActivationTypeResolver isAnonymousConfiguration:config]);
}

@end
