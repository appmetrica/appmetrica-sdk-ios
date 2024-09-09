
#import <Kiwi/Kiwi.h>
#import "AMAReporterStoragesContainer.h"
#import "AMAEnvironmentContainer.h"
#import "AMAReporterStorage.h"
#import "AMAMetricaConfiguration.h"
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>

SPEC_BEGIN(AMAReporterStoragesContainerTests)

describe(@"AMAReporterStoragesContainer", ^{

    NSString *const apiKey = @"API_KEY";
    NSString *const mainApiKey = @"MAIN_API_KEY";

    AMAMetricaConfiguration *__block metricaConfiguration = nil;
    AMAEnvironmentContainer *__block eventEnvironment = nil;
    AMAReporterStorage *__block reporterStorageMock = nil;
    AMAReporterStorage *__block mainReporterStorageMock = nil;
    AMAReporterStorage *__block allocedStorage = nil;
    AMAReporterStoragesContainer *__block container = nil;

    beforeEach(^{
        metricaConfiguration = [AMAMetricaConfiguration nullMock];
        [AMAMetricaConfiguration stub:@selector(sharedInstance) andReturn:metricaConfiguration];

        eventEnvironment = [AMAEnvironmentContainer stubbedNullMockForDefaultInit];
        
        allocedStorage = [AMAReporterStorage nullMock];
        reporterStorageMock = [AMAReporterStorage nullMock];
        mainReporterStorageMock = [AMAReporterStorage nullMock];
        
        [allocedStorage stub:@selector(initWithApiKey:eventEnvironment:main:)
                   andReturn:reporterStorageMock
               withArguments:apiKey, eventEnvironment, theValue(NO)];
        [allocedStorage stub:@selector(initWithApiKey:eventEnvironment:main:)
                   andReturn:mainReporterStorageMock
               withArguments:mainApiKey, eventEnvironment, theValue(YES)];
        [AMAReporterStorage stub:@selector(alloc) andReturn:allocedStorage];
        
        container = [[AMAReporterStoragesContainer alloc] init];
    });

    it(@"Should return valid error environment", ^{
        [[container.eventEnvironment should] equal:eventEnvironment];
    });
    
    context(@"Reporter storage creation", ^{
        it(@"Should create valid reporter storage", ^{
            [[allocedStorage should] receive:@selector(initWithApiKey:eventEnvironment:main:)
                               withArguments:apiKey, eventEnvironment, theValue(NO)];
            [container storageForApiKey:apiKey];
        });
        it(@"Should return valid storage", ^{
            [[[container storageForApiKey:apiKey] should] equal:reporterStorageMock];
        });
        it(@"Should not create storage twice", ^{
            AMAReporterStorage *firstReporterStorage = [container storageForApiKey:apiKey];
            reporterStorageMock = [AMAReporterStorage stubbedNullMockForInit:@selector(initWithApiKey:eventEnvironment:main:)];
            [[[container storageForApiKey:apiKey] should] equal:firstReporterStorage];
        });
    });
    
    context(@"Main reporter storage creation", ^{
        it(@"Should create valid main reporter storage", ^{
            [[allocedStorage should] receive:@selector(initWithApiKey:eventEnvironment:main:)
                                        withArguments:mainApiKey, eventEnvironment, theValue(YES)];
            [container mainStorageForApiKey:mainApiKey];
        });
        it(@"Should return valid storage", ^{
            [[[container mainStorageForApiKey:mainApiKey] should] equal:mainReporterStorageMock];
        });
        it(@"Should not create storage twice", ^{
            AMAReporterStorage *firstReporterStorage = [container mainStorageForApiKey:mainApiKey];
            mainReporterStorageMock = [AMAReporterStorage stubbedNullMockForInit:@selector(initWithApiKey:eventEnvironment:main:)];
            [[[container mainStorageForApiKey:mainApiKey] should] equal:firstReporterStorage];
        });
        it(@"Should return main storage for main api key", ^{
            [container mainStorageForApiKey:mainApiKey];
            [mainReporterStorageMock stub:@selector(apiKey) andReturn:mainApiKey];
            [[[container storageForApiKey:mainApiKey] should] equal:mainReporterStorageMock];
        });
        it(@"Should update main storage api key if exists", ^{
            [container mainStorageForApiKey:mainApiKey];
            
            [[mainReporterStorageMock should] receive:@selector(updateAPIKey:) withArguments:apiKey];
            
            [container mainStorageForApiKey:apiKey];
        });
    });

    context(@"Migration wait", ^{
        NSTimeInterval const timeout = 0.5;
        NSTimeInterval const delta = 0.3;

        id<AMAAsyncExecuting> __block executor = nil;
        id<AMAAsyncExecuting> __block apiKeyMigrationExecutor = nil;

        beforeEach(^{
            executor = [[AMAExecutor alloc] initWithIdentifier:self];
            apiKeyMigrationExecutor = [[AMAExecutor alloc] initWithIdentifier:self];
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
    });

});

SPEC_END

