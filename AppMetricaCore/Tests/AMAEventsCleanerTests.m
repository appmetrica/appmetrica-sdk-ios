
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMAEventsCleaner.h"
#import "AMAStubReporterProvider.h"
#import "AMAReporter.h"
#import "AMAEventsCleanupInfo.h"
#import "AMADatabaseHelper.h"
#import "AMADatabaseProtocol.h"
#import "AMADatabaseConstants.h"

SPEC_BEGIN(AMAEventsCleanerTests)

describe(@"AMAEventsCleaner", ^{

    NSArray *const eventOids = @[ @1, @2, @3 ];
    NSDictionary *const cleanupReport = @{ @"foo": @"bar" };
    NSObject *__block db = [[NSObject alloc] init];

    NSInteger __block changes = 0;

    NSError *__block filledError = nil;
    AMAEventsCleanupInfo *__block cleanupInfo = nil;
    NSObject<AMADatabaseProtocol> *__block database = nil;
    AMAStubReporterProvider *__block reporterProvider = nil;
    AMAEventsCleaner *__block cleaner = nil;

    beforeEach(^{
        cleanupInfo = [AMAEventsCleanupInfo nullMock];
        [cleanupInfo stub:@selector(shouldReport) andReturn:theValue(YES)];
        [cleanupInfo stub:@selector(eventOids) andReturn:eventOids];
        [cleanupInfo stub:@selector(cleanupReport) andReturn:cleanupReport];

        database = [KWMock nullMockForProtocol:@protocol(AMADatabaseProtocol)];
        [database stub:@selector(inDatabase:) withBlock:^id(NSArray *params) {
            void (^block)(id) = params[0];
            block(db);
            return nil;
        }];

        changes = 0;
        [AMADatabaseHelper stub:@selector(deleteRowsWhereKey:inArray:tableName:db:error:) andReturn:theValue(YES)];
        [AMADatabaseHelper stub:@selector(changesForDB:) withBlock:^id(NSArray *params) {
            return theValue(changes);
        }];

        reporterProvider = [[AMAStubReporterProvider alloc] init];
        reporterProvider.reporter = [AMAReporter nullMock];
        cleaner = [[AMAEventsCleaner alloc] initWithReporterProvider:reporterProvider];
    });
    afterEach(^{
        [AMADatabaseHelper clearStubs];
    });

    __auto_type purge = ^BOOL {
        filledError = nil;
        return [cleaner purgeAndReportEventsForInfo:cleanupInfo database:database error:&filledError];
    };

    context(@"Normal", ^{
        it(@"Should delete rows", ^{
            [[AMADatabaseHelper should] receive:@selector(deleteRowsWhereKey:inArray:tableName:db:error:)
                                  withArguments:kAMACommonTableFieldOID, eventOids, kAMAEventTableName, db, kw_any()];
            purge();
        });
        it(@"Should set actualDeletedNumber", ^{
            changes = 23;
            [[cleanupInfo should] receive:@selector(setActualDeletedNumber:) withArguments:theValue(changes)];
            purge();
        });
        it(@"Should report", ^{
            [[reporterProvider.reporter should] receive:@selector(reportCleanupEvent:onFailure:)
                                          withArguments:cleanupReport, kw_any()];
            purge();
        });
        it(@"Should not fill error", ^{
            purge();
            [[filledError should] beNil];
        });
        it(@"Should return true", ^{
            [[theValue(purge()) should] beYes];
        });
    });

    context(@"Delete failed", ^{
        NSError *const expectedError = [NSError errorWithDomain:@"DOMAIN" code:23 userInfo:nil];
        beforeEach(^{
            [AMADatabaseHelper stub:@selector(deleteRowsWhereKey:inArray:tableName:db:error:)
                          withBlock:^id(NSArray *params) {
                [AMATestUtilities fillObjectPointerParameter:params[4] withValue:expectedError];
                return theValue(NO);
            }];
        });
        it(@"Should not set actualDeletedNumber", ^{
            changes = 42;
            [[cleanupInfo shouldNot] receive:@selector(setActualDeletedNumber:)];
            purge();
        });
        it(@"Should not report", ^{
            [[reporterProvider.reporter shouldNot] receive:@selector(reportCleanupEvent:onFailure:)];
            purge();
        });
        it(@"Should fill error", ^{
            purge();
            [[filledError should] equal:expectedError];
        });
        it(@"Should return false", ^{
            [[theValue(purge()) should] beNo];
        });
    });

    context(@"Should not report", ^{
        beforeEach(^{
            [cleanupInfo stub:@selector(shouldReport) andReturn:theValue(NO)];
        });
        it(@"Should not report", ^{
            [[reporterProvider.reporter shouldNot] receive:@selector(reportCleanupEvent:onFailure:)];
            purge();
        });
        it(@"Should not fill error", ^{
            purge();
            [[filledError should] beNil];
        });
        it(@"Should return true", ^{
            [[theValue(purge()) should] beYes];
        });
    });

});

SPEC_END
