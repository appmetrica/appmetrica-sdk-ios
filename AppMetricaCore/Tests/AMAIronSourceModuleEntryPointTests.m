
#import <XCTest/XCTest.h>
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMAIronSourceModuleEntryPoint.h"
#import "AMAIronSourceAdRevenuePolicy.h"
#import "AMAIronSourceManager.h"
#import "AMAIronSourceImpressionDelegate.h"
#import "AMAIronSourceTestSDKStubs.h"
#import "AMAAppMetricaMock.h"
#import "AMABundleInfoMock.h"
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>

static NSString *const kPolicyKey = @"io.appmetrica.ironsource_auto_ad_revenue_enabled";

@interface AMAIronSourceManager (EntryPointTesting)
@property (nonatomic, strong) AMAIronSourceImpressionDelegate *impressionDelegate;
@end

// MARK: - Helpers

@interface AMAIronSourceModuleEntryPointTests : XCTestCase
@property (nonatomic, strong) AMAModuleContextMock *context;
@end

@implementation AMAIronSourceModuleEntryPointTests

- (void)setUp
{
    AMAIronSourceTestSDKStubsReset();
    [AMAAppMetricaMock resetCaptures];
    [AMAAppMetrica stub:@selector(registerAdRevenueNativeSource:)
             withBlock:^id(NSArray *params) {
        [AMAAppMetricaMock.capturedNativeSources addObject:params[0]];
        return nil;
    }];
    self.context = [[AMAModuleContextMock alloc] initWithTestCase:self];
}

- (void)tearDown
{
    [AMAAppMetrica clearStubs];
}

- (AMAIronSourceModuleEntryPoint *)entryPointWithPolicyEnabled:(BOOL)enabled
{
    AMABundleInfoMock *bundle = [AMABundleInfoMock new];
    bundle.mockedInfo = @{ kPolicyKey: @(enabled) };
    AMAIronSourceAdRevenuePolicy *policy = [[AMAIronSourceAdRevenuePolicy alloc] initWithBundle:bundle];
    return [[AMAIronSourceModuleEntryPoint alloc] initWithPolicy:policy];
}

// MARK: - Policy disabled

- (void)testPolicyDisabled_skipsRegistration
{
    gIronSourceSDKVersion = @"9.0.0";
    AMAIronSourceModuleEntryPoint *ep = [self entryPointWithPolicyEnabled:NO];

    [ep initModuleWithContext:self.context];

    XCTAssertEqual(self.context.activationDelegates.count, 0u);
    XCTAssertEqual(AMAAppMetricaMock.capturedNativeSources.count, 0u);
}

// MARK: - No SDK / version too low

- (void)testNoSDKVersion_skipsRegistration
{
    AMAIronSourceModuleEntryPoint *ep = [self entryPointWithPolicyEnabled:YES];
    gIronSourceSDKVersion = nil;
    gLevelPlaySDKVersion  = nil;

    [ep initModuleWithContext:self.context];

    XCTAssertEqual(self.context.activationDelegates.count, 0u);
    XCTAssertEqual(AMAAppMetricaMock.capturedNativeSources.count, 0u);
}

- (void)testVersionBelowV8_skipsRegistration
{
    AMAIronSourceModuleEntryPoint *ep = [self entryPointWithPolicyEnabled:YES];
    gIronSourceSDKVersion = @"7.9.9";

    [ep initModuleWithContext:self.context];

    XCTAssertEqual(self.context.activationDelegates.count, 0u);
    XCTAssertEqual(AMAAppMetricaMock.capturedNativeSources.count, 0u);
}

// MARK: - V8

- (void)testVersionV8_registersNativeSourceAndDelegate
{
    AMAIronSourceModuleEntryPoint *ep = [self entryPointWithPolicyEnabled:YES];
    gIronSourceSDKVersion = @"8.0.0";

    [ep initModuleWithContext:self.context];

    XCTAssertEqualObjects(AMAAppMetricaMock.capturedNativeSources.firstObject, @"ironsource");
    XCTAssertEqual(self.context.activationDelegates.count, 1u);
    XCTAssertEqual(self.context.activationDelegates.firstObject, [AMAIronSourceManager class]);
}

- (void)testVersionV8_delegateRegisteredWithIronSourceSDK
{
    AMAIronSourceModuleEntryPoint *ep = [self entryPointWithPolicyEnabled:YES];
    gIronSourceSDKVersion = @"8.5.1";

    [ep initModuleWithContext:self.context];

    XCTAssertEqual(gIronSourceRegisteredDelegates.count, 1u);
    XCTAssertEqual(gLevelPlayRegisteredDelegates.count, 0u);
}

// MARK: - V9+

- (void)testVersionV9_registersNativeSourceAndDelegate
{
    AMAIronSourceModuleEntryPoint *ep = [self entryPointWithPolicyEnabled:YES];
    gLevelPlaySDKVersion = @"9.0.0";

    [ep initModuleWithContext:self.context];

    XCTAssertEqualObjects(AMAAppMetricaMock.capturedNativeSources.firstObject, @"ironsource");
    XCTAssertEqual(self.context.activationDelegates.count, 1u);
    XCTAssertEqual(self.context.activationDelegates.firstObject, [AMAIronSourceManager class]);
}

- (void)testVersionV9_delegateRegisteredWithLevelPlaySDK
{
    AMAIronSourceModuleEntryPoint *ep = [self entryPointWithPolicyEnabled:YES];
    gLevelPlaySDKVersion = @"9.1.0";

    [ep initModuleWithContext:self.context];

    XCTAssertEqual(gLevelPlayRegisteredDelegates.count, 1u);
    XCTAssertEqual(gIronSourceRegisteredDelegates.count, 0u);
}

- (void)testIronSourceVersionNil_fallsBackToLevelPlay
{
    AMAIronSourceModuleEntryPoint *ep = [self entryPointWithPolicyEnabled:YES];
    gIronSourceSDKVersion = nil;
    gLevelPlaySDKVersion  = @"9.2.0";

    [ep initModuleWithContext:self.context];

    XCTAssertEqual(self.context.activationDelegates.count, 1u);
    XCTAssertEqual(gLevelPlayRegisteredDelegates.count, 1u);
}

@end
