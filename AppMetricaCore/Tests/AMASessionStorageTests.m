
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaStorageUtils/AppMetricaStorageUtils.h>
#import <AppMetricaPlatform/AppMetricaPlatform.h>
#import "AMASessionStorage.h"
#import "AMAMockDatabase.h"
#import "AMADatabaseConstants.h"
#import "AMASessionSerializer.h"
#import "AMAReporterStateStorage.h"
#import "AMAMetricaConfiguration.h"
#import "AMAStartupParametersConfiguration.h"
#import "AMADate.h"
#import "AMADatabaseHelper.h"
#import "AMAEnvironmentContainer.h"
#import "AMAAppStateManagerTestHelper.h"
#import "AMAApplicationStateManager.h"
#import "AMAMetricaConfigurationTestUtilities.h"
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>

SPEC_BEGIN(AMASessionStorageTests)

describe(@"AMASessionStorage", ^{

    NSDate *const date = [NSDate date];

    AMAAppStateManagerTestHelper *__block stateHelper = nil;
    AMAMockDatabase *__block database = nil;
    AMAEnvironmentContainer *__block eventEnvironment = nil;
    AMASessionSerializer *__block serializer = nil;
    AMAReporterStateStorage *__block stateStorage = nil;
    AMASessionStorage *__block storage = nil;

    beforeEach(^{
        [AMAMetricaConfigurationTestUtilities stubConfigurationWithNullMock];
        stateHelper = [[AMAAppStateManagerTestHelper alloc] init];
        [stateHelper stubApplicationState];

        database = [AMAMockDatabase reporterDatabase];
        serializer = [[AMASessionSerializer alloc] init];
        eventEnvironment = [[AMAEnvironmentContainer alloc] init];
        stateStorage = [[AMAReporterStateStorage alloc] initWithStorageProvider:database.storageProvider
                                                               eventEnvironment:eventEnvironment];
        storage = [[AMASessionStorage alloc] initWithDatabase:database
                                                   serializer:serializer
                                                 stateStorage:stateStorage];
    });

    NSString *(^sid)(AMASession *) = ^(AMASession *session) {
        return [NSString stringWithFormat:@"%@_%@_%@_%@",
                session.oid, session.sessionID, session.finished ? @"F" : @"C",
                session.appState.dictionaryRepresentation];
    };

    context(@"Getters", ^{
        context(@"Empty storage", ^{
            it(@"Should return nil for last session", ^{
                [[[storage lastSessionWithError:nil] should] beNil];
            });
            it(@"Should return nil for last general session", ^{
                [[[storage lastGeneralSessionWithError:nil] should] beNil];
            });
            context(@"Last session with type", ^{
                it(@"Should return nil for last background session", ^{
                    [[[storage lastSessionWithType:AMASessionTypeBackground error:nil] should] beNil];
                });
                it(@"Should return nil for last general session", ^{
                    [[[storage lastSessionWithType:AMASessionTypeGeneral error:nil] should] beNil];
                });
            });
        });
        context(@"Single general session", ^{
            AMASession *__block session = nil;
            beforeEach(^{
                session = [storage newGeneralSessionCreatedAt:date error:nil];
            });
            it(@"Should return valid session for last session", ^{
                [[sid([storage lastSessionWithError:nil]) should] equal:sid(session)];
            });
            it(@"Should return valid last general session", ^{
                [[sid([storage lastGeneralSessionWithError:nil]) should] equal:sid(session)];
            });
            context(@"Last session with type", ^{
                it(@"Should return nil for last background session", ^{
                    [[[storage lastSessionWithType:AMASessionTypeBackground error:nil] should] beNil];
                });
                it(@"Should return valid last general session", ^{
                    [[sid([storage lastSessionWithType:AMASessionTypeGeneral error:nil]) should] equal:sid(session)];
                });
            });
        });
        context(@"Single background session", ^{
            AMASession *__block session = nil;
            beforeEach(^{
                session = [storage newBackgroundSessionCreatedAt:date error:nil];
            });
            it(@"Should return valid session for last session", ^{
                [[sid([storage lastSessionWithError:nil]) should] equal:sid(session)];
            });
            it(@"Should return nol for last general session", ^{
                [[[storage lastGeneralSessionWithError:nil] should] beNil];
            });
            context(@"Last session with type", ^{
                it(@"Should return valid last background session", ^{
                    [[sid([storage lastSessionWithType:AMASessionTypeBackground error:nil]) should] equal:sid(session)];
                });
                it(@"Should return nil for last general session", ^{
                    [[[storage lastSessionWithType:AMASessionTypeGeneral error:nil] should] beNil];
                });
            });
        });
        context(@"Multiple sessions", ^{
            AMASession *__block generalSession = nil;
            AMASession *__block backgroundSession = nil;
            AMASession *__block previousSession = nil;
            AMASession *__block firstSession = nil;
            beforeEach(^{
                firstSession = [storage newBackgroundSessionCreatedAt:date error:nil];
                [storage newGeneralSessionCreatedAt:date error:nil];
                previousSession = [storage newGeneralSessionCreatedAt:date error:nil];
                generalSession = [storage newGeneralSessionCreatedAt:date error:nil];
                backgroundSession = [storage newBackgroundSessionCreatedAt:date error:nil];
            });
            it(@"Should return valid session for last session", ^{
                [[sid([storage lastSessionWithError:nil]) should] equal:sid(backgroundSession)];
            });
            it(@"Should return nol for last general session", ^{
                [[sid([storage lastGeneralSessionWithError:nil]) should] equal:sid(generalSession)];
            });
            context(@"Last session with type", ^{
                it(@"Should return valid last background session", ^{
                    [[sid([storage lastSessionWithType:AMASessionTypeBackground error:nil]) should] equal:sid(backgroundSession)];
                });
                it(@"Should return valid last general session", ^{
                    [[sid([storage lastSessionWithType:AMASessionTypeGeneral error:nil]) should] equal:sid(generalSession)];
                });
            });
            context(@"Previous", ^{
                it(@"Should return valid previous session for last session", ^{
                    [[sid([storage previousSessionForSession:backgroundSession error:nil]) should] equal:sid(generalSession)];
                });
                it(@"Should return valid previous session for previous session", ^{
                    [[sid([storage previousSessionForSession:generalSession error:nil]) should] equal:sid(previousSession)];
                });
                it(@"Should return nil for previous session for the first session", ^{
                    [[[storage previousSessionForSession:firstSession error:nil] should] beNil];
                });
                it(@"Should return nil for nil previous session", ^{
                    [[[storage previousSessionForSession:nil error:nil] should] beNil];
                });
            });
        });
    });

    context(@"Session creation", ^{
        NSNumber *const sessionID = @23;
        NSNumber *const attributionID = @42;
        NSNumber *const serverTimeOffset = @108;

        AMAApplicationState *__block appState = nil;
        AMASession *__block session = nil;

        beforeEach(^{
            [stateHelper stubApplicationState];
            appState = AMAApplicationStateManager.applicationState;

            [database.storageProvider.syncStorage saveLongLongNumber:@(sessionID.integerValue - 1)
                                                              forKey:@"session.id"
                                                               error:nil];
            [database.storageProvider.syncStorage saveLongLongNumber:attributionID
                                                              forKey:@"attribution.id"
                                                               error:nil];
            [[AMAMetricaConfiguration sharedInstance].startup stub:@selector(serverTimeOffset)
                                                         andReturn:serverTimeOffset];
        });

        context(@"General", ^{
            beforeEach(^{
                [storage newGeneralSessionCreatedAt:date error:nil];
                session = [storage lastSessionWithError:nil];
            });
            it(@"Should have valid type", ^{
                [[theValue(session.type) should] equal:theValue(AMASessionTypeGeneral)];
            });
            it(@"Should not be finished", ^{
                [[theValue(session.finished) should] beNo];
            });
            it(@"Should have valid session ID", ^{
                [[session.sessionID should] equal:sessionID];
            });
            it(@"Should have valid attribution ID", ^{
                [[session.attributionID should] equal:[attributionID stringValue]];
            });
            it(@"Should have valid start date", ^{
                [[session.startDate.deviceDate should] equal:date];
            });
            it(@"Should have valid server time offset", ^{
                [[session.startDate.serverTimeOffset should] equal:serverTimeOffset];
            });
            it(@"Should have no last event date", ^{
                [[session.lastEventTime should] beNil];
            });
            it(@"Should have valid pause date", ^{
                [[session.pauseTime should] equal:date];
            });
            it(@"Should have valid app state", ^{
                [[session.appState should] equal:appState];
            });
        });
        context(@"Background", ^{
            beforeEach(^{
                [storage newBackgroundSessionCreatedAt:date error:nil];
                session = [storage lastSessionWithError:nil];
            });
            it(@"Should have valid type", ^{
                [[theValue(session.type) should] equal:theValue(AMASessionTypeBackground)];
            });
            it(@"Should not be finished", ^{
                [[theValue(session.finished) should] beNo];
            });
            it(@"Should have valid session ID", ^{
                [[session.sessionID should] equal:sessionID];
            });
            it(@"Should have valid attribution ID", ^{
                [[session.attributionID should] equal:[attributionID stringValue]];
            });
            it(@"Should have valid start date", ^{
                [[session.startDate.deviceDate should] equal:date];
            });
            it(@"Should have valid server time offset", ^{
                [[session.startDate.serverTimeOffset should] equal:serverTimeOffset];
            });
            it(@"Should have no last event date", ^{
                [[session.lastEventTime should] beNil];
            });
            it(@"Should have valid pause date", ^{
                [[session.pauseTime should] equal:date];
            });
            it(@"Should have valid app state", ^{
                [[session.appState should] equal:appState];
            });
        });
        context(@"Finished background session", ^{
            beforeEach(^{
                appState = [appState copyWithNewAppVersion:@"ANOTHER" appBuildNumber:@"123"];
                [storage newFinishedBackgroundSessionCreatedAt:date appState:appState error:nil];
                session = [storage lastSessionWithError:nil];
            });
            it(@"Should have valid type", ^{
                [[theValue(session.type) should] equal:theValue(AMASessionTypeBackground)];
            });
            it(@"Should be finished", ^{
                [[theValue(session.finished) should] beYes];
            });
            it(@"Should have valid session ID", ^{
                [[session.sessionID should] equal:sessionID];
            });
            it(@"Should have valid attribution ID", ^{
                [[session.attributionID should] equal:[attributionID stringValue]];
            });
            it(@"Should have valid start date", ^{
                [[session.startDate.deviceDate should] equal:date];
            });
            it(@"Should have valid server time offset", ^{
                [[session.startDate.serverTimeOffset should] equal:serverTimeOffset];
            });
            it(@"Should have no last event date", ^{
                [[session.lastEventTime should] beNil];
            });
            it(@"Should have valid pause date", ^{
                [[session.pauseTime should] equal:date];
            });
            it(@"Should have valid app state", ^{
                [[session.appState should] equal:appState];
            });
        });
        context(@"Next attribution ID", ^{
            beforeEach(^{
                [storage newSessionWithNextAttributionIDCreatedAt:date type:AMASessionTypeGeneral error:nil];
                session = [storage lastSessionWithError:nil];
            });
            it(@"Should have valid type", ^{
                [[theValue(session.type) should] equal:theValue(AMASessionTypeGeneral)];
            });
            it(@"Should not be finished", ^{
                [[theValue(session.finished) should] beNo];
            });
            it(@"Should have valid session ID", ^{
                [[session.sessionID should] equal:sessionID];
            });
            it(@"Should have valid attribution ID", ^{
                [[session.attributionID should] equal:[@(attributionID.integerValue + 1) stringValue]];
            });
            it(@"Should have valid start date", ^{
                [[session.startDate.deviceDate should] equal:date];
            });
            it(@"Should have valid server time offset", ^{
                [[session.startDate.serverTimeOffset should] equal:serverTimeOffset];
            });
            it(@"Should have no last event date", ^{
                [[session.lastEventTime should] beNil];
            });
            it(@"Should have valid pause date", ^{
                [[session.pauseTime should] equal:date];
            });
            it(@"Should have valid app state", ^{
                [[session.appState should] equal:appState];
            });
        });
        context(@"Save session as last", ^{
            AMASession *__block previousSession = nil;
            beforeEach(^{
                [storage newGeneralSessionCreatedAt:date error:nil];
                session = [storage lastSessionWithError:nil];
                [storage saveSessionAsLastSession:session error:nil];
                session = [storage lastSessionWithError:nil];
                previousSession = [storage previousSessionForSession:session error:nil];
            });
            context(@"Old session", ^{
                beforeEach(^{
                    session = previousSession;
                });
                it(@"Should have valid type", ^{
                    [[theValue(session.type) should] equal:theValue(AMASessionTypeGeneral)];
                });
                it(@"Should be finished", ^{
                    [[theValue(session.finished) should] beYes];
                });
                it(@"Should have valid session ID", ^{
                    [[session.sessionID should] equal:sessionID];
                });
                it(@"Should have valid attribution ID", ^{
                    [[session.attributionID should] equal:[attributionID stringValue]];
                });
                it(@"Should have valid start date", ^{
                    [[session.startDate.deviceDate should] equal:date];
                });
                it(@"Should have valid server time offset", ^{
                    [[session.startDate.serverTimeOffset should] equal:serverTimeOffset];
                });
                it(@"Should have no last event date", ^{
                    [[session.lastEventTime should] beNil];
                });
                it(@"Should have valid pause date", ^{
                    [[session.pauseTime should] equal:date];
                });
                it(@"Should have valid app state", ^{
                    [[session.appState should] equal:appState];
                });
            });
            context(@"New session", ^{
                it(@"Should have valid type", ^{
                    [[theValue(session.type) should] equal:theValue(AMASessionTypeGeneral)];
                });
                it(@"Should not be finished", ^{
                    [[theValue(session.finished) should] beNo];
                });
                it(@"Should have valid session ID", ^{
                    [[session.sessionID should] equal:sessionID];
                });
                it(@"Should have valid attribution ID", ^{
                    [[session.attributionID should] equal:[attributionID stringValue]];
                });
                it(@"Should have valid start date", ^{
                    [[session.startDate.deviceDate should] equal:date];
                });
                it(@"Should have valid server time offset", ^{
                    [[session.startDate.serverTimeOffset should] equal:serverTimeOffset];
                });
                it(@"Should have no last event date", ^{
                    [[session.lastEventTime should] beNil];
                });
                it(@"Should have valid pause date", ^{
                    [[session.pauseTime should] equal:date];
                });
                it(@"Should have valid app state", ^{
                    [[session.appState should] equal:appState];
                });
            });
        });
        context(@"Updates", ^{
            beforeEach(^{
                [storage newGeneralSessionCreatedAt:date error:nil];
                session = [storage lastSessionWithError:nil];
            });
            context(@"Pause time", ^{
                NSDate *__block pauseTime = [NSDate date];
                beforeEach(^{
                    [storage updateSession:session pauseTime:pauseTime error:nil];
                    session = [storage lastSessionWithError:nil];
                });
                it(@"Should have valid type", ^{
                    [[theValue(session.type) should] equal:theValue(AMASessionTypeGeneral)];
                });
                it(@"Should not be finished", ^{
                    [[theValue(session.finished) should] beNo];
                });
                it(@"Should have valid session ID", ^{
                    [[session.sessionID should] equal:sessionID];
                });
                it(@"Should have valid attribution ID", ^{
                    [[session.attributionID should] equal:[attributionID stringValue]];
                });
                it(@"Should have valid start date", ^{
                    [[session.startDate.deviceDate should] equal:date];
                });
                it(@"Should have valid server time offset", ^{
                    [[session.startDate.serverTimeOffset should] equal:serverTimeOffset];
                });
                it(@"Should have no last event date", ^{
                    [[session.lastEventTime should] beNil];
                });
                it(@"Should have valid pause date", ^{
                    [[session.pauseTime should] equal:pauseTime];
                });
                it(@"Should have valid app state", ^{
                    [[session.appState should] equal:appState];
                });
            });
            context(@"Finish", ^{
                context(@"With date", ^{
                    NSDate *__block finishTime = [NSDate date];
                    beforeEach(^{
                        [storage finishSession:session atDate:finishTime error:nil];
                        session = [storage lastSessionWithError:nil];
                    });
                    it(@"Should have valid type", ^{
                        [[theValue(session.type) should] equal:theValue(AMASessionTypeGeneral)];
                    });
                    it(@"Should be finished", ^{
                        [[theValue(session.finished) should] beYes];
                    });
                    it(@"Should have valid session ID", ^{
                        [[session.sessionID should] equal:sessionID];
                    });
                    it(@"Should have valid attribution ID", ^{
                        [[session.attributionID should] equal:[attributionID stringValue]];
                    });
                    it(@"Should have valid start date", ^{
                        [[session.startDate.deviceDate should] equal:date];
                    });
                    it(@"Should have valid server time offset", ^{
                        [[session.startDate.serverTimeOffset should] equal:serverTimeOffset];
                    });
                    it(@"Should have no last event date", ^{
                        [[session.lastEventTime should] beNil];
                    });
                    it(@"Should have valid pause date", ^{
                        [[session.pauseTime should] equal:finishTime];
                    });
                    it(@"Should have valid app state", ^{
                        [[session.appState should] equal:appState];
                    });
                });
                context(@"Without date", ^{
                    beforeEach(^{
                        [storage finishSession:session atDate:nil error:nil];
                        session = [storage lastSessionWithError:nil];
                    });
                    it(@"Should have valid type", ^{
                        [[theValue(session.type) should] equal:theValue(AMASessionTypeGeneral)];
                    });
                    it(@"Should be finished", ^{
                        [[theValue(session.finished) should] beYes];
                    });
                    it(@"Should have valid session ID", ^{
                        [[session.sessionID should] equal:sessionID];
                    });
                    it(@"Should have valid attribution ID", ^{
                        [[session.attributionID should] equal:[attributionID stringValue]];
                    });
                    it(@"Should have valid start date", ^{
                        [[session.startDate.deviceDate should] equal:date];
                    });
                    it(@"Should have valid server time offset", ^{
                        [[session.startDate.serverTimeOffset should] equal:serverTimeOffset];
                    });
                    it(@"Should have no last event date", ^{
                        [[session.lastEventTime should] beNil];
                    });
                    it(@"Should have valid pause date", ^{
                        [[session.pauseTime should] equal:date];
                    });
                    it(@"Should have valid app state", ^{
                        [[session.appState should] equal:appState];
                    });
                });
                context(@"App state", ^{
                    NSString *newIDFA = @"3264429A-3997-4786-AC2A-1790482363BC";
                    AMAMutableApplicationState *newState = [[AMAApplicationStateManager applicationState] mutableCopy];
                    newState.IFA = newIDFA;
                    
                    beforeEach(^{
                        NSError *error = nil;
                        BOOL result = [storage updateSession:session appState:newState error:&error];
                        [[error should] beNil];
                        [[theValue(result) should] equal:theValue(YES)];
                        
                        session = [storage lastSessionWithError:nil];
                    });
                    
                    it(@"should update IDFA", ^{
                        [[session.appState should] equal:newState];
                        [[session.appState.IFA should] equal:newIDFA];
                    });
                });
            });
        });
        context(@"Error", ^{
            NSError *const expectedError = [NSError errorWithDomain:@"DOMAIN" code:23 userInfo:nil];
            context(@"Session ID", ^{
                beforeEach(^{
                    [stateStorage.sessionIDStorage stub:@selector(nextInStorage:rollback:error:) withBlock:^id(NSArray *params) {
                        [AMATestUtilities fillObjectPointerParameter:params[2] withValue:expectedError];
                        AMARollbackHolder *rollbackHolder = params[1];
                        rollbackHolder.rollback = YES;
                        return nil;
                    }];
                });
                it(@"Should be nil", ^{
                    session = [storage newGeneralSessionCreatedAt:date error:nil];
                    [[session should] beNil];
                });
                it(@"Should not create session in DB", ^{
                    [storage newGeneralSessionCreatedAt:date error:nil];
                    session = [storage lastSessionWithError:nil];
                    [[session should] beNil];
                });
                it(@"Should not update session ID in database", ^{
                    [[[database.storageProvider.syncStorage longLongNumberForKey:@"session.id" error:nil] should] equal:@(sessionID.integerValue - 1)];
                });
                it(@"Should not update attribution ID in database", ^{
                    [[[database.storageProvider.syncStorage longLongNumberForKey:@"attribution.id" error:nil] should] equal:attributionID];
                });
                it(@"Should fill error", ^{
                    NSError *error = nil;
                    [storage newGeneralSessionCreatedAt:date error:&error];
                    [[error should] equal:expectedError];
                });
            });
            context(@"Attribution ID", ^{
                beforeEach(^{
                    [stateStorage.attributionIDStorage stub:@selector(nextInStorage:rollback:error:) withBlock:^id(NSArray *params) {
                        [AMATestUtilities fillObjectPointerParameter:params[2] withValue:expectedError];
                        AMARollbackHolder *rollbackHolder = params[1];
                        rollbackHolder.rollback = YES;
                        return nil;
                    }];
                });
                it(@"Should be nil", ^{
                    session = [storage newSessionWithNextAttributionIDCreatedAt:date type:AMASessionTypeGeneral error:nil];
                    [[session should] beNil];
                });
                it(@"Should not create session in DB", ^{
                    [storage newSessionWithNextAttributionIDCreatedAt:date type:AMASessionTypeGeneral error:nil];
                    session = [storage lastSessionWithError:nil];
                    [[session should] beNil];
                });
                it(@"Should not update session ID in database", ^{
                    [[[database.storageProvider.syncStorage longLongNumberForKey:@"session.id" error:nil] should] equal:@(sessionID.integerValue - 1)];
                });
                it(@"Should not update attribution ID in database", ^{
                    [[[database.storageProvider.syncStorage longLongNumberForKey:@"attribution.id" error:nil] should] equal:attributionID];
                });
                it(@"Should fill error", ^{
                    NSError *error = nil;
                    [storage newSessionWithNextAttributionIDCreatedAt:date type:AMASessionTypeGeneral error:&error];
                    [[error should] equal:expectedError];
                });
            });
            context(@"Session insert", ^{
                beforeEach(^{
                    [AMADatabaseHelper stub:@selector(insertRowWithDictionary:tableName:db:error:) withBlock:^id(NSArray *params) {
                        [AMATestUtilities fillObjectPointerParameter:params[3] withValue:expectedError];
                        return nil;
                    }];
                });
                it(@"Should be nil", ^{
                    session = [storage newSessionWithNextAttributionIDCreatedAt:date type:AMASessionTypeGeneral error:nil];
                    [[session should] beNil];
                });
                it(@"Should not create session in DB", ^{
                    [storage newSessionWithNextAttributionIDCreatedAt:date type:AMASessionTypeGeneral error:nil];
                    session = [storage lastSessionWithError:nil];
                    [[session should] beNil];
                });
                it(@"Should not update session ID in database", ^{
                    [[[database.storageProvider.syncStorage longLongNumberForKey:@"session.id" error:nil] should] equal:@(sessionID.integerValue - 1)];
                });
                it(@"Should not update attribution ID in database", ^{
                    [[[database.storageProvider.syncStorage longLongNumberForKey:@"attribution.id" error:nil] should] equal:attributionID];
                });
                it(@"Should fill error", ^{
                    NSError *error = nil;
                    [storage newSessionWithNextAttributionIDCreatedAt:date type:AMASessionTypeGeneral error:&error];
                    [[error should] equal:expectedError];
                });
            });
        });
    });

});

SPEC_END

