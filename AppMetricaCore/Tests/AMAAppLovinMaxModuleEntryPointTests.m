
#import <XCTest/XCTest.h>
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMAAppLovinMaxModuleEntryPoint.h"
#import "AMAAppLovinAdRevenuePolicy.h"
#import "AMAAppLovinManager.h"
#import "AMAAppLovinTestSDKStubs.h"
#import "AMAAppMetricaMock.h"
#import "AMABundleInfoMock.h"
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>

static NSString *const kPolicyKey = @"io.appmetrica.applovin_auto_ad_revenue_enabled";

@interface AMAAppLovinMaxModuleEntryPointTests : XCTestCase
@property (nonatomic, strong) AMAModuleContextMock *context;
@end

@implementation AMAAppLovinMaxModuleEntryPointTests

- (void)setUp
{
    AMAAppLovinTestSDKStubsReset();
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

- (AMAAppLovinMaxModuleEntryPoint *)entryPointWithPolicyEnabled:(BOOL)enabled
{
    AMABundleInfoMock *bundle = [AMABundleInfoMock new];
    bundle.mockedInfo = @{ kPolicyKey: @(enabled) };
    AMAAppLovinAdRevenuePolicy *policy = [[AMAAppLovinAdRevenuePolicy alloc] initWithBundle:bundle];
    return [[AMAAppLovinMaxModuleEntryPoint alloc] initWithPolicy:policy];
}

// MARK: - Policy disabled

- (void)testPolicyDisabled_skipsRegistration
{
    gALCCommunicatorAvailable = YES;
    AMAAppLovinMaxModuleEntryPoint *ep = [self entryPointWithPolicyEnabled:NO];

    [ep initModuleWithContext:self.context];

    XCTAssertEqual(self.context.activationDelegates.count, 0u);
    XCTAssertEqual(AMAAppMetricaMock.capturedNativeSources.count, 0u);
}

// MARK: - No SDK

- (void)testNoALCCommunicator_skipsRegistration
{
    gALCCommunicatorAvailable = NO;
    AMAAppLovinMaxModuleEntryPoint *ep = [self entryPointWithPolicyEnabled:YES];

    [ep initModuleWithContext:self.context];

    XCTAssertEqual(self.context.activationDelegates.count, 0u);
    XCTAssertEqual(AMAAppMetricaMock.capturedNativeSources.count, 0u);
}

// MARK: - SDK present

- (void)testALCCommunicatorPresent_registersNativeSource
{
    gALCCommunicatorAvailable = YES;
    AMAAppLovinMaxModuleEntryPoint *ep = [self entryPointWithPolicyEnabled:YES];

    [ep initModuleWithContext:self.context];

    XCTAssertEqualObjects(AMAAppMetricaMock.capturedNativeSources.firstObject, @"applovin");
}

- (void)testALCCommunicatorPresent_registersActivationDelegate
{
    gALCCommunicatorAvailable = YES;
    AMAAppLovinMaxModuleEntryPoint *ep = [self entryPointWithPolicyEnabled:YES];

    [ep initModuleWithContext:self.context];

    XCTAssertEqual(self.context.activationDelegates.count, 1u);
    XCTAssertEqual(self.context.activationDelegates.firstObject, [AMAAppLovinManager class]);
}

- (void)testALCCommunicatorPresent_registersExternalService
{
    gALCCommunicatorAvailable = YES;
    AMAAppLovinMaxModuleEntryPoint *ep = [self entryPointWithPolicyEnabled:YES];

    [ep initModuleWithContext:self.context];

    XCTAssertEqual(self.context.serviceConfigurations.count, 1u);
}

- (void)testALCCommunicatorPresent_startupObserverIsManager
{
    gALCCommunicatorAvailable = YES;
    AMAAppLovinMaxModuleEntryPoint *ep = [self entryPointWithPolicyEnabled:YES];

    [ep initModuleWithContext:self.context];

    id<AMAExtendedStartupObserving> observer = self.context.serviceConfigurations.firstObject.startupObserver;
    XCTAssertTrue([observer isKindOfClass:[AMAAppLovinManager class]]);
}

@end
