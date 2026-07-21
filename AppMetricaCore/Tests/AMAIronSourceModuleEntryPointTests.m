
#import <XCTest/XCTest.h>
#import "AMAIronSourceModuleEntryPoint.h"
#import "AMAIronSourceAdRevenuePolicy.h"
#import "AMAIronSourceManager.h"
#import "AMAIronSourceImpressionDelegate.h"
#import "AMAIronSourceTestSDKStubs.h"
#import "AMABundleInfoMock.h"
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>

static NSString *const kPolicyKey = @"io.appmetrica.ironsource_auto_ad_revenue_enabled";

@interface AMAIronSourceModuleEntryPoint (Testing)
- (void)registerNativeSource;
@end

@interface AMAIronSourceModuleEntryPointSpy : AMAIronSourceModuleEntryPoint
@property (nonatomic, strong) NSMutableArray<NSString *> *registeredNativeSources;
@end

@implementation AMAIronSourceModuleEntryPointSpy

- (instancetype)initWithPolicy:(AMAInfoPlistPolicy *)policy
{
    self = [super initWithPolicy:policy];
    if (self != nil) {
        _registeredNativeSources = [NSMutableArray array];
    }
    return self;
}

- (void)registerNativeSource
{
    [self.registeredNativeSources addObject:@"ironsource"];
}

@end

@interface AMAIronSourceManager (EntryPointTesting)
@property (nonatomic, strong) AMAIronSourceImpressionDelegate *impressionDelegate;
@end

// MARK: - Helpers

@interface AMAIronSourceModuleEntryPointTests : XCTestCase
@property (nonatomic, strong) AMAModuleRegistrarMock *registrar;
@end

@implementation AMAIronSourceModuleEntryPointTests

- (void)setUp
{
    AMAIronSourceTestSDKStubsReset();
    self.registrar = [[AMAModuleRegistrarMock alloc] initWithTestCase:self];
}

- (AMAIronSourceModuleEntryPointSpy *)entryPointWithPolicyEnabled:(BOOL)enabled
{
    AMABundleInfoMock *bundle = [AMABundleInfoMock new];
    bundle.mockedInfo = @{ kPolicyKey: @(enabled) };
    AMAIronSourceAdRevenuePolicy *policy = [[AMAIronSourceAdRevenuePolicy alloc] initWithBundle:bundle];
    return [[AMAIronSourceModuleEntryPointSpy alloc] initWithPolicy:policy];
}

// MARK: - Policy disabled

- (void)testPolicyDisabled_skipsRegistration
{
    gIronSourceSDKVersion = @"9.0.0";
    AMAIronSourceModuleEntryPointSpy *ep = [self entryPointWithPolicyEnabled:NO];

    [ep registerComponentsWithRegistrar:self.registrar];

    XCTAssertEqual(self.registrar.activationDelegates.count, 0u);
    XCTAssertEqual(ep.registeredNativeSources.count, 0u);
}

// MARK: - No SDK / version too low

- (void)testNoSDKVersion_skipsRegistration
{
    AMAIronSourceModuleEntryPointSpy *ep = [self entryPointWithPolicyEnabled:YES];
    gIronSourceSDKVersion = nil;
    gLevelPlaySDKVersion  = nil;

    [ep registerComponentsWithRegistrar:self.registrar];

    XCTAssertEqual(self.registrar.activationDelegates.count, 0u);
    XCTAssertEqual(ep.registeredNativeSources.count, 0u);
}

- (void)testVersionBelowV8_skipsRegistration
{
    AMAIronSourceModuleEntryPointSpy *ep = [self entryPointWithPolicyEnabled:YES];
    gIronSourceSDKVersion = @"7.9.9";

    [ep registerComponentsWithRegistrar:self.registrar];

    XCTAssertEqual(self.registrar.activationDelegates.count, 0u);
    XCTAssertEqual(ep.registeredNativeSources.count, 0u);
}

// MARK: - V8

- (void)testVersionV8_registersNativeSourceAndDefersManagerSetupUntilPreActivation
{
    AMAIronSourceModuleEntryPointSpy *ep = [self entryPointWithPolicyEnabled:YES];
    gIronSourceSDKVersion = @"8.0.0";

    [ep registerComponentsWithRegistrar:self.registrar];

    XCTAssertEqualObjects(ep.registeredNativeSources, (@[ @"ironsource" ]));
    XCTAssertEqualObjects(self.registrar.preActivationHandlers, (@[ ep ]));
    XCTAssertEqual(self.registrar.activationDelegates.count, 1u);
    XCTAssertEqual(self.registrar.activationDelegates.firstObject, [AMAIronSourceManager class]);

    [ep handlePreActivationWithConfiguration:
        [[AMAModuleActivationConfiguration alloc] initWithApiKey:@"test-key"]];
    [ep handlePreActivationWithConfiguration:
        [[AMAModuleActivationConfiguration alloc] initWithApiKey:@"test-key"]];
    XCTAssertEqual(ep.registeredNativeSources.count, 1u);
}

- (void)testVersionV8_delegateRegisteredWithIronSourceSDK
{
    AMAIronSourceModuleEntryPointSpy *ep = [self entryPointWithPolicyEnabled:YES];
    gIronSourceSDKVersion = @"8.5.1";

    [ep registerComponentsWithRegistrar:self.registrar];

    XCTAssertEqual(gIronSourceRegisteredDelegates.count, 0u);
    [ep handlePreActivationWithConfiguration:
        [[AMAModuleActivationConfiguration alloc] initWithApiKey:@"test-key"]];

    XCTAssertEqual(gIronSourceRegisteredDelegates.count, 1u);
    XCTAssertEqual(gLevelPlayRegisteredDelegates.count, 0u);
}

// MARK: - V9+

- (void)testVersionV9_registersNativeSourceAndDefersManagerSetupUntilPreActivation
{
    AMAIronSourceModuleEntryPointSpy *ep = [self entryPointWithPolicyEnabled:YES];
    gLevelPlaySDKVersion = @"9.0.0";

    [ep registerComponentsWithRegistrar:self.registrar];

    XCTAssertEqualObjects(ep.registeredNativeSources, (@[ @"ironsource" ]));
    XCTAssertEqualObjects(self.registrar.preActivationHandlers, (@[ ep ]));
    XCTAssertEqual(self.registrar.activationDelegates.count, 1u);
    XCTAssertEqual(self.registrar.activationDelegates.firstObject, [AMAIronSourceManager class]);

    [ep handlePreActivationWithConfiguration:
        [[AMAModuleActivationConfiguration alloc] initWithApiKey:@"test-key"]];
    XCTAssertEqual(ep.registeredNativeSources.count, 1u);
}

- (void)testVersionV9_delegateRegisteredWithLevelPlaySDK
{
    AMAIronSourceModuleEntryPointSpy *ep = [self entryPointWithPolicyEnabled:YES];
    gLevelPlaySDKVersion = @"9.1.0";

    [ep registerComponentsWithRegistrar:self.registrar];

    XCTAssertEqual(gLevelPlayRegisteredDelegates.count, 0u);
    [ep handlePreActivationWithConfiguration:
        [[AMAModuleActivationConfiguration alloc] initWithApiKey:@"test-key"]];

    XCTAssertEqual(gLevelPlayRegisteredDelegates.count, 1u);
    XCTAssertEqual(gIronSourceRegisteredDelegates.count, 0u);
}

- (void)testIronSourceVersionNil_fallsBackToLevelPlay
{
    AMAIronSourceModuleEntryPointSpy *ep = [self entryPointWithPolicyEnabled:YES];
    gIronSourceSDKVersion = nil;
    gLevelPlaySDKVersion  = @"9.2.0";

    [ep registerComponentsWithRegistrar:self.registrar];

    [ep handlePreActivationWithConfiguration:
        [[AMAModuleActivationConfiguration alloc] initWithApiKey:@"test-key"]];

    XCTAssertEqual(self.registrar.activationDelegates.count, 1u);
    XCTAssertEqual(gLevelPlayRegisteredDelegates.count, 1u);
}

@end
