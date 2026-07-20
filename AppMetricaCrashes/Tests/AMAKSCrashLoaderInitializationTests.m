#import <XCTest/XCTest.h>
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaPlatform/AppMetricaPlatform.h>
#import <KSCrashConfiguration.h>

#import "AMAAppMetricaCrashes.h"
#import "AMACrashSafeTransactor.h"
#import "AMAKSCrash.h"
#import "AMAKSCrashImports.h"
#import "AMAKSCrashLoader.h"
#import "AMAUnhandledCrashDetector.h"

static dispatch_time_t AMAKSCrashLoaderTestTimeout(void)
{
    return dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC);
}

static void AMAKSCrashLoaderInitializationTestsCallback(
    __unused const AMAAppMetricaCrashErrorEnvironmentWriter *writer
)
{
}

static KSCrashMonitorType AMAKSCrashLoaderTestsFullMonitoring(void)
{
    return (
        KSCrashMonitorTypeMachException
        | KSCrashMonitorTypeSignal
        | KSCrashMonitorTypeCPPException
        | KSCrashMonitorTypeNSException
        | KSCrashMonitorTypeUserReported
        | KSCrashMonitorTypeSystem
        | KSCrashMonitorTypeApplicationState
    );
}

@interface AMAKSCrashLoader ()

- (void)installKSCrashWithMonitoring:(KSCrashMonitorType)monitoring;
- (void)initializeKSCrashBinaryImageCache;

@end

@interface AMAKSCrashLoaderDetectorSpy : NSObject

@property (nonatomic, assign) NSUInteger startCount;
@property (nonatomic, copy) dispatch_block_t startBlock;

@end

@implementation AMAKSCrashLoaderDetectorSpy

- (void)startDetecting
{
    self.startCount += 1;
    if (self.startBlock != nil) {
        self.startBlock();
    }
}

@end

@interface AMAKSCrashLoaderInstallationSpy : AMAKSCrashLoader

@property (nonatomic, assign) NSUInteger binaryImageInitializationCount;

@end

@implementation AMAKSCrashLoaderInstallationSpy

- (void)initializeKSCrashBinaryImageCache
{
    self.binaryImageInitializationCount += 1;
}

@end

@interface AMAKSCrashLoaderConcurrencySpy : AMAKSCrashLoader

@property (nonatomic, assign) NSUInteger installationCount;
@property (nonatomic, assign) KSCrashMonitorType installedMonitoring;
@property (nonatomic, assign) BOOL blockInstallation;
@property (nonatomic, assign) BOOL reentersRequiredMonitoringDuringInstallation;
@property (nonatomic, strong) dispatch_semaphore_t installationEntered;
@property (nonatomic, strong) dispatch_semaphore_t continueInstallation;
@property (nonatomic, assign) long installationWaitResult;

@end

@implementation AMAKSCrashLoaderConcurrencySpy

- (void)installKSCrashWithMonitoring:(KSCrashMonitorType)monitoring
{
    BOOL shouldBlock = NO;
    BOOL shouldReenter = NO;
    @synchronized (self) {
        self.installationCount += 1;
        self.installedMonitoring = monitoring;
        shouldBlock = self.blockInstallation;
        shouldReenter = self.reentersRequiredMonitoringDuringInstallation;
        self.reentersRequiredMonitoringDuringInstallation = NO;
    }

    if (shouldReenter) {
        [self enableRequiredMonitoring];
    }

    if (shouldBlock) {
        dispatch_semaphore_signal(self.installationEntered);
        self.installationWaitResult = dispatch_semaphore_wait(self.continueInstallation,
                                                               AMAKSCrashLoaderTestTimeout());
    }
}

- (void)initializeKSCrashBinaryImageCache
{
}

@end

@interface AMAKSCrashLoaderInitializationTests : XCTestCase

@property (nonatomic, strong) KSCrash *ksCrash;
@property (nonatomic, strong) AMAKSCrashLoaderDetectorSpy *detector;
@property (nonatomic, strong) AMAKSCrashLoaderInstallationSpy *loader;

@end

@implementation AMAKSCrashLoaderInitializationTests

- (void)setUp
{
    [super setUp];

    self.ksCrash = [KSCrash nullMock];
    [KSCrash stub:@selector(sharedInstance) andReturn:self.ksCrash];
    [AMAPlatformDescription stub:@selector(isDebuggerAttached) andReturn:theValue(NO)];
    self.detector = [AMAKSCrashLoaderDetectorSpy new];
    self.loader = [[AMAKSCrashLoaderInstallationSpy alloc]
        initWithUnhandledCrashDetector:(AMAUnhandledCrashDetector *)self.detector
        transactor:(AMACrashSafeTransactor *)[NSObject new]];
}

- (void)tearDown
{
    [KSCrash clearStubs];
    [AMAPlatformDescription clearStubs];
    self.loader = nil;
    self.detector = nil;
    self.ksCrash = nil;

    [super tearDown];
}

- (KSCrashConfiguration *)capturedConfigurationForSelector:(SEL)selector
{
    KWCaptureSpy *configurationSpy = [self.ksCrash captureArgument:@selector(installWithConfiguration:error:)
                                                            atIndex:0];
    [self.ksCrash stub:@selector(installWithConfiguration:error:) andReturn:theValue(YES)];
    if (selector == @selector(enableCrashMonitoring)) {
        [self.loader enableCrashMonitoring];
    }
    else {
        [self.loader enableRequiredMonitoring];
    }
    return configurationSpy.argument;
}

- (void)testFullInstallationUsesExactMonitoringAndConfiguration
{
    KSCrashConfiguration *configuration = [self capturedConfigurationForSelector:@selector(enableCrashMonitoring)];

    XCTAssertEqual(configuration.monitors, AMAKSCrashLoaderTestsFullMonitoring());
    XCTAssertFalse(configuration.enableMemoryIntrospection);
    XCTAssertFalse(configuration.enableQueueNameSearch);
    XCTAssertFalse(configuration.enableSwapCxaThrow);
    XCTAssertEqual(self.loader.binaryImageInitializationCount, 1u);
    XCTAssertEqual(self.detector.startCount, 0u);
    XCTAssertNil(self.loader.crashedLastLaunch);
}

- (void)testRequiredInstallationUsesExactMonitoringAndConfiguration
{
    KSCrashConfiguration *configuration = [self capturedConfigurationForSelector:@selector(enableRequiredMonitoring)];

    XCTAssertEqual(configuration.monitors, KSCrashMonitorTypeRequired);
    XCTAssertFalse(configuration.enableMemoryIntrospection);
    XCTAssertFalse(configuration.enableQueueNameSearch);
    XCTAssertFalse(configuration.enableSwapCxaThrow);
    XCTAssertEqual(self.loader.binaryImageInitializationCount, 0u);
}

- (void)testNormalCompletionDoesNotReinstallAndStartsDetectorOnce
{
    [self.ksCrash stub:@selector(installWithConfiguration:error:) andReturn:theValue(YES)];
    [self.ksCrash stub:@selector(crashedLastLaunch) andReturn:theValue(NO)];
    [[self.ksCrash should] receive:@selector(installWithConfiguration:error:) withCount:1];

    [self.loader enableCrashMonitoring];
    [self.loader enableCrashLoader];
    [self.loader enableCrashLoader];

    XCTAssertEqual(self.detector.startCount, 1u);
    XCTAssertEqualObjects(self.loader.crashedLastLaunch, @NO);
}

- (void)testReentrantNormalCompletionStartsDetectorOnce
{
    [self.ksCrash stub:@selector(installWithConfiguration:error:) andReturn:theValue(YES)];
    __weak AMAKSCrashLoaderInstallationSpy *loader = self.loader;
    self.detector.startBlock = ^{
        [loader enableCrashLoader];
    };

    [self.loader enableCrashLoader];

    XCTAssertEqual(self.detector.startCount, 1u);
}

- (void)testRepeatedRequiredInstallationAttemptsOnlyOnce
{
    [self.ksCrash stub:@selector(installWithConfiguration:error:) andReturn:theValue(YES)];
    [[self.ksCrash should] receive:@selector(installWithConfiguration:error:) withCount:1];

    [self.loader enableRequiredMonitoring];
    [self.loader enableRequiredMonitoring];
}

- (void)testFailedInstallationConsumesInstallationState
{
    [self.ksCrash stub:@selector(installWithConfiguration:error:) andReturn:theValue(NO)];
    [[self.ksCrash should] receive:@selector(installWithConfiguration:error:) withCount:1];

    [self.loader enableCrashMonitoring];
    [self.loader enableCrashMonitoring];
}

- (void)testFullInstallationIncludesCrashEnvironmentCallback
{
    self.loader.crashErrorEnvironmentCallback = AMAKSCrashLoaderInitializationTestsCallback;

    KSCrashConfiguration *configuration = [self capturedConfigurationForSelector:@selector(enableCrashMonitoring)];

    XCTAssertNotEqual(configuration.isWritingReportCallback, NULL);
}

- (void)testRequiredInstallationIncludesCrashEnvironmentCallback
{
    self.loader.crashErrorEnvironmentCallback = AMAKSCrashLoaderInitializationTestsCallback;

    KSCrashConfiguration *configuration = [self capturedConfigurationForSelector:@selector(enableRequiredMonitoring)];

    XCTAssertNotEqual(configuration.isWritingReportCallback, NULL);
}

@end

@interface AMAKSCrashLoaderConcurrencyTests : XCTestCase

@property (nonatomic, strong) AMAKSCrashLoaderConcurrencySpy *loader;

@end

@implementation AMAKSCrashLoaderConcurrencyTests

- (void)setUp
{
    [super setUp];
    self.loader = [[AMAKSCrashLoaderConcurrencySpy alloc]
        initWithUnhandledCrashDetector:(AMAUnhandledCrashDetector *)[NSObject new]
        transactor:(AMACrashSafeTransactor *)[NSObject new]];
}

- (void)tearDown
{
    self.loader = nil;
    [super tearDown];
}

- (void)testConcurrentFullCallsInstallOnce
{
    dispatch_queue_t queue = dispatch_queue_create("io.appmetrica.kscrash-full-installation-test",
                                                    DISPATCH_QUEUE_CONCURRENT);
    dispatch_apply(20, queue, ^(__unused size_t index) {
        [self.loader enableCrashMonitoring];
    });

    XCTAssertEqual(self.loader.installationCount, 1u);
    XCTAssertEqual(self.loader.installedMonitoring, AMAKSCrashLoaderTestsFullMonitoring());
}

- (void)testConcurrentRequiredCallsInstallOnce
{
    dispatch_queue_t queue = dispatch_queue_create("io.appmetrica.kscrash-required-installation-test",
                                                    DISPATCH_QUEUE_CONCURRENT);
    dispatch_apply(20, queue, ^(__unused size_t index) {
        [self.loader enableRequiredMonitoring];
    });

    XCTAssertEqual(self.loader.installationCount, 1u);
    XCTAssertEqual(self.loader.installedMonitoring, KSCrashMonitorTypeRequired);
}

- (void)testReentrantRequiredCallDoesNotReplaceFullMonitoring
{
    self.loader.reentersRequiredMonitoringDuringInstallation = YES;

    [self.loader enableCrashMonitoring];

    XCTAssertEqual(self.loader.installationCount, 1u);
    XCTAssertEqual(self.loader.installedMonitoring, AMAKSCrashLoaderTestsFullMonitoring());
}

- (void)testFullAndRequiredRaceKeepsFirstMonitoring
{
    self.loader.blockInstallation = YES;
    self.loader.installationEntered = dispatch_semaphore_create(0);
    self.loader.continueInstallation = dispatch_semaphore_create(0);
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_queue_create("io.appmetrica.kscrash-monitoring-race-test",
                                                    DISPATCH_QUEUE_CONCURRENT);
    dispatch_group_async(group, queue, ^{
        [self.loader enableCrashMonitoring];
    });
    long installationEntered = dispatch_semaphore_wait(self.loader.installationEntered,
                                                         AMAKSCrashLoaderTestTimeout());
    dispatch_semaphore_t requiredStarted = dispatch_semaphore_create(0);
    dispatch_group_async(group, queue, ^{
        dispatch_semaphore_signal(requiredStarted);
        [self.loader enableRequiredMonitoring];
    });
    long requiredStartedResult = dispatch_semaphore_wait(requiredStarted, AMAKSCrashLoaderTestTimeout());

    dispatch_semaphore_signal(self.loader.continueInstallation);
    long groupResult = dispatch_group_wait(group, AMAKSCrashLoaderTestTimeout());

    XCTAssertEqual(installationEntered, 0l);
    XCTAssertEqual(requiredStartedResult, 0l);
    XCTAssertEqual(groupResult, 0l);
    XCTAssertEqual(self.loader.installationWaitResult, 0l);
    XCTAssertEqual(self.loader.installationCount, 1u);
    XCTAssertEqual(self.loader.installedMonitoring, AMAKSCrashLoaderTestsFullMonitoring());
}

@end
