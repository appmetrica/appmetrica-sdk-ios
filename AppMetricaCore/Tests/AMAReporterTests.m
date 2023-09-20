
#import <Kiwi/Kiwi.h>
#import <sys/stat.h>
#import <AppMetricaWebKit/AppMetricaWebKit.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import <AppMetricaPlatform/AppMetricaPlatform.h>
#import "AMAReporter.h"
#import "AMAReporterStorage.h"
#import "AMAReporterStateStorage.h"
#import "AMAEvent.h"
#import "AMAEventStorage+TestUtilities.h"
#import "AMAStringEventValue.h"
#import "AMABinaryEventValue.h"
#import "AMAFileEventValue.h"
#import "AMASession.h"
#import "AMASessionStorage+AMATestUtilities.h"
#import "AMADatabaseProtocol.h"
#import "AMAReachability.h"
#import "AMAMetricaConfigurationTestUtilities.h"
#import "AMAReporterConfiguration+Internal.h"
#import "AMAAppMetrica.h"
#import "AMAReporterTestHelper.h"
#import "AMALocationManager+TestUtilities.h"
#import "AMAAppStateManagerTestHelper.h"
#import "AMAReporterNotifications.h"
#import "AMADate.h"
#import "AMAFailureDispatcherTestHelper.h"
#import "AMAEventBuilder.h"
#import "AMAUserProfileModelSerializer.h"
#import "AMAUserProfile.h"
#import "AMAProfileAttribute.h"
#import "AMARevenueInfo.h"
#import "AMARevenueInfoModelSerializer.h"
#import "AMACancelableExecutingUtils.h"
#import "AMAAppMetricaImpl.h"
#import "AMAAppMetrica+TestUtilities.h"
#import "AMARevenueInfoConverter.h"
#import "AMARevenueInfoMutableModel.h"
#import "AMAAdRevenueInfo.h"
#import "AMAAdRevenueInfoProcessor.h"
#import "AMAAdRevenueInfoConverter.h"
#import "AMAAdRevenueInfoMutableModel.h"
#import "AMATruncatedDataProcessingResult.h"
#import "AMAAttributionChecker.h"
#import "AMAECommerce.h"
#import "AMAInternalEventsReporter.h"
#import "AMAECommerceSerializer.h"
#import "AMAECommerceTruncator.h"
#import "AMAAdServicesDataProvider.h"
#import "AMAPluginErrorDetails.h"
#import "AMAErrorLogger.h"
#import "AMAErrorsFactory.h"
#import "AMAStackTraceElement.h"
#import "AMAAppMetrica+Internal.h"
#import "AMAEventFirstOccurrenceController.h"
#import "AMAEventValueFactory.h"
#import "AMAExtrasContainer.h"

@interface AMAReporterStorage (Test)

@property (nonatomic, strong, readonly) id<AMADatabaseProtocol> database;

@end

SPEC_BEGIN(AMAReporterTests)

describe(@"AMAReporter", ^{

    NSTimeInterval acceptableEventOffset = [AMAReporterTestHelper acceptableEventDeltaOffset];

    NSString *apiKey = [AMAReporterTestHelper defaultApiKey];
    NSString *stringAPIKey = [AMAReporterTestHelper defaultApiKey];
    NSString *testEventName = [AMAReporterTestHelper testEventName];
    NSDictionary *parameters = [AMAReporterTestHelper testUserInfo];

    NSTimeInterval sleepInterval = 0.1;
    NSTimeInterval lowerAllowedOffset = sleepInterval;
    NSTimeInterval upperAllowedOffset = sleepInterval + acceptableEventOffset;
    NSString *expectedJSONValue = [AMAReporterTestHelper testJSONValue];
    NSTimeInterval reverseMoreThanSessionTimeoutInterval = -700;
    double floatingComparisonDelta = 1e-4;

    NSTimeInterval foregroundSessionTimeout = 10;
    NSTimeInterval backgroundSessionTimeout = 60 * 60;
    NSTimeInterval sessionDuration = 24 * 60 * 60;

    AMAReporterTestHelper *__block reporterTestHelper = nil;

    AMAJSController *__block jsController = nil;

    void (^executeWithStubbedDate)(NSDate *, dispatch_block_t) = ^(NSDate *date, void (^block)(void)) {
        NSDate *expiredDate = date;
        if (expiredDate == nil) {
            expiredDate = [[NSDate date] dateByAddingTimeInterval:reverseMoreThanSessionTimeoutInterval];
        }
        [NSDate stub:@selector(date) andReturn:expiredDate];
        block();
        [NSDate clearStubs];
    };

    AMASessionStorage *(^sessionStorage)(void) = ^{
        return reporterTestHelper.appReporter.reporterStorage.sessionStorage;
    };
    AMAEventStorage *(^eventStorage)(void) = ^{
        return reporterTestHelper.appReporter.reporterStorage.eventStorage;
    };

    beforeEach(^{
        [AMAMetricaConfigurationTestUtilities stubConfiguration];
        [AMAFailureDispatcherTestHelper stubFailureDispatcher];

        reporterTestHelper = [[AMAReporterTestHelper alloc] init];

        jsController = [AMAJSController stubbedNullMockForInit:@selector(initWithUserContentController:)];
    });
    context(@"Starts and ends foreground sessions", ^{
        it(@"Should start new session", ^{
            AMAReporter *reporter = [reporterTestHelper appReporterForApiKey:apiKey];
            [reporter resumeSession];
            AMASession *session = [reporter.reporterStorage.sessionStorage lastGeneralSessionWithError:nil];
            [[session.oid should] equal:@1];
        });
        it(@"Should add EVENT_ALIVE to previous session on start new session", ^{
            AMAReporter *reporter = [reporterTestHelper appReporterForApiKey:apiKey];
            NSDate *date = [NSDate date];
            [reporter.reporterStorage.sessionStorage newGeneralSessionCreatedAt:date error:nil];
            [reporterTestHelper finishCurrentSessionAndCreateNewOneInDistandFutureWithReporter:reporter];
            [[[reporter.reporterStorage.eventStorage amatest_savedEventWithType:AMAEventTypeAlive] should] beNonNil];
        });
        it(@"Should add EVENT_ALIVE to ended session", ^{
            NSDate *date = [NSDate date];
            [reporterTestHelper createAndFinishSessionInBackgroundWithDate:date];
            AMAEvent *alive = [eventStorage() amatest_savedEventWithType:AMAEventTypeAlive];
            AMASession *endedSession = [sessionStorage() amatest_sessionWithOid:@1];
            [[alive.sessionOid should] equal:endedSession.oid];
        });
        it(@"Should set finished to YES for ended session", ^{
            NSDate *date = [NSDate date];
            [reporterTestHelper createAndFinishSessionInBackgroundWithDate:date];
            AMASession *endedSession = [sessionStorage() amatest_sessionWithOid:@1];
            [[theValue(endedSession.isFinished) should] beYes];
        });
        it(@"Should update session stamp if ended in background", ^{
            NSDate *date = [NSDate date];
            [reporterTestHelper createAndFinishSessionInBackgroundWithDate:date];
            AMASession *updatedSession = [sessionStorage() lastGeneralSessionWithError:nil];
            [[theValue([updatedSession.pauseTime compare:date]) should] equal:theValue(NSOrderedDescending)];
        });
        it(@"Should update session stamp if ended in foreground", ^{
            NSDate *date = [NSDate date];
            [reporterTestHelper createAndFinishSessionInForegroundWithDate:date];
            AMASession *updatedSession = [sessionStorage() lastGeneralSessionWithError:nil];
            [[theValue([updatedSession.pauseTime compare:date]) should] equal:theValue(NSOrderedDescending)];
        });
        it(@"Should start new session on start after setup", ^{
            NSDate *date = [NSDate date];
            [reporterTestHelper createAndFinishSessionInBackgroundWithDate:date];
            AMAReporter *reporter = [reporterTestHelper appReporterForApiKey:apiKey];
            [reporter start];
            AMASession *newSession = [sessionStorage() amatest_sessionWithOid:@2];
            [[newSession shouldNot] beNil];
        });
    });
    context(@"Starts and ends background sessions", ^{
        it(@"Should start new session", ^{
            AMAReporter *reporter = [reporterTestHelper appReporterForApiKey:apiKey];
            [reporter reportEvent:@"Test" onFailure:nil];
            AMASession *session = [sessionStorage() lastSessionWithError:nil];
            [[session.oid should] equal:@1];
        });
        it(@"Should add EVENT_ALIVE to previous session on start new session", ^{
            AMAReporter *reporter = [reporterTestHelper appReporterForApiKey:apiKey];
            NSDate *date = [NSDate date];
            [sessionStorage() newGeneralSessionCreatedAt:date error:nil];
            [reporterTestHelper finishCurrentSessionAndCreateNewOneInDistandFutureWithReporter:reporter];
            [reporter reportEvent:@"Test" onFailure:nil];
            [[[eventStorage() amatest_savedEventWithType:AMAEventTypeAlive] should] beNonNil];
        });
        it(@"Should add EVENT_ALIVE to ended session", ^{
            NSDate *date = [NSDate date];
            [reporterTestHelper createBackgroundAndStartForegroundSessionWithDate:date];
            AMAEvent *alive = [eventStorage() amatest_savedEventWithType:AMAEventTypeAlive];
            AMASession *endedSession = [sessionStorage() amatest_sessionWithOid:@1];
            [[alive.sessionOid should] equal:endedSession.oid];
        });
        it(@"Should set finished to YES for ended session", ^{
            NSDate *date = [NSDate date];
            [reporterTestHelper createBackgroundAndStartForegroundSessionWithDate:date];
            AMASession *endedSession = [sessionStorage() amatest_sessionWithOid:@1];
            [[theValue(endedSession.isFinished) should] beYes];
        });
    });
    context(@"Saves client event to background session", ^{
        it(@"Should save client event to background session if current session is finished", ^{
            [reporterTestHelper initReporterAndSendEventWithParameters:nil];
            AMAReporter *reporter = [reporterTestHelper appReporterForApiKey:apiKey];
            [reporterTestHelper finishCurrentSessionAndCreateNewOneInDistandFutureWithReporter:reporter];
            [reporter reportEvent:@"TestEventBackground" onFailure:nil];
            AMAEvent *event = [eventStorage() amatest_savedEventWithType:AMAEventTypeClient
                                                                    name:@"TestEventBackground"];
            NSNumber *sessionOid = event.sessionOid;
            AMASession *session = [sessionStorage() amatest_sessionWithOid:sessionOid];
            [[theValue(session.type) should] equal:theValue(AMASessionTypeBackground)];
        });
        it(@"Should save client event to background session if current session is expired", ^{
            NSDate *date = [[NSDate date] dateByAddingTimeInterval:reverseMoreThanSessionTimeoutInterval];
            [NSDate stub:@selector(date) andReturn:date];
            [sessionStorage() newGeneralSessionCreatedAt:date error:nil];
            AMAReporter *reporter = [reporterTestHelper appReporterForApiKey:apiKey];
            [reporter shutdown];
            [NSDate clearStubs];
            [reporter reportEvent:testEventName onFailure:nil];
            AMAEvent *event = [eventStorage() amatest_savedEventWithType:AMAEventTypeClient];
            AMASession *eventSession = [sessionStorage() amatest_sessionWithOid:event.sessionOid];
            [[theValue(eventSession.type) should] equal:theValue(AMASessionTypeBackground)];
        });
        it(@"Should not save event to background session if current session is expired and is started manually", ^{
            NSDate *date = [[NSDate date] dateByAddingTimeInterval:reverseMoreThanSessionTimeoutInterval];
            [NSDate stub:@selector(date) andReturn:date];
            AMAReporter *reporter = [reporterTestHelper appReporterForApiKey:apiKey];
            [reporter resumeSession];
            [NSDate clearStubs];
            [reporter reportEvent:testEventName onFailure:nil];
            AMAEvent *event = [eventStorage() amatest_savedEventWithType:AMAEventTypeClient];
            AMASession *eventSession = [sessionStorage() amatest_sessionWithOid:event.sessionOid];
            [[theValue(eventSession.type) should] equal:theValue(AMASessionTypeGeneral)];
        });
        it(@"Should save event to background session if started manually and then ended manually", ^{
            AMAReporter *reporter = [reporterTestHelper appReporterForApiKey:apiKey];
            [reporter resumeSession];
            [reporterTestHelper finishCurrentSessionAndCreateNewOneInDistandFutureWithReporter:reporter];
            [reporter reportEvent:testEventName onFailure:nil];
            AMAEvent *event = [eventStorage() amatest_savedEventWithType:AMAEventTypeClient];
            AMASession *eventSession = [sessionStorage() amatest_sessionWithOid:event.sessionOid];
            [[theValue(eventSession.type) should] equal:theValue(AMASessionTypeBackground)];
        });
    });
    context(@"Pause and resume session", ^{
        AMAReporter *__block reporter = nil;
        beforeEach(^{
            reporter = [reporterTestHelper appReporterForApiKey:apiKey];
        });
        context(@"After first resume", ^{
            NSDate *__block startDate = nil;
            AMASession *__block foregroundSession = nil;
            beforeEach(^{
                startDate = [NSDate date];
                [NSDate stub:@selector(date) andReturn:startDate];
                [reporter resumeSession];
                foregroundSession = [sessionStorage() lastGeneralSessionWithError:nil];
            });
            it(@"Should start foreground session", ^{
                [[foregroundSession should] beNonNil];
            });
            context(@"After pause", ^{
                NSUInteger pauseOffsetSeconds = 23;
                NSUInteger sessionTimeout = kAMASessionValidIntervalInSecondsDefault;
                NSUInteger timeDelta = 2;
                NSDate *__block pauseDate = nil;
                beforeEach(^{
                    pauseDate = [startDate dateByAddingTimeInterval:pauseOffsetSeconds];
                    [NSDate stub:@selector(date) andReturn:pauseDate];
                    [reporter pauseSession];
                });
                context(@"Before timeout", ^{
                    NSDate *__block beforeTimeoutDate = nil;
                    beforeEach(^{
                        beforeTimeoutDate = [pauseDate dateByAddingTimeInterval:sessionTimeout - timeDelta];
                        [NSDate stub:@selector(date) andReturn:beforeTimeoutDate];
                    });
                    context(@"Report event", ^{
                        beforeEach(^{
                            [reporter reportEvent:@"Test" onFailure:nil];
                        });
                        it(@"Should add event in foreground session", ^{
                            AMAEvent *event = [eventStorage() amatest_savedEventWithType:AMAEventTypeClient];
                            [[event.sessionOid should] equal:foregroundSession.oid];
                        });
                        context(@"After timeout", ^{
                            NSDate *__block timeoutDate = nil;
                            beforeEach(^{
                                timeoutDate = [pauseDate dateByAddingTimeInterval:sessionTimeout + timeDelta];
                                [NSDate stub:@selector(date) andReturn:timeoutDate];
                            });
                            it(@"Should use last event time offset for next EVENT_ALIVE", ^{
                                [reporter resumeSession];

                                AMAEvent *event = [eventStorage() amatest_savedEventWithType:AMAEventTypeAlive];
                                NSTimeInterval expectedTimeOffset = [beforeTimeoutDate timeIntervalSinceDate:startDate];
                                [[theValue(event.timeSinceSession) should] equal:expectedTimeOffset
                                                                       withDelta:floatingComparisonDelta];
                            });
                        });
                    });
                    context(@"Resume session", ^{
                        beforeEach(^{
                            [reporter resumeSession];
                        });
                        it(@"Should not create new session", ^{
                            AMASession *session = [sessionStorage() lastGeneralSessionWithError:nil];
                            [[session.oid should] equal:foregroundSession.oid];
                        });
                    });
                    context(@"After second pause", ^{
                        NSDate *__block newPauseDate = nil;
                        beforeEach(^{
                            newPauseDate = beforeTimeoutDate;
                            [reporter pauseSession];
                        });
                        context(@"Before new timeout", ^{
                            NSDate *__block newBeforeTimeoutDate = nil;
                            beforeEach(^{
                                newBeforeTimeoutDate = [newPauseDate dateByAddingTimeInterval:sessionTimeout - timeDelta];
                                [NSDate stub:@selector(date) andReturn:newBeforeTimeoutDate];
                            });
                            it(@"Should not create new sessin on resume", ^{
                                [reporter resumeSession];
                                AMASession *session = [sessionStorage() lastGeneralSessionWithError:nil];
                                [[session.oid should] equal:foregroundSession.oid];
                            });
                        });
                        context(@"After new timeout", ^{
                            NSDate *__block newAfterTimeoutDate = nil;
                            beforeEach(^{
                                newAfterTimeoutDate = [newPauseDate dateByAddingTimeInterval:sessionTimeout + timeDelta];
                                [NSDate stub:@selector(date) andReturn:newAfterTimeoutDate];
                            });
                            context(@"Resume session", ^{
                                beforeEach(^{
                                    [reporter resumeSession];
                                });
                                it(@"Should create new sessin on resume", ^{
                                    AMASession *session = [sessionStorage() lastGeneralSessionWithError:nil];
                                    [[session.oid shouldNot] equal:foregroundSession.oid];
                                });
                                it(@"Should add EVENT_ALIVE in previous session", ^{
                                    AMAEvent *event = [eventStorage() amatest_savedEventWithType:AMAEventTypeAlive];
                                    [[event.sessionOid should] equal:foregroundSession.oid];
                                });
                                it(@"Should add EVENT_ALIVE with last pause time offset", ^{
                                    AMAEvent *event = [eventStorage() amatest_savedEventWithType:AMAEventTypeAlive];
                                    NSTimeInterval expectedTimeOffset = [newPauseDate timeIntervalSinceDate:startDate];
                                    [[theValue(event.timeSinceSession) should] equal:expectedTimeOffset
                                                                           withDelta:floatingComparisonDelta];
                                });
                            });
                        });
                    });
                });
                context(@"After timeout", ^{
                    NSDate *__block afterTimeoutDate = nil;
                    beforeEach(^{
                        afterTimeoutDate = [pauseDate dateByAddingTimeInterval:sessionTimeout + timeDelta];
                        [NSDate stub:@selector(date) andReturn:afterTimeoutDate];
                    });
                    context(@"Report event", ^{
                        beforeEach(^{
                            [reporter reportEvent:@"Test" onFailure:nil];
                        });
                        it(@"Should add event in new session", ^{
                            AMAEvent *event = [eventStorage() amatest_savedEventWithType:AMAEventTypeClient];

                            [[event.sessionOid shouldNot] equal:foregroundSession.oid];
                        });
                        it(@"New session should be a background one", ^{
                            AMASession *session = [sessionStorage() lastSessionWithError:nil];
                            [[theValue(session.type) should] equal:theValue(AMASessionTypeBackground)];
                        });
                        it(@"Should add EVENT_ALIVE in previous session", ^{
                            AMAEvent *event = [eventStorage() amatest_savedEventWithType:AMAEventTypeAlive];
                            [[event.sessionOid should] equal:foregroundSession.oid];
                        });
                        it(@"Should add EVENT_ALIVE with actual time offset", ^{
                            AMAEvent *event = [eventStorage() amatest_savedEventWithType:AMAEventTypeAlive];
                            NSTimeInterval expectedTimeOffset = [pauseDate timeIntervalSinceDate:startDate];
                            [[theValue(event.timeSinceSession) should] equal:expectedTimeOffset
                                                                   withDelta:floatingComparisonDelta];
                        });
                        context(@"Report second event", ^{
                            NSUInteger secondEventTimeDelta = 4;
                            NSDate *__block secondEventDate = nil;
                            beforeEach(^{
                                secondEventDate = [afterTimeoutDate dateByAddingTimeInterval:secondEventTimeDelta];
                                [NSDate stub:@selector(date) andReturn:secondEventDate];
                                [reporter reportEvent:@"Test" onFailure:nil];
                            });
                            it(@"Should add event in current background session", ^{
                                AMAEvent *event = [eventStorage() amatest_savedEventWithType:AMAEventTypeClient];

                                [[event.sessionOid shouldNot] equal:foregroundSession.oid];
                            });
                            context(@"After resume", ^{
                                AMASession *__block backgroundSession = nil;
                                beforeEach(^{
                                    backgroundSession = [sessionStorage() lastSessionWithError:nil];
                                    [reporter resumeSession];
                                });
                                it(@"Should add EVENT_ALIVE in background session", ^{
                                    AMAEvent *event = [eventStorage() amatest_savedEventWithType:AMAEventTypeAlive];
                                    [[event.sessionOid should] equal:backgroundSession.oid];
                                });
                                it(@"Should add EVENT_ALIVE with actual time offset", ^{
                                    AMAEvent *event = [eventStorage() amatest_savedEventWithType:AMAEventTypeAlive];
                                    NSTimeInterval expectedTimeOffset = [secondEventDate timeIntervalSinceDate:afterTimeoutDate];
                                    [[theValue(event.timeSinceSession) should] equal:expectedTimeOffset
                                                                           withDelta:floatingComparisonDelta];
                                });
                            });
                        });
                        context(@"Resume session", ^{
                            AMASession *__block backgroundSession = nil;
                            beforeEach(^{
                                backgroundSession = [sessionStorage() lastSessionWithError:nil];
                                [reporter resumeSession];
                            });
                            it(@"Should add EVENT_ALIVE in background session", ^{
                                AMAEvent *event = [eventStorage() amatest_savedEventWithType:AMAEventTypeAlive];
                                [[event.sessionOid should] equal:backgroundSession.oid];
                            });
                            it(@"Should add EVENT_ALIVE with zero time offset", ^{
                                AMAEvent *event = [eventStorage() amatest_savedEventWithType:AMAEventTypeAlive];
                                [[theValue(event.timeSinceSession) should] equal:0
                                                                       withDelta:floatingComparisonDelta];
                            });
                        });
                    });
                    context(@"Resume session", ^{
                        beforeEach(^{
                            [reporter resumeSession];
                        });
                        it(@"Should create new foreground session", ^{
                            AMASession *session = [sessionStorage() lastGeneralSessionWithError:nil];
                            [[session.oid shouldNot] equal:foregroundSession];
                        });
                        it(@"Should add EVENT_ALIVE in previous session", ^{
                            AMAEvent *event = [eventStorage() amatest_savedEventWithType:AMAEventTypeAlive];
                            [[event.sessionOid should] equal:foregroundSession.oid];
                        });
                        it(@"Should add EVENT_ALIVE with actual time offset", ^{
                            AMAEvent *event = [eventStorage() amatest_savedEventWithType:AMAEventTypeAlive];
                            NSTimeInterval expectedTimeOffset = [pauseDate timeIntervalSinceDate:startDate];
                            [[theValue(event.timeSinceSession) should] equal:expectedTimeOffset
                                                                   withDelta:floatingComparisonDelta];
                        });
                    });
                    context(@"After second pause", ^{
                        NSDate *__block newPauseDate = nil;
                        beforeEach(^{
                            newPauseDate = afterTimeoutDate;
                            [reporter pauseSession];
                        });
                        it(@"Should not create new session", ^{
                            AMASession *session = [sessionStorage() lastSessionWithError:nil];
                            [[session.oid should] equal:foregroundSession.oid];
                        });
                        context(@"Report event", ^{
                            beforeEach(^{
                                [reporter reportEvent:@"Test" onFailure:nil];
                            });
                            it(@"Should add event in new session", ^{
                                AMAEvent *event = [eventStorage() amatest_savedEventWithType:AMAEventTypeClient];

                                [[event.sessionOid shouldNot] equal:foregroundSession.oid];
                            });
                            it(@"New session should be a background one", ^{
                                AMASession *session = [sessionStorage() lastSessionWithError:nil];
                                [[theValue(session.type) should] equal:theValue(AMASessionTypeBackground)];
                            });
                            it(@"Should add EVENT_ALIVE in previous session", ^{
                                AMAEvent *event = [eventStorage() amatest_savedEventWithType:AMAEventTypeAlive];
                                [[event.sessionOid should] equal:foregroundSession.oid];
                            });
                            it(@"Should add EVENT_ALIVE with first pause time offset", ^{
                                AMAEvent *event = [eventStorage() amatest_savedEventWithType:AMAEventTypeAlive];
                                NSTimeInterval expectedTimeOffset = [pauseDate timeIntervalSinceDate:startDate];
                                [[theValue(event.timeSinceSession) should] equal:expectedTimeOffset
                                                                       withDelta:floatingComparisonDelta];
                            });
                        });
                        context(@"Resume session", ^{
                            beforeEach(^{
                                [reporter resumeSession];
                            });
                            it(@"Should create new foreground session", ^{
                                AMASession *session = [sessionStorage() lastGeneralSessionWithError:nil];
                                [[session.oid shouldNot] equal:foregroundSession];
                            });
                            it(@"Should add EVENT_ALIVE in previous session", ^{
                                AMAEvent *event = [eventStorage() amatest_savedEventWithType:AMAEventTypeAlive];
                                [[event.sessionOid should] equal:foregroundSession.oid];
                            });
                            it(@"Should add EVENT_ALIVE with actual time offset", ^{
                                AMAEvent *event = [eventStorage() amatest_savedEventWithType:AMAEventTypeAlive];
                                NSTimeInterval expectedTimeOffset = [pauseDate timeIntervalSinceDate:startDate];
                                [[theValue(event.timeSinceSession) should] equal:expectedTimeOffset
                                                                       withDelta:floatingComparisonDelta];
                            });
                        });
                    });
                });
            });
        });
    });
    context(@"Is inactive initially", ^{
        it(@"Should add event to general background if not started", ^{
            AMAReporter *reporter = [reporterTestHelper appReporterForApiKey:apiKey];
            [reporter setupWithOnStorageRestored:nil onSetupComplete:nil];
            [reporter reportEvent:testEventName onFailure:nil];
            AMAEvent *event = [eventStorage() amatest_savedEventWithType:AMAEventTypeClient];
            AMASession *eventSession = [sessionStorage() amatest_sessionWithOid:event.sessionOid];
            [[theValue(eventSession.type) should] equal:theValue(AMASessionTypeBackground)];
        });
        it(@"Should not create session on app launch before app becomes active", ^{
            AMAReporter *reporter = [reporterTestHelper appReporterForApiKey:apiKey];
            [reporter setupWithOnStorageRestored:nil onSetupComplete:nil];
            AMASession *session = [sessionStorage() amatest_sessionWithOid:@1];
            [[session should] beNil];
        });
    });
    context(@"Saves client event", ^{
        it(@"Should create session", ^{
            [reporterTestHelper initReporterAndSendEventWithParameters:nil];
            AMASession *session = [sessionStorage() amatest_sessionWithOid:@1];
            [[session shouldNot] beNil];
        });
        it(@"Should create the only session", ^{
            [reporterTestHelper initReporterAndSendEventWithParameters:nil];
            AMASession *session = [sessionStorage() amatest_sessionWithOid:@2];
            [[session should] beNil];
        });
        it(@"Should notify when event is added", ^{
            [[[NSNotificationCenter defaultCenter] should] receive:@selector(postNotificationName:object:userInfo:)
                                                         withCount:3];
            [reporterTestHelper initReporterAndSendEventWithParameters:nil];
        });
        it(@"Should send correct notification name", ^{
            BOOL __block didReceive = NO;
            NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
            id __block observer = [center addObserverForName:@"AMAReporterDidAddEventNotification"
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      didReceive = YES;
                                                      [[NSNotificationCenter defaultCenter] removeObserver:observer];
                                                  }];
            [reporterTestHelper initReporterAndSendEventWithParameters:nil];
            [[theValue(didReceive) shouldEventually] beYes];
        });
        it(@"Should send correct notification userInfo", ^{
            NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
            id __block observer = [center addObserverForName:@"AMAReporterDidAddEventNotification"
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      [[NSNotificationCenter defaultCenter] removeObserver:observer];
                                                      [[note.userInfo[kAMAReporterDidAddEventNotificationUserInfoKeyApiKey] should] equal:stringAPIKey];
                                                  }];
            [reporterTestHelper initReporterAndSendEventWithParameters:nil];
        });
    });
    context(@"Creates correct event sequence for first session", ^{
        context(@"EVENT_INIT", ^{
            it(@"Should create", ^{
                [reporterTestHelper initReporterAndSendEventWithParameters:nil];
                AMAEvent *event = [eventStorage() amatest_savedEventWithType:AMAEventTypeInit];
                [[event shouldNot] beNil];
            });
            it(@"Should refer to correct session", ^{
                [reporterTestHelper initReporterAndSendEventWithParameters:nil];
                AMAEvent *event = [eventStorage() amatest_savedEventWithType:AMAEventTypeInit];
                [[[event sessionOid] should] equal:@1];
            });
            it(@"Should have correct sequence number", ^{
                [reporterTestHelper initReporterAndSendEventWithParameters:nil];
                AMAEvent *event = [eventStorage() amatest_savedEventWithType:AMAEventTypeInit];
                [[theValue([event sequenceNumber]) should] equal:theValue(1)];
            });
            it(@"Should have correct event time offset", ^{
                [reporterTestHelper initReporterAndSendEventWithParameters:nil];
                AMAEvent *event = [eventStorage() amatest_savedEventWithType:AMAEventTypeInit];
                [[theValue(event.timeSinceSession) should] beLessThan:theValue(DBL_EPSILON)];
            });
            it(@"Should not send on first event report if not started", ^{
                AMAReporter *reporter = [reporterTestHelper appReporterForApiKey:apiKey];
                [reporter reportEvent:testEventName onFailure:nil];
                NSArray *eventsInit = [eventStorage() amatest_allSavedEventsWithType:AMAEventTypeInit name:nil];
                [[eventsInit should] haveCountOfAtMost:0];
            });
            it(@"Should send to background session on first event report if started", ^{
                AMAReporter *reporter = [reporterTestHelper appReporterForApiKey:apiKey];
                [reporter start];
                [reporter reportEvent:testEventName onFailure:nil];
                AMAEvent *eventInit = [eventStorage() amatest_savedEventWithType:AMAEventTypeInit];
                [[eventInit shouldNot] beNil];
            });
            it(@"Should not create more than one", ^{
                AMAReporter *reporter = [reporterTestHelper appReporterForApiKey:apiKey];
                [reporter resumeSession];
                [reporter reportEvent:testEventName onFailure:nil];
                NSArray *eventsInit = [eventStorage() amatest_allSavedEventsWithType:AMAEventTypeInit name:nil];
                [[eventsInit should] haveCountOf:1];
            });
            it(@"Should create for each API key", ^{
                AMAReporter *reporter = [reporterTestHelper appReporterForApiKey:apiKey];
                [reporter resumeSession];
                [reporter reportEvent:testEventName onFailure:nil];
                AMAReporter *secondReporter =
                    [reporterTestHelper appReporterForApiKey:[AMAReporterTestHelper octopusApiKey]];
                [secondReporter resumeSession];
                [secondReporter reportEvent:testEventName onFailure:nil];
                NSArray *eventsInit =
                    [secondReporter.reporterStorage.eventStorage amatest_allSavedEventsWithType:AMAEventTypeInit
                                                                                           name:nil];
                [[eventsInit should] haveCountOf:1];
            });
        });
        context(@"EVENT_START", ^{
            AMAEventType const eventType = AMAEventTypeStart;
            context(@"Application in foreground", ^{
                it(@"Should create", ^{
                    [reporterTestHelper initReporterAndSendEventWithParameters:nil];
                    AMAEvent *event = [eventStorage() amatest_savedEventWithType:eventType];
                    [[event shouldNot] beNil];
                });
                it(@"Should refer to session with correct number", ^{
                    [reporterTestHelper initReporterAndSendEventWithParameters:nil];
                    AMAEvent *event = [eventStorage() amatest_savedEventWithType:eventType];
                    [[[event sessionOid] should] equal:@1];
                });
                it(@"Should refer to session with correct type", ^{
                    [reporterTestHelper initReporterAndSendEventWithParameters:nil];
                    AMAEvent *event = [eventStorage() amatest_savedEventWithType:eventType];
                    AMASession *session = [sessionStorage() amatest_sessionWithOid:event.sessionOid];
                    [[theValue(session.type) should] equal:theValue(AMASessionTypeGeneral)];
                });
                it(@"Should have correct sequence number", ^{
                    [reporterTestHelper initReporterAndSendEventWithParameters:nil];
                    AMAEvent *event = [eventStorage() amatest_savedEventWithType:eventType];
                    [[theValue([event sequenceNumber]) should] equal:theValue(0)];
                });
                it(@"Should have correct event time offset", ^{
                    [reporterTestHelper initReporterAndSendEventWithParameters:nil];
                    AMAEvent *event = [eventStorage() amatest_savedEventWithType:eventType];
                    [[theValue(event.timeSinceSession) should] beLessThan:theValue(DBL_EPSILON)];
                });
                it(@"Should create on next application start", ^{
                    [reporterTestHelper initReporterTwice];
                    AMAEvent *eventStart = [eventStorage() amatest_savedEventWithType:eventType];
                    [[eventStart.sessionOid should] equal:@2];
                });
            });
            context(@"Application in background", ^{
                it(@"Should create", ^{
                    [reporterTestHelper sendEvent];
                    AMAEvent *event = [eventStorage() amatest_savedEventWithType:eventType];
                    [[event shouldNot] beNil];
                });
                it(@"Should refer to session with correct number", ^{
                    [reporterTestHelper sendEvent];
                    AMAEvent *event = [eventStorage() amatest_savedEventWithType:eventType];
                    [[[event sessionOid] should] equal:@1];
                });
                it(@"Should refer to session with correct type", ^{
                    [reporterTestHelper sendEvent];
                    AMAEvent *event = [eventStorage() amatest_savedEventWithType:eventType];
                    AMASession *session = [sessionStorage() amatest_sessionWithOid:event.sessionOid];
                    [[theValue(session.type) should] equal:theValue(AMASessionTypeBackground)];
                });
                it(@"Should have correct sequence number", ^{
                    [reporterTestHelper sendEvent];
                    AMAEvent *event = [eventStorage() amatest_savedEventWithType:eventType];
                    [[theValue([event sequenceNumber]) should] equal:theValue(0)];
                });
                it(@"Should have correct event time offset", ^{
                    [reporterTestHelper sendEvent];
                    AMAEvent *event = [eventStorage() amatest_savedEventWithType:eventType];
                    [[theValue(event.timeSinceSession) should] beLessThan:theValue(DBL_EPSILON)];
                });
            });
        });
        context(@"EVENT_CLIENT", ^{
            AMAEventType const eventType = AMAEventTypeClient;
            it(@"Should create", ^{
                [reporterTestHelper initReporterAndSendEventWithParameters:nil];
                AMAEvent *event = [eventStorage() amatest_savedEventWithType:eventType];
                [[event shouldNot] beNil];
            });
            it(@"Should refer to correct session", ^{
                [reporterTestHelper initReporterAndSendEventWithParameters:nil];
                AMAEvent *event = [eventStorage() amatest_savedEventWithType:eventType];
                [[[event sessionOid] should] equal:@1];
            });
            it(@"Should refer to background session if session not started", ^{
                [reporterTestHelper initReporterAndSendEventWithoutStartingSessionWithParameters:nil];
                AMAEvent *event = [eventStorage() amatest_savedEventWithType:eventType];
                NSNumber *oid = event.sessionOid;
                AMASession *backgroundSession = [sessionStorage() amatest_backgroundSession];
                [[backgroundSession.oid should] equal:oid];
            });
            it(@"Should refer to background session oid if current session is expired", ^{
                [reporterTestHelper createForegroundSessionWithDate:[NSDate distantPast]];
                AMAReporter *reporter = [reporterTestHelper appReporterForApiKey:apiKey];
                [reporter reportEvent:testEventName onFailure:nil];
                AMAEvent *event = [eventStorage() amatest_savedEventWithType:eventType];
                NSNumber *oid = event.sessionOid;
                [[oid should] equal:@2];
            });
            it(@"Should refer to background session type if current session is expired", ^{
                [reporterTestHelper initReporterAndSendEventToExpiredSessionWithParameters:nil];
                AMAEvent *event = [eventStorage() amatest_savedEventWithType:eventType];
                AMASession *session = [sessionStorage() amatest_sessionWithOid:event.sessionOid];
                [[theValue(session.type) should] equal:theValue(AMASessionTypeBackground)];
            });
            it(@"Should have correct sequence number", ^{
                [reporterTestHelper initReporterAndSendEventWithParameters:nil];
                AMAEvent *event = [eventStorage() amatest_savedEventWithType:eventType];
                [[theValue([event sequenceNumber]) should] equal:theValue(2)];
            });
            it(@"Should have correct event time offset", ^{
                [reporterTestHelper initReporterAndSendEventWithParameters:nil async:YES];
                [NSThread sleepForTimeInterval:0.5];
                AMAEvent *event = [eventStorage() amatest_savedEventWithType:eventType];
                [[theValue(event.timeSinceSession) should] beLessThan:theValue(acceptableEventOffset)];
            });
        });
        context(@"Adds only one EVENT_ALIVE to finished session", ^{
            void (^assertOnlyOneEventAlive)(void) = ^{
                NSMutableArray *eventsAlive = [NSMutableArray array];
                NSArray *events = [eventStorage() amatest_eventsForSessionOid:@1];
                for (AMAEvent *event in events) {
                    if (event.type == AMAEventTypeAlive) {
                        [eventsAlive addObject:event];
                    }
                }
                [[eventsAlive should] haveCountOf:1];
            };
            it(@"Should add only one EVENT_ALIVE to finished session after app launch", ^{
                [reporterTestHelper initReporterTwice];
                assertOnlyOneEventAlive();
            });
            it(@"Should add only one EVENT_ALIVE to finished and expired session after app launch", ^{
                AMAReporter *reporter = [reporterTestHelper appReporterForApiKey:apiKey];
                executeWithStubbedDate(nil, ^{
                    [reporterTestHelper initReporterAndSendEventWithParameters:nil];
                });
                [reporter setupWithOnStorageRestored:nil onSetupComplete:nil];
                [reporter start];
                assertOnlyOneEventAlive();
            });
        });
    });
    context(@"First activation is an update", ^{
        beforeEach(^{
            AMAMetricaInMemoryConfiguration *config = [AMAMetricaConfiguration sharedInstance].inMemory;
            [config stub:@selector(handleFirstActivationAsUpdate) andReturn:theValue(YES)];
        });
        it(@"Should create EVENT_UPDATE", ^{
            [reporterTestHelper initReporterAndSendEventWithParameters:nil];
            AMAEvent *event = [eventStorage() amatest_savedEventWithType:AMAEventTypeUpdate];
            [[event shouldNot] beNil];
        });
        it(@"EVENT_UPDATE should refer to correct session", ^{
            [reporterTestHelper initReporterAndSendEventWithParameters:nil];
            AMAEvent *event = [eventStorage() amatest_savedEventWithType:AMAEventTypeUpdate];
            [[[event sessionOid] should] equal:@1];
        });
        it(@"EVENT_UPDATE should have correct sequence number", ^{
            [reporterTestHelper initReporterAndSendEventWithParameters:nil];
            AMAEvent *event = [eventStorage() amatest_savedEventWithType:AMAEventTypeUpdate];
            [[theValue([event sequenceNumber]) should] equal:theValue(1)];
        });
        it(@"EVENT_UPDATE should have correct event time offset", ^{
            [reporterTestHelper initReporterAndSendEventWithParameters:nil];
            AMAEvent *event = [eventStorage() amatest_savedEventWithType:AMAEventTypeUpdate];
            [[theValue(event.timeSinceSession) should] beLessThan:theValue(DBL_EPSILON)];
        });
        it(@"Should not send EVENT_UPDATE on first event report if not started", ^{
            AMAReporter *reporter = [reporterTestHelper appReporterForApiKey:apiKey];
            [reporter reportEvent:testEventName onFailure:nil];
            NSArray *eventsInit = [eventStorage() amatest_allSavedEventsWithType:AMAEventTypeUpdate name:nil];
            [[eventsInit should] haveCountOfAtMost:0];
        });
        it(@"Should send EVENT_UPDATE to background session on first event report if started", ^{
            AMAReporter *reporter = [reporterTestHelper appReporterForApiKey:apiKey];
            [reporter start];
            [reporter reportEvent:testEventName onFailure:nil];
            AMAEvent *eventInit = [eventStorage() amatest_savedEventWithType:AMAEventTypeUpdate];
            [[eventInit shouldNot] beNil];
        });
        it(@"Should not create more than one EVENT_UPDATE", ^{
            AMAReporter *reporter = [reporterTestHelper appReporterForApiKey:apiKey];
            [reporter resumeSession];
            [reporter reportEvent:testEventName onFailure:nil];
            NSArray *eventsInit = [eventStorage() amatest_allSavedEventsWithType:AMAEventTypeUpdate name:nil];
            [[eventsInit should] haveCountOf:1];
        });
    });
    context(@"Updates session stamp", ^{
        AMAReporter *__block reporter = nil;
        NSString *lastEventName = @"LastEvent";
        context(@"On event reporting", ^{
            beforeEach(^{
                reporter = [reporterTestHelper appReporterForApiKey:apiKey];
            });
            it(@"Should update last_event_time on each event reporting in foreground", ^{
                [reporter start];
                [reporter reportEvent:testEventName onFailure:nil];
                [reporter reportEvent:lastEventName onFailure:nil];
                AMASession *session = [sessionStorage() amatest_sessionWithOid:@1];
                NSTimeInterval updatedAtInterval = [session.lastEventTime timeIntervalSince1970];
                AMAEvent *lastEvent = [eventStorage() amatest_savedEventWithType:AMAEventTypeClient name:lastEventName];
                NSTimeInterval lastEventInterval = [lastEvent.createdAt timeIntervalSince1970];
                [[theValue(updatedAtInterval) should] equal:lastEventInterval withDelta:floatingComparisonDelta];
            });
            it(@"Should update last_event_time on each event reporting in background, foreground session", ^{
                [reporter start];
                [reporter shutdown];
                [reporter reportEvent:testEventName onFailure:nil];
                [reporter reportEvent:lastEventName onFailure:nil];
                AMASession *session = [sessionStorage() amatest_sessionWithOid:@1];
                NSTimeInterval updatedAtInterval = [session.lastEventTime timeIntervalSince1970];
                AMAEvent *lastEvent = [eventStorage() amatest_savedEventWithType:AMAEventTypeClient name:lastEventName];
                NSTimeInterval lastEventInterval = [lastEvent.createdAt timeIntervalSince1970];
                [[theValue(updatedAtInterval) should] equal:lastEventInterval withDelta:floatingComparisonDelta];
            });
        });
        context(@"Automatically", ^{
            NSUInteger updateSessionInterval = 1;
            AMAReporter *(^createReporterAndStubUpdateInterval)(void) = ^AMAReporter *() {
                AMAReporter *reporter = [reporterTestHelper appReporterForApiKey:apiKey];
                [[AMAMetricaConfiguration sharedInstance].inMemory stub:@selector(updateSessionStampInterval)
                                                              andReturn:theValue(updateSessionInterval)];
                [reporter start];
                [reporter reportEvent:testEventName onFailure:nil];
                return reporter;
            };
            it(@"Should call timer with proper delayed interval", ^{
                AMAReporter *reporter = createReporterAndStubUpdateInterval();
                AMATestDelayedManualExecutor *executor = (AMATestDelayedManualExecutor *)reporter.executor;
                NSTimeInterval delayInterval = executor.delayInterval;
                [[theValue(delayInterval) should] equal:updateSessionInterval withDelta:floatingComparisonDelta];
            });
            it(@"Should update session stamp automatically when active", ^{
                AMAReporter *reporter = createReporterAndStubUpdateInterval();
                [reporter reportEvent:lastEventName onFailure:nil];
                AMASession *session = [sessionStorage() amatest_sessionWithOid:@1];
                AMAEvent *lastEvent = [eventStorage() amatest_savedEventWithType:AMAEventTypeClient name:lastEventName];
                NSTimeInterval lastEventInterval = [lastEvent.createdAt timeIntervalSince1970];
                [NSDate stub:@selector(date) andReturn:[NSDate dateWithTimeIntervalSinceNow:updateSessionInterval]];
                [reporter.executor execute:nil];
                session = [sessionStorage() amatest_sessionWithOid:@1];
                NSTimeInterval pauteTimeInterval = [session.pauseTime timeIntervalSince1970];
                [[theValue(pauteTimeInterval) should] beGreaterThan:theValue(lastEventInterval)];
            });
            it(@"Should update session stamp immediately after start", ^{
                AMAReporter *reporter = createReporterAndStubUpdateInterval();
                [reporter shutdown];
                [[AMAMetricaConfiguration sharedInstance] clearStubs];
                [reporter.executor execute:nil];
                NSTimeInterval beforeStart = [[NSDate date] timeIntervalSince1970] - floatingComparisonDelta;
                [reporter start];
                NSTimeInterval afterStart = [[NSDate date] timeIntervalSince1970] + floatingComparisonDelta;
                AMASession *session = [sessionStorage() amatest_sessionWithOid:@1];
                NSTimeInterval pauseTimeInterval = [session.pauseTime timeIntervalSince1970];
                [[theValue(pauseTimeInterval) should] beBetween:theValue(beforeStart - floatingComparisonDelta)
                                                            and:theValue(afterStart + floatingComparisonDelta)];
            });
            it(@"Should not update session stamp automatically after shutdown", ^{
                AMAReporter *reporter = createReporterAndStubUpdateInterval();
                [reporter shutdown];
                AMASession *session = [sessionStorage() amatest_sessionWithOid:@1];
                NSTimeInterval shutdownInterval = [session.pauseTime timeIntervalSince1970];
                [reporter.executor execute:nil];
                session = [sessionStorage() amatest_sessionWithOid:@1];
                NSTimeInterval pauteTimeInterval = [session.pauseTime timeIntervalSince1970];
                [[theValue(pauteTimeInterval) should] equal:shutdownInterval withDelta:floatingComparisonDelta];
            });
            it(@"Should not update session stamp if session expired", ^{
                NSDate *nowDate = [NSDate date];
                NSDate *startDate = [nowDate dateByAddingTimeInterval:-(sessionDuration + floatingComparisonDelta)];
                [NSDate stub:@selector(date) andReturn:startDate];

                AMAReporter *reporter = createReporterAndStubUpdateInterval();
                AMASession *session = [sessionStorage() amatest_sessionWithOid:@1];
                NSTimeInterval shutdownInterval = [session.pauseTime timeIntervalSince1970];

                [NSDate stub:@selector(date) andReturn:nowDate];
                [reporter.executor execute:nil];
                session = [sessionStorage() amatest_sessionWithOid:@1];
                NSTimeInterval pauteTimeInterval = [session.pauseTime timeIntervalSince1970];

                [[theValue(pauteTimeInterval) should] equal:shutdownInterval withDelta:floatingComparisonDelta];
            });
        });
    });
    context(@"Finishes session automatically with correct EVENT_ALIVE offset", ^{
        void (^startAfterExpiredSession)(NSDate *, NSDate *) = ^(NSDate *startDate, NSDate *shutdownDate) {
            AMAReporter *reporter = [reporterTestHelper appReporterForApiKey:apiKey];
            executeWithStubbedDate(startDate, ^{
                [reporterTestHelper initReporterAndSendEventWithParameters:nil];
            });
            executeWithStubbedDate(shutdownDate, ^{
                [reporter shutdown];
            });
            [reporter start];
        };
        it(@"Should not update session finished stamp on start", ^{
            NSDate *expiredDate = [[NSDate date] dateByAddingTimeInterval:reverseMoreThanSessionTimeoutInterval];
            NSDate *shutdownDate = [expiredDate dateByAddingTimeInterval:1.0];
            startAfterExpiredSession(expiredDate, shutdownDate);
            AMASession *session = [sessionStorage() amatest_sessionWithOid:@1];
            NSTimeInterval updatedAtInterval = [session.pauseTime timeIntervalSince1970];
            NSTimeInterval sessionShutdownInterval = [shutdownDate timeIntervalSince1970];
            [[theValue(updatedAtInterval) should] equal:sessionShutdownInterval withDelta:floatingComparisonDelta];
        });
        it(@"Should create EVENT_ALIVE with shutdown time offset", ^{
            NSDate *expiredDate = [[NSDate date] dateByAddingTimeInterval:reverseMoreThanSessionTimeoutInterval];
            NSDate *shutdownDate = [expiredDate dateByAddingTimeInterval:1.0];
            startAfterExpiredSession(expiredDate, shutdownDate);
            AMAEvent *eventAlive = [eventStorage() amatest_savedEventWithType:AMAEventTypeAlive];
            AMASession *session = [sessionStorage() amatest_sessionWithOid:@1];
            NSTimeInterval interval = [session.pauseTime timeIntervalSinceDate:session.startDate.deviceDate];
            NSTimeInterval timeSinceSession = eventAlive.timeSinceSession;
            [[theValue(timeSinceSession) should] equal:interval withDelta:floatingComparisonDelta];
        });
    });
    context(@"Creates correct event offsets for session while in background", ^{
        it(@"Should set alive event offset equal to client offset if client event sent after shutdown", ^{
            [reporterTestHelper initReporterAndSendEventWithParameters:nil];
            AMAReporter *reporter = [reporterTestHelper appReporterForApiKey:apiKey];
            [reporter shutdown];
            NSString *newEventName = @"New event";
            executeWithStubbedDate([NSDate dateWithTimeIntervalSinceNow:1.0], ^{
                [reporter reportEvent:newEventName onFailure:nil];
                [reporter setupWithOnStorageRestored:nil onSetupComplete:nil];
            });
            AMAEvent *eventAlive = [eventStorage() amatest_savedEventWithType:AMAEventTypeAlive];
            AMAEvent *eventClient = [eventStorage() amatest_savedEventWithType:AMAEventTypeClient name:newEventName];
            [[theValue(eventAlive.timeSinceSession) should] equal:eventClient.timeSinceSession
                                                        withDelta:floatingComparisonDelta];
        });
    });
    context(@"Fills client event correctly", ^{
        it(@"Should create EVENT_CLIENT with correct offset", ^{
            [reporterTestHelper initReporterAndSendEventWithParameters:nil async:YES];
            [NSThread sleepForTimeInterval:sleepInterval];
            AMAReporter *reporter = [reporterTestHelper appReporterForApiKey:apiKey];
            [reporter reportEvent:@"TestEvent2" parameters:nil onFailure:nil];
            [NSThread sleepForTimeInterval:0.5];
            AMAEvent *event = [eventStorage() amatest_savedEventWithType:AMAEventTypeClient name:@"TestEvent2"];
            [[theValue(event.timeSinceSession) should] beInTheIntervalFrom:theValue(lowerAllowedOffset)
                                                                        to:theValue(upperAllowedOffset)];
        });
        it(@"Should parse parameters to JSON", ^{
            [reporterTestHelper initReporterAndSendEventWithParameters:parameters];
            AMAEvent *event = [eventStorage() amatest_savedEventWithType:AMAEventTypeClient];
            AMAStringEventValue *value = (AMAStringEventValue *)event.value;
            [[value.value should] equal:expectedJSONValue];
        });
    });

    context(@"Sends JS client event", ^{
        AMAReporter * __block reporter = nil;
        beforeEach(^{
            reporter = [reporterTestHelper appReporterForApiKey:apiKey];
        });
        it(@"Should save JS client event", ^{
            NSString *name = @"name";
            NSString *value = @"value";
            [reporter reportJSEvent:name value:value];
            AMAEvent *event = [eventStorage() amatest_savedEventWithType:AMAEventTypeClient];
            [[event shouldNot] beNil];
            [[event.name should] equal:name];
            AMAStringEventValue *stringEventValue = (AMAStringEventValue *)event.value;
            [[stringEventValue.value should] equal:value];
        });
    });
    context(@"Sends JS init event", ^{
        AMAReporter * __block reporter = nil;
        beforeEach(^{
            reporter = [reporterTestHelper appReporterForApiKey:apiKey];
        });
        it(@"Should save JS init event", ^{
            NSString *value = @"value";
            [reporter reportJSInitEvent:value];
            AMAEvent *event = [eventStorage() amatest_savedEventWithType:AMAEventTypeWebViewSync];
            [[event shouldNot] beNil];
            [[event.name should] equal:@""];
            AMAStringEventValue *stringEventValue = (AMAStringEventValue *)event.value;
            [[stringEventValue.value should] equal:value];
        });
    });
    context(@"Sends REFERRER events", ^{
        it(@"Should create EVENT_REFERRER", ^{
            AMAReporter *reporter = [reporterTestHelper appReporterForApiKey:apiKey];
            [reporter reportReferrerEventWithValue:@"bar" onFailure:nil];
            NSArray *eventsReferrer = [eventStorage() amatest_allSavedEventsWithType:AMAEventTypeReferrer name:nil];
            [[eventsReferrer should] haveCountOfAtLeast:1];
        });
        it(@"Should not create additional EVENT_REFERRER", ^{
            AMAReporter *reporter = [reporterTestHelper appReporterForApiKey:apiKey];
            [reporter reportReferrerEventWithValue:@"bar" onFailure:nil];
            [reporter reportReferrerEventWithValue:@"foo" onFailure:nil];
            NSArray *eventsReferrer = [eventStorage() amatest_allSavedEventsWithType:AMAEventTypeReferrer name:nil];
            [[eventsReferrer should] haveCountOfAtMost:1];
        });
        it(@"Should not create additional EVENT_REFERRER after restart", ^{
            AMAReporter *reporter = [reporterTestHelper appReporterForApiKey:apiKey];
            [reporter reportReferrerEventWithValue:@"bar" onFailure:nil];
            [reporter shutdown];
            [reporter start];
            [reporter reportReferrerEventWithValue:@"foo" onFailure:nil];
            NSArray *eventsReferrer = [eventStorage() amatest_allSavedEventsWithType:AMAEventTypeReferrer name:nil];
            [[eventsReferrer should] haveCountOfAtMost:1];
        });
    });
    context(@"Sends ASA_TOKEN events", ^{
        it(@"Should create EVENT_ASA_TOKEN", ^{
            AMAReporter *reporter = [reporterTestHelper appReporterForApiKey:apiKey];
            [reporter reportASATokenEventWithParameters:@{@"asaToken":@"123456789"} onFailure:nil];
            NSArray *eventsOpen = [eventStorage() amatest_allSavedEventsWithType:AMAEventTypeASAToken name:nil];
            [[eventsOpen should] haveCountOfAtLeast:1];
        });
    });
    context(@"Sends OPEN events", ^{
        it(@"Should create EVENT_OPEN", ^{
            AMAReporter *reporter = [reporterTestHelper appReporterForApiKey:apiKey];
            [reporter reportOpenEvent:@{@"link":@"l"} reattribution:NO onFailure:nil];
            NSArray *eventsOpen = [eventStorage() amatest_allSavedEventsWithType:AMAEventTypeOpen name:nil];
            [[eventsOpen should] haveCountOfAtLeast:1];
        });
        it(@"Should increment open_id", ^{
            AMAReporter *reporter = [reporterTestHelper appReporterForApiKey:apiKey];
            NSUInteger prevOpenId = reporter.reporterStorage.stateStorage.openID;
            [reporter reportOpenEvent:@{@"link":@"l"} reattribution:NO onFailure:nil];
            [[theValue(reporter.reporterStorage.stateStorage.openID) should] equal:theValue(prevOpenId + 1)];
            [reporter reportOpenEvent:@{@"link":@"l"} reattribution:NO onFailure:nil];
            [[theValue(reporter.reporterStorage.stateStorage.openID) should] equal:theValue(prevOpenId + 2)];
        });
        context(@"Reattribution", ^{
            context(@"Storage", ^{
                AMAReporter *__block reporter = nil;
                beforeEach(^{
                    reporter = [reporterTestHelper appReporterForApiKey:apiKey];
                });
                it(@"Should increment open id", ^{
                    [[reporter.reporterStorage.stateStorage should] receive:@selector(incrementOpenID)];

                    [reporter reportOpenEvent:@{@"link":@"l"} reattribution:NO onFailure:nil];
                });
            });
            context(@"Attribution id changed flag", ^{
                AMAReporter *__block reporter = nil;
                beforeEach(^{
                    reporter = [reporterTestHelper appReporterForApiKey:apiKey];
                });
                it(@"YES", ^{
                    [reporter reportOpenEvent:@{@"link":@"l"} reattribution:YES onFailure:nil];
                    NSArray *eventsOpen = [eventStorage() amatest_allSavedEventsWithType:AMAEventTypeOpen name:nil];
                    [[theValue(((AMAEvent *)eventsOpen[0]).attributionIDChanged) should] beYes];
                });
                it(@"NO", ^{
                    [reporter reportOpenEvent:@{@"link":@"l"} reattribution:NO onFailure:nil];
                    NSArray *eventsOpen = [eventStorage() amatest_allSavedEventsWithType:AMAEventTypeOpen name:nil];
                    [[theValue(((AMAEvent *)eventsOpen[0]).attributionIDChanged) should] beNo];
                });
            });
        });
    });
    context(@"Sends PERMISSION events", ^{
        NSString *permissionJSON = @"{\"permissions\":"
                                        "["
                                            "{"
                                                "\"name\":\"CLAuthorizationStatusAuthorizedWhenInUse\","
                                                "\"granted\":true,"
                                                "\"grant_type\": \"authorized\""
                                            "}"
                                        "]"
                                    "}";
        it(@"Should create EVENT_PERMISSIONS", ^{
            AMAReporter *reporter = [reporterTestHelper appReporterForApiKey:apiKey];
            [reporter reportPermissionsEventWithPermissions:permissionJSON onFailure:nil];
            NSArray *eventsPermissions = [eventStorage() amatest_allSavedEventsWithType:AMAEventTypePermissions
                                                                                   name:nil];
            [[eventsPermissions should] haveCountOfAtLeast:1];
        });
    });
    context(@"Sends PROFILE events", ^{
        NSData *const serializedData = [@"DATA" dataUsingEncoding:NSUTF8StringEncoding];

        AMAReporter *__block reporter = nil;
        NSArray *__block events = nil;

        beforeEach(^{
            AMAUserProfileModelSerializer *serializer = [AMAUserProfileModelSerializer stubbedNullMockForDefaultInit];
            [serializer stub:@selector(dataWithModel:) andReturn:serializedData];
            reporter = [reporterTestHelper appReporterForApiKey:apiKey];
        });
        it(@"Should have correct data in event", ^{
            AMAMutableUserProfile *profile = [[AMAMutableUserProfile alloc] init];
            [profile applyFromArray:@[
                [[AMAProfileAttribute customString:@"foo"] withValue:@"bar"],
            ]];
            [reporter reportUserProfile:[profile copy] onFailure:nil];
            events = [eventStorage() amatest_allSavedEventsWithType:AMAEventTypeProfile name:nil];

            AMAEvent *event = events.firstObject;
            AMABinaryEventValue *value = (AMABinaryEventValue *)event.value;
            [[value.data should] equal:serializedData];
        });
        it(@"Should send PROFILE event on profileID change", ^{
            [reporter setUserProfileID:@"new"];
            events = [eventStorage() amatest_allSavedEventsWithType:AMAEventTypeProfile name:nil];
            [[theValue(events.count) should] equal:theValue(1)];
        });
        it(@"Should not send PROFILE event if new profileID is equal to current", ^{
            [reporter setUserProfileID:@"profileID"];
            [reporter setUserProfileID:@"profileID"];
            events = [eventStorage() amatest_allSavedEventsWithType:AMAEventTypeProfile name:nil];
            [[theValue(events.count) should] equal:theValue(1)];
        });
    });
    context(@"Sends REVENUE events", ^{
        NSData *const serializedData = [@"DATA" dataUsingEncoding:NSUTF8StringEncoding];

        AMAReporter *__block reporter = nil;
        NSArray *__block events = nil;

        beforeEach(^{
            AMARevenueInfoModelSerializer *serializer = [AMARevenueInfoModelSerializer stubbedNullMockForDefaultInit];
            [serializer stub:@selector(dataWithRevenueInfoModel:) andReturn:serializedData];
            reporter = [reporterTestHelper appReporterForApiKey:apiKey];
        });
        it(@"Should have correct data in event", ^{
            AMARevenueInfo *revenueInfo = [[AMARevenueInfo alloc] initWithPriceDecimal:[NSDecimalNumber one]
                                                                              currency:@"USD"];
            [reporter reportRevenue:revenueInfo onFailure:nil];
            events = [eventStorage() amatest_allSavedEventsWithType:AMAEventTypeRevenue name:nil];

            AMAEvent *event = events.firstObject;
            AMABinaryEventValue *value = (AMABinaryEventValue *)event.value;
            [[value.data should] equal:serializedData];
        });
        context(@"Wrong currency", ^{
            AMARevenueInfo *__block revenueInfo = nil;
            beforeEach(^{
                revenueInfo = [[AMARevenueInfo alloc] initWithPriceDecimal:[NSDecimalNumber one] currency:@"wrong"];
            });
            it(@"Should not save event", ^{
                [reporter reportRevenue:revenueInfo onFailure:nil];
                events = [eventStorage() amatest_allSavedEventsWithType:AMAEventTypeRevenue name:nil];
                [[events should] beEmpty];
            });
            it(@"Should call failure callback", ^{
                NSError *__block receivedError = nil;
                [reporter reportRevenue:revenueInfo onFailure:^(NSError * _Nonnull error) {
                    receivedError = error;
                }];
                [[receivedError should] beNonNil];
            });
        });
        context(@"Model reporting", ^{
            it(@"Should have correct data in event", ^{
                AMARevenueInfoMutableModel *model = [[AMARevenueInfoMutableModel alloc] initWithPriceDecimal:[NSDecimalNumber one]
                                                                                                    currency:@"USD"];
                [reporter reportAutoRevenue:model onFailure:nil];
                events = [eventStorage() amatest_allSavedEventsWithType:AMAEventTypeRevenue name:nil];

                AMAEvent *event = events.firstObject;
                AMABinaryEventValue *value = (AMABinaryEventValue *)event.value;
                [[value.data should] equal:serializedData];
            });
            it(@"Should convert public data model", ^{
                AMARevenueInfo *revenueInfo = [[AMARevenueInfo alloc] initWithPriceDecimal:[NSDecimalNumber one]
                                                                                  currency:@"USD"];
                [[AMARevenueInfoConverter should] receive:@selector(convertRevenueInfo:error:) withArguments:revenueInfo, kw_any()];
                [reporter reportRevenue:revenueInfo onFailure:nil];
            });
            context(@"Wrong currency", ^{
                AMARevenueInfoMutableModel *__block revenueModel = nil;
                beforeEach(^{
                    revenueModel = [[AMARevenueInfoMutableModel alloc] initWithPriceDecimal:[NSDecimalNumber one] currency:@"wrong"];
                });
                it(@"Should not save event", ^{
                    [reporter reportAutoRevenue:revenueModel onFailure:nil];
                    events = [eventStorage() amatest_allSavedEventsWithType:AMAEventTypeRevenue name:nil];
                    [[events should] beEmpty];
                });
                it(@"Should call failure callback", ^{
                    NSError *__block receivedError = nil;
                    [reporter reportAutoRevenue:revenueModel onFailure:^(NSError *_Nonnull error) {
                        receivedError = error;
                    }];
                    [[receivedError should] beNonNil];
                });
            });
        });
    });
    context(@"Sends AD_REVENUE events", ^{
        AMAReporter *__block reporter = nil;
        NSArray *__block events = nil;
        context(@"Valid data", ^{
            NSData *const serializedData = [@"DATA" dataUsingEncoding:NSUTF8StringEncoding];
            AMATruncatedDataProcessingResult *const result = [[AMATruncatedDataProcessingResult alloc] initWithData:serializedData
                                                                                                     bytesTruncated:0];

            AMAAdRevenueInfo *const adRevenueInfo = [[AMAAdRevenueInfo alloc] initWithAdRevenue:[NSDecimalNumber one]
                                                                                       currency:@"USD"];

            AMAAdRevenueInfoProcessor *__block processor = nil;

            beforeEach(^{
                processor = [AMAAdRevenueInfoProcessor stubbedNullMockForDefaultInit];
                [processor stub:@selector(processAdRevenueModel:error:) andReturn:result];

                reporter = [reporterTestHelper appReporterForApiKey:apiKey];
            });
            it(@"Should have correct data in event", ^{
                [reporter reportAdRevenue:adRevenueInfo onFailure:nil];
                events = [eventStorage() amatest_allSavedEventsWithType:AMAEventTypeAdRevenue name:nil];

                AMAEvent *event = events.firstObject;
                AMABinaryEventValue *value = (AMABinaryEventValue *)event.value;
                [[value.data should] equal:serializedData];
            });

            it(@"Should not return event if processing nil", ^{
                [processor stub:@selector(processAdRevenueModel:error:) andReturn:nil];

                [reporter reportAdRevenue:adRevenueInfo onFailure:nil];
                events = [eventStorage() amatest_allSavedEventsWithType:AMAEventTypeAdRevenue name:nil];

                [[events should] beEmpty];
            });
        });
        context(@"Wrong currency", ^{
            AMAAdRevenueInfo *__block adRevenueInfo = nil;
            beforeEach(^{
                adRevenueInfo = [[AMAAdRevenueInfo alloc] initWithAdRevenue:[NSDecimalNumber one] currency:@"wrong"];
            });
            it(@"Should not save event", ^{
                [reporter reportAdRevenue:adRevenueInfo onFailure:nil];
                events = [eventStorage() amatest_allSavedEventsWithType:AMAEventTypeAdRevenue name:nil];
                [[events should] beEmpty];
            });
            it(@"Should call failure callback", ^{
                NSError *__block receivedError = nil;
                [reporter reportAdRevenue:adRevenueInfo onFailure:^(NSError * _Nonnull error) {
                    receivedError = error;
                }];
                [[receivedError should] beNonNil];
            });
        });
    });
    context(@"Sends attribution event", ^{
        AMAReporter * __block reporter = nil;
        beforeEach(^{
            reporter = [reporterTestHelper appReporterForApiKey:apiKey];
        });
        it(@"Should save attribution event", ^{
            NSString *name = @"some name";
            NSDictionary *value = @{ @"some key" : @16 };
            [reporter reportAttributionEventWithName:name value:value];
            AMAEvent *event = [eventStorage() amatest_savedEventWithType:AMAEventTypeAttribution];
            [[event shouldNot] beNil];
            [[event.name should] equal:name];
            AMAStringEventValue *stringEventValue = (AMAStringEventValue *)event.value;
            NSDictionary *dictionary = [AMAJSONSerialization dictionaryWithJSONString:stringEventValue.value error:nil];
            [[dictionary should] equal:value];
        });
    });
    context(@"Fills session objects correctly", ^{
        context(@"General session", ^{
            void (^initAndSendEventWithStubbedLocation)(CLLocation *) = ^(CLLocation *location) {
                [AMALocationManager stubCurrentLocation:location];
                [reporterTestHelper initReporterAndSendEventWithParameters:nil];
            };
            void (^initAndSendEventWithStubbedAppState)(AMAAppStateManagerTestHelper *) = ^(AMAAppStateManagerTestHelper *helper) {
                [helper stubApplicationState];
                [reporterTestHelper initReporterAndSendEventWithParameters:nil];
            };
            it(@"Should set location if any location object exists", ^{
                CLLocation *location = [[CLLocation alloc] initWithLatitude:113.0 longitude:-53.0];
                initAndSendEventWithStubbedLocation(nil);
                [AMALocationManager stubCurrentLocation:location];
                [reporterTestHelper sendEvent];
                AMAEvent *event = [eventStorage() amatest_savedEventWithType:AMAEventTypeClient];
                [[theValue([event.location test_isEqualToLocation:location]) should] beYes];
            });
            it(@"Should not load empty location from database", ^{
                initAndSendEventWithStubbedLocation(nil);
                [AMALocationManager stubCurrentLocation:nil];
                [reporterTestHelper sendEvent];
                AMAEvent *event = [eventStorage() amatest_savedEventWithType:AMAEventTypeClient];
                [[event.location should] beNil];
            });
            it(@"Should set app state for new session", ^{
                AMAAppStateManagerTestHelper *helper = [[AMAAppStateManagerTestHelper alloc] init];
                initAndSendEventWithStubbedAppState(helper);
                AMASession *modifiedSession = [sessionStorage() lastGeneralSessionWithError:nil];
                [[[modifiedSession appState] shouldNot] beNil];
            });
            it(@"Should set non-empty app state for new session", ^{
                AMAAppStateManagerTestHelper *helper = [[AMAAppStateManagerTestHelper alloc] init];
                initAndSendEventWithStubbedAppState(helper);
                AMASession *modifiedSession = [sessionStorage() lastGeneralSessionWithError:nil];
                [[[[modifiedSession appState] appVersionName] should] equal:[helper appVersionName]];
            });
            it(@"Should not overwrite app state for new event", ^{
                AMAAppStateManagerTestHelper *helper = [[AMAAppStateManagerTestHelper alloc] init];
                initAndSendEventWithStubbedAppState(helper);
                helper.appVersionName = @"767";
                [helper stubApplicationState];
                [reporterTestHelper sendEvent];
                AMASession *modifiedSession = [sessionStorage() lastGeneralSessionWithError:nil];
                [[[modifiedSession.appState appVersionName] shouldNot] equal:helper.appVersionName];
            });
            it(@"Should overwrite app state if previous value is nil", ^{
                [AMAApplicationStateManager stub:@selector(applicationState)];
                [reporterTestHelper initReporterAndSendEventWithParameters:nil];
                [AMAApplicationStateManager stub:@selector(applicationState) andReturn:[AMAApplicationState new]];
                [reporterTestHelper sendEvent];
                AMASession *session = [sessionStorage() lastGeneralSessionWithError:nil];
                [[session.appState shouldNot] beNil];
            });
        });
        context(@"Background session", ^{
            void (^initAndSendEventWithStubbedAppState)(AMAAppStateManagerTestHelper *) = ^(AMAAppStateManagerTestHelper *helper) {
                [helper stubApplicationState];
                [reporterTestHelper initReporterAndSendEventWithoutStartingSessionWithParameters:nil];
            };
            it(@"Should set app state for new session", ^{
                AMAAppStateManagerTestHelper *helper = [[AMAAppStateManagerTestHelper alloc] init];
                initAndSendEventWithStubbedAppState(helper);
                AMASession *session = [sessionStorage() amatest_backgroundSession];
                [[session.appState shouldNot] beNil];
            });
            it(@"Should set non-empty app state for new sesssion", ^{
                AMAAppStateManagerTestHelper *helper = [[AMAAppStateManagerTestHelper alloc] init];
                initAndSendEventWithStubbedAppState(helper);
                AMASession *session = [sessionStorage() amatest_backgroundSession];
                NSUInteger code = helper.appBuildNumber;
                [[session.appState.appBuildNumber should] equal:[@(code) stringValue]];
            });
            it(@"Should not overwrite app state after adding new event", ^{
                AMAAppStateManagerTestHelper *helper = [[AMAAppStateManagerTestHelper alloc] init];
                initAndSendEventWithStubbedAppState(helper);
                NSString *kitVersion = helper.kitVersionName;
                helper.kitVersionName = @"9.9.9";
                [helper stubApplicationState];
                [reporterTestHelper sendEvent];
                AMASession *session = [sessionStorage() amatest_backgroundSession];
                [[session.appState.kitVersionName should] equal:kitVersion];
            });
            it(@"Should overwrite app state if previous value is nil", ^{
                [AMAApplicationStateManager stub:@selector(applicationState)];
                [reporterTestHelper initReporterAndSendEventWithoutStartingSessionWithParameters:nil];
                [AMAApplicationStateManager stub:@selector(applicationState) andReturn:[AMAApplicationState new]];
                [reporterTestHelper sendEvent];
                AMASession *session = [sessionStorage() amatest_backgroundSession];
                [[session.appState shouldNot] beNil];
            });
        });
    });
    context(@"Starts and shuts down reporter", ^{
        it(@"Should create new session on start if current session is not valid", ^{
            AMAReporter *reporter = [reporterTestHelper appReporterForApiKey:apiKey];
            [sessionStorage() newGeneralSessionCreatedAt:[NSDate distantPast] error:nil];

            [reporter start];
            AMASession *currentSession = [sessionStorage() lastGeneralSessionWithError:nil];
            [[currentSession.oid should] equal:@2];
        });
        it(@"Should create new session on start if there are no existing sessions", ^{
            AMAReporter *reporter = [reporterTestHelper appReporterForApiKey:apiKey];
            [reporter start];
            AMASession *currentSession = [sessionStorage() lastGeneralSessionWithError:nil];
            [[currentSession.oid should] equal:@1];
        });
        it(@"Should update session stamp on shutdown", ^{
            AMAReporter *reporter = [reporterTestHelper appReporterForApiKey:apiKey];
            NSDate *date = [NSDate date];
            [sessionStorage() newGeneralSessionCreatedAt:date error:nil];
            [reporter shutdown];
            AMASession *updatedSession = [sessionStorage() lastGeneralSessionWithError:nil];
            [[theValue([updatedSession.pauseTime compare:date]) should] equal:theValue(NSOrderedDescending)];
        });
    });
    context(@"Provides errors", ^{
        it(@"Should provide invalid name error for wrong named event", ^{
            AMAReporter *reporter = [reporterTestHelper appReporterForApiKey:apiKey];
            NSError *__block reportError = nil;
            [reporter reportEvent:@"" parameters:nil onFailure:^(NSError *error) {
                reportError = error;
            }];
            [[theValue(reportError.code) should] equal:theValue(AMAAppMetricaEventErrorCodeInvalidName)];
        });
        it(@"Should provide JSON serialization error for wrong parameters", ^{
            [AMATestUtilities stubAssertions];
            AMAReporter *reporter = [reporterTestHelper appReporterForApiKey:apiKey];
            NSCondition *condition = [[NSCondition alloc] init];
            NSError *__block reportError = nil;
            [reporter reportEvent:testEventName parameters:@{ @"key" : condition } onFailure:^(NSError *error) {
                reportError = error;
            }];
            [[theValue(reportError.code) should] equal:theValue(AMAAppMetricaInternalEventJsonSerializationError)];
        });
        it(@"Should not call block if there's no error", ^{
            BOOL __block didCallBlock = NO;
            AMAReporter *reporter = [reporterTestHelper appReporterForApiKey:apiKey];
            [reporter reportEvent:testEventName onFailure:^(NSError *error) {
                didCallBlock = YES;
            }];
            [[theValue(didCallBlock) shouldEventually] beNo];
        });
    });
    context(@"Processes system time change correctly", ^{
        NSDate *futureDate = [NSDate distantFuture];
        it(@"Should create new session if event has negative time offset", ^{
            AMASession *session = [sessionStorage() newGeneralSessionCreatedAt:futureDate error:nil];
            NSInteger prevSessionOid = [session.oid integerValue];

            AMAReporter *reporter = [reporterTestHelper appReporterForApiKey:apiKey];
            [reporter reportEvent:testEventName onFailure:nil];
            session = [sessionStorage() lastSessionWithError:nil];
            NSInteger lastSessionOid = [session.oid integerValue];

            [[theValue(prevSessionOid + 1) should] equal:theValue(lastSessionOid)];
        });
    });

    context(@"Background session handling", ^{
        __block AMAReporter *reporter = nil;
        beforeEach(^{
            reporter = [reporterTestHelper appReporterForApiKey:apiKey];
        });

        it(@"Should not create new background session", ^{
            [reporter reportEvent:@"test" onFailure:nil];
            [reporter reportEvent:@"test" onFailure:nil];
            NSArray *sessions = [sessionStorage() amatest_allSessionsWithType:AMASessionTypeBackground];
            [[theValue(sessions.count) should] equal:theValue(1)];
        });

        it(@"Should return new background session if there was user session after it", ^{
            [AMAReporterTestHelper reportDelayedEvent:reporter delay:0];
            AMASession *oldSession =
                [[sessionStorage() amatest_allSessionsWithType:AMASessionTypeBackground] firstObject];
            [AMAReporterTestHelper cycleReporterWithStubbedDateFromNow:reporter interval:0];
            [AMAReporterTestHelper reportDelayedEvent:reporter delay:backgroundSessionTimeout + 1];
            AMASession *newSession =
                [[sessionStorage() amatest_allSessionsWithType:AMASessionTypeBackground] firstObject];

            [[oldSession.oid shouldNot] equal:newSession.oid];
        });

        it(@"Should return old background session if not expired", ^{
            [AMAReporterTestHelper reportDelayedEvent:reporter delay:0];
            [AMAReporterTestHelper reportDelayedEvent:reporter delay:backgroundSessionTimeout - 1];
            NSArray *sessions = [sessionStorage() amatest_allSessionsWithType:AMASessionTypeBackground];
            [[theValue(sessions.count) should] equal:theValue(1)];
        });

        it(@"Should update last_event_time in background session on reporting event", ^{
            AMASession *session = [sessionStorage() amatest_existingOrNewBackgroundSessionCreatedAt:[NSDate date]];
            NSTimeInterval initialInterval = [session.lastEventTime timeIntervalSince1970];
            [AMAReporterTestHelper reportDelayedEvent:reporter delay:backgroundSessionTimeout - 1];
            AMASession *backgroundSession =
                [sessionStorage() amatest_existingOrNewBackgroundSessionCreatedAt:[NSDate date]];
            NSTimeInterval currentInterval = [backgroundSession.lastEventTime timeIntervalSince1970];
            [[theValue(initialInterval) should] beLessThan:theValue(currentInterval)];
        });

        it(@"Should not create new background session if previous one hasn't expired because of reported events", ^{
            [AMAReporterTestHelper reportDelayedEvent:reporter delay:0];
            [AMAReporterTestHelper reportDelayedEvent:reporter delay:backgroundSessionTimeout - 1];
            [AMAReporterTestHelper reportDelayedEvent:reporter delay:backgroundSessionTimeout - 1];
            NSArray *sessions = [sessionStorage() amatest_allSessionsWithType:AMASessionTypeBackground];
            [[theValue(sessions.count) should] equal:theValue(1)];
        });

        it(@"Should create new background session if expired by timeout", ^{
            AMASession *session = [sessionStorage() amatest_existingOrNewBackgroundSessionCreatedAt:[NSDate date]];
            [AMAReporterTestHelper reportDelayedEvent:reporter delay:backgroundSessionTimeout + 1];
            AMASession *backgroundSession = [sessionStorage() lastSessionWithError:nil];
            [[backgroundSession.oid shouldNot] equal:session.oid];
        });

        it(@"Should create new background session if background session expired by session duration", ^{
            NSDate *sessionDate = [NSDate date];
            AMASession *session = [sessionStorage() newBackgroundSessionCreatedAt:sessionDate error:nil];
            NSInteger updateDelta = sessionDuration - (backgroundSessionTimeout / 2);
            NSDate *pauseTime = [sessionDate dateByAddingTimeInterval:updateDelta];
            [sessionStorage() updateSession:session pauseTime:pauseTime error:nil];

            executeWithStubbedDate([sessionDate dateByAddingTimeInterval:sessionDuration + 1], ^{
                [reporter reportEvent:@"test" onFailure:nil];
            });
            AMASession *backgroundSession = [sessionStorage() lastSessionWithError:nil];

            [[backgroundSession.oid shouldNot] equal:session.oid];
        });

        it(@"Should create new background session if foreground session expired by session duration", ^{
            [reporter setupWithOnStorageRestored:nil onSetupComplete:nil];

            NSDate *sessionDate = [NSDate date];
            AMASession *session = [sessionStorage() newGeneralSessionCreatedAt:sessionDate error:nil];
            NSInteger updateDelta = sessionDuration - (foregroundSessionTimeout / 2);
            NSDate *pauseTime = [sessionDate dateByAddingTimeInterval:updateDelta];
            [sessionStorage() updateSession:session pauseTime:pauseTime error:nil];

            executeWithStubbedDate([sessionDate dateByAddingTimeInterval:sessionDuration + 1], ^{
                [reporter reportEvent:@"test" onFailure:nil];
            });
            AMASession *backgroundSession = [sessionStorage() lastSessionWithError:nil];

            [[backgroundSession.oid shouldNot] equal:session.oid];
        });

        it(@"Should create 3 background sessions", ^{
            [AMAReporterTestHelper cycleReporterWithStubbedDateFromNow:reporter interval:0];
            [AMAReporterTestHelper reportDelayedEvent:reporter delay:backgroundSessionTimeout + 1];
            [AMAReporterTestHelper reportDelayedEvent:reporter delay:backgroundSessionTimeout + 1];
            [AMAReporterTestHelper reportDelayedEvent:reporter delay:backgroundSessionTimeout + 1];
            NSArray *sessions = [sessionStorage() amatest_allSessionsWithType:AMASessionTypeBackground];
            [[theValue(sessions.count) should] equal:theValue(3)];
        });
    });

    context(@"Environment data handling", ^{
        it(@"Should use event environment dictionary", ^{
            __block AMAEvent *userEvent = nil;
            AMAReporter *reporter = [reporterTestHelper appReporterForApiKey:apiKey];
            [reporter stub:NSSelectorFromString(@"reportEvent:createdAt:onFailure:")
                 withBlock:^id(NSArray *params) {
                     userEvent = params.firstObject;
                     return nil;
                 }];
            [reporter setAppEnvironmentValue:@"fizz" forKey:@"buzz"];
            [reporter reportEvent:@"TestUserEvent" onFailure:nil];
            [[userEvent.appEnvironment should] equal:@{ @"buzz" : @"fizz" }];
        });
        it(@"Should remove event environment value for empty value", ^{
            __block AMAEvent *userEvent = nil;
            AMAReporter *reporter = [reporterTestHelper appReporterForApiKey:apiKey];
            [reporter stub:NSSelectorFromString(@"reportEvent:createdAt:onFailure:")
                 withBlock:^id(NSArray *params) {
                     userEvent = params.firstObject;
                     return nil;
                 }];
            [reporter setAppEnvironmentValue:@"fizz" forKey:@"buzz"];
            [reporter setAppEnvironmentValue:nil forKey:@"buzz"];
            [reporter reportEvent:@"TestUserEvent" onFailure:nil];
            [userEvent.appEnvironment shouldBeNil];
        });
    });

    context(@"Sends events", ^{
        it(@"Invokes delegates sendEventsBuffer method", ^{
            AMAAppMetricaImpl *impl = [AMAAppMetricaImpl nullMock];
            [AMAAppMetrica stub:@selector(sharedImpl) andReturn:impl];
            [[impl should] receive:@selector(sendEventsBufferWithApiKey:) withArguments:apiKey];
            AMAReporter *reporter = [reporterTestHelper appReporterForApiKey:apiKey];
            reporter.delegate = (id<AMAReporterDelegate>)impl;
            [reporter sendEventsBuffer];
        });
        it(@"Should call executor", ^{
            AMAReporter *reporter = [reporterTestHelper appReporterForApiKey:apiKey];
            [[((NSObject *)reporter.executor) should] receive:@selector(execute:)];
            [reporter sendEventsBuffer];
        });
    });

    context(@"Set attribution checker delegate", ^{
        AMAAttributionChecker *__block delegate = nil;
        id __block attributionCheckExecutor = nil;
        AMAReporter *__block reporter = nil;
        AMAMetricaPersistentConfiguration *__block persistentConfiguration = nil;
        beforeEach(^{
            attributionCheckExecutor = [KWMock nullMockForProtocol:@protocol(AMAExecuting)];
            [attributionCheckExecutor stub:@selector(execute:) withBlock:^id (NSArray *params) {
                void (^block)(void) = params[0];
                block();
                return nil;
            }];
            delegate = [AMAAttributionChecker nullMock];
            persistentConfiguration = [AMAMetricaPersistentConfiguration nullMock];
            AMAMetricaConfiguration *metricaConfiguration = [AMAMetricaConfiguration nullMock];
            [metricaConfiguration stub:@selector(persistent) andReturn:persistentConfiguration];
            [AMAMetricaConfiguration stub:@selector(sharedInstance) andReturn:metricaConfiguration];
            reporter = [reporterTestHelper appReporterForApiKey:apiKey attributionCheckExecutor:attributionCheckExecutor];
        });
        it(@"Should proxy initial attribution check to right queue", ^{
            [[attributionCheckExecutor should] receive:@selector(execute:)];
            reporter.attributionChecker = delegate;
        });
        it(@"Should not check initial attribution if already checked", ^{
            [persistentConfiguration stub:@selector(checkedInitialAttribution) andReturn:theValue(YES)];
            [reporter reportEvent:@"Test" onFailure:nil];

            [[delegate shouldNot] receive:@selector(checkInitialAttribution)];
            [[delegate shouldNot] receive:@selector(checkSerializedEventAttribution:)];

            [[persistentConfiguration shouldNot] receive:@selector(setCheckedInitialAttribution:)];
            reporter.attributionChecker = delegate;
        });
        it(@"Should check initial attribution if has not checked yes", ^{
            [persistentConfiguration stub:@selector(checkedInitialAttribution) andReturn:theValue(NO)];
            [reporter reportEvent:@"Test1" onFailure:nil];
            [reporter reportEvent:@"Test2" onFailure:nil];

            [[delegate should] receive:@selector(checkInitialAttribution)];
            [[delegate should] receive:@selector(checkSerializedEventAttribution:) withCountAtLeast:2];

            reporter.attributionChecker = delegate;
        });
        it(@"Should set initial attribution checked", ^{
            [persistentConfiguration stub:@selector(checkedInitialAttribution) andReturn:theValue(NO)];
            [[persistentConfiguration should] receive:@selector(setCheckedInitialAttribution:) withArguments:theValue(YES)];
            reporter.attributionChecker = delegate;
        });
        it(@"Should proxy client event without parameters", ^{
            reporter.attributionChecker = delegate;
            [[delegate should] receive:@selector(checkClientEventAttribution:) withArguments:@"some name"];
            [reporter reportEvent:@"some name" onFailure:nil];
        });
        it(@"Should proxy client event with parameters", ^{
            reporter.attributionChecker = delegate;
            [[delegate should] receive:@selector(checkClientEventAttribution:) withArguments:@"some name"];
            [reporter reportEvent:@"some name" parameters:@{} onFailure:nil];
        });
        context(@"Revenue event", ^{
            it(@"Should proxy manual", ^{
                AMARevenueInfoModel *convertedRevenue = [AMARevenueInfoModel nullMock];
                [AMARevenueInfoConverter stub:@selector(convertRevenueInfo:error:) andReturn:convertedRevenue];
                AMARevenueInfo *revenue = [AMARevenueInfo nullMock];
                reporter.attributionChecker = delegate;
                [[delegate should] receive:@selector(checkRevenueEventAttribution:) withArguments:convertedRevenue];
                [reporter reportRevenue:revenue onFailure:nil];
            });
            it(@"Should proxy auto", ^{
                AMARevenueInfoModel *revenue = [AMARevenueInfoModel nullMock];
                reporter.attributionChecker = delegate;
                [[delegate should] receive:@selector(checkRevenueEventAttribution:) withArguments:revenue];
                [reporter reportAutoRevenue:revenue onFailure:nil];
            });
        });
        it(@"Should proxy e-comm event", ^{
            AMAECommerce *eCommerce = [AMAECommerce nullMock];
            reporter.attributionChecker = delegate;
            [[delegate should] receive:@selector(checkECommerceEventAttribution:) withArguments:eCommerce];
            [reporter reportECommerce:eCommerce onFailure:nil];
        });
    });

    context(@"WebViewReporting", ^{
        it(@"Should init web view reporting", ^{
            [AMAAppMetrica stub:@selector(isAppMetricaStarted) andReturn:theValue(YES)];
            AMAReporter *reporter = [reporterTestHelper appReporterForApiKey:apiKey];

            [[jsController should] receive:@selector(setUpWebViewReporting:withReporter:)
                             withArguments:reporter.executor, reporter];

            [reporter setupWebViewReporting:jsController onFailure:nil];
        });

        it(@"Should not init web view reporting if metrica not started", ^{
            [AMAAppMetrica stub:@selector(isAppMetricaStarted) andReturn:theValue(NO)];
            AMAReporter *reporter = [reporterTestHelper appReporterForApiKey:apiKey];

            [[jsController shouldNot] receive:@selector(setUpWebViewReporting:withReporter:)];

            [reporter setupWebViewReporting:jsController onFailure:nil];
        });
    });
    
    context(@"Reporting custom events", ^{
        let(error, ^NSError *{ return nil; });
        let(reporter, ^{ return [reporterTestHelper appReporterForApiKey:apiKey]; });
        
        context(@"String events", ^{
            __block AMAEvent *event;
            beforeEach(^{
                [reporter reportEventWithType:AMAEventTypeClient
                                         name:nil
                                        value:nil
                                  environment:nil
                                       extras:nil
                                    onFailure:^(NSError *anError) { error = anError; }];
                event = [eventStorage() amatest_savedEventWithType:AMAEventTypeClient];
            });
            it(@"Should save event", ^{
                [[error should] beNil];
                [[event shouldNot] beNil];
            });
        });
        context(@"Binary events", ^{
            NSData *__block data = [@"data" dataUsingEncoding:NSUTF8StringEncoding];
            __block AMAEvent *event;
            beforeEach(^{
                [reporter reportBinaryEventWithType:AMAEventTypeClient
                                               data:data
                                            gZipped:YES
                                        environment:nil
                                             extras:nil
                                          onFailure:^(NSError *anError) { error = anError; }];
                event = [eventStorage() amatest_savedEventWithType:AMAEventTypeClient];
            });
            it(@"Should save event", ^{
                [[error should] beNil];
                [[event shouldNot] beNil];
            });
        });
        context(@"File events", ^{
            NSData *__block data = [@"data" dataUsingEncoding:NSUTF8StringEncoding];
            __block AMAEvent *event;
            beforeEach(^{
                [reporter reportFileEventWithType:AMAEventTypeClient
                                             data:data
                                         fileName:@""
                                          gZipped:YES
                                        encrypted:YES
                                        truncated:YES
                                      environment:nil
                                           extras:nil
                                        onFailure:^(NSError *anError) { error = anError; }];
                event = [eventStorage() amatest_savedEventWithType:AMAEventTypeClient];
            });
            it(@"Should save event", ^{
                [[error should] beNil];
                [[event shouldNot] beNil];
            });
        });
    });
    
    context(@"Session extras", ^{
        AMAReporter *__block reporter = nil;
        AMAExtrasContainer *__block extrasContainer = nil;
        beforeEach(^{
            reporter = [reporterTestHelper appReporterForApiKey:apiKey];
            extrasContainer = [AMAExtrasContainer nullMock];
            [reporter.reporterStorage.stateStorage stub:@selector(extrasContainer)
                                              andReturn:extrasContainer];
        });
        NSString *const key = @"key";
        it(@"Should remove session extras if data is empty", ^{
            NSData *data = [NSData data];
            
            [[extrasContainer should] receive:@selector(removeValueForKey:) withArguments:key];
            
            [reporter setSessionExtras:data forKey:key];
        });
        it(@"Should set session extras if reporter is data is not nil", ^{
            NSData *data = [key dataUsingEncoding:NSUTF8StringEncoding];
            
            [[extrasContainer should] receive:@selector(addValue:forKey:) withArguments:data, key];
            
            [reporter setSessionExtras:data forKey:key];
        });
        
        it(@"Should clear session extras if reporter is not nil", ^{
            [[extrasContainer should] receive:@selector(clearExtras)];
            
            [reporter clearSessionExtra];
        });
    });
    
    context(@"Protocols", ^{
        __block id reporter = nil;
        beforeEach(^{
            reporter = [reporterTestHelper appReporterForApiKey:apiKey];
        });
        it(@"Should conform to AMAAppMetricaReporting", ^{
            [[(NSObject *)reporter should] conformToProtocol:@protocol(AMAAppMetricaReporting)];
        });
        it(@"Should conform to AMAAppMetricaExtendedReporting", ^{
            [[(NSObject *)reporter should] conformToProtocol:@protocol(AMAAppMetricaExtendedReporting)];
        });
        it(@"Should conform to AMAJSReporting", ^{
            [[(NSObject *)reporter should] conformToProtocol:@protocol(AMAJSReporting)];
        });
    });
});

SPEC_END
