
#import <Kiwi/Kiwi.h>
#import <AppMetricaWebKit/AppMetricaWebKit.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMAAppMetricaImpl+TestUtilities.h"
#import "AMAAppMetricaImplTestFactory.h"
#import "AMADispatcher.h"
#import "AMADispatchingController.h"
#import "AMADispatchStrategiesContainer.h"
#import "AMADispatchStrategy+Private.h"
#import "AMAEventCountDispatchStrategy.h"
#import "AMATimerDispatchStrategy.h"
#import "AMAAppMetrica.h"
#import "AMAReporter.h"
#import "AMAReporterStorage.h"
#import "AMAReporterStateStorage.h"
#import "AMAEvent.h"
#import "AMAStringEventValue.h"
#import "AMAEventBuilder.h"
#import "AMAReporterTestHelper.h"
#import "AMAReporterConfiguration.h"
#import "AMASessionStorage.h"
#import "AMAAppMetrica+Internal.h"
#import "AMAErrorsFactory.h"
#import "AMAAppMetrica+TestUtilities.h"
#import "AMADispatchStrategyMask.h"
#import "AMAMetricaConfigurationTestUtilities.h"
#import "AMAEventStorage+TestUtilities.h"
#import "AMAEnvironmentContainer.h"
#import "AMAAppMetricaPreloadInfo.h"
#import "AMAAppMetricaPreloadInfo+AMAInternal.h"
#import "AMAStubHostAppStateProvider.h"
#import "AMAInternalEventsReporter.h"
#import "AMAUserProfile.h"
#import "AMAProfileAttribute.h"
#import "AMARevenueInfo.h"
#import "AMAAppMetricaConfiguration+Extended.h"
#import "AMAStartupController.h"
#import "AMAPermissionsController.h"
#import "AMAExtensionsReportController.h"
#import "AMAInternalStateReportingController.h"
#import "AMAAppOpenWatcher.h"
#import "AMAAutoPurchasesWatcher.h"
#import "AMAAdServicesReportingController.h"
#import "AMALocationManager.h"
#import "AMAAttributionController.h"
#import "AMADeepLinkController.h"
#import "AMAPluginErrorDetails.h"
#import "AMAAdRevenueInfo.h"

static NSString *const kAMAEnvironmentTestKey = @"TestEnvironmentKey";
static NSString *const kAMAEnvironmentTestValue = @"TestEnvironmentValue";

SPEC_BEGIN(AMAAppMetricaImplTests)

describe(@"AMAAppMetricaImpl", ^{
    AMAAppMetricaConfiguration *__block configuration = nil;
    NSString *apiKey = @"550e8400-e29b-41d4-a716-446655440000";

    AMAReporterTestHelper *__block reporterTestHelper = nil;
    AMAEventStorage *__block eventStorage = nil;
    AMAAppMetricaImpl * __block appMetricaImpl = nil;
    AMAStubHostAppStateProvider * __block hostStateProvider = nil;
    AMAStartupController *__block startupController = nil;
    AMAPermissionsController *__block permissionsController = nil;
    AMAExtensionsReportController *__block extensionsReportController = nil;
    AMADispatchStrategiesContainer *__block dispatchStrategiesContainer = nil;
    AMAInternalStateReportingController *__block stateReportingController = nil;
    AMAAppOpenWatcher *__block appOpenWatcher = nil;
    AMAAdServicesReportingController *__block adServicesReportingController = nil;
    AMAAutoPurchasesWatcher *__block autoPurchasesWatcher = nil;
    AMAJSController *__block jsController = nil;
    AMADispatchingController *__block dispatchingController = nil;
    AMADeepLinkController *__block deeplinkController = nil;
    AMAInternalEventsReporter *__block internalEventsReporter = nil;

    beforeEach(^{
        [AMALocationManager stub:@selector(sharedManager)];
        configuration = [AMAAppMetricaConfiguration nullMock];
        [configuration stub:@selector(apiKey) andReturn:apiKey];
        startupController = [AMAStartupController stubbedNullMockForInit:@selector(initWithTimeoutRequestsController:)];
        permissionsController = [AMAPermissionsController stubbedNullMockForInit:@selector(initWithConfiguration:
                                                                                           extrcator:
                                                                                           dateProvider:)];
        extensionsReportController = [AMAExtensionsReportController stubbedNullMockForInit:@selector(initWithReporter:
                                                                                                     conditionProvider:
                                                                                                     provider:
                                                                                                     executor:)];
        dispatchStrategiesContainer = [AMADispatchStrategiesContainer stubbedNullMockForDefaultInit];
        stateReportingController = [AMAInternalStateReportingController stubbedNullMockForInit:@selector(initWithExecutor:)];
        
        appOpenWatcher = [AMAAppOpenWatcher stubbedNullMockForDefaultInit];
        autoPurchasesWatcher = [AMAAutoPurchasesWatcher stubbedNullMockForInit:@selector(initWithExecutor:)];
        deeplinkController = [AMADeepLinkController stubbedNullMockForInit:@selector(initWithReporter:executor:)];
        adServicesReportingController = [AMAAdServicesReportingController stubbedNullMockForInit:@selector(initWithApiKey:
                                                                                                           reporterStateStorage:)];
        jsController = [AMAJSController stubbedNullMockForInit:@selector(initWithUserContentController:)];
        dispatchingController = [AMADispatchingController stubbedNullMockForInit:@selector(initWithTimeoutConfiguration:)];
        internalEventsReporter = [AMAInternalEventsReporter nullMock];

        hostStateProvider = [AMAStubHostAppStateProvider new];
        hostStateProvider.hostState = AMAHostAppStateBackground;

        [AMAMetricaConfigurationTestUtilities stubConfigurationWithAppVersion:@"1.00"
                                                                  buildNumber:100];
        reporterTestHelper = [[AMAReporterTestHelper alloc] init];
        eventStorage = [reporterTestHelper appReporterForApiKey:apiKey].reporterStorage.eventStorage;
        appMetricaImpl =
        [AMAAppMetricaImplTestFactory createCurrentQueueImplWithReporterHelper:reporterTestHelper
                                                             hostStateProvider:hostStateProvider];
        [AMAAppMetrica stub:@selector(sharedImpl) andReturn:appMetricaImpl];
        
        id<AMAExecuting>executor = [AMACurrentQueueExecutor new];
        [AMAAppMetrica stub:@selector(sharedExecutor) andReturn:executor];
        [AMAAppMetrica stub:@selector(sharedInternalEventsReporter) andReturn:internalEventsReporter];
    });
    afterEach(^{
        appMetricaImpl = nil;
    });

    context(@"Database recovery event", ^{
        AMAInternalEventsReporter *__block reporter = nil;
        void (^stubConfiguration)(NSString *) = ^ void (NSString *inconsistencyData) {
            [[AMAMetricaConfiguration sharedInstance] stub:@selector(detectedInconsistencyDescription)
                                                 andReturn:inconsistencyData];
        };
        beforeEach(^{
            reporter = [AMAInternalEventsReporter nullMock];
            [AMAAppMetrica stub:@selector(sharedInternalEventsReporter) andReturn:reporter];
        });

        it(@"Should report event to database if inconsistency detected", ^{
            NSString *inconsistancyDescription = @"schema";
            stubConfiguration(inconsistancyDescription);
            [[reporter should] receive:@selector(reportSchemaInconsistencyWithDescription:)
                         withArguments:inconsistancyDescription];
            [appMetricaImpl reportDatabaseInconsistencyStateIfNeeded];
        });

        it(@"Should report event to database if inconsistency not detected", ^{
            NSString *inconsistancyDescription = @"";
            stubConfiguration(inconsistancyDescription);
            [[reporter shouldNot] receive:@selector(reportSchemaInconsistencyWithDescription:)
                            withArguments:inconsistancyDescription];
            [appMetricaImpl reportDatabaseInconsistencyStateIfNeeded];
        });

        it(@"Should call reportDatabaseInconsistencyStateIfNeeded on start ", ^{
            [appMetricaImpl stub:NSSelectorFromString(@"startReporter")];
            [[appMetricaImpl should] receive:@selector(reportDatabaseInconsistencyStateIfNeeded)];
            [appMetricaImpl start];
        });
    });

    context(@"Settings app environment", ^{
        __block AMAAppMetricaImpl *impl;

        AMAEnvironmentContainer *(^appEnvironment)(void) = ^{
            return [reporterTestHelper appReporterForApiKey:apiKey].reporterStorage.stateStorage.appEnvironment;
        };

        beforeEach(^{
            impl = [AMAAppMetricaImplTestFactory createCurrentQueueImplWithReporterHelper:reporterTestHelper
                                                                        hostStateProvider:hostStateProvider];
        });
        it(@"Should set app environment before metrica activation", ^{
            [impl setAppEnvironmentValue:@"foo" forKey:@"bar"];
            [impl activateWithConfiguration:configuration];
            [[appEnvironment().dictionaryEnvironment[@"bar"] should] equal:@"foo"];
        });
        it(@"Should clean app environment before metrica activation", ^{
            [impl setAppEnvironmentValue:@"foo" forKey:@"bar"];
            [impl clearAppEnvironment];
            [impl activateWithConfiguration:configuration];
            [[appEnvironment().dictionaryEnvironment should] haveCountOf:0];
        });
    });
    context(@"Setting user profile ID", ^{
        NSString *profileIDBeforeActivation = @"Profile ID before activation";
        NSString *profileIDDuringActivation = @"Profile ID during activation";
        __block AMAAppMetricaImpl *impl;

        beforeEach(^{
            impl = [AMAAppMetricaImplTestFactory createCurrentQueueImplWithReporterHelper:reporterTestHelper
                                                                        hostStateProvider:hostStateProvider];
        });
        context(@"Main API Key", ^{
            NSString *(^resultProfileID)(void) = ^{
                return [reporterTestHelper appReporterForApiKey:apiKey].reporterStorage.stateStorage.profileID;
            };
            it(@"Set only before activation", ^{
                [impl setUserProfileID:profileIDBeforeActivation];
                [impl activateWithConfiguration:configuration];
                [[resultProfileID() should] equal:profileIDBeforeActivation];
            });
            it(@"Set only during activation", ^{
                [configuration stub:@selector(userProfileID) andReturn:profileIDDuringActivation];
                [impl activateWithConfiguration:configuration];
                [[resultProfileID() should] equal:profileIDDuringActivation];
            });
            it(@"Set before and during activation", ^{
                [impl setUserProfileID:profileIDBeforeActivation];
                [configuration stub:@selector(userProfileID) andReturn:profileIDDuringActivation];
                [impl activateWithConfiguration:configuration];
                [[resultProfileID() should] equal:profileIDDuringActivation];
            });
        });
        context(@"Manual reporter", ^{
            NSString *differentApiKey = @"f3f8bafd-b9c2-47e5-8065-fec0f54b67d2";
            NSString *(^resultProfileID)(void) = ^{
                return [reporterTestHelper appReporterForApiKey:differentApiKey].reporterStorage.stateStorage.profileID;
            };

            it(@"Set only before activation", ^{
                [impl setUserProfileID:profileIDBeforeActivation];
                [impl manualReporterForConfiguration:[[AMAReporterConfiguration alloc] initWithApiKey:differentApiKey]];
                [[resultProfileID() should] beNil];
            });
            it(@"Set only during activation", ^{
                AMAMutableReporterConfiguration *reporterConfig = [[AMAMutableReporterConfiguration alloc] initWithApiKey:differentApiKey];
                reporterConfig.userProfileID = profileIDDuringActivation;
                [impl manualReporterForConfiguration:reporterConfig];
                [[resultProfileID() should] equal:profileIDDuringActivation];
            });
            it(@"Set before and during activation", ^{
                [impl setUserProfileID:profileIDBeforeActivation];
                AMAMutableReporterConfiguration *reporterConfig = [[AMAMutableReporterConfiguration alloc] initWithApiKey:differentApiKey];
                reporterConfig.userProfileID = profileIDDuringActivation;
                [impl manualReporterForConfiguration:reporterConfig];
                [[resultProfileID() should] equal:profileIDDuringActivation];
            });
        });
    });

    context(@"Starting AppMetrica on internal queue", ^{
        NSString *differentApiKey = @"f3f8bafd-b9c2-47e5-8065-fec0f54b67d2";
        it(@"Should not access storage on current queue", ^{
            id<AMACancelableExecuting> executor = [AMAManualCurrentQueueExecutor new];
            [reporterTestHelper appReporterForApiKey:differentApiKey main:YES executor:executor inMemory:YES preloadInfo:nil attributionCheckExecutor:nil];
            AMAAppMetricaImpl *impl = [AMAAppMetricaImplTestFactory createNoQueueImplWithReporterHelper:reporterTestHelper];
            [[[AMAMetricaConfiguration sharedInstance] shouldNot] receive:@selector(persistent)];
            [configuration stub:@selector(apiKey) andReturn:differentApiKey];
            [impl activateWithConfiguration:configuration];
        });
    });

    context(@"Main reporter is set to AttributionController", ^{
        AMAAttributionController *__block controller = nil;
        beforeEach(^{
            controller = [AMAAttributionController nullMock];
            [AMAAttributionController stub:@selector(sharedInstance) andReturn:controller];
        });
        it(@"Should set main reporter", ^{
            KWCaptureSpy *reporterCaptor = [controller captureArgument:@selector(setMainReporter:) atIndex:0];
            [appMetricaImpl activateWithConfiguration:configuration];
            [reporterCaptor.argument shouldNotBeNil];
        });
        it(@"Should not set manual reporter", ^{
            NSString *differentApiKey = @"220e8400-e29b-41d4-a716-446655440022";
            [[controller shouldNot] receive:@selector(setMainReporter:)];
            [appMetricaImpl manualReporterForConfiguration:[[AMAReporterConfiguration alloc] initWithApiKey:differentApiKey]];
        });
    });

    context(@"AppWatcher watching", ^{
        it(@"Should start if enabled", ^{
            [configuration stub:@selector(appOpenTrackingEnabled) andReturn:theValue(YES)];
            [[appOpenWatcher should] receive:@selector(startWatchingWithDeeplinkController:) withArguments:deeplinkController];
            [appMetricaImpl activateWithConfiguration:configuration];
        });
        it(@"Should not start if disabled", ^{
            [configuration stub:@selector(appOpenTrackingEnabled) andReturn:theValue(NO)];
            [[appOpenWatcher shouldNot] receive:@selector(startWatchingWithDeeplinkController:)];
            [appMetricaImpl activateWithConfiguration:configuration];
        });
    });

    context(@"InAppWatcher watching", ^{
        it(@"Should start watching on activate if enabled", ^{
            [configuration stub:@selector(revenueAutoTrackingEnabled) andReturn:theValue(YES)];
            KWCaptureSpy *reporterCaptor = [autoPurchasesWatcher captureArgument:@selector(startWatchingWithReporter:) atIndex:0];
            [[autoPurchasesWatcher should] receive:@selector(startWatchingWithReporter:)];
            [appMetricaImpl activateWithConfiguration:configuration];
            [reporterCaptor.argument shouldNotBeNil];
        });
        it(@"Should not start watching on activate if disabled", ^{
            [configuration stub:@selector(revenueAutoTrackingEnabled) andReturn:theValue(NO)];
            [[autoPurchasesWatcher shouldNot] receive:@selector(startWatchingWithReporter:)];
            [appMetricaImpl activateWithConfiguration:configuration];
        });
    });

    context(@"Sends PROFILE events", ^{
        it(@"Should save PROFILE event", ^{
            [appMetricaImpl activateWithConfiguration:configuration];
            AMAMutableUserProfile *profile = [[AMAMutableUserProfile alloc] init];
            [profile apply:[[AMAProfileAttribute customString:@"key"] withValue:@"value"]];
            [appMetricaImpl reportUserProfile:[profile copy] onFailure:nil];

            AMAEvent *event = [eventStorage amatest_savedEventWithType:AMAEventTypeProfile];
            [[event shouldNot] beNil];
        });
    });

    context(@"Sends REVENUE events", ^{
        it(@"Should save REVENUE event", ^{
            [appMetricaImpl activateWithConfiguration:configuration];
            AMARevenueInfo *revenueInfo = [[AMARevenueInfo alloc] initWithPriceDecimal:[NSDecimalNumber one]
                                                                              currency:@"USD"];
            [appMetricaImpl reportRevenue:revenueInfo onFailure:nil];

            AMAEvent *event = [eventStorage amatest_savedEventWithType:AMAEventTypeRevenue];
            [[event shouldNot] beNil];
        });
    });
    context(@"Sends AD_REVENUE events", ^{
        it(@"Should save AD_REVENUE event", ^{
            [appMetricaImpl activateWithConfiguration:configuration];
            AMAAdRevenueInfo *adRevenueInfo = [[AMAAdRevenueInfo alloc] initWithAdRevenue:[NSDecimalNumber one]
                                                                              currency:@"USD"];

            [[appMetricaImpl.reporter should] receive:@selector(reportAdRevenue:onFailure:)];
            [appMetricaImpl reportAdRevenue:adRevenueInfo onFailure:nil];
        });
    });

    context(@"Init web view reporting", ^{
        it(@"Should init web view reporting", ^{
            WKUserContentController *controller = [WKUserContentController nullMock];
            [appMetricaImpl activateWithConfiguration:configuration];

            [[jsController should] receive:@selector(setUpWebViewReporting:withReporter:)
                             withArguments:appMetricaImpl.executor, appMetricaImpl.reporter];

            [appMetricaImpl setupWebViewReporting:jsController];
        });
    });

    context(@"Sends events with custom EventType", ^{
        NSUInteger const eventType = 1234;
        it(@"Should save event with custom EventType", ^{
            [appMetricaImpl activateWithConfiguration:configuration];
            [appMetricaImpl reportEventWithType:eventType name:@"" value:@"" environment:@{} extras:nil onFailure:nil];

            AMAEvent *event = [eventStorage amatest_savedEventWithType:eventType];
            [[event shouldNot] beNil];
        });
    });

    context(@"On set api key", ^{
        beforeEach(^{
            reporterTestHelper = [[AMAReporterTestHelper alloc] init];
            eventStorage = nil;
            appMetricaImpl =
            [AMAAppMetricaImplTestFactory createCurrentQueueImplWithReporterHelper:reporterTestHelper
                                                                 hostStateProvider:hostStateProvider];
            [AMAAppMetrica stub:@selector(sharedImpl) andReturn:appMetricaImpl];
        });

        AMAEventStorage *(^dynamicEventStorage)(void) = ^{
            return [reporterTestHelper appReporterForApiKey:apiKey].reporterStorage.eventStorage;
        };

        if (@available(iOS 14.3, *)) {
            it(@"Should report ASA token for main reporter", ^{
                [[adServicesReportingController should] receive:@selector(reportTokenIfNeeded)];
                [appMetricaImpl activateWithConfiguration:configuration];
            });
        }

        it(@"Should fill value of EVENT_FIRST from preload info for main reporter", ^{
            AMAAppMetricaPreloadInfo *info = [[AMAAppMetricaPreloadInfo alloc] initWithTrackingIdentifier:@"foo"];
            [appMetricaImpl setPreloadInfo:info];
            [appMetricaImpl activateWithConfiguration:configuration];

            AMAEvent *event = [dynamicEventStorage() amatest_savedEventWithType:AMAEventTypeFirst];
            AMAStringEventValue *eventValue = (AMAStringEventValue *)event.value;
            NSDictionary *eventObject = [AMAJSONSerialization dictionaryWithJSONString:eventValue.value
                                                                                 error:nil];
            [[eventObject should] equal:info.preloadInfoJSONObject];
        });
        it(@"Should not fill value for EVENT_FIRST if preload info is empty", ^{
            [appMetricaImpl setPreloadInfo:nil];
            [appMetricaImpl activateWithConfiguration:configuration];

            AMAEvent *event = [dynamicEventStorage() amatest_savedEventWithType:AMAEventTypeFirst];
            [[((NSObject *)event.value) should] beNil];
        });
        it(@"Should create EVENT_FIRST as first event with background host state", ^{
            [appMetricaImpl setPreloadInfo:nil];
            [appMetricaImpl activateWithConfiguration:configuration];

            AMAEvent *event = [dynamicEventStorage() amatest_savedEventWithType:AMAEventTypeFirst];
            [[event.oid should] equal:@(1)];
        });
        it(@"Should create EVENT_FIRST as first event with foreground host state", ^{
            hostStateProvider.hostState = AMAHostAppStateForeground;
            [appMetricaImpl setPreloadInfo:nil];
            [appMetricaImpl activateWithConfiguration:configuration];

            AMAEvent *event = [dynamicEventStorage() amatest_savedEventWithType:AMAEventTypeFirst];
            [[event.oid should] equal:@(1)];
        });
    });

    context(@"Host state changing", ^{
        it(@"Should call start on foreground entering", ^{
            [[appMetricaImpl should] receive:@selector(start)];
            [[appMetricaImpl shouldNot] receive:@selector(shutdown)];
            hostStateProvider.hostState = AMAHostAppStateForeground;
        });
        it(@"Should not call start on background entering", ^{
            [[appMetricaImpl shouldNot] receive:@selector(start)];
            hostStateProvider.hostState = AMAHostAppStateBackground;
        });
        it(@"Should call shutdown on background entering", ^{
            [[appMetricaImpl should] receive:@selector(shutdown)];
            hostStateProvider.hostState = AMAHostAppStateBackground;
        });
        it(@"Should not call shutdown on foreground entering", ^{
            [[appMetricaImpl shouldNot] receive:@selector(shutdown)];
            hostStateProvider.hostState = AMAHostAppStateForeground;
        });
        it(@"Should trigger dispatch controller start", ^{
            [[dispatchingController should] receive:@selector(start)];
            hostStateProvider.hostState = AMAHostAppStateForeground;
        });
        it(@"Should trigger dispatch controller shutdown", ^{
            [[dispatchingController should] receive:@selector(shutdown)];
            hostStateProvider.hostState = AMAHostAppStateBackground;
        });
        it(@"Should trigger strategies dispatch", ^{
            [[dispatchStrategiesContainer should] receive:@selector(dispatchMoreIfNeeded)];
            hostStateProvider.hostState = AMAHostAppStateForeground;
        });
        it(@"Should trigger strategies shutdown", ^{
            [[dispatchStrategiesContainer should] receive:@selector(shutdown)];
            hostStateProvider.hostState = AMAHostAppStateBackground;
        });
        it(@"Should trigger state reporting start", ^{
            [[stateReportingController should] receive:@selector(start)];
            hostStateProvider.hostState = AMAHostAppStateForeground;
        });
        it(@"Sends update permissions", ^{
            [[permissionsController should] receive:@selector(updateIfNeeded)];
            hostStateProvider.hostState = AMAHostAppStateForeground;
        });
        it(@"Should trigger state reporting shutdown", ^{
            [[stateReportingController should] receive:@selector(shutdown)];
            hostStateProvider.hostState = AMAHostAppStateBackground;
        });
        it(@"Should not call shutdown on termination", ^{
            [[appMetricaImpl shouldNot] receive:@selector(shutdown)];
            hostStateProvider.hostState = AMAHostAppStateTerminated;
        });
        it(@"Should call terminate on termination", ^{
            [[appMetricaImpl should] receive:@selector(terminate)];
            hostStateProvider.hostState = AMAHostAppStateTerminated;
        });
        it(@"Should not call start on terminating", ^{
            [[appMetricaImpl shouldNot] receive:@selector(start)];
            hostStateProvider.hostState = AMAHostAppStateTerminated;
        });
        it(@"Should not call shutdown on unknown", ^{
            [[appMetricaImpl shouldNot] receive:@selector(shutdown)];
            hostStateProvider.hostState = AMAHostAppStateUnknown;
        });
        it(@"Should not call start on unknown", ^{
            [[appMetricaImpl shouldNot] receive:@selector(start)];
            hostStateProvider.hostState = AMAHostAppStateUnknown;
        });
        it(@"Should not call terminate on unknown", ^{
            [[appMetricaImpl shouldNot] receive:@selector(terminate)];
            hostStateProvider.hostState = AMAHostAppStateUnknown;
        });
    });

    context(@"Startup triggering", ^{
        NSString *const apiKey = kAMAMetricaLibraryApiKey;
        AMADispatchStrategy *__block strategy = nil;
        AMAReporterStorage *__block storage = nil;
        beforeEach(^{
            strategy = [AMADispatchStrategy nullMock];
            storage = [AMAReporterStorage nullMock];
            [storage stub:@selector(apiKey) andReturn:apiKey];
            [strategy stub:@selector(storage) andReturn:storage];
        });
        it(@"Can be executed", ^{
            [strategy stub:@selector(canBeExecuted:) andReturn:theValue(YES)];
            [[dispatchingController should] receive:@selector(performReportForApiKey:forced:) withArguments:apiKey, theValue(NO)];
            [appMetricaImpl dispatchStrategyWantsReportingToHappen:strategy];
        });
        it(@"Cannot be executed", ^{
            [strategy stub:@selector(canBeExecuted:) andReturn:theValue(NO)];
            [[dispatchingController shouldNot] receive:@selector(performReportForApiKey:forced:)];
            [appMetricaImpl dispatchStrategyWantsReportingToHappen:strategy];
        });
    });

    context(@"Startup triggers", ^{
        it(@"Should dispatch startup update to extensions controller", ^{
            [startupController stub:@selector(upToDate) andReturn:theValue(YES)];
            [[extensionsReportController should] receive:@selector(startupUpdateCompletedWithConfiguration:)];
            [appMetricaImpl startupControllerDidFinishWithSuccess:startupController];
        });

        it(@"Should dispatch startup update to strategies controller", ^{
            [startupController stub:@selector(upToDate) andReturn:theValue(YES)];
            [[dispatchStrategiesContainer should] receive:@selector(dispatchMoreIfNeeded)];
            [appMetricaImpl startupControllerDidFinishWithSuccess:startupController];
        });

        it(@"Should dispatch startup update to permissions controller", ^{
            [startupController stub:@selector(upToDate) andReturn:theValue(YES)];
            [[permissionsController should] receive:@selector(updateIfNeeded)];
            [appMetricaImpl startupControllerDidFinishWithSuccess:startupController];
        });
    });

    context(@"Send events buffer", ^{
        beforeEach(^{
            [appMetricaImpl activateWithConfiguration:configuration];
        });

        it(@"Should call reporter's sendEventsBuffer", ^{
            [[appMetricaImpl.reporter should] receive:@selector(sendEventsBuffer)];
            [appMetricaImpl sendEventsBuffer];
        });
        it(@"Should call dispatcher on sendEventsBufferForApiKey", ^{
            [[appMetricaImpl.dispatchingController should] receive:@selector(performReportForApiKey:forced:)
                                                        withArguments:apiKey, theValue(YES)];
            [((NSObject<AMAReporterDelegate> *)appMetricaImpl) sendEventsBufferWithApiKey:apiKey];
        });
        it(@"Should run on queue", ^{
            [[((NSObject *)appMetricaImpl.executor) should] receive:@selector(execute:)];
            [appMetricaImpl sendEventsBuffer];
        });
    });

    context(@"Sessions Autotracking", ^{
        AMASessionStorage *__block sessionStorage = nil;
        beforeEach(^{
            sessionStorage = [reporterTestHelper appReporterForApiKey:apiKey].reporterStorage.sessionStorage;
        });
        context(@"Enabled", ^{
            it(@"Should start foreground session if activated in foreground", ^{
                hostStateProvider.hostState = AMAHostAppStateForeground;
                [appMetricaImpl activateWithConfiguration:configuration];
                [[theValue([sessionStorage lastSessionWithError:nil].type) should] equal:theValue(AMASessionTypeGeneral)];
            });
            it(@"Should start background session if activated in background", ^{
                hostStateProvider.hostState = AMAHostAppStateBackground;
                [appMetricaImpl activateWithConfiguration:configuration];
                [[theValue([sessionStorage lastSessionWithError:nil].type) should] equal:theValue(AMASessionTypeBackground)];
            });
            it(@"Should start foreground session on app entering foreground", ^{
                hostStateProvider.hostState = AMAHostAppStateBackground;
                [appMetricaImpl activateWithConfiguration:configuration];
                [appMetricaImpl start];
                [[theValue([sessionStorage lastSessionWithError:nil].type) should] equal:theValue(AMASessionTypeGeneral)];
            });
        });
        context(@"Disabled", ^{
            beforeEach(^{
                [AMAMetricaConfiguration sharedInstance].inMemory.sessionsAutoTracking = NO;
            });
            it(@"Should start background session if activated in foreground", ^{
                hostStateProvider.hostState = AMAHostAppStateForeground;
                [appMetricaImpl activateWithConfiguration:configuration];
                [[theValue([sessionStorage lastSessionWithError:nil].type) should] equal:theValue(AMASessionTypeBackground)];
            });
            it(@"Should start background session if activated in background", ^{
                hostStateProvider.hostState = AMAHostAppStateBackground;
                [appMetricaImpl activateWithConfiguration:configuration];
                [[theValue([sessionStorage lastSessionWithError:nil].type) should] equal:theValue(AMASessionTypeBackground)];
            });
            it(@"Should not start foreground session on app entering foreground", ^{
                hostStateProvider.hostState = AMAHostAppStateBackground;
                [appMetricaImpl activateWithConfiguration:configuration];
                [appMetricaImpl start];
                [[theValue([sessionStorage lastSessionWithError:nil].type) should] equal:theValue(AMASessionTypeBackground)];
            });
            context(@"Manual", ^{
                context(@"Should start foreground session manually", ^{
                    hostStateProvider.hostState = AMAHostAppStateBackground;
                    [appMetricaImpl activateWithConfiguration:configuration];
                    [appMetricaImpl resumeSession];
                    [[theValue([sessionStorage lastSessionWithError:nil].type) should] equal:theValue(AMASessionTypeGeneral)];
                });
            });
        });
    });

    context(@"Report URL", ^{
        it(@"Should report URL", ^{
            NSURL *url = [[NSURL alloc] initWithString:@"https://appmetrica.io"];
            NSString *type = @"open";
            [[deeplinkController should] receive:@selector(reportUrl:ofType:isAuto:) withArguments:url, type, theValue(YES)];
            [appMetricaImpl activateWithConfiguration:configuration];
            [appMetricaImpl reportUrl:url ofType:type isAuto:YES];
        });
    });
    context(@"Update dispatch strategies", ^{
        it(@"Should update strategies", ^{
            [[dispatchStrategiesContainer should] receive:@selector(addStrategies:)];
            [appMetricaImpl activateWithConfiguration:configuration];
        });
    });
    context(@"State reporting should register storage", ^{
        it(@"Should register storage", ^{
            [[stateReportingController should] receive:@selector(registerStorage:forApiKey:)];
            [appMetricaImpl activateWithConfiguration:configuration];
        });
    });
    context(@"Report Login SDK Event", ^{
        AMAInternalEventsReporter *__block internalEventsReporter = nil;
        beforeEach(^{
            internalEventsReporter = [AMAInternalEventsReporter nullMock];
            [AMAAppMetrica stub:@selector(sharedInternalEventsReporter) andReturn:internalEventsReporter];
        });
    });
});

SPEC_END
