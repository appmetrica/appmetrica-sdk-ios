
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMAEventsCountStorageTrimmer.h"
#import "AMADatabaseProtocol.h"
#import "AMADatabaseConstants.h"
#import "AMAStorageEventsTrimTransaction.h"
#import "AMAMetricaConfigurationTestUtilities.h"
#import "AMADatabaseHelper.h"
#import "AMAReporterConfiguration.h"

SPEC_BEGIN(AMAEventsCountStorageTrimmerTests)

describe(@"AMAEventsCountStorageTrimmer", ^{

    NSString *const apiKey = @"API_KEY";
    NSObject *const db = [[NSObject alloc] init];

    NSInteger __block currentEventsCount = 0;
    NSInteger __block maxReportsInDatabaseCount = 0;

    NSObject<AMADatabaseProtocol> *__block database = nil;
    AMAStorageEventsTrimTransaction *__block transaction = nil;
    AMAEventsCountStorageTrimmer *__block trimmer = nil;

    beforeEach(^{
        [AMAMetricaConfigurationTestUtilities stubConfigurationWithNullMock];
        AMAReporterConfiguration *configuration = [AMAReporterConfiguration nullMock];
        [configuration stub:@selector(maxReportsInDatabaseCount) withBlock:^id(NSArray *params) {
            return theValue(maxReportsInDatabaseCount);
        }];
        [[AMAMetricaConfiguration sharedInstance] stub:@selector(configurationForApiKey:) andReturn:configuration];

        [AMADatabaseHelper stub:@selector(countWhereField:inArray:tableName:db:error:) withBlock:^id(NSArray *params) {
            return theValue(currentEventsCount);
        }];

        currentEventsCount = 0;
        maxReportsInDatabaseCount = 10;

        database = [KWMock nullMockForProtocol:@protocol(AMADatabaseProtocol)];
        [database stub:@selector(inDatabase:) withBlock:^id(NSArray *params) {
            void (^block)(id db) = params[0];
            if (block != nil) {
                block(db);
            }
            return nil;
        }];

        transaction = [AMAStorageEventsTrimTransaction nullMock];
        [transaction stub:@selector(performTransactionInDatabase:) withBlock:^id(NSArray *params) {
            currentEventsCount = MAX(currentEventsCount - 1, 0);
            return nil;
        }];

        trimmer = [[AMAEventsCountStorageTrimmer alloc] initWithApiKey:apiKey
                                                       trimTransaction:transaction];
    });

    it(@"Should not trim if database is null", ^{
        [[transaction shouldNot] receive:@selector(performTransactionInDatabase:)];
        [trimmer trimDatabase:nil];
    });

    it(@"Should not trim if events count equals limit", ^{
        currentEventsCount = maxReportsInDatabaseCount;
        [[transaction shouldNot] receive:@selector(performTransactionInDatabase:)];
        [trimmer trimDatabase:database];
    });

    it(@"Should trim if events count is greater than limit", ^{
        currentEventsCount = maxReportsInDatabaseCount + 1;
        [[transaction should] receive:@selector(performTransactionInDatabase:) withArguments:database];
        [trimmer trimDatabase:database];
    });

    it(@"Should trim once if count remains being greater than limit", ^{
        currentEventsCount = maxReportsInDatabaseCount + 100;
        [[transaction should] receive:@selector(performTransactionInDatabase:) withCount:1];
        [trimmer trimDatabase:database];
    });

    it(@"Should count events with valid parameters", ^{
        [[AMADatabaseHelper should] receive:@selector(countWhereField:inArray:tableName:db:error:)
                              withArguments:nil, nil, kAMAEventTableName, db, kw_any()];
        [trimmer trimDatabase:database];
    });

    it(@"Should not count events twice if count is smaller than limit", ^{
        currentEventsCount = maxReportsInDatabaseCount - 1;
        [trimmer handleEventAdding];
        [trimmer trimDatabase:database];

        [[AMADatabaseHelper shouldNot] receive:@selector(countWhereField:inArray:tableName:db:error:)];
        [trimmer handleEventAdding];
        [trimmer trimDatabase:database];
    });

    it(@"Should count events twice if count reaches the limit", ^{
        currentEventsCount = maxReportsInDatabaseCount;
        [trimmer handleEventAdding];
        [trimmer trimDatabase:database];

        [[AMADatabaseHelper should] receive:@selector(countWhereField:inArray:tableName:db:error:)];
        [trimmer handleEventAdding];
        [trimmer trimDatabase:database];
    });
    
    it(@"Should conform to AMAStorageTrimming", ^{
        [[trimmer should] conformToProtocol:@protocol(AMAStorageTrimming)];
    });
});

SPEC_END
