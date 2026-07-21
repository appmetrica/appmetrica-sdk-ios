
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaCoreExtension/AppMetricaCoreExtension.h>
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>
#import <AppMetricaWebKit/AppMetricaWebKit.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import <AppMetricaPlatform/AppMetricaPlatform.h>
#import "AMAAppMetricaImpl+TestUtilities.h"
#import "AMAAdRevenueInfo.h"
#import "AMAAdServicesReportingController.h"
#import "AMAAppMetrica+Internal.h"
#import "AMAAppMetrica+TestUtilities.h"
#import "AMAAppMetrica.h"
#import "AMAAppMetricaImplTestFactory.h"
#import "AMAAppMetricaPreloadInfo+AMAInternal.h"
#import "AMAAppMetricaPreloadInfo.h"
#import "AMAAppOpenWatcher.h"
#import "AMAAttributionController.h"
#import "AMAAutoPurchasesWatcher.h"
#import "AMACachingStorageProvider.h"
#import "AMADeepLinkController.h"
#import "AMADispatchStrategiesContainer.h"
#import "AMADispatchStrategy+Private.h"
#import "AMADispatchStrategyMask.h"
#import "AMADispatcher.h"
#import "AMADispatchingController.h"
#import "AMAECommerce.h"
#import "AMAEnvironmentContainer.h"
#import "AMAEvent.h"
#import "AMAEventBuilder.h"
#import "AMAEventCountDispatchStrategy.h"
#import "AMAEventPollingDelegateMock.h"
#import "AMAEventStorage+TestUtilities.h"
#import "AMAExtensionsReportController.h"
#import "AMAExtrasContainer.h"
#import "AMAExternalAttributionController.h"
#import "AMAInternalEventsReporter.h"
#import "AMALocationManager.h"
#import "AMAMetricaConfigurationTestUtilities.h"
#import "AMAModulesController.h"
#import "AMAPermissionsController.h"
#import "AMAProfileAttribute.h"
#import "AMAReporter.h"
#import "AMAReporterConfiguration.h"
#import "AMAReporterStateStorage.h"
#import "AMAReporterStorage.h"
#import "AMAReporterStoragesContainer.h"
#import "AMAReporterTestHelper.h"
#import "AMARevenueInfo.h"
#import "AMASessionStorage.h"
#import "AMAStartupController.h"
#import "AMAStartupItemsChangedNotifier.h"
#import "AMAStartupStorageProvider.h"
#import "AMAStringEventValue.h"
#import "AMATimerDispatchStrategy.h"
#import "AMAUserProfile.h"
#import "AMAAppMetricaConfigurationManager.h"
#import "AMAFirstActivationDetector.h"
#import "AMAMetricaPersistentConfiguration.h"
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMAAppMetricaConfiguration+JSONSerializable.h"
#import "AMAAnonymousActivationPolicy.h"
#import "AMAAdProviderProxy.h"
#import "AMADataSendingRestrictionController.h"
#import "AMAModulesController.h"
#import "AMAReporterAutocollectedDataProvider.h"
#import "Mocks/AMAAdProvidingMock.h"
#import "Mocks/AMAAdProviderProxyMock.h"
#import "Mocks/AMAModuleEntryPointDiscovererMock.h"
#import "Mocks/AMAModuleRegistrarMocks.h"

static NSString *apiKey = @"550e8400-e29b-41d4-a716-446655440000";
static NSString *const anonymousApiKey = @"629a824d-c717-4ba5-bc0f-3f3968554d01";

@interface AMAAppMetricaImpl (AsyncModulesTests)
@property (nonatomic, strong) AMAModulesController *modulesController;
@end


@interface AMAAppMetricaImplAsyncTests : XCTestCase

@property AMAAppMetricaConfiguration *configuration;
@property AMAReporterTestHelper *reporterTestHelper;
@property AMAEventStorage *eventStorage;
@property AMAEventStorage *anomymousEventStorage;
@property AMAAppMetricaImplStub *appMetricaImpl;
@property AMAStubHostAppStateProvider *hostStateProvider;
@property AMAStartupController *startupController;
@property AMAPermissionsController *permissionsController;
@property AMAExtensionsReportController *extensionsReportController;
@property AMADispatchStrategiesContainer *dispatchStrategiesContainer;
@property AMAAppOpenWatcher *appOpenWatcher;
@property AMAAdServicesReportingController *adServicesReportingController;
@property AMAAutoPurchasesWatcher *autoPurchasesWatcher;
@property AMADispatchingController *dispatchingController;
@property AMADeepLinkController *deeplinkController;
@property AMAInternalEventsReporter *internalEventsReporter;
@property AMAStartupItemsChangedNotifier *startupNotifier;
@property AMAExternalAttributionController *externalAttributionController;
@property AMAFirstActivationDetector *firstActivationDetector;
@property AMADataSendingRestrictionController *restrictionController;
@property AMAReporterAutocollectedDataProvider *autocollectedDataProvider;
@property AMAManualCurrentQueueExecutor *executor;

@end

@implementation AMAAppMetricaImplAsyncTests

- (void)configureModuleRegistration:
    (void (^)(id<AMAModuleRegistrar> registrar))registrationHandler
{
    AMAFakeEntryPoint *entryPoint = [[AMAFakeEntryPoint alloc] init];
    entryPoint.registrationHandler = registrationHandler;
    self.appMetricaImpl.moduleEntryPointDiscoverer.entryPoints = @[ entryPoint ];
}

- (void)setUp
{
    [AMAModuleActivationDelegateMock reset];
    [AMALocationManager stub:@selector(sharedManager)];
    self.configuration = [AMAAppMetricaConfiguration nullMock];
    [self.configuration stub:@selector(APIKey) andReturn:apiKey];
    self.startupController = [AMAStartupController stubbedNullMockForInit:@selector(initWithTimeoutRequestsController:attributionController:)];
    self.permissionsController = [AMAPermissionsController stubbedNullMockForInit:@selector(initWithConfiguration:
                                                                                       extrcator:
                                                                                       dateProvider:)];
    self.extensionsReportController = [AMAExtensionsReportController stubbedNullMockForInit:@selector(initWithReporter:
                                                                                                 conditionProvider:
                                                                                                 provider:
                                                                                                 executor:)];
    self.dispatchStrategiesContainer = [AMADispatchStrategiesContainer stubbedNullMockForDefaultInit];
    
    self.appOpenWatcher = [AMAAppOpenWatcher stubbedNullMockForDefaultInit];
    self.autoPurchasesWatcher = [AMAAutoPurchasesWatcher stubbedNullMockForInit:@selector(initWithExecutor:)];
    self.deeplinkController = [AMADeepLinkController stubbedNullMockForInit:@selector(initWithExecutor:)];
    self.adServicesReportingController = [AMAAdServicesReportingController stubbedNullMockForInit:@selector(initWithApiKey:
                                                                                                       reporterStateStorage:)];
    self.dispatchingController = [AMADispatchingController stubbedNullMockForInit:@selector(initWithTimeoutConfiguration:)];
    self.internalEventsReporter = [AMAInternalEventsReporter nullMock];
    self.firstActivationDetector = [AMAFirstActivationDetector stubbedNullMockForDefaultInit];
    
    self.autocollectedDataProvider = [AMAReporterAutocollectedDataProvider stubbedNullMockForInit:@selector(initWithPersistentConfiguration:)];

    self.hostStateProvider = [AMAStubHostAppStateProvider new];
    self.hostStateProvider.hostState = AMAHostAppStateBackground;

    [AMAMetricaConfigurationTestUtilities stubConfigurationWithAppVersion:@"1.00"
                                                              buildNumber:100];
    self.reporterTestHelper = [[AMAReporterTestHelper alloc] init];
    self.eventStorage = [self.reporterTestHelper appReporterForApiKey:apiKey].reporterStorage.eventStorage;
    self.anomymousEventStorage = [self.reporterTestHelper appReporterForApiKey:anonymousApiKey].reporterStorage.eventStorage;
    self.startupNotifier = [AMAStartupItemsChangedNotifier stubbedNullMockForDefaultInit];
    self.externalAttributionController = [AMAExternalAttributionController stubbedNullMockForInit:@selector(initWithReporter:)];
    
    self.executor = [AMAManualCurrentQueueExecutor new];
    
    self.appMetricaImpl = [[AMAAppMetricaImplStub alloc] initWithHostStateProvider:self.hostStateProvider
                                                                          executor:self.executor
                                                                reporterTestHelper:self.reporterTestHelper];
    [AMAAppMetrica stub:@selector(sharedImpl) andReturn:self.appMetricaImpl];
    
    id<AMAAsyncExecuting>executor = [AMACurrentQueueExecutor new];
    [AMAAppMetrica stub:@selector(sharedExecutor) andReturn:executor];
    [AMAAppMetrica stub:@selector(sharedInternalEventsReporter) andReturn:self.internalEventsReporter];
    
    self.restrictionController = [AMADataSendingRestrictionController stubbedNullMockForDefaultInit];
    [AMADataSendingRestrictionController stub:@selector(sharedInstance) andReturn:self.restrictionController];
}

- (void)tearDown
{
    [AMAModuleActivationDelegateMock reset];
    [AMAReporterStoragesContainer clearStubs];
    [AMAExternalAttributionController clearStubs];
    [AMAReporterAutocollectedDataProvider clearStubs];
    [AMAAdServicesReportingController clearStubs];
    [AMADeepLinkController clearStubs];
    [AMAAutoPurchasesWatcher clearStubs];
    [AMAPermissionsController clearStubs];
    [AMAStartupController clearStubs];
    [AMAStartupItemsChangedNotifier clearStubs];
    [AMAFirstActivationDetector clearStubs];
    [AMAAppOpenWatcher clearStubs];
    [AMADispatchStrategiesContainer clearStubs];
    [AMADataSendingRestrictionController clearStubs];
    [AMAMetricaConfigurationTestUtilities destubConfiguration];
    [AMALocationManager clearStubs];
    [AMAAppMetrica clearStubs];
    [AMAMetricaConfiguration clearStubs];
    [[AMAMetricaConfiguration sharedInstance] clearStubs];
    [AMAReporterStoragesContainer clearStubs];
    [self.reporterTestHelper destub];
    self.appMetricaImpl = nil;
}

- (void)testActivationRunsCoreSynchronouslyAndModuleLifecycleAfterDiscovery
{
    XCTAssertNotNil(self.appMetricaImpl.modulesController);
    [self configureModuleRegistration:^(id<AMAModuleRegistrar> registrar) {
        [registrar registerActivationDelegate:AMAModuleActivationDelegateMock.class];
    }];

    AMAAppMetricaConfiguration *configuration =
        [[AMAAppMetricaConfiguration alloc] initWithAPIKey:apiKey];
    [self.appMetricaImpl activateWithConfiguration:configuration];

    XCTAssertNotNil(self.appMetricaImpl.mainReporter);
    XCTAssertEqual([AMAModuleActivationDelegateMock willActivateCallCount], 0);
    XCTAssertEqual([AMAModuleActivationDelegateMock didActivateCallCount], 0);

    [self.executor execute];

    XCTAssertEqual([AMAModuleActivationDelegateMock willActivateCallCount], 1);
    XCTAssertEqual([AMAModuleActivationDelegateMock didActivateCallCount], 1);
}

- (void)testModuleAdProviderIsAppliedInsideQueuedPreActivationAfterDiscovery
{
    AMAAdProviderProxyMock *adProviderProxy = [AMAAdProviderProxyMock new];
    self.appMetricaImpl.adProviderProxy = adProviderProxy;

    id<AMAAdProviding> moduleAdProvider = [AMAAdProvidingMock new];
    __block BOOL providerWasAppliedBeforeWill = NO;
    [self configureModuleRegistration:^(id<AMAModuleRegistrar> registrar) {
        [registrar registerAdProvider:moduleAdProvider];
        [registrar registerActivationDelegate:AMAModuleActivationDelegateMock.class];
    }];
    AMAModuleActivationDelegateMock.willActivateHandler =
        ^(__unused AMAModuleActivationConfiguration *configuration) {
        providerWasAppliedBeforeWill = adProviderProxy.lastBackingProvider == moduleAdProvider;
    };

    AMAAppMetricaConfiguration *configuration =
        [[AMAAppMetricaConfiguration alloc] initWithAPIKey:apiKey];
    [self.appMetricaImpl activateWithConfiguration:configuration];

    XCTAssertNil(adProviderProxy.lastBackingProvider);

    [self.executor execute];

    XCTAssertTrue(adProviderProxy.lastBackingProvider == moduleAdProvider);
    XCTAssertEqual(adProviderProxy.setBackingProviderCallCount, 1u);
    XCTAssertTrue(providerWasAppliedBeforeWill);
}

- (void)testAnonymousActivationAppliesModuleAdProviderBeforeWillCallback
{
    AMAAdProviderProxyMock *adProviderProxy = [AMAAdProviderProxyMock new];
    self.appMetricaImpl.adProviderProxy = adProviderProxy;

    id<AMAAdProviding> moduleAdProvider = [AMAAdProvidingMock new];
    __block BOOL providerWasAppliedBeforeWill = NO;
    [self configureModuleRegistration:^(id<AMAModuleRegistrar> registrar) {
        [registrar registerAdProvider:moduleAdProvider];
        [registrar registerActivationDelegate:AMAModuleActivationDelegateMock.class];
    }];
    AMAModuleActivationDelegateMock.willActivateHandler =
        ^(__unused AMAModuleActivationConfiguration *configuration) {
        providerWasAppliedBeforeWill = adProviderProxy.lastBackingProvider == moduleAdProvider;
    };
    AMAAppMetricaConfiguration *anonymousConfiguration =
        [[AMAAppMetricaConfiguration alloc] initWithAPIKey:anonymousApiKey];
    AMAAppMetricaConfigurationManager *configurationManager =
        [AMAAppMetricaConfigurationManager nullMock];
    [configurationManager stub:@selector(anonymousConfiguration)
                     andReturn:anonymousConfiguration];
    self.appMetricaImpl.configurationManager = configurationManager;

    [self.appMetricaImpl activateAnonymously];

    XCTAssertNil(adProviderProxy.lastBackingProvider);

    [self.executor execute];

    XCTAssertTrue(providerWasAppliedBeforeWill);
    XCTAssertTrue(adProviderProxy.lastBackingProvider == moduleAdProvider);
    XCTAssertEqual(adProviderProxy.setBackingProviderCallCount, 1u);
}

- (void)testInitializeMainReporter
{
    AMAAppMetricaConfiguration *config = [[AMAAppMetricaConfiguration alloc] initWithAPIKey:apiKey];
    [self.appMetricaImpl activateWithConfiguration:config];

    XCTAssertNotNil(self.appMetricaImpl.mainReporter);
    XCTAssertEqualObjects(self.appMetricaImpl.mainReporter.apiKey, apiKey);
}

- (void)testReportEvent
{
    AMAAppMetricaConfiguration *config = [[AMAAppMetricaConfiguration alloc] initWithAPIKey:apiKey];
    [self.appMetricaImpl activateWithConfiguration:config];

    XCTAssertNotNil(self.appMetricaImpl.mainReporter);

    XCTestExpectation *onFailureExpectation = [self expectationWithDescription:@"should not call onFailure"];
    
    onFailureExpectation.inverted = YES;
    
    [self.appMetricaImpl reportEvent:@"test" parameters:@{} onFailure:^(NSError * _Nonnull error) {
        [onFailureExpectation fulfill];
    }];

    [self.executor execute];

    XCTAssertNotNil(self.appMetricaImpl.mainReporter);
    [self waitForExpectations:@[ onFailureExpectation ] timeout:1];
}

- (void)testSetUserProfileIDBeforeActivationAppliesWithoutFlushingExecutor
{
    NSString *profileID = @"Profile ID before activation";
    
    self.executor.executeNonDelayedBlocksImmediately = NO;
    [self.appMetricaImpl setUserProfileID:profileID];

    XCTAssertEqualObjects(self.appMetricaImpl.userProfileID, profileID);
}

- (void)testSetUserProfileIDImmediatelyAfterSynchronousActivationIsApplied
{
    AMAAppMetricaConfiguration *config = [[AMAAppMetricaConfiguration alloc] initWithAPIKey:apiKey];
    [self.appMetricaImpl activateWithConfiguration:config];

    NSString *profileID = @"Profile ID after activation";
    
    self.executor.executeNonDelayedBlocksImmediately = NO;
    [self.appMetricaImpl setUserProfileID:profileID];

    [self.executor execute];

    AMAReporter *reporter = [self.reporterTestHelper appReporterForApiKey:apiKey];

    XCTAssertEqualObjects(reporter.reporterStorage.stateStorage.profileID, profileID);
}

@end
