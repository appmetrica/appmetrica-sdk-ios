#import <XCTest/XCTest.h>
#import "AMAModulesController.h"
#import <AppMetricaCoreExtension/AppMetricaCoreExtension.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "Mocks/AMAAdProvidingMock.h"
#import "Mocks/AMAModuleEntryPointDiscovererMock.h"
#import "Mocks/AMAModuleRegistrarMocks.h"

@interface AMAModulesControllerTests : XCTestCase
@property (nonatomic, strong) AMAModulesController *controller;
@property (nonatomic, strong) AMAModuleEntryPointDiscovererMock *discoverer;
@end

@implementation AMAModulesControllerTests

static NSString *const kAMATestAPIKey = @"550e8400-e29b-41d4-a716-446655440000";

- (void)setUp
{
    [super setUp];
    AMACurrentQueueExecutor *executor = [[AMACurrentQueueExecutor alloc] init];
    self.discoverer = [[AMAModuleEntryPointDiscovererMock alloc] init];
    self.controller = [[AMAModulesController alloc]
        initWithExecutor:executor
        discoverer:self.discoverer
        registrationCoordinator:nil
        startupParametersHandler:nil];
    [AMAModuleActivationDelegateMock reset];
    [AMAEventFlushableDelegateMock reset];
}

- (void)tearDown
{
    [AMAModuleActivationDelegateMock reset];
    [AMAEventFlushableDelegateMock reset];
    self.discoverer = nil;
    self.controller = nil;
    [super tearDown];
}

- (AMAFakeEntryPoint *)entryPointRegistering:
    (void (^)(id<AMAModuleRegistrar> registrar))registrationHandler
{
    AMAFakeEntryPoint *entryPoint = [[AMAFakeEntryPoint alloc] init];
    entryPoint.registrationHandler = registrationHandler;
    self.discoverer.entryPoints = @[ entryPoint ];
    return entryPoint;
}

- (void)testStartLoadingDiscoversEntryPointsRegistersComponentsAndPublishesOnlyOnce
{
    AMAFakeEntryPoint *entryPoint = [self entryPointRegistering:nil];

    [self.controller startLoading];
    [self.controller startLoading];

    XCTAssertEqual(self.discoverer.discoverCallCount, 1u);
    XCTAssertEqual(entryPoint.registrationCallCount, 1);
    XCTAssertNotNil(entryPoint.receivedRegistrar);
}

- (void)testFailingEntryPointDoesNotPreventFollowingEntryPointRegistration
{
    AMAFakeEntryPoint *failingEntryPoint = [[AMAFakeEntryPoint alloc] init];
    failingEntryPoint.registrationHandler = ^(__unused id<AMAModuleRegistrar> registrar) {
        @throw [NSException exceptionWithName:@"test"
                                       reason:@"expected registration failure"
                                     userInfo:nil];
    };
    AMAFakeEntryPoint *followingEntryPoint = [[AMAFakeEntryPoint alloc] init];
    followingEntryPoint.registrationHandler = ^(id<AMAModuleRegistrar> registrar) {
        [registrar registerActivationDelegate:AMAModuleActivationDelegateMock.class];
    };
    self.discoverer.entryPoints = @[ failingEntryPoint, followingEntryPoint ];

    [self.controller startLoading];
    [self.controller performActivationWithAppMetricaConfiguration:
        [[AMAAppMetricaConfiguration alloc] initWithAPIKey:kAMATestAPIKey]
                                                  activationBlock:nil];

    XCTAssertEqual(failingEntryPoint.registrationCallCount, 1);
    XCTAssertEqual(followingEntryPoint.registrationCallCount, 1);
    XCTAssertEqual(AMAModuleActivationDelegateMock.willActivateCallCount, 1);
    XCTAssertEqual(AMAModuleActivationDelegateMock.didActivateCallCount, 1);
}

- (void)testActivationAndFlushCallbacksAreRoutedFromPublishedRegistry
{
    [self entryPointRegistering:^(id<AMAModuleRegistrar> registrar) {
        [registrar registerActivationDelegate:AMAModuleActivationDelegateMock.class];
        [registrar registerEventFlushableDelegate:AMAEventFlushableDelegateMock.class];
    }];
    AMAAppMetricaConfiguration *configuration =
        [[AMAAppMetricaConfiguration alloc] initWithAPIKey:kAMATestAPIKey];

    [self.controller startLoading];
    [self.controller performActivationWithAppMetricaConfiguration:configuration activationBlock:nil];
    [self.controller notifySendEventsBuffer];

    XCTAssertEqual(AMAModuleActivationDelegateMock.willActivateCallCount, 1);
    XCTAssertEqual(AMAModuleActivationDelegateMock.didActivateCallCount, 1);
    XCTAssertEqualObjects(AMAModuleActivationDelegateMock.lastConfiguration.apiKey, configuration.APIKey);
    XCTAssertEqual(AMAEventFlushableDelegateMock.sendEventsBufferCallCount, 1);
}

- (void)testActivationCreatesModuleConfigurationSnapshot
{
    AMAModulePreActivationHandlerMock *handler = [[AMAModulePreActivationHandlerMock alloc] init];
    [self entryPointRegistering:^(id<AMAModuleRegistrar> registrar) {
        [registrar registerPreActivationHandler:handler];
        [registrar registerActivationDelegate:AMAModuleActivationDelegateMock.class];
    }];
    __block AMAModuleActivationConfiguration *preActivationConfiguration = nil;
    __block AMAModuleActivationConfiguration *willConfiguration = nil;
    __block AMAModuleActivationConfiguration *didConfiguration = nil;
    handler.preActivationBlock = ^(AMAModuleActivationConfiguration *configuration) {
        preActivationConfiguration = configuration;
    };
    AMAModuleActivationDelegateMock.willActivateHandler = ^(AMAModuleActivationConfiguration *configuration) {
        willConfiguration = configuration;
    };
    AMAModuleActivationDelegateMock.didActivateHandler = ^(AMAModuleActivationConfiguration *configuration) {
        didConfiguration = configuration;
    };
    AMAAppMetricaConfiguration *configuration =
        [[AMAAppMetricaConfiguration alloc] initWithAPIKey:kAMATestAPIKey];
    configuration.appVersion = @"1.2.3";
    configuration.appBuildNumber = @"42";

    [self.controller startLoading];
    [self.controller performActivationWithAppMetricaConfiguration:configuration
                                                  activationBlock:^{
        configuration.appVersion = @"changed";
        configuration.appBuildNumber = @"43";
    }];

    XCTAssertTrue(preActivationConfiguration == willConfiguration);
    XCTAssertTrue(willConfiguration == didConfiguration);
    XCTAssertEqualObjects(didConfiguration.apiKey, kAMATestAPIKey);
    XCTAssertEqualObjects(didConfiguration.appVersion, @"1.2.3");
    XCTAssertEqualObjects(didConfiguration.appBuildNumber, @"42");
}

- (void)testStartupCallbacksAndInitialParametersAreRoutedFromPublishedRegistry
{
    AMAExtendedStartupObservingMock *observer = [[AMAExtendedStartupObservingMock alloc] init];
    observer.stubbedStartupParameters = @{ @"initial" : @"value" };
    [self entryPointRegistering:^(id<AMAModuleRegistrar> registrar) {
        [registrar registerServiceConfiguration:[[AMAServiceConfiguration alloc]
            initWithStartupObserver:observer reporterStorageController:nil]];
    }];
    NSMutableArray<NSDictionary *> *initialParameters = [NSMutableArray array];
    self.controller.startupParametersHandler = ^(NSDictionary *parameters) {
        [initialParameters addObject:parameters];
    };
    NSError *error = [NSError errorWithDomain:@"test" code:42 userInfo:nil];

    [self.controller startLoading];
    [self.controller notifyStartupUpdatedWithParameters:@{ @"updated" : @"value" }];
    [self.controller notifyStartupFailedWithError:error];

    XCTAssertEqual(observer.setupCallCount, 1);
    XCTAssertEqual(observer.updatedCallCount, 1);
    XCTAssertEqual(observer.failedCallCount, 1);
    XCTAssertEqualObjects(observer.lastParameters, (@{ @"updated" : @"value" }));
    XCTAssertEqualObjects(observer.lastError, error);
    XCTAssertEqualObjects(initialParameters, (@[ @{ @"initial" : @"value" } ]));
}

- (void)testReporterStorageControllerIsRoutedFromPublishedRegistry
{
    AMAReporterStorageControllingMock *storageController =
        [[AMAReporterStorageControllingMock alloc] init];
    [self entryPointRegistering:^(id<AMAModuleRegistrar> registrar) {
        [registrar registerServiceConfiguration:[[AMAServiceConfiguration alloc]
            initWithStartupObserver:nil reporterStorageController:storageController]];
    }];

    [self.controller startLoading];
    [self.controller setupReporterStorageWithProvider:(id<AMAKeyValueStorageProviding>)[NSObject new]
                                                 main:YES
                                               apiKey:@"test-key"];

    XCTAssertEqual(storageController.setupCallCount, 1);
}

- (void)testAdProviderIsResolvedOnlyAfterEntryPointRegistration
{
    AMAAdProvidingMock *provider = [[AMAAdProvidingMock alloc] init];
    [self entryPointRegistering:^(id<AMAModuleRegistrar> registrar) {
        [registrar registerAdProvider:provider];
    }];
    __block id<AMAAdProviding> resolvedProvider = nil;

    [self.controller startLoading];
    [self.controller resolveModuleAdProviderWithHandler:^(id<AMAAdProviding> moduleAdProvider) {
        resolvedProvider = moduleAdProvider;
    }];

    XCTAssertTrue(resolvedProvider == provider);
}

@end
