
#import <XCTest/XCTest.h>
#import "AMAAppLovinMaxModuleEntryPoint.h"
#import "AMAAppLovinAdRevenuePolicy.h"
#import "AMAAppLovinManager.h"
#import "AMAAppLovinTestSDKStubs.h"
#import "AMABundleInfoMock.h"
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>

static NSString *const kPolicyKey = @"io.appmetrica.applovin_auto_ad_revenue_enabled";

@interface AMAAppLovinMaxModuleEntryPoint (Testing)
- (void)registerNativeSource;
- (void)setupManager;
@end

@interface AMAAppLovinMaxModuleEntryPointSpy : AMAAppLovinMaxModuleEntryPoint
@property (nonatomic, strong) NSMutableArray<NSString *> *registeredNativeSources;
@property (nonatomic, assign) NSUInteger setupManagerCallCount;
@end

@implementation AMAAppLovinMaxModuleEntryPointSpy

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
    [self.registeredNativeSources addObject:@"applovin"];
}

- (void)setupManager
{
    ++self.setupManagerCallCount;
}

@end

@interface AMAAppLovinMaxModuleEntryPointTests : XCTestCase
@property (nonatomic, strong) AMAModuleRegistrarMock *registrar;
@end

@implementation AMAAppLovinMaxModuleEntryPointTests

- (void)setUp
{
    AMAAppLovinTestSDKStubsReset();
    self.registrar = [[AMAModuleRegistrarMock alloc] initWithTestCase:self];
}

- (AMAAppLovinMaxModuleEntryPointSpy *)entryPointWithPolicyEnabled:(BOOL)enabled
{
    AMABundleInfoMock *bundle = [AMABundleInfoMock new];
    bundle.mockedInfo = @{ kPolicyKey: @(enabled) };
    AMAAppLovinAdRevenuePolicy *policy = [[AMAAppLovinAdRevenuePolicy alloc] initWithBundle:bundle];
    return [[AMAAppLovinMaxModuleEntryPointSpy alloc] initWithPolicy:policy];
}

// MARK: - Policy disabled

- (void)testPolicyDisabled_skipsRegistration
{
    gALCCommunicatorAvailable = YES;
    AMAAppLovinMaxModuleEntryPointSpy *ep = [self entryPointWithPolicyEnabled:NO];

    [ep registerComponentsWithRegistrar:self.registrar];

    XCTAssertEqual(self.registrar.activationDelegates.count, 0u);
    XCTAssertEqual(ep.registeredNativeSources.count, 0u);
}

// MARK: - No SDK

- (void)testNoALCCommunicator_skipsRegistration
{
    gALCCommunicatorAvailable = NO;
    AMAAppLovinMaxModuleEntryPointSpy *ep = [self entryPointWithPolicyEnabled:YES];

    [ep registerComponentsWithRegistrar:self.registrar];

    XCTAssertEqual(self.registrar.activationDelegates.count, 0u);
    XCTAssertEqual(ep.registeredNativeSources.count, 0u);
}

// MARK: - SDK present

- (void)testRegisterComponentsWithRegistrar_registersNativeSourceAndDefersManagerSetupUntilPreActivation
{
    gALCCommunicatorAvailable = YES;
    AMAAppLovinMaxModuleEntryPointSpy *ep = [self entryPointWithPolicyEnabled:YES];

    [ep registerComponentsWithRegistrar:self.registrar];

    XCTAssertEqualObjects(ep.registeredNativeSources, (@[ @"applovin" ]));
    XCTAssertEqual(ep.setupManagerCallCount, 0u);
    XCTAssertEqualObjects(self.registrar.preActivationHandlers, (@[ ep ]));
    [ep handlePreActivationWithConfiguration:
        [[AMAModuleActivationConfiguration alloc] initWithApiKey:@"test-key"]];
    [ep handlePreActivationWithConfiguration:
        [[AMAModuleActivationConfiguration alloc] initWithApiKey:@"test-key"]];

    XCTAssertEqual(ep.registeredNativeSources.count, 1u);
    XCTAssertEqual(ep.setupManagerCallCount, 1u);
}

- (void)testALCCommunicatorPresent_registersActivationDelegate
{
    gALCCommunicatorAvailable = YES;
    AMAAppLovinMaxModuleEntryPointSpy *ep = [self entryPointWithPolicyEnabled:YES];

    [ep registerComponentsWithRegistrar:self.registrar];

    XCTAssertEqual(self.registrar.activationDelegates.count, 1u);
    XCTAssertEqual(self.registrar.activationDelegates.firstObject, [AMAAppLovinManager class]);
}

- (void)testALCCommunicatorPresent_registersServiceConfiguration
{
    gALCCommunicatorAvailable = YES;
    AMAAppLovinMaxModuleEntryPointSpy *ep = [self entryPointWithPolicyEnabled:YES];

    [ep registerComponentsWithRegistrar:self.registrar];

    XCTAssertEqual(self.registrar.serviceConfigurations.count, 1u);
}

- (void)testALCCommunicatorPresent_startupObserverIsManager
{
    gALCCommunicatorAvailable = YES;
    AMAAppLovinMaxModuleEntryPointSpy *ep = [self entryPointWithPolicyEnabled:YES];

    [ep registerComponentsWithRegistrar:self.registrar];

    id<AMAExtendedStartupObserving> observer = self.registrar.serviceConfigurations.firstObject.startupObserver;
    XCTAssertTrue([observer isKindOfClass:[AMAAppLovinManager class]]);
}

@end
