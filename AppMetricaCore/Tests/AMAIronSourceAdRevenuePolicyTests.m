
#import <XCTest/XCTest.h>
#import "AMAIronSourceAdRevenuePolicy.h"
#import "Mocks/AMABundleInfoMock.h"

static NSString *const kKey = @"io.appmetrica.ironsource_auto_ad_revenue_enabled";

@interface AMAIronSourceAdRevenuePolicyTests : XCTestCase
@property (nonatomic, strong) AMABundleInfoMock *bundle;
@property (nonatomic, strong) AMAIronSourceAdRevenuePolicy *policy;
@end

@implementation AMAIronSourceAdRevenuePolicyTests

- (void)setUp
{
    self.bundle = [AMABundleInfoMock new];
    self.policy = [[AMAIronSourceAdRevenuePolicy alloc] initWithBundle:self.bundle];
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
    for (id value in @[@"yes", @42]) {
        self.bundle.mockedInfo = @{ kKey: value };
        AMAIronSourceAdRevenuePolicy *p = [[AMAIronSourceAdRevenuePolicy alloc] initWithBundle:self.bundle];
        XCTAssertTrue(p.isEnabled, @"Expected default YES for non-NSNumber value: %@", value);
    }
}

@end
