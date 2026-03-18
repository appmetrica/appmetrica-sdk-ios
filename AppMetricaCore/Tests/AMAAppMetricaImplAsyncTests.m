
#import <AppMetricaKiwi/AppMetricaKiwi.h>
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
#import "AMADataSendingRestrictionController.h"
#import "AMAReporterAutocollectedDataProvider.h"

static NSString *apiKey = @"550e8400-e29b-41d4-a716-446655440000";
static NSString *const anonymousApiKey = @"629a824d-c717-4ba5-bc0f-3f3968554d01";


@interface AMAAppMetricaImplAsyncTests : XCTestCase

@property AMAAppMetricaConfiguration *configuration;
@property AMAReporterTestHelper *reporterTestHelper;
@property AMAEventStorage *eventStorage;
@property AMAEventStorage *anomymousEventStorage;
@property AMAAppMetricaImpl *appMetricaImpl;
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

- (void)setUp
{
    [AMALocationManager stub:@selector(sharedManager)];
    self.configuration = [AMAAppMetricaConfiguration nullMock];
    [self.configuration stub:@selector(APIKey) andReturn:apiKey];
    self.startupController = [AMAStartupController stubbedNullMockForInit:@selector(initWithTimeoutRequestsController:)];
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
    self.deeplinkController = [AMADeepLinkController stubbedNullMockForInit:@selector(initWithReporter:executor:)];
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

- (void)testInitializeMainReporter
{
    AMAAppMetricaConfiguration *config = [[AMAAppMetricaConfiguration alloc] initWithAPIKey:apiKey];
    [self.appMetricaImpl activateWithConfiguration:config];
    
    XCTAssertNil(self.appMetricaImpl.mainReporter);
    
    [self.executor execute];
    
    XCTAssertNotNil(self.appMetricaImpl.mainReporter);
    XCTAssertEqualObjects(self.appMetricaImpl.mainReporter.apiKey, apiKey);
}

- (void)testReportEvent
{
    AMAAppMetricaConfiguration *config = [[AMAAppMetricaConfiguration alloc] initWithAPIKey:apiKey];
    [self.appMetricaImpl activateWithConfiguration:config];
    
    XCTAssertNil(self.appMetricaImpl.mainReporter);
    
    XCTestExpectation *__block onFailureExpectation1 = [self expectationWithDescription:@"should not call onFailure"];
    XCTestExpectation *__block onFailureExpectation2 = [self expectationWithDescription:@"should not call onFailure"];
    
    onFailureExpectation1.inverted = YES;
    onFailureExpectation2.inverted = YES;
    
    [self.appMetricaImpl reportEvent:@"test" parameters:@{} onFailure:^(NSError * _Nonnull error) {
        [onFailureExpectation1 fulfill];
        [onFailureExpectation2 fulfill];
    }];
    
    [self waitForExpectations:@[onFailureExpectation1] timeout:2];
        
    [self.executor execute];
    
    [self waitForExpectations:@[onFailureExpectation2] timeout:1];
}

@end
