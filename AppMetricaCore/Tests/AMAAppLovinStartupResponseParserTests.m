
#import <XCTest/XCTest.h>
#import "AMAAppLovinStartupResponseParser.h"
#import "AMAAppLovinStartupConfiguration.h"
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>

static NSDictionary *AMAMakeFeatureResponse(id enabled)
{
    return @{ @"features": @{ @"list": @{ @"ad_revenue_applovin_max": @{ @"enabled": enabled } } } };
}

@interface AMAAppLovinStartupResponseParserTests : XCTestCase
@property (nonatomic, strong) AMAAppLovinStartupResponseParser *parser;
@property (nonatomic, strong) AMAAppLovinStartupConfiguration *config;
@end

@implementation AMAAppLovinStartupResponseParserTests

- (void)setUp
{
    self.parser = [[AMAAppLovinStartupResponseParser alloc] init];
    AMAKeyValueStorageMock *storage = [[AMAKeyValueStorageMock alloc] init];
    self.config = [[AMAAppLovinStartupConfiguration alloc] initWithStorage:storage];
}

// MARK: - enabled flag present

- (void)testEnabled_zero_setsAramEnabledNO
{
    [self.parser parseResponse:AMAMakeFeatureResponse(@0) intoConfiguration:self.config];
    XCTAssertFalse(self.config.aramEnabled);
}

- (void)testEnabled_one_setsAramEnabledYES
{
    self.config.aramEnabled = NO;
    [self.parser parseResponse:AMAMakeFeatureResponse(@1) intoConfiguration:self.config];
    XCTAssertTrue(self.config.aramEnabled);
}

// MARK: - missing or invalid structure

- (void)testFeaturesBlockAbsent_doesNotChangeConfig
{
    [self.parser parseResponse:@{} intoConfiguration:self.config];
    XCTAssertTrue(self.config.aramEnabled);
}

- (void)testFeaturesListAbsent_doesNotChangeConfig
{
    [self.parser parseResponse:@{ @"features": @{} } intoConfiguration:self.config];
    XCTAssertTrue(self.config.aramEnabled);
}

- (void)testAramFeatureAbsent_doesNotChangeConfig
{
    self.config.aramEnabled = NO;
    [self.parser parseResponse:@{ @"features": @{ @"list": @{} } } intoConfiguration:self.config];
    XCTAssertFalse(self.config.aramEnabled);
}

- (void)testAramFeatureNotDict_doesNotChangeConfig
{
    [self.parser parseResponse:@{ @"features": @{ @"list": @{ @"ad_revenue_applovin_max": @"yes" } } }
            intoConfiguration:self.config];
    XCTAssertTrue(self.config.aramEnabled);
}

- (void)testEnabledNotNumber_doesNotChangeConfig
{
    self.config.aramEnabled = NO;
    [self.parser parseResponse:@{ @"features": @{ @"list": @{ @"ad_revenue_applovin_max": @{ @"enabled": @"1" } } } }
            intoConfiguration:self.config];
    XCTAssertFalse(self.config.aramEnabled);
}

@end
