
#import <XCTest/XCTest.h>
#import "AMAAppLovinAdRevenuePolicy.h"
#import "Mocks/AMABundleInfoMock.h"

static NSString *const kKey = @"io.appmetrica.applovin_auto_ad_revenue_enabled";

@interface AMAAppLovinAdRevenuePolicyTests : XCTestCase
@property (nonatomic, strong) AMABundleInfoMock *bundle;
@property (nonatomic, strong) AMAAppLovinAdRevenuePolicy *policy;
@end

@implementation AMAAppLovinAdRevenuePolicyTests

- (void)setUp
{
    self.bundle = [AMABundleInfoMock new];
    self.policy = [[AMAAppLovinAdRevenuePolicy alloc] initWithBundle:self.bundle];
}

- (void)testEnabled_whenPlistContainsYES
{
    self.bundle.mockedInfo = @{ kKey: @YES };
    XCTAssertTrue(self.policy.isEnabled);
}

- (void)testDisabled_whenPlistContainsNO
{
    self.bundle.mockedInfo = @{ kKey: @NO };
    XCTAssertFalse(self.policy.isEnabled);
}

- (void)testDefaultEnabled_whenPlistValueAbsent
{
    self.bundle.mockedInfo = @{};
    XCTAssertTrue(self.policy.isEnabled);
}

- (void)testDefaultEnabled_whenPlistValueIsNotNSNumber
{
    for (id value in @[@"yes", @"1"]) {
        self.bundle.mockedInfo = @{ kKey: value };
        AMAAppLovinAdRevenuePolicy *p = [[AMAAppLovinAdRevenuePolicy alloc] initWithBundle:self.bundle];
        XCTAssertTrue(p.isEnabled, @"Expected default YES for non-NSNumber value: %@", value);
    }
}

@end
