#import <XCTest/XCTest.h>
#import <objc/objc-sync.h>
#import "AMAAppMetricaCrashes+Private.h"
#import "AMAAppMetricaCrashesConfiguration.h"
#import "AMACrashReporter.h"
#import "AMADecodedCrashSerializer.h"
#import "AMAErrorEnvironment.h"
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>

@interface AMAAppMetricaCrashes (ErrorEnvironmentSynchronizationTests)
@property (nonatomic, strong) AMAErrorEnvironment *errorEnvironment;
- (void)setupMainReporterWithConfiguration:(AMAModuleActivationConfiguration *)configuration;
@end

// Pause activation after taking the old environment snapshot, before it is merged.
@interface AMASnapshotErrorEnvironment : AMAErrorEnvironment
@property (nonatomic, copy) dispatch_block_t snapshotHandler;
@end

@implementation AMASnapshotErrorEnvironment

- (NSDictionary *)currentEnvironment
{
    NSDictionary *snapshot = [super currentEnvironment];
    dispatch_block_t handler = nil;
    @synchronized (self) {
        handler = self.snapshotHandler;
        self.snapshotHandler = nil;
    }
    if (handler != nil) {
        handler();
    }
    return snapshot;
}

@end

@interface AMAErrorEnvironmentSynchronizationTests : XCTestCase
@end

@implementation AMAErrorEnvironmentSynchronizationTests

- (void)testEnvironmentUpdatesDuringActivationAreNotLost
{
    for (NSNumber *clear in @[@NO, @YES]) {
        AMAExecutor *executor = [[AMAExecutor alloc] initWithIdentifier:self];
        AMAAppMetricaCrashes *crashes = [[AMAAppMetricaCrashes alloc]
            initWithExecutor:executor
               ksCrashLoader:nil
               stateNotifier:nil
           hostStateProvider:[[AMAStubHostAppStateProvider alloc] init]
                  serializer:[[AMADecodedCrashSerializer alloc] init]
               configuration:[[AMAAppMetricaCrashesConfiguration alloc] init]
         externalCrashLoader:nil];
        AMASnapshotErrorEnvironment *environment = [[AMASnapshotErrorEnvironment alloc] init];
        [environment addValue:@"old" forKey:@"probe"];
        crashes.errorEnvironment = environment;
        NSString *apiKey = @"550e8400-e29b-41d4-a716-446655440000";
        AMACrashReporter *reporter = (AMACrashReporter *)[crashes reporterForAPIKey:apiKey];
        AMAModuleActivationConfiguration *configuration =
            [[AMAModuleActivationConfiguration alloc] initWithApiKey:apiKey];
        dispatch_semaphore_t resumeActivation = dispatch_semaphore_create(0);
        XCTestExpectation *snapshotTaken = [self expectationWithDescription:@"Snapshot taken"];
        XCTestExpectation *activationFinished = [self expectationWithDescription:@"Activation finished"];
        XCTestExpectation *updatesFinished = [self expectationWithDescription:@"Updates finished"];
        environment.snapshotHandler = ^{
            // Probe ownership on the activation thread and restore the monitor before proceeding.
            int ownership = objc_sync_exit(crashes);
            if (ownership == OBJC_SYNC_SUCCESS) {
                objc_sync_enter(crashes);
            }
            XCTAssertEqual(ownership, OBJC_SYNC_SUCCESS);
            [snapshotTaken fulfill];
            long result = dispatch_semaphore_wait(resumeActivation,
                                                  dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC));
            XCTAssertEqual(result, 0);
        };

        dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
            [crashes setupMainReporterWithConfiguration:configuration];
            [activationFinished fulfill];
        });
        [self waitForExpectations:@[snapshotTaken] timeout:5];

        if (clear.boolValue) {
            [crashes clearErrorEnvironment];
        }
        else {
            [crashes setErrorEnvironmentValue:@"new" forKey:@"probe"];
        }
        [executor execute:^{
            [updatesFinished fulfill];
        }];
        dispatch_semaphore_signal(resumeActivation);
        [self waitForExpectations:@[activationFinished, updatesFinished] timeout:5];

        NSDictionary *expected = clear.boolValue ? @{} : @{ @"probe" : @"new" };
        XCTAssertEqualObjects(reporter.errorEnvironment.currentEnvironment, expected);
        XCTAssertEqual(crashes.errorEnvironment, reporter.errorEnvironment);
    }
}

@end
