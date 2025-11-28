
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMASessionsCleaner.h"
#import "AMAReporter.h"
#import "AMAReporterStorage.h"
#import "AMAReporterTestHelper.h"
#import "AMAEventStorage+TestUtilities.h"
#import "AMASessionStorage+AMATestUtilities.h"
#import "AMAEvent.h"
#import "AMAEventLogger.h"
#import "AMAReportEventsBatch.h"
#import "AMASessionSerializer.h"
#import "AMAMetricaConfigurationTestUtilities.h"
#import "AMAEventsCleaner.h"
#import "AMAEventsCleanupInfo.h"
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMAReporterStoragesContainer.h"

SPEC_BEGIN(AMASessionsCleanerTests)

describe(@"AMASessionsCleaner", ^{

    NSString *const apiKey = [AMAReporterTestHelper defaultApiKey];

    AMAReporterTestHelper *__block reporterTestHelper = nil;
    AMASessionStorage *__block sessionStorage = nil;
    AMAEventStorage *__block eventStorage = nil;
    AMASession *__block lastSession = nil;
    AMASession *__block previousSession = nil;
    AMASession *__block firstSession = nil;
    AMASessionsCleaner *__block cleaner = nil;

    beforeEach(^{
        [AMAMetricaConfigurationTestUtilities stubConfigurationWithNullMock];

        reporterTestHelper = [[AMAReporterTestHelper alloc] init];

        [reporterTestHelper initReporterAndCreateThreeSessionsWithDifferentAppStates];
        [reporterTestHelper sendEvent];
        [reporterTestHelper sendEvent];

        AMAReporterStorage *reporterStorage = reporterTestHelper.appReporter.reporterStorage;
        sessionStorage = reporterStorage.sessionStorage;
        eventStorage = reporterStorage.eventStorage;
        lastSession = [sessionStorage lastSessionWithError:nil];
        previousSession = [sessionStorage previousSessionForSession:lastSession error:nil];
        firstSession = [sessionStorage previousSessionForSession:previousSession error:nil];

        cleaner = reporterStorage.sessionsCleaner;
    });
    afterEach(^{
        [AMAMetricaConfigurationTestUtilities destubConfiguration];
        [AMAReporterStoragesContainer clearStubs];
        [reporterTestHelper destub];
    });

    NSArray *(^oidsArray)(NSArray *dbObjects) = ^NSArray *(NSArray *dbObjects) {
        NSMutableArray *oids = [NSMutableArray arrayWithCapacity:dbObjects.count];
        for (AMAEvent *obj in dbObjects) {
            [oids addObject:obj.oid ?: [NSNull null]];
        }
        return [oids copy];
    };

    context(@"Purge event batches", ^{

        it(@"Should purge one event of session", ^{
            NSArray *events = [eventStorage amatest_eventsForSessionOid:lastSession.oid];
            AMAEvent *eventToPurge = events.lastObject;
            NSMutableArray *expectedEvents = [events mutableCopy];
            [expectedEvents removeLastObject];
            AMAReportEventsBatch *batch = [[AMAReportEventsBatch alloc] initWithSession:lastSession
                                                                         appEnvironment:@{}
                                                                                 events:@[ eventToPurge ]];

            [cleaner purgeSessionWithEventsBatches:@[ batch ] reason:AMAEventsCleanupReasonTypeSuccessfulReport];

            NSArray *updatedEvents = [eventStorage amatest_eventsForSessionOid:lastSession.oid];
            [[oidsArray(updatedEvents) should] equal:oidsArray([expectedEvents copy])];
        });

        it(@"Should purge one event of session if passed only last one", ^{
            NSArray *events = [eventStorage amatest_eventsForSessionOid:lastSession.oid];
            AMAEvent *eventToPurge = events.firstObject;
            NSMutableArray *expectedEvents = [events mutableCopy];
            [expectedEvents removeObjectAtIndex:0];
            AMAReportEventsBatch *batch = [[AMAReportEventsBatch alloc] initWithSession:lastSession
                                                                         appEnvironment:@{}
                                                                                 events:@[ eventToPurge ]];

            [cleaner purgeSessionWithEventsBatches:@[ batch ] reason:AMAEventsCleanupReasonTypeSuccessfulReport];

            NSArray *updatedEvents = [eventStorage amatest_eventsForSessionOid:lastSession.oid];
            [[oidsArray(updatedEvents) should] equal:oidsArray(expectedEvents)];
        });

        it(@"Should purge all events of session", ^{
            NSArray *events = [eventStorage amatest_eventsForSessionOid:lastSession.oid];
            AMAReportEventsBatch *batch = [[AMAReportEventsBatch alloc] initWithSession:lastSession
                                                                         appEnvironment:@{}
                                                                                 events:events];

            [cleaner purgeSessionWithEventsBatches:@[ batch ] reason:AMAEventsCleanupReasonTypeSuccessfulReport];

            NSArray *updatedEvents = [eventStorage amatest_eventsForSessionOid:lastSession.oid];
            [[updatedEvents should] beEmpty];
        });

        it(@"Should purge all events of multiple sessions", ^{
            NSArray *lastSessionEvents = [eventStorage amatest_eventsForSessionOid:lastSession.oid];
            NSArray *previousSessionEvents = [eventStorage amatest_eventsForSessionOid:previousSession.oid];
            AMAReportEventsBatch *lastBatch = [[AMAReportEventsBatch alloc] initWithSession:lastSession
                                                                             appEnvironment:@{}
                                                                                     events:lastSessionEvents];
            AMAReportEventsBatch *previousBatch = [[AMAReportEventsBatch alloc] initWithSession:previousSession
                                                                                 appEnvironment:@{}
                                                                                         events:previousSessionEvents];

            [cleaner purgeSessionWithEventsBatches:@[ lastBatch, previousBatch ]
                                            reason:AMAEventsCleanupReasonTypeSuccessfulReport];

            NSArray *updatedLastSessionEvents = [eventStorage amatest_eventsForSessionOid:lastSession.oid];
            NSArray *updatedPreviousSessionEvents = [eventStorage amatest_eventsForSessionOid:previousSession.oid];
            NSArray *updatedEvents = [updatedLastSessionEvents arrayByAddingObjectsFromArray:updatedPreviousSessionEvents];
            [[updatedEvents should] beEmpty];
        });

        context(@"Log", ^{
            AMAEventLogger *__block logger = nil;
            AMAEvent *__block event = nil;
            AMAReportEventsBatch *__block batch = nil;
            beforeEach(^{
                logger = [AMAEventLogger nullMock];
                [AMAEventLogger stub:@selector(sharedInstanceForApiKey:) andReturn:logger];

                NSArray *events = [eventStorage amatest_eventsForSessionOid:lastSession.oid];
                event = events.lastObject;

                batch = [[AMAReportEventsBatch alloc] initWithSession:lastSession appEnvironment:@{} events:@[ event ]];
            });
            afterEach(^{
                [AMAEventLogger clearStubs];
            });
            
            it(@"Should request valid logger", ^{
                [[AMAEventLogger should] receive:@selector(sharedInstanceForApiKey:) withArguments:apiKey];
                [cleaner purgeSessionWithEventsBatches:@[ batch ] reason:AMAEventsCleanupReasonTypeSuccessfulReport];
            });
            it(@"Should log purged events", ^{
                [[logger should] receive:@selector(logEventPurged:) withArguments:event];
                [cleaner purgeSessionWithEventsBatches:@[ batch ] reason:AMAEventsCleanupReasonTypeSuccessfulReport];
            });

            context(@"Cleanup Info", ^{
                AMAEventsCleanupInfo *__block cleanupInfo = nil;
                beforeEach(^{
                    cleanupInfo = [AMAEventsCleanupInfo stubbedNullMockForInit:@selector(initWithReasonType:)];
                });
                afterEach(^{
                    [AMAEventsCleanupInfo clearStubs];
                });

                context(@"Reason", ^{
                    it(@"Should be AMAEventsCleanupReasonTypeSuccessfulReport", ^{
                        [[cleanupInfo should] receive:@selector(initWithReasonType:)
                                        withArguments:theValue(AMAEventsCleanupReasonTypeSuccessfulReport)];
                        [cleaner purgeSessionWithEventsBatches:@[ batch ]
                                                        reason:AMAEventsCleanupReasonTypeSuccessfulReport];
                    });
                    it(@"Should be AMAEventsCleanupReasonTypeBadRequest", ^{
                        [[cleanupInfo should] receive:@selector(initWithReasonType:)
                                        withArguments:theValue(AMAEventsCleanupReasonTypeBadRequest)];
                        [cleaner purgeSessionWithEventsBatches:@[ batch ]
                                                        reason:AMAEventsCleanupReasonTypeBadRequest];
                    });
                });

                it(@"Should add event", ^{
                    [[cleanupInfo should] receive:@selector(addEvent:) withArguments:event];
                    [cleaner purgeSessionWithEventsBatches:@[ batch ]
                                                    reason:AMAEventsCleanupReasonTypeBadRequest];
                });

                it(@"Should cleanup with info", ^{
                    [[cleaner.eventsCleaner should] receive:@selector(purgeAndReportEventsForInfo:database:error:)
                                              withArguments:cleanupInfo, kw_any(), kw_any()];
                    [cleaner purgeSessionWithEventsBatches:@[ batch ]
                                                    reason:AMAEventsCleanupReasonTypeBadRequest];
                });
            });
        });
    });

    context(@"Purge empty sessions", ^{

        context(@"No empty sessions", ^{

            beforeEach(^{
                [cleaner purgeSessionWithEventsBatches:@[] reason:AMAEventsCleanupReasonTypeSuccessfulReport];
            });

            it(@"Should not purge last session", ^{
                AMASession *session = [sessionStorage amatest_sessionWithOid:lastSession.oid];
                [[session should] beNonNil];
            });

            it(@"Should not purge previous session", ^{
                AMASession *session = [sessionStorage amatest_sessionWithOid:previousSession.oid];
                [[session should] beNonNil];
            });

            it(@"Should not purge first session", ^{
                AMASession *session = [sessionStorage amatest_sessionWithOid:firstSession.oid];
                [[session should] beNonNil];
            });

        });

        context(@"Last session is empty", ^{

            beforeEach(^{
                NSArray *eventsToPurge = [eventStorage amatest_eventsForSessionOid:lastSession.oid];
                AMAReportEventsBatch *batch = [[AMAReportEventsBatch alloc] initWithSession:lastSession
                                                                             appEnvironment:@{}
                                                                                     events:eventsToPurge];
                [cleaner purgeSessionWithEventsBatches:@[ batch ] reason:AMAEventsCleanupReasonTypeSuccessfulReport];
            });

            it(@"Should not purge last session", ^{
                AMASession *session = [sessionStorage amatest_sessionWithOid:lastSession.oid];
                [[session should] beNonNil];
            });

            it(@"Should not purge previous session", ^{
                AMASession *session = [sessionStorage amatest_sessionWithOid:previousSession.oid];
                [[session should] beNonNil];
            });

            it(@"Should not purge first session", ^{
                AMASession *session = [sessionStorage amatest_sessionWithOid:firstSession.oid];
                [[session should] beNonNil];
            });

        });

        context(@"Previous session is empty", ^{

            beforeEach(^{
                NSArray *eventsToPurge = [eventStorage amatest_eventsForSessionOid:previousSession.oid];
                AMAReportEventsBatch *batch = [[AMAReportEventsBatch alloc] initWithSession:lastSession
                                                                             appEnvironment:@{}
                                                                                     events:eventsToPurge];
                [cleaner purgeSessionWithEventsBatches:@[ batch ] reason:AMAEventsCleanupReasonTypeSuccessfulReport];
            });

            it(@"Should not purge last session", ^{
                AMASession *session = [sessionStorage amatest_sessionWithOid:lastSession.oid];
                [[session should] beNonNil];
            });

            it(@"Should not purge previous session", ^{
                AMASession *session = [sessionStorage amatest_sessionWithOid:previousSession.oid];
                [[session should] beNonNil];
            });

            it(@"Should not purge first session", ^{
                AMASession *session = [sessionStorage amatest_sessionWithOid:firstSession.oid];
                [[session should] beNonNil];
            });

        });

        context(@"Last two sessions is empty", ^{

            beforeEach(^{
                NSArray *lastSessionEvents = [eventStorage amatest_eventsForSessionOid:lastSession.oid];
                NSArray *previousSessionEvents = [eventStorage amatest_eventsForSessionOid:previousSession.oid];
                AMAReportEventsBatch *lastBatch = [[AMAReportEventsBatch alloc] initWithSession:lastSession
                                                                                 appEnvironment:@{}
                                                                                         events:lastSessionEvents];
                AMAReportEventsBatch *previousBatch = [[AMAReportEventsBatch alloc] initWithSession:previousSession
                                                                                     appEnvironment:@{}
                                                                                             events:previousSessionEvents];
                [cleaner purgeSessionWithEventsBatches:@[ lastBatch, previousBatch ]
                                                reason:AMAEventsCleanupReasonTypeSuccessfulReport];
            });

            it(@"Should purge last session", ^{
                AMASession *session = [sessionStorage amatest_sessionWithOid:lastSession.oid];
                [[session should] beNonNil];
            });

            it(@"Should not purge previous session", ^{
                AMASession *session = [sessionStorage amatest_sessionWithOid:previousSession.oid];
                [[session should] beNonNil];
            });

            it(@"Should not purge first session", ^{
                AMASession *session = [sessionStorage amatest_sessionWithOid:firstSession.oid];
                [[session should] beNonNil];
            });

        });

        context(@"Every session is empty", ^{

            beforeEach(^{
                NSArray *lastSessionEvents = [eventStorage amatest_eventsForSessionOid:lastSession.oid];
                NSArray *previousSessionEvents = [eventStorage amatest_eventsForSessionOid:previousSession.oid];
                NSArray *firstSessionEvents = [eventStorage amatest_eventsForSessionOid:firstSession.oid];
                AMAReportEventsBatch *lastBatch = [[AMAReportEventsBatch alloc] initWithSession:lastSession
                                                                                 appEnvironment:@{}
                                                                                         events:lastSessionEvents];
                AMAReportEventsBatch *previousBatch = [[AMAReportEventsBatch alloc] initWithSession:previousSession
                                                                                     appEnvironment:@{}
                                                                                             events:previousSessionEvents];
                AMAReportEventsBatch *firstBatch = [[AMAReportEventsBatch alloc] initWithSession:firstSession
                                                                                  appEnvironment:@{}
                                                                                          events:firstSessionEvents];
                [cleaner purgeSessionWithEventsBatches:@[ lastBatch, previousBatch, firstBatch ]
                                                reason:AMAEventsCleanupReasonTypeSuccessfulReport];
            });

            it(@"Should not purge last session", ^{
                AMASession *session = [sessionStorage amatest_sessionWithOid:lastSession.oid];
                [[session should] beNonNil];
            });

            it(@"Should not purge previous session", ^{
                AMASession *session = [sessionStorage amatest_sessionWithOid:previousSession.oid];
                [[session should] beNonNil];
            });

            it(@"Should purge first session", ^{
                AMASession *session = [sessionStorage amatest_sessionWithOid:firstSession.oid];
                [[session should] beNil];
            });

        });

    });

});

SPEC_END
