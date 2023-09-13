
#import <Kiwi/Kiwi.h>
#import "AMAReporterStoragesContainer.h"
#import "AMAEnvironmentContainer.h"
#import "AMAReporterStorage.h"
#import "AMAMetricaConfiguration.h"
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>

SPEC_BEGIN(AMAReporterStoragesContainerTests)

describe(@"AMAReporterStoragesContainer", ^{

    NSString *const apiKey = @"API_KEY";

    AMAMetricaConfiguration *__block metricaConfiguration = nil;
    AMAEnvironmentContainer *__block errorEnvironment = nil;
    AMAReporterStorage *__block reporterStorage = nil;
    AMAReporterStoragesContainer *__block container = nil;

    beforeEach(^{
        metricaConfiguration = [AMAMetricaConfiguration nullMock];
        [AMAMetricaConfiguration stub:@selector(sharedInstance) andReturn:metricaConfiguration];

        errorEnvironment = [AMAEnvironmentContainer stubbedNullMockForDefaultInit];
        reporterStorage = [AMAReporterStorage stubbedNullMockForInit:@selector(initWithApiKey:errorEnvironment:)];
        container = [[AMAReporterStoragesContainer alloc] init];
    });

    it(@"Should return valid error environment", ^{
        [[container.errorEnvironment should] equal:errorEnvironment];
    });

    context(@"Reporter storage creation", ^{
        it(@"Should create valid storage", ^{
            [[reporterStorage should] receive:@selector(initWithApiKey:errorEnvironment:)
                                withArguments:apiKey, errorEnvironment];
            [container storageForApiKey:apiKey];
        });
        it(@"Should return valid storage", ^{
            [[[container storageForApiKey:apiKey] should] equal:reporterStorage];
        });
        it(@"Should not create storage twice", ^{
            AMAReporterStorage *firstReporterStorage = [container storageForApiKey:apiKey];
            reporterStorage = [AMAReporterStorage stubbedNullMockForInit:@selector(initWithApiKey:errorEnvironment:)];
            [[[container storageForApiKey:apiKey] should] equal:firstReporterStorage];
        });
    });

    context(@"Migration wait", ^{
        NSTimeInterval const timeout = 0.5;
        NSTimeInterval const delta = 0.3;

        id<AMAExecuting> __block executor = nil;
        id<AMAExecuting> __block apiKeyMigrationExecutor = nil;

        beforeEach(^{
            executor = [[AMAAsyncExecutor alloc] initWithIdentifier:self];
            apiKeyMigrationExecutor = [[AMAAsyncExecutor alloc] initWithIdentifier:self];
        });
        afterEach(^{
            [container waitMigrationForApiKey:apiKey];
        });

        void (^stubForcedMigrationWait)(NSTimeInterval time) = ^(NSTimeInterval time) {
            [metricaConfiguration stub:@selector(ensureMigrated) withBlock:^id(NSArray *params) {
                [NSThread sleepForTimeInterval:time];
                return nil;
            }];
        };
        void (^waitForMigration)(dispatch_block_t) = ^(dispatch_block_t callback){
            [executor execute:^{
                [container waitMigrationForApiKey:apiKey];
                callback();
            }];
        };
        void (^migrateApiKeyAfter)(NSString *, NSTimeInterval) = ^(NSString *concreteApiKey, NSTimeInterval time) {
            [apiKeyMigrationExecutor execute:^{
                [NSThread sleepForTimeInterval:time];
                [container completeMigrationForApiKey:concreteApiKey];
            }];
        };

        it(@"Should not exit before migration", ^{
            stubForcedMigrationWait(timeout + delta);
            BOOL __block complete = NO;
            waitForMigration(^{ complete = YES; });
            [[expectFutureValue(theValue(complete)) shouldNotEventuallyBeforeTimingOutAfter(timeout)] beYes];
        });
        it(@"Should exit after forced migration", ^{
            stubForcedMigrationWait(timeout - delta);
            BOOL __block complete = NO;
            waitForMigration(^{ complete = YES; });
            [[expectFutureValue(theValue(complete)) shouldEventuallyBeforeTimingOutAfter(timeout)] beYes];
        });
        it(@"Should exit after same key migration", ^{
            stubForcedMigrationWait(timeout + delta);
            BOOL __block complete = NO;
            waitForMigration(^{ complete = YES; });
            migrateApiKeyAfter(apiKey, delta);
            [[expectFutureValue(theValue(complete)) shouldEventuallyBeforeTimingOutAfter(timeout)] beYes];
        });
        it(@"Should not exit after other key migration", ^{
            stubForcedMigrationWait(timeout + delta);
            BOOL __block complete = NO;
            waitForMigration(^{ complete = YES; });
            migrateApiKeyAfter(@"OTHER_API_KEY", delta);
            [[expectFutureValue(theValue(complete)) shouldNotEventuallyBeforeTimingOutAfter(timeout)] beYes];
        });
        it(@"Should assert on apiKey migration completion after global migrated", ^{
            stubForcedMigrationWait(0);
            [container waitMigrationForApiKey:apiKey];
            [[theBlock(^{
                [container completeMigrationForApiKey:apiKey];
            }) should] raise];
        });
    });

});

SPEC_END

