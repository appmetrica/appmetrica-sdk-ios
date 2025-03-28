#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>

#import "AMAScreenshotStartupParser.h"
#import "AMAScreenshotConfigurationMock.h"
#import "AMAScreenshotStartupResponse.h"


@interface AMAScreenshotStartupParserTests : XCTestCase
@end

@implementation AMAScreenshotStartupParserTests

- (void)setUp
{
}

- (void)testParseEmpty
{
    NSDictionary *params = @{
    };
    
    AMAScreenshotStartupResponse *expectedResponse = [AMAScreenshotStartupResponse new];
    
    AMAScreenshotStartupResponse *response = [AMAScreenshotStartupParser parse:params];
    XCTAssertEqualObjects(expectedResponse, response);
}

- (void)testParseEnabled
{
    NSDictionary *params = @{
        @"features": @{
            @"list": @{
                @"screenshot": @{
                    @"enabled": @(YES),
                },
            },
        },
        @"screenshot": @{
            @"api_captor_config": @{
                @"enabled": @(YES),
            },
        },
    };
    
    AMAScreenshotStartupResponse *expectedResponse = [AMAScreenshotStartupResponse new];
    
    AMAScreenshotStartupResponse *response = [AMAScreenshotStartupParser parse:params];
    XCTAssertEqualObjects(expectedResponse, response);
}

- (void)testParseDisabled
{
    NSDictionary *params = @{
        @"features": @{
            @"list": @{
                @"screenshot": @{
                    @"enabled": @(NO),
                },
            },
        },
        @"screenshot": @{
            @"api_captor_config": @{
                @"enabled": @(NO),
            },
        },
    };
    
    AMAScreenshotStartupResponse *expectedResponse = [AMAScreenshotStartupResponse new];
    expectedResponse.featureEnabled = NO;
    expectedResponse.captorEnabled = NO;
    
    AMAScreenshotStartupResponse *response = [AMAScreenshotStartupParser parse:params];
    XCTAssertEqualObjects(expectedResponse, response);
}

- (void)testParseFeatureDisabled
{
    NSDictionary *params = @{
        @"features": @{
            @"list": @{
                @"screenshot": @{
                    @"enabled": @(YES),
                },
            },
        },
        @"screenshot": @{
            @"api_captor_config": @{
                @"enabled": @(NO),
            },
        },
    };
    
    AMAScreenshotStartupResponse *expectedResponse = [AMAScreenshotStartupResponse new];
    expectedResponse.featureEnabled = YES;
    expectedResponse.captorEnabled = NO;
    
    AMAScreenshotStartupResponse *response = [AMAScreenshotStartupParser parse:params];
    XCTAssertEqualObjects(expectedResponse, response);
}

- (void)testParseCaptorDisabled
{
    NSDictionary *params = @{
        @"features": @{
            @"list": @{
                @"screenshot": @{
                    @"enabled": @(NO),
                },
            },
        },
        @"screenshot": @{
            @"api_captor_config": @{
                @"enabled": @(YES),
            },
        },
    };
    
    AMAScreenshotStartupResponse *expectedResponse = [AMAScreenshotStartupResponse new];
    expectedResponse.featureEnabled = NO;
    expectedResponse.captorEnabled = YES;
    
    AMAScreenshotStartupResponse *response = [AMAScreenshotStartupParser parse:params];
    XCTAssertEqualObjects(expectedResponse, response);
}

@end
