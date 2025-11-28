
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMAAppMetrica+TestUtilities.h"
#import "AMAAppMetricaConfiguration.h"
#import "AMAAppMetricaImplTestFactory.h"
#import "AMAEvent.h"
#import "AMASession.h"
#import "AMAEventStorage+TestUtilities.h"
#import "AMAMetricaConfigurationTestUtilities.h"
#import "AMADate.h"
#import "AMAReporterTestHelper.h"
#import "AMAReporter.h"
#import "AMAReporterStorage.h"
#import "AMAReporterStateStorage.h"
#import "AMASessionStorage+AMATestUtilities.h"
#import "AMAReporterTestHelper.h"

SPEC_BEGIN(AMAMetricaSessionsTests)

describe(@"AMAMetricaSessions", ^{
    NSString *const apiKey = [AMAReporterTestHelper defaultApiKey];

    AMAReporterTestHelper *__block reporterTestHelper = nil;
    AMAStubHostAppStateProvider *__block hostStateProvider = nil;
    AMAStubHostAppStateProvider *__block hostAppStateProvider = nil;
    AMAReporterStateStorage *__block stateStorage = nil;
    AMASessionStorage *__block sessionStorage = nil;

    void (^stubSharedImpl)(void) = ^{
        [NSURLProtocol registerClass:[AMATestURLProtocol class]];
        [AMAMetricaConfigurationTestUtilities stubConfigurationWithAppVersion:@"1.00" buildNumber:100];
        hostStateProvider = [AMAStubHostAppStateProvider new];
        hostStateProvider.hostState = AMAHostAppStateBackground;
        hostAppStateProvider = [[AMAStubHostAppStateProvider alloc] init];
        reporterTestHelper = [[AMAReporterTestHelper alloc] init];
        AMAAppMetricaImpl *impl =
        [AMAAppMetricaImplTestFactory createCurrentQueueImplWithReporterHelper:reporterTestHelper
                                                             hostStateProvider:hostAppStateProvider];
        [AMAAppMetrica stub:@selector(sharedImpl) andReturn:impl];

        id<AMAAsyncExecuting>executor = [AMACurrentQueueExecutor new];
        [AMAAppMetrica stub:@selector(sharedExecutor) andReturn:executor];

        AMAReporterStorage *reporterStorage = [reporterTestHelper appReporterForApiKey:apiKey].reporterStorage;
        stateStorage = reporterStorage.stateStorage;
        sessionStorage = reporterStorage.sessionStorage;
    };
    void (^start)(void) = ^{
        [AMAAppMetrica activateWithConfiguration:[[AMAAppMetricaConfiguration alloc] initWithAPIKey:apiKey]];
        sleep(2);
    };
    void (^clearAndStart)(void) = ^{
        UIApplication *app = [UIApplication nullMock];
        [app stub:@selector(applicationState) andReturn:theValue(UIApplicationStateBackground)];
        [UIApplication stub:@selector(sharedApplication) andReturn:app];
        stubSharedImpl();
        start();
    };
    
    afterEach(^{
        [AMAMetricaConfigurationTestUtilities destubConfiguration];
        [AMAAppMetrica clearStubs];
        [reporterTestHelper destub];
        [UIApplication clearStubs];
        [NSDate clearStubs];
    });
    
	context(@"Creates one session", ^{
        void (^startAndSendEvent)(void) = ^{
            clearAndStart();
            [AMAAppMetrica reportEvent:@"TestEvent" onFailure:nil];
            sleep(2);
        };
        it(@"Should not have session with oid = 0", ^{
            startAndSendEvent();
            AMASession *session = [sessionStorage amatest_sessionWithOid:@0];
            [[session should] beNil];
        });
        it(@"Should only have session with oid = 1", ^{
            startAndSendEvent();
            AMASession *session = [sessionStorage amatest_sessionWithOid:@1];
            [[session shouldNot] beNil];
        });
        it(@"Should create background session if app is inactive", ^{
            startAndSendEvent();
            AMASession *session = [sessionStorage amatest_sessionWithOid:@1];
            [[theValue(session.type) should] equal:theValue(AMASessionTypeBackground)];
        });
        it(@"Should not have session with oid = 2", ^{
            startAndSendEvent();
            AMASession *session = [sessionStorage amatest_sessionWithOid:@2];
            [[session should] beNil];
        });
    });
    context(@"Does start session with activateWithApiKey", ^{
        
        afterEach(^{
            [UIApplication clearStubs];
        });
        
        it(@"Should create session on first launch", ^{
            clearAndStart();
            AMASession *session = [sessionStorage amatest_sessionWithOid:@1];
            [[session should] beNonNil];
        });
        it(@"Should not create new session on second launch", ^{
            stubSharedImpl();

            [stateStorage markFirstEventSent];
            [sessionStorage newGeneralSessionCreatedAt:[NSDate date] error:nil];

            UIApplication *app = [UIApplication nullMock];
            [app stub:@selector(applicationState) andReturn:theValue(UIApplicationStateBackground)];
            [UIApplication stub:@selector(sharedApplication) andReturn:app];
            start();

            AMASession *createdSession = [sessionStorage amatest_sessionWithOid:@2];
            [[createdSession should] beNil];
        });
    });
    context(@"Handles application active events", ^{
        it(@"Should create new session when host state become foreground", ^{
            clearAndStart();
            hostStateProvider.hostState = AMAHostAppStateForeground;
            AMASession *session = [sessionStorage amatest_sessionWithOid:@1];
            [[session shouldNot] beNil];
        });
        context(@"Finishes last session in application start", ^{
            beforeEach(^{
                stubSharedImpl();
            });
            void (^saveSession)(void) = ^{
                [sessionStorage newGeneralSessionCreatedAt:[NSDate date] error:nil];
            };
            it(@"Should finish last session on application start", ^{
                saveSession();
                start();
                AMASession *savedSession = [sessionStorage amatest_sessionWithOid:@1];
                [[theValue(savedSession.isFinished) should] beYes];
            });
            it(@"Should not update finished session stamp on application start", ^{
                saveSession();
                AMASession *savedSession = [sessionStorage amatest_sessionWithOid:@1];
                NSDate *pauseTime = savedSession.pauseTime;
                start();
                AMASession *updatedSession = [sessionStorage amatest_sessionWithOid:@1];
                [[updatedSession.pauseTime should] equal:pauseTime];
            });
            it(@"Should not finish last session for manual reporters on application start", ^{
                NSString *manualApiKey = @"550e8400-e29b-41d4-a716-446655440001";
                AMAReporter *reporter = (AMAReporter *)[AMAAppMetrica reporterForAPIKey:manualApiKey];
                [reporter.reporterStorage.sessionStorage newGeneralSessionCreatedAt:[NSDate date] error:nil];

                start();

                [reporter reportEvent:@"Event" onFailure:nil];
                AMASession *savedSession = [sessionStorage amatest_sessionWithOid:@1];
                [[theValue(savedSession.isFinished) should] beNo];
            });
        });
        context(@"Starts new session on activateWithApiKey or on active notification", ^{
            it(@"Should start new session if application is already active on metrica start", ^{
                clearAndStart();
                hostStateProvider.hostState = AMAHostAppStateForeground;
                AMASession *savedSession = [sessionStorage amatest_sessionWithOid:@1];
                [[savedSession shouldNot] beNil];
            });
            it(@"Should not start manual reporters on applicationDidBecomeActive", ^{
                stubSharedImpl();
                NSString *manualApiKey = @"550e8400-e29b-41d4-a716-446655440001";
                id<AMAAppMetricaReporting> __unused reporter = [AMAAppMetrica reporterForAPIKey:manualApiKey];
                start();
                [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidBecomeActiveNotification
                                                                    object:nil];

                AMASession *session =
                    [[AMAAppMetrica sharedImpl].mainReporter.reporterStorage.sessionStorage lastGeneralSessionWithError:nil];
                [[session should] beNil];
            });
            it(@"Should not start new session after receiving notification before start and then starting Impl", ^{
                stubSharedImpl();
                hostStateProvider.hostState = AMAHostAppStateForeground;
                [AMAAppMetrica activateWithConfiguration:[[AMAAppMetricaConfiguration alloc] initWithAPIKey:apiKey]];
                AMASession *session = [sessionStorage amatest_sessionWithOid:@3];
                [[session should] beNil];
            });
            context(@"Getting sessions logics", ^{
                it(@"Should return last session if only one", ^{
                    AMASession *session = [sessionStorage newBackgroundSessionCreatedAt:[NSDate date] error:nil];
                    AMASession *lastSession = [sessionStorage lastSessionWithError:nil];
                    [[lastSession.oid should] equal:session.oid];
                });

                it(@"Should return last session if only 2", ^{
                    AMASession *session = [sessionStorage newBackgroundSessionCreatedAt:[NSDate date] error:nil];
                    session = [sessionStorage newBackgroundSessionCreatedAt:[NSDate date] error:nil];
                    AMASession *lastSession = [sessionStorage lastSessionWithError:nil];
                    [[lastSession.oid should] equal:session.oid];
                });
            });
        });
    });
    context(@"Creates new session", ^{
        NSDate * __block date = nil;
        AMAStartupParametersConfiguration * __block configuration = nil;
        beforeEach(^{
            [AMAMetricaConfigurationTestUtilities stubConfiguration];
            configuration = [AMAMetricaConfiguration sharedInstance].startup;
            configuration.serverTimeOffset = nil;
            AMAReporter *reporter = [[[AMAReporterTestHelper alloc] init] appReporter];
            sessionStorage = reporter.reporterStorage.sessionStorage;
            date = [NSDate date];
            [NSDate stub:@selector(date) andReturn:date];
        });
        afterEach(^{
            [AMAMetricaConfigurationTestUtilities destubConfiguration];
            [NSDate clearStubs];
        });
        it(@"Should create new general session with correct date", ^{
            AMASession *session = [sessionStorage newGeneralSessionCreatedAt:date error:nil];
            [[session.startDate.deviceDate should] equal:date];
        });
        it(@"Should create new background session with correct date", ^{
            AMASession *session = [sessionStorage newBackgroundSessionCreatedAt:date error:nil];
            [[session.startDate.deviceDate should] equal:date];
        });
        it(@"Should create new general session with nil server time offset if unavailable", ^{
            AMASession *session = [sessionStorage newGeneralSessionCreatedAt:date error:nil];
            [[session.startDate.serverTimeOffset should] beNil];
        });
        it(@"Should create new background session with nil server time offset if unavailable", ^{
            AMASession *session = [sessionStorage newBackgroundSessionCreatedAt:date error:nil];
            [[session.startDate.serverTimeOffset should] beNil];
        });
        it(@"Should create new general session with server time offset if it is available", ^{
            configuration.serverTimeOffset = @(444.0);
            AMASession *session = [sessionStorage newGeneralSessionCreatedAt:date error:nil];
            [[session.startDate.serverTimeOffset should] equal:@444];
        });
        it(@"Should create new background session with server time offset if it is available", ^{
            configuration.serverTimeOffset = @(-1.34);
            AMASession *session = [sessionStorage newBackgroundSessionCreatedAt:date error:nil];
            [[session.startDate.serverTimeOffset should] equal:@-1.34];
        });
    });
    context(@"Sets correct session_id tests", ^{
        NSNumber *newSessionID = [NSNumber numberWithUnsignedLongLong:1010101010];

        beforeEach(^{
            clearAndStart();
            [stateStorage.sessionIDStorage stub:@selector(nextInStorage:rollback:error:) andReturn:newSessionID];
        });
        it(@"Should set correct session_id for the new session", ^{
            AMASession *session = [sessionStorage newBackgroundSessionCreatedAt:[NSDate date] error:nil];
            [[session.sessionID should] equal:theValue(newSessionID.unsignedLongLongValue)];
        });
    });
});

SPEC_END
