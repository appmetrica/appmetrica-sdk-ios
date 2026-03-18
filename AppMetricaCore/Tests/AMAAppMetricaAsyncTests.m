
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
#import "AMAAppMetricaMock.h"

static NSString *apiKey = @"550e8400-e29b-41d4-a716-446655440000";
static NSString *const anonymousApiKey = @"629a824d-c717-4ba5-bc0f-3f3968554d01";


@interface AMAAppMetricaAsyncTests : XCTestCase

@property (nonatomic, strong) AMAAppMetricaConfiguration *configuration;
@property (nonatomic, strong) AMAReporterTestHelper *reporterTestHelper;
@property (nonatomic, strong) AMAEventStorage *eventStorage;
@property (nonatomic, strong) AMAEventStorage *anomymousEventStorage;
@property (nonatomic, strong) AMAAppMetricaImpl *appMetricaImpl;
@property (nonatomic, strong) AMAStubHostAppStateProvider *hostStateProvider;
@property (nonatomic, strong) AMAStartupController *startupController;
@property (nonatomic, strong) AMAPermissionsController *permissionsController;
@property (nonatomic, strong) AMAExtensionsReportController *extensionsReportController;
@property (nonatomic, strong) AMADispatchStrategiesContainer *dispatchStrategiesContainer;
@property (nonatomic, strong) AMAAppOpenWatcher *appOpenWatcher;
@property (nonatomic, strong) AMAAdServicesReportingController *adServicesReportingController;
@property (nonatomic, strong) AMAAutoPurchasesWatcher *autoPurchasesWatcher;
@property (nonatomic, strong) AMADispatchingController *dispatchingController;
@property (nonatomic, strong) AMADeepLinkController *deeplinkController;
@property (nonatomic, strong) AMAInternalEventsReporter *internalEventsReporter;
@property (nonatomic, strong) AMAStartupItemsChangedNotifier *startupNotifier;
@property (nonatomic, strong) AMAExternalAttributionController *externalAttributionController;
@property (nonatomic, strong) AMAFirstActivationDetector *firstActivationDetector;
@property (nonatomic, strong) AMADataSendingRestrictionController *restrictionController;
@property (nonatomic, strong) AMAReporterAutocollectedDataProvider *autocollectedDataProvider;
@property (nonatomic, strong) AMAManualCurrentQueueExecutor *executor;
@property (nonatomic, strong) AMAMetricaConfiguration *metricaConfiguration;

@end

@implementation AMAAppMetricaAsyncTests

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
    self.metricaConfiguration = [AMAMetricaConfiguration sharedInstance];
    
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
    
    // syncExecute not be called
    AMAAppMetricaMock.sharedExecutor = executor;
    AMAAppMetricaMock.sharedImpl = self.appMetricaImpl;
    AMAAppMetricaMock.metricaConfiguration = self.metricaConfiguration;
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
    
    [AMAAppMetricaMock activateWithConfiguration:config];
    
    XCTestExpectation *failureExpectation1 = [self expectationWithDescription:@"should not be called 1"];
    failureExpectation1.inverted = YES;
    
    XCTestExpectation *failureExpectation2 = [self expectationWithDescription:@"should not be called 2"];
    failureExpectation2.inverted = YES;
    
    [AMAAppMetricaMock reportEvent:@"test" onFailure:^(NSError * _Nonnull error) {
        [failureExpectation1 fulfill];
        [failureExpectation2 fulfill];
    }];
    
    [self waitForExpectations:@[failureExpectation1] timeout:2];
    
    [self.executor execute];
    
    [self waitForExpectations:@[failureExpectation2] timeout:2];
}

@end
