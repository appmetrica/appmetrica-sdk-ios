#import <XCTest/XCTest.h>
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaCoreExtension/AppMetricaCoreExtension.h>
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>
#import <AppMetricaHostState/AppMetricaHostState.h>
#import <AppMetricaPlatform/AppMetricaPlatform.h>
#import <AppMetricaPlatform/AMAApplicationState.h>
#import <AppMetricaCoreExtension/AMAApplicationStateManager.h>

#import "AMAAppMetricaCrashes.h"
#import "AMAAppMetricaCrashes+Private.h"
#import "AMAAppMetricaCrashesConfiguration.h"
#import "AMACrashContext.h"
#import "AMACrashLoading.h"
#import "AMACrashReportingStateNotifier.h"
#import "AMACrashSafeTransactor.h"
#import "AMADecodedCrashSerializer.h"
#import "AMAExternalCrashLoader.h"
#import "AMAKSCrashLoader.h"
#import "AMAUnhandledCrashDetector.h"

@interface AMAAppMetricaCrashes (AMAAppMetricaCrashesEarlyInitializationTests)

- (NSArray<AMAEventPollingParameters *> *)pollingEvents;

@end

static dispatch_time_t AMAEarlyCrashTestTimeout(void)
{
    return dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC);
}

static void AMAAppMetricaCrashesEarlyTestsCallback(
    __unused const AMAAppMetricaCrashErrorEnvironmentWriter *writer
)
{
}

@interface AMAEarlyCrashTestExecutor : NSObject <AMAAsyncExecuting, AMASyncExecuting>

@property (nonatomic, assign) NSUInteger executionCount;

@end

@implementation AMAEarlyCrashTestExecutor

- (void)execute:(AMAExecutingBlock)block
{
    @synchronized (self) {
        self.executionCount += 1;
    }
    block();
}

- (id)syncExecute:(id (^)(void))block
{
    return block();
}

@end

@interface AMAEarlyCrashHostStateProvider : NSObject <AMAHostStateProviding>

@property (nonatomic, weak) id<AMAHostStateProviderDelegate> delegate;

@end

@implementation AMAEarlyCrashHostStateProvider

- (AMAHostAppState)hostState
{
    return AMAHostAppStateForeground;
}

- (void)forceUpdateToForeground
{
}

@end

@interface AMAEarlyCrashExternalLoader : NSObject <AMACrashLoading>

@property (nonatomic, weak) id<AMACrashLoaderDelegate> delegate;
@property (nonatomic, assign) NSUInteger delegateAssignmentCount;
@property (nonatomic, assign) NSUInteger loadingCount;
@property (nonatomic, assign) NSUInteger registrationCount;

- (void)registerProvider:(id<AMACrashProviding>)provider;

@end

@implementation AMAEarlyCrashExternalLoader

- (void)setDelegate:(id<AMACrashLoaderDelegate>)delegate
{
    _delegate = delegate;
    self.delegateAssignmentCount += 1;
}

- (void)loadCrashReports
{
    self.loadingCount += 1;
}

- (void)registerProvider:(__unused id<AMACrashProviding>)provider
{
    self.registrationCount += 1;
}

@end

@interface AMAEarlyCrashStateNotifier : AMACrashReportingStateNotifier

@property (nonatomic, assign) NSUInteger notificationCount;
@property (nonatomic, assign) BOOL lastEnabledValue;

@end

@implementation AMAEarlyCrashStateNotifier

- (void)notifyWithEnabled:(BOOL)enabled crashedLastLaunch:(__unused NSNumber *)crashedLastLaunch
{
    self.notificationCount += 1;
    self.lastEnabledValue = enabled;
}

@end

@interface AMAEarlyCrashLoader : AMAKSCrashLoader

@property (nonatomic, assign) NSUInteger fullInstallationCount;
@property (nonatomic, assign) NSUInteger requiredInstallationCount;
@property (nonatomic, assign) NSUInteger activationCount;
@property (nonatomic, assign) NSUInteger delegateAssignmentCount;
@property (nonatomic, assign) NSUInteger probableUnhandledConfigurationCount;
@property (nonatomic, assign) NSUInteger loadingCount;
@property (nonatomic, assign) BOOL probableUnhandledEnabled;
@property (nonatomic, assign) AMAAppMetricaCrashErrorEnvironmentCallback callbackAtInstallation;
@property (nonatomic, copy) dispatch_block_t installationReentryBlock;
@property (nonatomic, copy) BOOL (^contextAvailableBlock)(void);
@property (nonatomic, assign) BOOL contextAvailableAtInstallation;
@property (nonatomic, assign) BOOL blockInstallation;
@property (nonatomic, strong) dispatch_semaphore_t installationEntered;
@property (nonatomic, strong) dispatch_semaphore_t continueInstallation;
@property (nonatomic, assign) long installationWaitResult;

@end

@implementation AMAEarlyCrashLoader

- (void)enableCrashMonitoring
{
    [self performInstallationReentryIfNeeded];
    [self recordInstallationWithFullMonitoring:YES];
}

- (void)enableRequiredMonitoring
{
    [self performInstallationReentryIfNeeded];
    [self recordInstallationWithFullMonitoring:NO];
}

- (void)enableCrashLoader
{
    @synchronized (self) {
        self.activationCount += 1;
    }
}

- (void)setDelegate:(id<AMACrashLoaderDelegate>)delegate
{
    [super setDelegate:delegate];
    @synchronized (self) {
        self.delegateAssignmentCount += 1;
    }
}

- (void)setIsUnhandledCrashDetectingEnabled:(BOOL)enabled
{
    [super setIsUnhandledCrashDetectingEnabled:enabled];
    @synchronized (self) {
        self.probableUnhandledConfigurationCount += 1;
        self.probableUnhandledEnabled = enabled;
    }
}

- (void)loadCrashReports
{
    @synchronized (self) {
        self.loadingCount += 1;
    }
}

- (NSArray<AMADecodedCrash *> *)syncLoadCrashReports
{
    return @[];
}

- (NSNumber *)crashedLastLaunch
{
    return @NO;
}

- (void)recordInstallationWithFullMonitoring:(BOOL)fullMonitoring
{
    BOOL shouldBlock = NO;
    @synchronized (self) {
        if (fullMonitoring) {
            self.fullInstallationCount += 1;
        }
        else {
            self.requiredInstallationCount += 1;
        }
        self.callbackAtInstallation = self.crashErrorEnvironmentCallback;
        self.contextAvailableAtInstallation = self.contextAvailableBlock != nil && self.contextAvailableBlock();
        shouldBlock = self.blockInstallation;
    }

    if (shouldBlock) {
        dispatch_semaphore_signal(self.installationEntered);
        self.installationWaitResult = dispatch_semaphore_wait(self.continueInstallation,
                                                               AMAEarlyCrashTestTimeout());
    }
}

- (void)performInstallationReentryIfNeeded
{
    dispatch_block_t reentryBlock = self.installationReentryBlock;
    self.installationReentryBlock = nil;
    if (reentryBlock != nil) {
        reentryBlock();
    }
}

@end

@interface AMAAppMetricaCrashesEarlyInitializationTests : XCTestCase

@property (nonatomic, strong) AMAEarlyCrashTestExecutor *executor;
@property (nonatomic, strong) AMAEarlyCrashLoader *loader;
@property (nonatomic, strong) AMAEarlyCrashExternalLoader *externalLoader;
@property (nonatomic, strong) AMAEarlyCrashStateNotifier *stateNotifier;
@property (nonatomic, strong) AMAAppMetricaCrashes *crashes;
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *contexts;

@end


@implementation AMAAppMetricaCrashesEarlyInitializationTests

- (void)setUp
{
    [super setUp];

    self.executor = [AMAEarlyCrashTestExecutor new];
    self.loader = [[AMAEarlyCrashLoader alloc]
        initWithUnhandledCrashDetector:(AMAUnhandledCrashDetector *)[NSObject new]
        transactor:(AMACrashSafeTransactor *)[NSObject new]];
    self.externalLoader = [AMAEarlyCrashExternalLoader new];
    self.stateNotifier = [AMAEarlyCrashStateNotifier new];
    self.contexts = [NSMutableArray array];

    NSMutableArray<NSDictionary *> *contexts = self.contexts;
    self.loader.contextAvailableBlock = ^BOOL{
        @synchronized (contexts) {
            return contexts.count > 0;
        }
    };
    [AMAKSCrashLoader stub:@selector(addCrashContext:) withBlock:^id(NSArray *params) {
        @synchronized (contexts) {
            [contexts addObject:[params[0] copy]];
        }
        return nil;
    }];

    self.crashes = [[AMAAppMetricaCrashes alloc]
        initWithExecutor:self.executor
        ksCrashLoader:self.loader
        stateNotifier:self.stateNotifier
        hostStateProvider:[AMAEarlyCrashHostStateProvider new]
        serializer:[AMADecodedCrashSerializer new]
        configuration:[AMAAppMetricaCrashesConfiguration new]
        externalCrashLoader:(AMAExternalCrashLoader *)self.externalLoader];
}

- (void)tearDown
{
    [AMAKSCrashLoader clearStubs];
    [AMAPlatformDescription clearStubs];
    [AMAApplicationStateManager clearStubs];

    self.crashes = nil;
    self.loader = nil;
    self.externalLoader = nil;
    self.stateNotifier = nil;
    self.executor = nil;
    self.contexts = nil;

    [super tearDown];
}

- (void)testFullMonitoringIsInstalledSynchronouslyWithoutActivation
{
    [self.crashes initializeCrashMonitoringWithConfiguration:[AMAAppMetricaCrashesConfiguration new]];

    XCTAssertEqual(self.loader.fullInstallationCount, 1u);
    XCTAssertEqual(self.loader.requiredInstallationCount, 0u);
    XCTAssertFalse(self.crashes.isActivated);
}

- (void)testRequiredMonitoringIsInstalledWhenAutomaticTrackingIsDisabled
{
    AMAAppMetricaCrashesConfiguration *configuration = [AMAAppMetricaCrashesConfiguration new];
    configuration.autoCrashTracking = NO;

    [self.crashes initializeCrashMonitoringWithConfiguration:configuration];

    XCTAssertEqual(self.loader.fullInstallationCount, 0u);
    XCTAssertEqual(self.loader.requiredInstallationCount, 1u);
}

- (void)testFirstEarlyConfigurationIsCopiedAndFrozen
{
    AMAAppMetricaCrashesConfiguration *first = [AMAAppMetricaCrashesConfiguration new];
    first.preActivationAppVersion = @"1.0";
    first.preActivationAppBuildNumber = @"1";
    first.ignoredCrashSignals = @[ @SIGABRT ];
    AMAAppMetricaCrashesConfiguration *second = [AMAAppMetricaCrashesConfiguration new];
    second.preActivationAppVersion = @"2.0";
    second.preActivationAppBuildNumber = @"2";
    second.autoCrashTracking = NO;

    [self.crashes initializeCrashMonitoringWithConfiguration:first];
    first.preActivationAppVersion = @"3.0";
    first.preActivationAppBuildNumber = @"3";
    first.ignoredCrashSignals = @[ @SIGSEGV ];
    [self.crashes initializeCrashMonitoringWithConfiguration:second];
    [self.crashes setConfiguration:second];

    XCTAssertEqualObjects(self.crashes.internalConfiguration.preActivationAppVersion, @"1.0");
    XCTAssertEqualObjects(self.crashes.internalConfiguration.preActivationAppBuildNumber, @"1");
    XCTAssertEqualObjects(self.crashes.internalConfiguration.ignoredCrashSignals, (@[ @SIGABRT ]));
    XCTAssertTrue(self.crashes.internalConfiguration.autoCrashTracking);
    XCTAssertEqual(self.loader.fullInstallationCount, 1u);
    XCTAssertEqual(self.loader.requiredInstallationCount, 0u);
}

- (void)testEarlyConfigurationOverridesProspectiveConfiguration
{
    AMAAppMetricaCrashesConfiguration *prospective = [AMAAppMetricaCrashesConfiguration new];
    prospective.autoCrashTracking = NO;
    [self.crashes setConfiguration:prospective];

    [self.crashes initializeCrashMonitoringWithConfiguration:[AMAAppMetricaCrashesConfiguration new]];

    XCTAssertTrue(self.crashes.internalConfiguration.autoCrashTracking);
    XCTAssertEqual(self.loader.fullInstallationCount, 1u);
}

- (void)testNilConfigurationDoesNotConsumeFirstInitialization
{
    AMAAppMetricaCrashesConfiguration *configuration = [AMAAppMetricaCrashesConfiguration new];
    configuration.autoCrashTracking = NO;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    [self.crashes initializeCrashMonitoringWithConfiguration:nil];
#pragma clang diagnostic pop
    [self.crashes initializeCrashMonitoringWithConfiguration:configuration];

    XCTAssertEqual(self.loader.requiredInstallationCount, 1u);
    XCTAssertFalse(self.crashes.internalConfiguration.autoCrashTracking);
}

- (void)testEarlyInitializationAfterActivationIsIgnored
{
    [self.crashes activate];
    AMAAppMetricaCrashesConfiguration *lateConfiguration = [AMAAppMetricaCrashesConfiguration new];
    lateConfiguration.autoCrashTracking = NO;

    [self.crashes initializeCrashMonitoringWithConfiguration:lateConfiguration];

    XCTAssertEqual(self.loader.fullInstallationCount, 1u);
    XCTAssertEqual(self.loader.requiredInstallationCount, 0u);
    XCTAssertTrue(self.crashes.internalConfiguration.autoCrashTracking);
}

- (void)testCallbackIsAssignedBeforeInstallation
{
    AMAAppMetricaCrashesConfiguration *configuration = [AMAAppMetricaCrashesConfiguration new];
    configuration.crashErrorEnvironmentCallback = AMAAppMetricaCrashesEarlyTestsCallback;

    [self.crashes initializeCrashMonitoringWithConfiguration:configuration];

    XCTAssertTrue(self.loader.callbackAtInstallation == AMAAppMetricaCrashesEarlyTestsCallback);
}

- (void)testMinimalContextIsWrittenBeforeInstallation
{
    [self.crashes initializeCrashMonitoringWithConfiguration:[AMAAppMetricaCrashesConfiguration new]];

    XCTAssertTrue(self.loader.contextAvailableAtInstallation);
}

- (void)testReentrantEarlyInitializationKeepsFirstConfiguration
{
    AMAAppMetricaCrashesConfiguration *first = [AMAAppMetricaCrashesConfiguration new];
    first.ignoredCrashSignals = @[ @SIGABRT ];
    AMAAppMetricaCrashesConfiguration *reentrant = [AMAAppMetricaCrashesConfiguration new];
    reentrant.autoCrashTracking = NO;
    __weak AMAAppMetricaCrashes *crashes = self.crashes;
    self.loader.installationReentryBlock = ^{
        [crashes initializeCrashMonitoringWithConfiguration:reentrant];
    };

    [self.crashes initializeCrashMonitoringWithConfiguration:first];

    XCTAssertEqual(self.loader.fullInstallationCount, 1u);
    XCTAssertEqual(self.loader.requiredInstallationCount, 0u);
    XCTAssertEqualObjects(self.crashes.internalConfiguration.ignoredCrashSignals, (@[ @SIGABRT ]));
}

- (void)testMinimalContextUsesRawVersionAndDoesNotRequestApplicationState
{
    [AMAPlatformDescription stub:@selector(appVersion) andReturn:@"1.2.3"];
    [AMAPlatformDescription stub:@selector(appBuildNumber) andReturn:@"42"];
    __block NSUInteger applicationStateRequestCount = 0;
    __block NSUInteger quickStateRequestCount = 0;
    [AMAApplicationStateManager stub:@selector(applicationState) withBlock:^id(__unused NSArray *params) {
        applicationStateRequestCount += 1;
        return nil;
    }];
    [AMAApplicationStateManager stub:@selector(quickApplicationState) withBlock:^id(__unused NSArray *params) {
        quickStateRequestCount += 1;
        return nil;
    }];

    [self.crashes initializeCrashMonitoringWithConfiguration:[AMAAppMetricaCrashesConfiguration new]];

    NSDictionary *context = self.contexts.lastObject;
    XCTAssertEqualObjects(context[kAMACrashContextAppStateKey], (@{
        kAMAAppVersionNameKey : @"1.2.3",
        kAMAAppBuildNumberKey : @"42",
    }));
    XCTAssertNotNil(context[kAMACrashContextAppBuildUIDKey]);
    XCTAssertNil(context[kAMACrashContextErrorEnvironmentKey]);
    XCTAssertNil(context[kAMACrashContextAppEnvironmentKey]);
    XCTAssertEqual(context.count, 2u);
    XCTAssertEqual(applicationStateRequestCount, 0u);
    XCTAssertEqual(quickStateRequestCount, 0u);
}

- (void)testMinimalContextUsesCustomVersionAndBuildNumber
{
    [AMAPlatformDescription stub:@selector(appVersion) andReturn:@"bundle-version"];
    [AMAPlatformDescription stub:@selector(appBuildNumber) andReturn:@"100"];
    AMAAppMetricaCrashesConfiguration *configuration = [AMAAppMetricaCrashesConfiguration new];
    configuration.preActivationAppVersion = @"26.8.3.701";
    configuration.preActivationAppBuildNumber = @"701";

    [self.crashes initializeCrashMonitoringWithConfiguration:configuration];

    NSDictionary *appState = self.contexts.lastObject[kAMACrashContextAppStateKey];
    XCTAssertEqualObjects(appState[kAMAAppVersionNameKey], @"26.8.3.701");
    XCTAssertEqualObjects(appState[kAMAAppBuildNumberKey], @"701");
}

- (void)testPreActivationContextUsesBundleBuildNumberWhenOnlyVersionIsCustom
{
    [AMAPlatformDescription stub:@selector(appVersion) andReturn:@"bundle-version"];
    [AMAPlatformDescription stub:@selector(appBuildNumber) andReturn:@"001"];
    AMAApplicationState *quickState = [AMAApplicationState objectWithDictionaryRepresentation:@{
        kAMAAppVersionNameKey : @"core-version",
        kAMAAppBuildNumberKey : @"1",
    }];
    [AMAApplicationStateManager stub:@selector(quickApplicationState) andReturn:quickState];
    AMAAppMetricaCrashesConfiguration *configuration = [AMAAppMetricaCrashesConfiguration new];
    configuration.preActivationAppVersion = @"26.8.3.701";

    [self.crashes initializeCrashMonitoringWithConfiguration:configuration];
    [self.crashes setErrorEnvironmentValue:@"value" forKey:@"key"];
    [self.crashes clearErrorEnvironment];

    XCTAssertEqual(self.contexts.count, 3u);
    for (NSDictionary *context in self.contexts) {
        NSDictionary *appState = context[kAMACrashContextAppStateKey];
        XCTAssertEqualObjects(appState[kAMAAppVersionNameKey], @"26.8.3.701");
        XCTAssertEqualObjects(appState[kAMAAppBuildNumberKey], @"001");
    }
}

- (void)testPreActivationContextUsesBundleVersionWhenOnlyBuildNumberIsCustom
{
    [AMAPlatformDescription stub:@selector(appVersion) andReturn:@"bundle-version"];
    [AMAPlatformDescription stub:@selector(appBuildNumber) andReturn:@"100"];
    AMAApplicationState *quickState = [AMAApplicationState objectWithDictionaryRepresentation:@{
        kAMAAppVersionNameKey : @"core-version",
        kAMAAppBuildNumberKey : @"1",
    }];
    [AMAApplicationStateManager stub:@selector(quickApplicationState) andReturn:quickState];
    AMAAppMetricaCrashesConfiguration *configuration = [AMAAppMetricaCrashesConfiguration new];
    configuration.preActivationAppBuildNumber = @"701";

    [self.crashes initializeCrashMonitoringWithConfiguration:configuration];
    [self.crashes setErrorEnvironmentValue:@"value" forKey:@"key"];
    [self.crashes clearErrorEnvironment];

    XCTAssertEqual(self.contexts.count, 3u);
    for (NSDictionary *context in self.contexts) {
        NSDictionary *appState = context[kAMACrashContextAppStateKey];
        XCTAssertEqualObjects(appState[kAMAAppVersionNameKey], @"bundle-version");
        XCTAssertEqualObjects(appState[kAMAAppBuildNumberKey], @"701");
    }
}

- (void)testPreActivationContextUsesEmptyStringsWhenBundleVersionsAreMissing
{
    [AMAPlatformDescription stub:@selector(appVersion) andReturn:nil];
    [AMAPlatformDescription stub:@selector(appBuildNumber) andReturn:nil];
    AMAApplicationState *quickState = [AMAApplicationState objectWithDictionaryRepresentation:@{
        kAMAAppVersionNameKey : @"core-version",
        kAMAAppBuildNumberKey : @"0",
    }];
    [AMAApplicationStateManager stub:@selector(quickApplicationState) andReturn:quickState];

    [self.crashes initializeCrashMonitoringWithConfiguration:[AMAAppMetricaCrashesConfiguration new]];
    [self.crashes setErrorEnvironmentValue:@"value" forKey:@"key"];
    [self.crashes clearErrorEnvironment];

    XCTAssertEqual(self.contexts.count, 3u);
    for (NSDictionary *context in self.contexts) {
        NSDictionary *appState = context[kAMACrashContextAppStateKey];
        XCTAssertEqualObjects(appState[kAMAAppVersionNameKey], @"");
        XCTAssertEqualObjects(appState[kAMAAppBuildNumberKey], @"");
    }
}

- (void)testPreActivationErrorEnvironmentUpdatesRefreshAppStateAndPreserveVersions
{
    AMAMutableApplicationState *quickState = [AMAMutableApplicationState new];
    quickState.appVersionName = @"core-version";
    quickState.appBuildNumber = @"1";
    quickState.OSAPILevel = 17;
    quickState.kitBuildNumber = 123;
    __block NSUInteger quickStateRequestCount = 0;
    [AMAApplicationStateManager stub:@selector(quickApplicationState) withBlock:^id(__unused NSArray *params) {
        quickStateRequestCount += 1;
        return quickState;
    }];
    AMAAppMetricaCrashesConfiguration *configuration = [AMAAppMetricaCrashesConfiguration new];
    configuration.preActivationAppVersion = @"26.8.3.701";
    configuration.preActivationAppBuildNumber = @"701";
    [self.crashes initializeCrashMonitoringWithConfiguration:configuration];
    configuration.preActivationAppVersion = @"changed-version";
    configuration.preActivationAppBuildNumber = @"999";

    [self.crashes setErrorEnvironmentValue:@"value" forKey:@"key"];

    NSMutableDictionary *expectedState = [quickState.dictionaryRepresentation mutableCopy];
    expectedState[kAMAAppVersionNameKey] = @"26.8.3.701";
    expectedState[kAMAAppBuildNumberKey] = @"701";
    XCTAssertEqualObjects(self.contexts.lastObject[kAMACrashContextAppStateKey], expectedState);
    XCTAssertEqualObjects(self.contexts.lastObject[kAMACrashContextErrorEnvironmentKey], (@{ @"key" : @"value" }));

    quickState.OSAPILevel = 18;
    quickState.kitBuildNumber = 124;
    [self.crashes clearErrorEnvironment];

    expectedState[kAMAOSAPILevelKey] = @"18";
    expectedState[kAMAKitBuildNumberKey] = @"124";
    XCTAssertEqual(self.contexts.count, 3u);
    XCTAssertEqualObjects(self.contexts.lastObject[kAMACrashContextAppStateKey], expectedState);
    XCTAssertEqualObjects(self.contexts.lastObject[kAMACrashContextErrorEnvironmentKey], @{});
    XCTAssertEqual(quickStateRequestCount, 2u);
    XCTAssertEqualObjects(quickState.appVersionName, @"core-version");
    XCTAssertEqualObjects(quickState.appBuildNumber, @"1");
}

- (void)testEarlyInitializationDoesNotRunActivationDependentWork
{
    AMAAppMetricaCrashesConfiguration *configuration = [AMAAppMetricaCrashesConfiguration new];
    configuration.applicationNotRespondingDetection = YES;
    configuration.probablyUnhandledCrashReporting = YES;

    [self.crashes initializeCrashMonitoringWithConfiguration:configuration];
    [self.crashes reportNSError:[NSError errorWithDomain:@"test" code:1 userInfo:nil] onFailure:nil];
    [self.crashes registerCrashProvider:(id<AMACrashProviding>)[NSObject new]];

    XCTAssertFalse(self.crashes.isActivated);
    XCTAssertEqual(self.executor.executionCount, 0u);
    XCTAssertEqual(self.loader.activationCount, 0u);
    XCTAssertEqual(self.loader.delegateAssignmentCount, 0u);
    XCTAssertEqual(self.loader.probableUnhandledConfigurationCount, 0u);
    XCTAssertEqual(self.loader.loadingCount, 0u);
    XCTAssertEqual(self.externalLoader.delegateAssignmentCount, 0u);
    XCTAssertEqual(self.externalLoader.loadingCount, 0u);
    XCTAssertEqual(self.externalLoader.registrationCount, 1u);
    XCTAssertEqual(self.stateNotifier.notificationCount, 0u);
}

- (void)testFullActivationCompletesAfterEarlyFullInstallationWithoutReinstalling
{
    AMAAppMetricaCrashesConfiguration *configuration = [AMAAppMetricaCrashesConfiguration new];
    configuration.probablyUnhandledCrashReporting = YES;
    [self.crashes initializeCrashMonitoringWithConfiguration:configuration];

    [self.crashes activate];

    XCTAssertTrue(self.crashes.isActivated);
    XCTAssertEqual(self.loader.fullInstallationCount, 1u);
    XCTAssertEqual(self.loader.activationCount, 1u);
    XCTAssertEqual(self.loader.delegateAssignmentCount, 1u);
    XCTAssertEqual(self.loader.probableUnhandledConfigurationCount, 1u);
    XCTAssertTrue(self.loader.probableUnhandledEnabled);
    XCTAssertEqual(self.loader.loadingCount, 1u);
    XCTAssertEqual(self.externalLoader.delegateAssignmentCount, 1u);
    XCTAssertEqual(self.externalLoader.loadingCount, 1u);
    XCTAssertEqual(self.stateNotifier.notificationCount, 1u);
    XCTAssertTrue(self.stateNotifier.lastEnabledValue);
    XCTAssertEqual(self.contexts.count, 2u);
}

- (void)testRepeatedFullActivationPreservesNormalLifecycleWithoutReinstalling
{
    [self.crashes initializeCrashMonitoringWithConfiguration:[AMAAppMetricaCrashesConfiguration new]];

    [self.crashes activate];
    [self.crashes activate];

    XCTAssertEqual(self.loader.fullInstallationCount, 1u);
    XCTAssertEqual(self.loader.activationCount, 2u);
    XCTAssertEqual(self.loader.loadingCount, 2u);
    XCTAssertEqual(self.externalLoader.loadingCount, 2u);
    XCTAssertEqual(self.stateNotifier.notificationCount, 2u);
    XCTAssertEqual(self.contexts.count, 3u);
}

- (void)testDisabledActivationCleansUpWithoutAnotherInstallation
{
    __block NSUInteger purgeCount = 0;
    [AMAKSCrashLoader stub:@selector(purgeCrashesDirectory) withBlock:^id(__unused NSArray *params) {
        purgeCount += 1;
        return nil;
    }];
    AMAAppMetricaCrashesConfiguration *configuration = [AMAAppMetricaCrashesConfiguration new];
    configuration.autoCrashTracking = NO;
    [self.crashes initializeCrashMonitoringWithConfiguration:configuration];

    [self.crashes activate];

    XCTAssertEqual(self.loader.requiredInstallationCount, 1u);
    XCTAssertEqual(self.loader.fullInstallationCount, 0u);
    XCTAssertEqual(self.loader.activationCount, 0u);
    XCTAssertEqual(purgeCount, 1u);
    XCTAssertEqual(self.stateNotifier.notificationCount, 1u);
    XCTAssertFalse(self.stateNotifier.lastEnabledValue);
    XCTAssertEqual(self.contexts.count, 2u);
}

- (void)testFullActivationReplacesMinimalApplicationState
{
    AMAAppMetricaCrashesConfiguration *configuration = [AMAAppMetricaCrashesConfiguration new];
    configuration.preActivationAppVersion = @"1.2.3";
    configuration.preActivationAppBuildNumber = @"42";
    AMAApplicationState *applicationState = [AMAApplicationState objectWithDictionaryRepresentation:@{
        kAMAAppVersionNameKey : @"activated-version",
        kAMAAppBuildNumberKey : @"100",
        kAMAOSAPILevelKey : @"17",
    }];
    [AMAApplicationStateManager stub:@selector(applicationState) andReturn:applicationState];
    [AMAApplicationStateManager stub:@selector(quickApplicationState) andReturn:applicationState];

    [self.crashes initializeCrashMonitoringWithConfiguration:configuration];
    [self.crashes activate];
    [self.crashes setErrorEnvironmentValue:@"value" forKey:@"key"];
    [self.crashes clearErrorEnvironment];

    XCTAssertEqualObjects(self.contexts[0][kAMACrashContextAppStateKey], (@{
        kAMAAppVersionNameKey : @"1.2.3",
        kAMAAppBuildNumberKey : @"42",
    }));
    XCTAssertEqual(self.contexts.count, 4u);
    for (NSUInteger index = 1; index < self.contexts.count; ++index) {
        XCTAssertEqualObjects(self.contexts[index][kAMACrashContextAppStateKey], applicationState.dictionaryRepresentation);
    }
}

- (void)testEarlyInitializationWaitsForErrorEnvironmentContextPublication
{
    AMAApplicationState *quickState = [AMAApplicationState objectWithDictionaryRepresentation:@{
        kAMAAppVersionNameKey : @"core-version",
        kAMAAppBuildNumberKey : @"1",
    }];
    [AMAApplicationStateManager stub:@selector(quickApplicationState) andReturn:quickState];
    AMAAppMetricaCrashesConfiguration *configuration = [AMAAppMetricaCrashesConfiguration new];
    configuration.preActivationAppVersion = @"early-version";
    configuration.preActivationAppBuildNumber = @"42";
    [self.crashes setConfiguration:configuration];

    dispatch_semaphore_t publicationEntered = dispatch_semaphore_create(0);
    dispatch_semaphore_t continuePublication = dispatch_semaphore_create(0);
    __block long publicationWaitResult = 0;
    NSMutableArray<NSDictionary *> *contexts = self.contexts;
    [AMAKSCrashLoader stub:@selector(addCrashContext:) withBlock:^id(NSArray *params) {
        NSDictionary *context = params[0];
        if (context[kAMACrashContextErrorEnvironmentKey] != nil) {
            dispatch_semaphore_signal(publicationEntered);
            publicationWaitResult = dispatch_semaphore_wait(continuePublication, AMAEarlyCrashTestTimeout());
        }
        @synchronized (contexts) {
            [contexts addObject:[context copy]];
        }
        return nil;
    }];

    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_queue_create("io.appmetrica.early-crash-environment-test",
                                                    DISPATCH_QUEUE_CONCURRENT);
    dispatch_group_async(group, queue, ^{
        [self.crashes setErrorEnvironmentValue:@"value" forKey:@"key"];
    });
    long publicationEnteredResult = dispatch_semaphore_wait(publicationEntered, AMAEarlyCrashTestTimeout());
    dispatch_semaphore_t initializationStarted = dispatch_semaphore_create(0);
    dispatch_semaphore_t initializationFinished = dispatch_semaphore_create(0);
    dispatch_group_async(group, queue, ^{
        dispatch_semaphore_signal(initializationStarted);
        [self.crashes initializeCrashMonitoringWithConfiguration:configuration];
        dispatch_semaphore_signal(initializationFinished);
    });
    long initializationStartedResult = dispatch_semaphore_wait(initializationStarted, AMAEarlyCrashTestTimeout());
    long initializationFinishedBeforePublication = dispatch_semaphore_wait(initializationFinished,
        dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC));

    dispatch_semaphore_signal(continuePublication);
    long groupResult = dispatch_group_wait(group, AMAEarlyCrashTestTimeout());

    XCTAssertEqual(publicationEnteredResult, 0l);
    XCTAssertEqual(initializationStartedResult, 0l);
    XCTAssertNotEqual(initializationFinishedBeforePublication, 0l);
    XCTAssertEqual(publicationWaitResult, 0l);
    XCTAssertEqual(groupResult, 0l);
    XCTAssertEqual(self.loader.fullInstallationCount, 1u);
    XCTAssertEqual(self.contexts.count, 2u);
    XCTAssertEqualObjects(self.contexts.firstObject[kAMACrashContextAppStateKey], quickState.dictionaryRepresentation);
    XCTAssertEqualObjects(self.contexts.lastObject[kAMACrashContextAppStateKey], (@{
        kAMAAppVersionNameKey : @"early-version",
        kAMAAppBuildNumberKey : @"42",
    }));
}

- (void)testActivationWaitsForEarlyInstallation
{
    self.loader.blockInstallation = YES;
    self.loader.installationEntered = dispatch_semaphore_create(0);
    self.loader.continueInstallation = dispatch_semaphore_create(0);
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_queue_create("io.appmetrica.early-crash-activation-test",
                                                    DISPATCH_QUEUE_CONCURRENT);
    dispatch_group_async(group, queue, ^{
        [self.crashes initializeCrashMonitoringWithConfiguration:[AMAAppMetricaCrashesConfiguration new]];
    });
    long installationEntered = dispatch_semaphore_wait(self.loader.installationEntered,
                                                         AMAEarlyCrashTestTimeout());
    dispatch_semaphore_t activationStarted = dispatch_semaphore_create(0);
    dispatch_semaphore_t activationFinished = dispatch_semaphore_create(0);
    dispatch_group_async(group, queue, ^{
        dispatch_semaphore_signal(activationStarted);
        [self.crashes activate];
        dispatch_semaphore_signal(activationFinished);
    });
    long activationStartedResult = dispatch_semaphore_wait(activationStarted, AMAEarlyCrashTestTimeout());
    long activationFinishedBeforeRelease = dispatch_semaphore_wait(activationFinished, DISPATCH_TIME_NOW);

    dispatch_semaphore_signal(self.loader.continueInstallation);
    long groupResult = dispatch_group_wait(group, AMAEarlyCrashTestTimeout());

    XCTAssertEqual(installationEntered, 0l);
    XCTAssertEqual(activationStartedResult, 0l);
    XCTAssertNotEqual(activationFinishedBeforeRelease, 0l);
    XCTAssertEqual(groupResult, 0l);
    XCTAssertEqual(self.loader.installationWaitResult, 0l);
    XCTAssertEqual(self.loader.fullInstallationCount, 1u);
    XCTAssertEqual(self.loader.activationCount, 1u);
}

- (void)testPollingWaitsForConfigurationFreeze
{
    self.loader.blockInstallation = YES;
    self.loader.installationEntered = dispatch_semaphore_create(0);
    self.loader.continueInstallation = dispatch_semaphore_create(0);
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_queue_create("io.appmetrica.early-crash-polling-test",
                                                    DISPATCH_QUEUE_CONCURRENT);
    dispatch_group_async(group, queue, ^{
        [self.crashes initializeCrashMonitoringWithConfiguration:[AMAAppMetricaCrashesConfiguration new]];
    });
    long installationEntered = dispatch_semaphore_wait(self.loader.installationEntered,
                                                         AMAEarlyCrashTestTimeout());
    dispatch_semaphore_t pollingStarted = dispatch_semaphore_create(0);
    dispatch_semaphore_t pollingFinished = dispatch_semaphore_create(0);
    dispatch_group_async(group, queue, ^{
        dispatch_semaphore_signal(pollingStarted);
        [self.crashes pollingEvents];
        dispatch_semaphore_signal(pollingFinished);
    });
    long pollingStartedResult = dispatch_semaphore_wait(pollingStarted, AMAEarlyCrashTestTimeout());
    long pollingFinishedBeforeRelease = dispatch_semaphore_wait(pollingFinished, DISPATCH_TIME_NOW);

    dispatch_semaphore_signal(self.loader.continueInstallation);
    long groupResult = dispatch_group_wait(group, AMAEarlyCrashTestTimeout());

    XCTAssertEqual(installationEntered, 0l);
    XCTAssertEqual(pollingStartedResult, 0l);
    XCTAssertNotEqual(pollingFinishedBeforeRelease, 0l);
    XCTAssertEqual(groupResult, 0l);
    XCTAssertEqual(self.loader.installationWaitResult, 0l);
}

- (void)testEarlyCallWaitsForActivationInstallationAndThenDoesNothing
{
    self.loader.blockInstallation = YES;
    self.loader.installationEntered = dispatch_semaphore_create(0);
    self.loader.continueInstallation = dispatch_semaphore_create(0);
    AMAAppMetricaCrashesConfiguration *activationConfiguration = [AMAAppMetricaCrashesConfiguration new];
    activationConfiguration.autoCrashTracking = NO;
    [self.crashes setConfiguration:activationConfiguration];
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_queue_create("io.appmetrica.activation-early-crash-test",
                                                    DISPATCH_QUEUE_CONCURRENT);
    dispatch_group_async(group, queue, ^{
        [self.crashes activate];
    });
    long installationEntered = dispatch_semaphore_wait(self.loader.installationEntered,
                                                         AMAEarlyCrashTestTimeout());
    dispatch_semaphore_t earlyStarted = dispatch_semaphore_create(0);
    dispatch_semaphore_t earlyFinished = dispatch_semaphore_create(0);
    dispatch_group_async(group, queue, ^{
        dispatch_semaphore_signal(earlyStarted);
        [self.crashes initializeCrashMonitoringWithConfiguration:[AMAAppMetricaCrashesConfiguration new]];
        dispatch_semaphore_signal(earlyFinished);
    });
    long earlyStartedResult = dispatch_semaphore_wait(earlyStarted, AMAEarlyCrashTestTimeout());
    long earlyFinishedBeforeRelease = dispatch_semaphore_wait(earlyFinished, DISPATCH_TIME_NOW);

    dispatch_semaphore_signal(self.loader.continueInstallation);
    long groupResult = dispatch_group_wait(group, AMAEarlyCrashTestTimeout());

    XCTAssertEqual(installationEntered, 0l);
    XCTAssertEqual(earlyStartedResult, 0l);
    XCTAssertNotEqual(earlyFinishedBeforeRelease, 0l);
    XCTAssertEqual(groupResult, 0l);
    XCTAssertEqual(self.loader.installationWaitResult, 0l);
    XCTAssertEqual(self.loader.requiredInstallationCount, 1u);
    XCTAssertEqual(self.loader.fullInstallationCount, 0u);
    XCTAssertFalse(self.crashes.internalConfiguration.autoCrashTracking);
}

- (void)testFirstConcurrentEarlyCallFreezesConfiguration
{
    self.loader.blockInstallation = YES;
    self.loader.installationEntered = dispatch_semaphore_create(0);
    self.loader.continueInstallation = dispatch_semaphore_create(0);
    AMAAppMetricaCrashesConfiguration *first = [AMAAppMetricaCrashesConfiguration new];
    first.ignoredCrashSignals = @[ @SIGABRT ];
    AMAAppMetricaCrashesConfiguration *second = [AMAAppMetricaCrashesConfiguration new];
    second.autoCrashTracking = NO;
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_queue_create("io.appmetrica.early-crash-race-test",
                                                    DISPATCH_QUEUE_CONCURRENT);
    dispatch_group_async(group, queue, ^{
        [self.crashes initializeCrashMonitoringWithConfiguration:first];
    });
    long installationEntered = dispatch_semaphore_wait(self.loader.installationEntered,
                                                         AMAEarlyCrashTestTimeout());
    dispatch_semaphore_t secondStarted = dispatch_semaphore_create(0);
    dispatch_group_async(group, queue, ^{
        dispatch_semaphore_signal(secondStarted);
        [self.crashes initializeCrashMonitoringWithConfiguration:second];
    });
    long secondStartedResult = dispatch_semaphore_wait(secondStarted, AMAEarlyCrashTestTimeout());

    dispatch_semaphore_signal(self.loader.continueInstallation);
    long groupResult = dispatch_group_wait(group, AMAEarlyCrashTestTimeout());

    XCTAssertEqual(installationEntered, 0l);
    XCTAssertEqual(secondStartedResult, 0l);
    XCTAssertEqual(groupResult, 0l);
    XCTAssertEqual(self.loader.installationWaitResult, 0l);
    XCTAssertEqual(self.loader.fullInstallationCount, 1u);
    XCTAssertEqual(self.loader.requiredInstallationCount, 0u);
    XCTAssertEqualObjects(self.crashes.internalConfiguration.ignoredCrashSignals, (@[ @SIGABRT ]));
}

@end
