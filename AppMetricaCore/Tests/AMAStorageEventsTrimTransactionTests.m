

#import <Kiwi/Kiwi.h>
#import "AMAStorageEventsTrimTransaction.h"
#import "AMAEventsCleaner.h"
#import "AMAEventsCleanupInfo.h"
#import "AMAEventSerializer.h"
#import "AMADatabaseHelper.h"
#import "AMADatabaseProtocol.h"
#import "AMADatabaseConstants.h"
#import "AMAReporterTestHelper.h"
#import "AMAReporter.h"
#import "AMAReporterStorage.h"
#import "AMAEventStorage+TestUtilities.h"
#import "AMAEvent.h"
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMAMetricaConfiguration.h"
#import "AMAMetricaInMemoryConfiguration.h"
#import "AMAMetricaConfigurationTestUtilities.h"

SPEC_BEGIN(AMAStorageEventsTrimTransactionTests)

describe(@"AMAStorageEventsTrimTransaction", ^{

    NSUInteger const priority2Type = 108;
    NSUInteger const priority1Type = 322;

    AMAReporterTestHelper *__block reporterHelper = nil;
    AMAReporter *__block reporter = nil;
    NSObject<AMADatabaseProtocol> *__block database = nil;
    AMAEventStorage *__block eventStorage = nil;

    AMAEventsCleaner *__block cleaner = nil;
    AMAStorageEventsTrimTransaction *__block transaction = nil;

    KWCaptureSpy *__block cleanupInfoSpy = nil;

    __auto_type cleanupInfo = ^AMAEventsCleanupInfo *{
        return cleanupInfoSpy.argument;
    };

    beforeEach(^{
        reporterHelper = [[AMAReporterTestHelper alloc] init];
        reporter = reporterHelper.appReporter;
        database = [reporterHelper databaseForApiKey:reporter.apiKey];
        eventStorage = reporter.reporterStorage.eventStorage;

        cleaner = [AMAEventsCleaner nullMock];
        transaction = [[AMAStorageEventsTrimTransaction alloc] initWithCleaner:cleaner
                                                                   trimPercent:0.5
                                                  importantEventTypePriorities:@{
                                                          @2: @[ @(priority2Type) ],
                                                          @1: @[ @(priority1Type) ],
                                                      }];

        cleanupInfoSpy = [cleaner captureArgument:@selector(purgeAndReportEventsForInfo:database:error:)
                                          atIndex:0];
    });

    context(@"Default initialization", ^{
        SEL const initSelector = @selector(initWithCleaner:trimPercent:importantEventTypePriorities:);
        beforeEach(^{
            [AMAMetricaConfigurationTestUtilities stubConfigurationWithNullMock];
            transaction = [AMAStorageEventsTrimTransaction alloc];
        });
        it(@"Should use cleaner", ^{
            KWCaptureSpy *spy = [transaction captureArgument:initSelector atIndex:0];
            __unused id _ = [transaction initWithCleaner:cleaner];
            [[spy.argument should] equal:cleaner];
        });
        it(@"Should have valid trim percent", ^{
            double trimPercent = 0.23;
            [[AMAMetricaConfiguration sharedInstance].inMemory stub:@selector(trimEventsPercent)
                                                          andReturn:theValue(trimPercent)];
            KWCaptureSpy *spy = [transaction captureArgument:initSelector atIndex:1];
            __unused id _ = [transaction initWithCleaner:cleaner];
            [[spy.argument should] equal:trimPercent withDelta:0.0001];
        });
        it(@"Should have valid type priorities", ^{
            KWCaptureSpy *spy = [transaction captureArgument:initSelector atIndex:2];
            __unused id _ = [transaction initWithCleaner:cleaner];
            [[spy.argument should] equal:@{
                @1: @[
                    @(AMAEventTypeCleanup)
                ],
                @2: @[
                    @(AMAEventTypeInit),
                    @(AMAEventTypeUpdate),
                    @(AMAEventTypeFirst),
                ],
            }];
        });
    });

    it(@"Should not clenup empty DB", ^{
        [[cleaner shouldNot] receive:@selector(purgeAndReportEventsForInfo:database:error:)];
        [transaction performTransactionInDatabase:database];
    });

    context(@"Single event", ^{
        AMAEvent *__block event = nil;
        beforeEach(^{
            [reporter reportEvent:@"EVENT" onFailure:NULL];
            event = [eventStorage amatest_allSavedEvents].lastObject;

            [transaction performTransactionInDatabase:database];
        });
        it(@"Should have valid oid", ^{
            [[cleanupInfo().eventOids should] equal:@[ event.oid ]];
        });
        it(@"Should report", ^{
            [[theValue(cleanupInfo().shouldReport) should] beYes];
        });
        it(@"Should have valid report", ^{
            [[cleanupInfo().cleanupReport should] equal: @{
                @"details": @{
                    @"reason": @"db_overflow",
                    @"cleared": @{
                        @"event_type": @[ @(event.type) ],
                        @"global_number": @[ @(event.globalNumber) ],
                        @"number_of_type":  @[ @(event.numberOfType) ],
                    },
                    @"actual_deleted_number": @0,
                    @"corrupted_number": @0,
                },
            }];
        });
    });

    it(@"Should cleanup valid events count", ^{
        for (NSUInteger idx = 1; idx < 6; ++idx) { // EVENT_START is added automatically after first report
            [reporter reportEvent:@"EVENT" onFailure:NULL];
        }
        NSArray<AMAEvent *> *events = [eventStorage amatest_allSavedEvents];
        NSArray *expectedOids = @[
            events[events.count - 1].oid,
            events[events.count - 2].oid,
            events[events.count - 3].oid,
        ];

        [transaction performTransactionInDatabase:database];
        [[cleanupInfo().eventOids should] equal:expectedOids];
    });

    context(@"Priority", ^{
        NSArray<AMAEvent *> *__block events = nil;
        beforeEach(^{
            for (NSNumber *type in @[ @(priority1Type), @(priority2Type), @(priority1Type), @(priority2Type) ]) {
                [reporter reportEventWithType:type.unsignedIntegerValue
                                         name:@"EVENT"
                                        value:@"VALUE"
                             eventEnvironment:@{}
                               appEnvironment:@{}
                                       extras:nil
                                    onFailure:NULL];
            }
            for (NSUInteger idx = 0; idx < 3; ++idx) {
                [reporter reportEvent:@"EVENT" onFailure:NULL];
            }

            events = [[[eventStorage amatest_allSavedEvents] reverseObjectEnumerator] allObjects];
            // Events in array:
            // 0 - EVENT_START
            // 1 - P1
            // 2 - P2
            // 3 - P1
            // 4 - P2
            // 5 - EVENT_CLIENT
            // 6 - EVENT_CLIENT
            // 7 - EVENT_CLIENT
        });

        __auto_type trimPercent = ^(double percent) {
            transaction = [[AMAStorageEventsTrimTransaction alloc] initWithCleaner:cleaner
                                                                       trimPercent:percent
                                                      importantEventTypePriorities:@{
                                                              @2: @[ @(priority2Type) ],
                                                              @1: @[ @(priority1Type) ],
                                                          }];
            [transaction performTransactionInDatabase:database];
        };

        it(@"Should clean regular events first", ^{
            trimPercent(4.0 / 8.0);
            [[cleanupInfo().eventOids should] equal:@[
                events[0].oid,
                events[5].oid,
                events[6].oid,
                events[7].oid,
            ]];
        });
        it(@"Should clean priority 1 events next", ^{
            trimPercent(6.0 / 8.0);
            [[cleanupInfo().eventOids should] equal:@[
                events[0].oid,
                events[5].oid,
                events[6].oid,
                events[7].oid,
                events[1].oid,
                events[3].oid,
            ]];
        });
        it(@"Should clean priority 2 events at last", ^{
            trimPercent(7.0 / 8.0);
            [[cleanupInfo().eventOids should] equal:@[
                events[0].oid,
                events[5].oid,
                events[6].oid,
                events[7].oid,
                events[1].oid,
                events[3].oid,
                events[2].oid,
            ]];
        });
    });

    context(@"Corrupted event with invalid encryption", ^{
        AMAEvent *__block event = nil;
        beforeEach(^{
            [reporter reportEvent:@"EVENT" onFailure:NULL];
            event = [eventStorage amatest_allSavedEvents].lastObject;

            [database inDatabase:^(AMAFMDatabase *db) {
                [AMADatabaseHelper updateFieldsWithDictionary:@{ kAMACommonTableFieldDataEncryptionType: @999 }
                                                     keyField:kAMACommonTableFieldOID
                                                          key:event.oid
                                                    tableName:kAMAEventTableName
                                                           db:db
                                                        error:NULL];
            }];

            [transaction performTransactionInDatabase:database];
        });
        it(@"Should report", ^{
            [[theValue(cleanupInfo().shouldReport) should] beYes];
        });
        it(@"Should have valid report", ^{
            [[cleanupInfo().cleanupReport should] equal: @{
                @"details": @{
                    @"reason": @"db_overflow",
                    @"cleared": @{
                        @"event_type": @[],
                        @"global_number": @[],
                        @"number_of_type":  @[],
                    },
                    @"actual_deleted_number": @0,
                    @"corrupted_number": @1,
                },
            }];
        });
        it(@"Should have valid oids", ^{
            [[cleanupInfo().eventOids should] contain:event.oid];
        });
    });

});

SPEC_END
