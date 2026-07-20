#import <XCTest/XCTest.h>
#import <AppMetricaCore/AppMetricaCore.h>
#import <objc/runtime.h>

#import "AMACrashReporter.h"
#import "AMATransactionReporter.h"

static id g_AMATransactionReporterTestReporter = nil;
static NSMutableArray<NSString *> *g_AMATransactionReporterTestAPIKeys = nil;

@interface AMATransactionReporterReportingSpy : NSObject
@end

@implementation AMATransactionReporterReportingSpy

- (void)reportEvent:(__unused NSString *)eventName
          parameters:(__unused NSDictionary *)parameters
           onFailure:(__unused void (^)(NSError *error))onFailure
{
}

@end

@interface AMAAppMetrica (AMATransactionReporterLazyInitializationTests)

+ (id<AMAAppMetricaReporting>)ama_test_reporterForAPIKey:(NSString *)apiKey;

@end

@implementation AMAAppMetrica (AMATransactionReporterLazyInitializationTests)

+ (id<AMAAppMetricaReporting>)ama_test_reporterForAPIKey:(NSString *)apiKey
{
    @synchronized (self) {
        [g_AMATransactionReporterTestAPIKeys addObject:apiKey];
        return (id<AMAAppMetricaReporting>)g_AMATransactionReporterTestReporter;
    }
}

@end

@interface AMATransactionReporterLazyInitializationTests : XCTestCase
@end

@implementation AMATransactionReporterLazyInitializationTests

- (void)setUp
{
    [super setUp];
    g_AMATransactionReporterTestReporter = [AMATransactionReporterReportingSpy new];
    g_AMATransactionReporterTestAPIKeys = [NSMutableArray array];
    [self exchangeReporterFactoryMethods];
}

- (void)tearDown
{
    [self exchangeReporterFactoryMethods];
    g_AMATransactionReporterTestReporter = nil;
    g_AMATransactionReporterTestAPIKeys = nil;
    [super tearDown];
}

- (void)exchangeReporterFactoryMethods
{
    Method originalMethod = class_getClassMethod([AMAAppMetrica class], @selector(reporterForAPIKey:));
    Method replacementMethod = class_getClassMethod([AMAAppMetrica class],
                                                     @selector(ama_test_reporterForAPIKey:));
    method_exchangeImplementations(originalMethod, replacementMethod);
}

- (void)reportWithReporter:(AMATransactionReporter *)reporter
{
    [reporter reportFailedTransactionWithID:@"transaction"
                                  ownerName:@"owner"
                            rollbackContent:@"content"
                          rollbackException:nil
                             rollbackFailed:NO];
}

- (void)testConfiguredInitializerDoesNotResolveCoreReporter
{
    __unused AMATransactionReporter *reporter =
        [[AMATransactionReporter alloc] initWithApiKey:@"configured-api-key"];

    XCTAssertEqual(g_AMATransactionReporterTestAPIKeys.count, 0u);
}

- (void)testDefaultInitializerDoesNotResolveCoreReporter
{
    __unused AMATransactionReporter *reporter = [AMATransactionReporter new];

    XCTAssertEqual(g_AMATransactionReporterTestAPIKeys.count, 0u);
}

- (void)testFirstReportResolvesConfiguredAPIKey
{
    AMATransactionReporter *reporter =
        [[AMATransactionReporter alloc] initWithApiKey:@"configured-api-key"];

    [self reportWithReporter:reporter];

    XCTAssertEqualObjects(g_AMATransactionReporterTestAPIKeys, (@[ @"configured-api-key" ]));
}

- (void)testDefaultReporterResolvesLibraryAPIKeyOnFirstReport
{
    AMATransactionReporter *reporter = [AMATransactionReporter new];

    [self reportWithReporter:reporter];

    XCTAssertEqualObjects(g_AMATransactionReporterTestAPIKeys, (@[ kAppMetricaLibraryAPIKey ]));
}

- (void)testMultipleReportsReuseResolvedReporter
{
    AMATransactionReporter *reporter =
        [[AMATransactionReporter alloc] initWithApiKey:@"configured-api-key"];

    [self reportWithReporter:reporter];
    [self reportWithReporter:reporter];

    XCTAssertEqual(g_AMATransactionReporterTestAPIKeys.count, 1u);
}

- (void)testConcurrentFirstUseResolvesReporterOnce
{
    AMATransactionReporter *reporter =
        [[AMATransactionReporter alloc] initWithApiKey:@"configured-api-key"];
    dispatch_queue_t queue = dispatch_queue_create("io.appmetrica.transaction-reporter-test",
                                                    DISPATCH_QUEUE_CONCURRENT);

    dispatch_apply(20, queue, ^(__unused size_t index) {
        [self reportWithReporter:reporter];
    });

    XCTAssertEqual(g_AMATransactionReporterTestAPIKeys.count, 1u);
    XCTAssertEqualObjects(g_AMATransactionReporterTestAPIKeys.firstObject, @"configured-api-key");
}

@end
