#import <XCTest/XCTest.h>
#import "AMAAppMetricaCrashes+Private.h"
#import "AMAAppMetricaCrashesConfiguration.h"
#import "AMAExternalCrashLoader.h"
#import "AMACrashEvent.h"
#import "AMACrashEventConverter.h"
#import "AMACrashProcessor.h"
#import "AMACrashReporter.h"
#import "AMACrashReportingStateNotifier.h"
#import "AMADecodedCrashSerializer.h"
#import "AMAErrorEnvironment.h"
#import "AMAExceptionFormatter.h"
#import "AMAExternalCrashLoaderMocks.h"
#import "AMAStubCrashSafeTransactor.h"
#import "AMATransactionReporter.h"
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import <AppMetricaStorageUtils/AppMetricaStorageUtils.h>

static NSString *const kAMATestAPIKey = @"550e8400-e29b-41d4-a716-446655440000";

@interface AMAAppMetricaCrashes (SynchronizationTests)
@property (nonatomic, strong) AMACrashProcessor *crashProcessor;
- (void)setupReporterWithConfiguration:(AMAModuleActivationConfiguration *)configuration;
@end

@interface AMAKSCrashLoaderStub : AMAKSCrashLoader
@property (nonatomic, copy, nullable) dispatch_block_t loadCrashReportsHandler;
- (instancetype)init;
@end

@interface AMACrashProcessorSpy : AMACrashProcessor
@property (nonatomic, assign) NSUInteger processCrashCallCount;
- (instancetype)init;
@end

@implementation AMAKSCrashLoaderStub

- (instancetype)init
{
    AMAUnhandledCrashDetector *detector = [[AMAUnhandledCrashDetector alloc]
        initWithStorage:[[AMAUserDefaultsStorage alloc] init]
        hostStateProvider:[[AMAStubHostAppStateProvider alloc] init]
        executor:[[AMACurrentQueueExecutor alloc] init]];
    AMAStubCrashSafeTransactor *transactor = [[AMAStubCrashSafeTransactor alloc]
        initWithReporter:[[AMATransactionReporter alloc] init]];
    return [super initWithUnhandledCrashDetector:detector transactor:transactor];
}

- (void)enableCrashLoader
{
}

- (void)loadCrashReports
{
    if (self.loadCrashReportsHandler != nil) {
        self.loadCrashReportsHandler();
    }
}

- (NSNumber *)crashedLastLaunch
{
    return nil;
}

@end

@implementation AMACrashProcessorSpy

- (instancetype)init
{
    AMACrashReporter *reporter = [[AMACrashReporter alloc]
        initWithApiKey:kAMATestAPIKey
        errorEnvironment:[[AMAErrorEnvironment alloc] init]];
    return [super initWithIgnoredSignals:@[]
                              serializer:[[AMADecodedCrashSerializer alloc] init]
                           crashReporter:reporter
                               formatter:[[AMAExceptionFormatter alloc] init]];
}

- (void)processCrash:(__unused AMADecodedCrash *)decodedCrash
           withError:(__unused NSError *)error
{
    self.processCrashCallCount += 1;
}

@end

@interface AMAAppMetricaCrashesSynchronizationTests : XCTestCase
@end

@implementation AMAAppMetricaCrashesSynchronizationTests

- (AMAAppMetricaCrashes *)crashesWithExecutor:(AMAManualCurrentQueueExecutor *)executor
                                ksCrashLoader:(AMAKSCrashLoader *)ksCrashLoader
                                configuration:(AMAAppMetricaCrashesConfiguration *)configuration
                          externalCrashLoader:(AMAExternalCrashLoader *)externalCrashLoader
{
    return [[AMAAppMetricaCrashes alloc]
        initWithExecutor:executor
           ksCrashLoader:ksCrashLoader
           stateNotifier:[[AMACrashReportingStateNotifier alloc] init]
       hostStateProvider:[[AMAStubHostAppStateProvider alloc] init]
              serializer:[[AMADecodedCrashSerializer alloc] init]
           configuration:configuration
     externalCrashLoader:externalCrashLoader];
}

- (AMAModuleActivationConfiguration *)activationConfiguration
{
    return [[AMAModuleActivationConfiguration alloc] initWithApiKey:kAMATestAPIKey];
}

- (void)testCrashProcessorIsReadyBeforePendingReportsAreLoaded
{
    // Reporter setup and report loading use the same executor, so processor creation must run first.
    AMAManualCurrentQueueExecutor *executor = [[AMAManualCurrentQueueExecutor alloc] init];
    AMAKSCrashLoaderStub *loader = [[AMAKSCrashLoaderStub alloc] init];
    AMAAppMetricaCrashes *crashes = [self crashesWithExecutor:executor
                                               ksCrashLoader:loader
                                               configuration:[[AMAAppMetricaCrashesConfiguration alloc] init]
                                         externalCrashLoader:nil];
    __block BOOL crashProcessorWasReady = NO;
    loader.loadCrashReportsHandler = ^{
        crashProcessorWasReady = crashes.crashProcessor != nil;
    };

    [crashes setupReporterWithConfiguration:self.activationConfiguration];
    [crashes activate];
    [executor execute];

    XCTAssertTrue(crashProcessorWasReady);
}

- (void)testExternalCrashSubmittedImmediatelyAfterActivationIsNotLost
{
    // A push report may arrive after activation returns but before the crashes executor is flushed.
    AMAManualCurrentQueueExecutor *crashExecutor = [[AMAManualCurrentQueueExecutor alloc] init];
    AMAExternalCrashLoader *externalLoader = [[AMAExternalCrashLoader alloc]
        initWithExecutor:[[AMACurrentQueueExecutor alloc] init]
              transactor:[[AMAStubCrashSafeTransactor alloc] initWithReporter:nil]
               converter:[[AMACrashEventConverter alloc] init]];
    AMAAppMetricaCrashes *crashes = [self
        crashesWithExecutor:crashExecutor
             ksCrashLoader:[[AMAKSCrashLoaderStub alloc] init]
             configuration:[[AMAAppMetricaCrashesConfiguration alloc] init]
       externalCrashLoader:externalLoader];
    AMACrashProcessorSpy *processor = [[AMACrashProcessorSpy alloc] init];
    AMAExternalLoaderMockPushProvider *provider = [[AMAExternalLoaderMockPushProvider alloc] init];
    AMAMutableCrashEvent *event = [[AMAMutableCrashEvent alloc] init];
    event.threads = @[];

    [externalLoader registerProvider:provider];
    [crashes setupReporterWithConfiguration:self.activationConfiguration];
    [crashExecutor execute:^{
        crashes.crashProcessor = processor;
    }];
    [crashes activate];
    [externalLoader crashProvider:provider
                   didDetectCrash:[event copy]];

    XCTAssertEqual(processor.processCrashCallCount, 0u);

    [crashExecutor execute];

    XCTAssertEqual(processor.processCrashCallCount, 1u);
}

@end
