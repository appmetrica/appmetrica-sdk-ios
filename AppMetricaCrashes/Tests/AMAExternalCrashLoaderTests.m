
#import <XCTest/XCTest.h>
#import "AMAExternalCrashLoader.h"
#import "AMACrashEvent.h"
#import "AMACrashEventConverter.h"
#import "AMAExternalCrashLoaderMocks.h"
#import "AMAStubCrashSafeTransactor.h"
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>

@interface AMAExternalCrashLoaderTests : XCTestCase

@property (nonatomic, strong) AMACurrentQueueExecutor *executor;
@property (nonatomic, strong) AMAStubCrashSafeTransactor *transactor;
@property (nonatomic, strong) AMACrashEventConverter *converter;
@property (nonatomic, strong) AMAExternalCrashLoader *loader;
@property (nonatomic, strong) AMAExternalLoaderMockDelegate *crashLoaderMockDelegate;

@end

@implementation AMAExternalCrashLoaderTests

- (void)setUp
{
    [super setUp];

    self.executor = [[AMACurrentQueueExecutor alloc] init];
    self.transactor = [[AMAStubCrashSafeTransactor alloc] initWithReporter:nil];
    self.converter = [[AMACrashEventConverter alloc] init];
    self.loader = [[AMAExternalCrashLoader alloc] initWithExecutor:self.executor
                                                        transactor:self.transactor
                                                         converter:self.converter];
    self.crashLoaderMockDelegate = [[AMAExternalLoaderMockDelegate alloc] init];
    self.loader.delegate = self.crashLoaderMockDelegate;
}

- (void)tearDown
{
    self.loader = nil;
    self.crashLoaderMockDelegate = nil;
    self.converter = nil;
    self.transactor = nil;
    self.executor = nil;

    [super tearDown];
}

- (AMACrashEvent *)sampleEvent
{
    AMAMutableCrashEvent *event = [[AMAMutableCrashEvent alloc] init];
    event.threads = @[];
    return [event copy];
}

#pragma mark - Registration

- (void)testRegisterNilProviderDoesNotCrash
{
    [self.loader registerProvider:nil];
    [self.loader loadCrashReports];
}

- (void)testRegisterPushProviderSetsSelfAsDelegate
{
    AMAExternalLoaderMockPushProvider *provider = [[AMAExternalLoaderMockPushProvider alloc] init];
    [self.loader registerProvider:provider];

    XCTAssertEqual(provider.delegate, (id<AMACrashProviderDelegate>)self.loader);
}

- (void)testDuplicateRegistrationProcessesOnce
{
    AMACrashEvent *event = [self sampleEvent];
    AMAExternalLoaderMockPullProvider *provider = [[AMAExternalLoaderMockPullProvider alloc] init];
    provider.reports = @[event];

    [self.loader registerProvider:provider];
    [self.loader registerProvider:provider];
    [self.loader loadCrashReports];

    XCTAssertEqual(self.crashLoaderMockDelegate.receivedCrashes.count, 1u);
}

#pragma mark - Pull Model

- (void)testLoadCrashReportsCallsDelegateForPendingReports
{
    AMACrashEvent *event = [self sampleEvent];
    AMAExternalLoaderMockPullProvider *provider = [[AMAExternalLoaderMockPullProvider alloc] init];
    provider.reports = @[event];
    [self.loader registerProvider:provider];

    [self.loader loadCrashReports];

    XCTAssertEqual(self.crashLoaderMockDelegate.receivedCrashes.count, 1u);
    XCTAssertEqual(self.crashLoaderMockDelegate.receivedLoaders.firstObject, self.loader);
}

- (void)testLoadCrashReportsCallsDidProcessWithEventObjects
{
    AMACrashEvent *event = [self sampleEvent];
    AMAExternalLoaderMockPullProvider *provider = [[AMAExternalLoaderMockPullProvider alloc] init];
    provider.reports = @[event];
    [self.loader registerProvider:provider];

    [self.loader loadCrashReports];

    XCTAssertEqual(provider.processedEvents.count, 1u);
    XCTAssertEqual(provider.processedEvents.firstObject, event);
}

- (void)testLoadCrashReportsSkipsEmptyPendingReports
{
    AMAExternalLoaderMockPullProvider *provider = [[AMAExternalLoaderMockPullProvider alloc] init];
    provider.reports = @[];
    [self.loader registerProvider:provider];

    [self.loader loadCrashReports];

    XCTAssertEqual(self.crashLoaderMockDelegate.receivedCrashes.count, 0u);
    XCTAssertNil(provider.processedEvents);
}

- (void)testLoadCrashReportsSkipsNilPendingReports
{
    AMAExternalLoaderMockPullProvider *provider = [[AMAExternalLoaderMockPullProvider alloc] init];
    provider.reports = nil;
    [self.loader registerProvider:provider];

    [self.loader loadCrashReports];

    XCTAssertEqual(self.crashLoaderMockDelegate.receivedCrashes.count, 0u);
}

- (void)testLoadCrashReportsProcessesMultipleProviders
{
    AMAExternalLoaderMockPullProvider *providerA = [[AMAExternalLoaderMockPullProvider alloc] init];
    providerA.reports = @[[self sampleEvent]];
    AMAExternalLoaderMockPullProvider *providerB = [[AMAExternalLoaderMockPullProvider alloc] init];
    providerB.reports = @[[self sampleEvent], [self sampleEvent]];

    [self.loader registerProvider:providerA];
    [self.loader registerProvider:providerB];
    [self.loader loadCrashReports];

    XCTAssertEqual(self.crashLoaderMockDelegate.receivedCrashes.count, 3u);
    XCTAssertEqual(providerA.processedEvents.count, 1u);
    XCTAssertEqual(providerB.processedEvents.count, 2u);
}

#pragma mark - Push Model

- (void)testPushCrashReportCallsDelegateWithCrash
{
    AMAExternalLoaderMockPushProvider *provider = [[AMAExternalLoaderMockPushProvider alloc] init];
    [self.loader registerProvider:provider];

    [self.loader crashProvider:provider didDetectCrash:[self sampleEvent]];

    XCTAssertEqual(self.crashLoaderMockDelegate.receivedCrashes.count, 1u);
    XCTAssertEqual(self.crashLoaderMockDelegate.receivedANRs.count, 0u);
}

- (void)testPushANRReportCallsDelegateWithANR
{
    AMAExternalLoaderMockPushProvider *provider = [[AMAExternalLoaderMockPushProvider alloc] init];
    [self.loader registerProvider:provider];

    [self.loader crashProvider:provider didDetectANR:[self sampleEvent]];

    XCTAssertEqual(self.crashLoaderMockDelegate.receivedANRs.count, 1u);
    XCTAssertEqual(self.crashLoaderMockDelegate.receivedCrashes.count, 0u);
}

- (void)testPushReportPassesLoaderToDelegate
{
    AMAExternalLoaderMockPushProvider *provider = [[AMAExternalLoaderMockPushProvider alloc] init];
    [self.loader registerProvider:provider];

    [self.loader crashProvider:provider didDetectCrash:[self sampleEvent]];

    XCTAssertEqual(self.crashLoaderMockDelegate.receivedLoaders.firstObject, self.loader);
}

- (void)testPushCrashCallsDidProcessCrashReports
{
    AMACrashEvent *event = [self sampleEvent];
    AMAExternalLoaderMockPushProvider *provider = [[AMAExternalLoaderMockPushProvider alloc] init];
    [self.loader registerProvider:provider];

    [self.loader crashProvider:provider didDetectCrash:event];

    XCTAssertEqual(provider.processedEvents.count, 1u);
    XCTAssertEqual(provider.processedEvents.firstObject, event);
}

- (void)testPushANRCallsDidProcessCrashReports
{
    AMACrashEvent *event = [self sampleEvent];
    AMAExternalLoaderMockPushProvider *provider = [[AMAExternalLoaderMockPushProvider alloc] init];
    [self.loader registerProvider:provider];

    [self.loader crashProvider:provider didDetectANR:event];

    XCTAssertEqual(provider.processedEvents.count, 1u);
    XCTAssertEqual(provider.processedEvents.firstObject, event);
}

#pragma mark - Weak Provider References

- (void)testDeallocatedProviderIsNotProcessed
{
    @autoreleasepool {
        AMAExternalLoaderMockPullProvider *provider = [[AMAExternalLoaderMockPullProvider alloc] init];
        provider.reports = @[[self sampleEvent]];
        [self.loader registerProvider:provider];
    }

    [self.loader loadCrashReports];

    XCTAssertEqual(self.crashLoaderMockDelegate.receivedCrashes.count, 0u);
}

@end
