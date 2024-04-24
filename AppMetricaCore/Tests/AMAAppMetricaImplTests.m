#import <Kiwi/Kiwi.h>
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>
#import <AppMetricaWebKit/AppMetricaWebKit.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import <AppMetricaPlatform/AppMetricaPlatform.h>
#import "AMAAppMetricaImpl+TestUtilities.h"
#import "AMAAdRevenueInfo.h"
#import "AMAAdServicesReportingController.h"
#import "AMAAppMetrica+Internal.h"
#import "AMAAppMetrica+TestUtilities.h"
#import "AMAAppMetrica.h"
#import "AMAAppMetricaImplTestFactory.h"
#import "AMAAppMetricaPreloadInfo+AMAInternal.h"
#import "AMAAppMetricaPreloadInfo.h"
#import "AMAAppOpenWatcher.h"
#import "AMAAttributionController.h"
#import "AMAAutoPurchasesWatcher.h"
#import "AMACachingStorageProvider.h"
#import "AMADeepLinkController.h"
#import "AMADispatchStrategiesContainer.h"
#import "AMADispatchStrategy+Private.h"
#import "AMADispatchStrategyMask.h"
#import "AMADispatcher.h"
#import "AMADispatchingController.h"
#import "AMAECommerce.h"
#import "AMAEnvironmentContainer.h"
#import "AMAEvent.h"
#import "AMAEventBuilder.h"
#import "AMAEventCountDispatchStrategy.h"
#import "AMAEventPollingDelegateMock.h"
#import "AMAEventStorage+TestUtilities.h"
#import "AMAExtensionsReportController.h"
#import "AMAExtrasContainer.h"
#import "AMAExternalAttributionController.h"
#import "AMAInternalEventsReporter.h"
#import "AMALocationManager.h"
#import "AMAMetricaConfigurationTestUtilities.h"
#import "AMAPermissionsController.h"
#import "AMAProfileAttribute.h"
#import "AMAReporter.h"
#import "AMAReporterConfiguration.h"
#import "AMAReporterStateStorage.h"
#import "AMAReporterStorage.h"
#import "AMAReporterStoragesContainer.h"
#import "AMAReporterTestHelper.h"
#import "AMARevenueInfo.h"
#import "AMASessionStorage.h"
#import "AMAStartupController.h"
#import "AMAStartupItemsChangedNotifier.h"
#import "AMAStartupStorageProvider.h"
#import "AMAStringEventValue.h"
#import "AMATimerDispatchStrategy.h"
#import "AMAUserProfile.h"

static NSString *const kAMAEnvironmentTestKey = @"TestEnvironmentKey";
static NSString *const kAMAEnvironmentTestValue = @"TestEnvironmentValue";

@interface AMAAppMetricaImpl () <AMAExtendedStartupObservingDelegate>
@end

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
    AMAAppOpenWatcher *__block appOpenWatcher = nil;
    AMAAdServicesReportingController *__block adServicesReportingController = nil;
    AMAAutoPurchasesWatcher *__block autoPurchasesWatcher = nil;
    AMADispatchingController *__block dispatchingController = nil;
    AMADeepLinkController *__block deeplinkController = nil;
    AMAInternalEventsReporter *__block internalEventsReporter = nil;
    AMAStartupItemsChangedNotifier *__block startupNotifier = nil;
    AMAExternalAttributionController *__block externalAttributionController = nil;

    beforeEach(^{
        [AMALocationManager stub:@selector(sharedManager)];
        configuration = [AMAAppMetricaConfiguration nullMock];
        [configuration stub:@selector(APIKey) andReturn:apiKey];
        startupController = [AMAStartupController stubbedNullMockForInit:@selector(initWithTimeoutRequestsController:)];
        permissionsController = [AMAPermissionsController stubbedNullMockForInit:@selector(initWithConfiguration:
                                                                                           extrcator:
                                                                                           dateProvider:)];
        extensionsReportController = [AMAExtensionsReportController stubbedNullMockForInit:@selector(initWithReporter:
                                                                                                     conditionProvider:
                                                                                                     provider:
                                                                                                     executor:)];
        dispatchStrategiesContainer = [AMADispatchStrategiesContainer stubbedNullMockForDefaultInit];
        
        appOpenWatcher = [AMAAppOpenWatcher stubbedNullMockForDefaultInit];
        autoPurchasesWatcher = [AMAAutoPurchasesWatcher stubbedNullMockForInit:@selector(initWithExecutor:)];
        deeplinkController = [AMADeepLinkController stubbedNullMockForInit:@selector(initWithReporter:executor:)];
        adServicesReportingController = [AMAAdServicesReportingController stubbedNullMockForInit:@selector(initWithApiKey:
                                                                                                           reporterStateStorage:)];
        dispatchingController = [AMADispatchingController stubbedNullMockForInit:@selector(initWithTimeoutConfiguration:)];
        internalEventsReporter = [AMAInternalEventsReporter nullMock];

        hostStateProvider = [AMAStubHostAppStateProvider new];
        hostStateProvider.hostState = AMAHostAppStateBackground;

        [AMAMetricaConfigurationTestUtilities stubConfigurationWithAppVersion:@"1.00"
                                                                  buildNumber:100];
        reporterTestHelper = [[AMAReporterTestHelper alloc] init];
        eventStorage = [reporterTestHelper appReporterForApiKey:apiKey].reporterStorage.eventStorage;
        startupNotifier = [AMAStartupItemsChangedNotifier stubbedNullMockForDefaultInit];
        externalAttributionController = [AMAExternalAttributionController stubbedNullMockForInit:@selector(initWithReporter:)];
        appMetricaImpl =
            [AMAAppMetricaImplTestFactory createCurrentQueueImplWithReporterHelper:reporterTestHelper
                                                                 hostStateProvider:hostStateProvider];
        [AMAAppMetrica stub:@selector(sharedImpl) andReturn:appMetricaImpl];
        
        id<AMAAsyncExecuting>executor = [AMACurrentQueueExecutor new];
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
    context(@"Event polling", ^{
        let(impl, ^{
            return [AMAAppMetricaImplTestFactory createCurrentQueueImplWithReporterHelper:reporterTestHelper
                                                                        hostStateProvider:hostStateProvider];
        });

        beforeEach(^{
            [impl setEventPollingDelegates:[NSSet setWithArray:@[AMAEventPollingDelegateMock.class]]];
            AMAEventPollingDelegateMock.mockedEvents = @[];
            [AMAAppMetrica stub:@selector(sharedImpl) andReturn:appMetricaImpl];
        });
        
        it(@"Should poll polling delegates", ^{
            [[AMAEventPollingDelegateMock should] receive:@selector(eventsForPreviousSession)];
            [impl activateWithConfiguration:configuration];
        });
        
        it(@"Should add events from delegage to previous session", ^{
            AMASessionStorage *sessionStorage = reporterTestHelper.appReporter.reporterStorage.sessionStorage;
            AMAEventStorage *eventsStorage = reporterTestHelper.appReporter.reporterStorage.eventStorage;
            NSDate *creationDate = [NSDate dateWithTimeIntervalSinceNow:-10];
            AMASession *session = [sessionStorage newFinishedBackgroundSessionCreatedAt:creationDate 
                                                                               appState:nil error:NULL];
            
            AMAEventPollingDelegateMock.mockedEvents = @[
                [[AMAEventPollingParameters alloc] initWithEventType:AMAEventTypeProtobufCrash],
                [[AMAEventPollingParameters alloc] initWithEventType:AMAEventTypeProtobufError],
            ];
            [impl activateWithConfiguration:configuration];
            
            [[theValue([eventStorage totalCountOfEventsWithTypes:@[ @(AMAEventTypeProtobufCrash) ]]) should] equal:theValue(1)];
            [[theValue([eventStorage totalCountOfEventsWithTypes:@[ @(AMAEventTypeProtobufError) ]]) should] equal:theValue(1)];
        });
        
        it(@"Should setup app environment events", ^{
            AMAEnvironmentContainer *appEnvironmentMock = [AMAEnvironmentContainer nullMock];
            [reporterTestHelper.appReporter.reporterStorage.stateStorage stub:@selector(appEnvironment) andReturn:appEnvironmentMock];
            
            [[AMAEventPollingDelegateMock.class should] receive:@selector(setupAppEnvironment:) withArguments:appEnvironmentMock];
            
            [impl activateWithConfiguration:configuration];
        });
    });
    context(@"User profile ID", ^{
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
            it(@"Should preserve userID before activation" ,^{
                impl.userProfileID = profileIDBeforeActivation;
                [[impl.userProfileID should] equal:profileIDBeforeActivation];
            });
            it(@"Should preserve userID after activation" ,^{
                impl.userProfileID = profileIDBeforeActivation;
                [impl activateWithConfiguration:configuration];
                [[impl.userProfileID should] equal:profileIDBeforeActivation];
            });
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
            it(@"Should preserve userID during activation" ,^{
                [configuration stub:@selector(userProfileID) andReturn:profileIDDuringActivation];
                [impl activateWithConfiguration:configuration];
                [[impl.userProfileID should] equal:profileIDDuringActivation];
            });
            it(@"Set before and during activation", ^{
                [impl setUserProfileID:profileIDBeforeActivation];
                [configuration stub:@selector(userProfileID) andReturn:profileIDDuringActivation];
                [impl activateWithConfiguration:configuration];
                [[resultProfileID() should] equal:profileIDDuringActivation];
            });
            it(@"Should use truncated value after activation" ,^{
                impl.userProfileID = profileIDBeforeActivation;
                [impl activateWithConfiguration:configuration];
                NSString *truncated = @"Profile ID be";
                [reporterTestHelper appReporterForApiKey:apiKey]
                    .reporterStorage.stateStorage.profileID = truncated;
                [[impl.userProfileID should] equal:truncated];
            });
            it(@"Should not use truncated value before activation" ,^{
                impl.userProfileID = profileIDBeforeActivation;
                NSString *truncated = @"Profile ID be";
                [reporterTestHelper appReporterForApiKey:apiKey]
                    .reporterStorage.stateStorage.profileID = truncated;
                [[impl.userProfileID should] equal:profileIDBeforeActivation];
            });
        });
        context(@"Manual reporter", ^{
            NSString *differentApiKey = @"f3f8bafd-b9c2-47e5-8065-fec0f54b67d2";
            NSString *(^resultProfileID)(void) = ^{
                return [reporterTestHelper appReporterForApiKey:differentApiKey].reporterStorage.stateStorage.profileID;
            };

            it(@"Set only before activation", ^{
                [impl setUserProfileID:profileIDBeforeActivation];
                [impl manualReporterForConfiguration:[[AMAReporterConfiguration alloc] initWithAPIKey:differentApiKey]];
                [[resultProfileID() should] beNil];
            });
            it(@"Set only during activation", ^{
                AMAMutableReporterConfiguration *reporterConfig = [[AMAMutableReporterConfiguration alloc] initWithAPIKey:differentApiKey];
                reporterConfig.userProfileID = profileIDDuringActivation;
                [impl manualReporterForConfiguration:reporterConfig];
                [[resultProfileID() should] equal:profileIDDuringActivation];
            });
            it(@"Set before and during activation", ^{
                [impl setUserProfileID:profileIDBeforeActivation];
                AMAMutableReporterConfiguration *reporterConfig = [[AMAMutableReporterConfiguration alloc] initWithAPIKey:differentApiKey];
                reporterConfig.userProfileID = profileIDDuringActivation;
                [impl manualReporterForConfiguration:reporterConfig];
                [[resultProfileID() should] equal:profileIDDuringActivation];
            });
        });
    });

    context(@"Starting AppMetrica on internal queue", ^{
        NSString *differentApiKey = @"f3f8bafd-b9c2-47e5-8065-fec0f54b67d2";
        it(@"Should not access storage on current queue", ^{
            AMAManualCurrentQueueExecutor *executor = [AMAManualCurrentQueueExecutor new];
            [reporterTestHelper appReporterForApiKey:differentApiKey main:YES executor:executor inMemory:YES preloadInfo:nil attributionCheckExecutor:nil];
            AMAAppMetricaImpl *impl = [AMAAppMetricaImplTestFactory createNoQueueImplWithReporterHelper:reporterTestHelper];
            [[[AMAMetricaConfiguration sharedInstance] shouldNot] receive:@selector(persistent)];
            [configuration stub:@selector(APIKey) andReturn:differentApiKey];
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
            [appMetricaImpl manualReporterForConfiguration:[[AMAReporterConfiguration alloc] initWithAPIKey:differentApiKey]];
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

    context(@"Sends ECOMMERCE events", ^{
        it(@"Should save ECOMMERCE event", ^{
            [appMetricaImpl activateWithConfiguration:configuration];
            AMAECommerce *eCommerce = [AMAECommerce nullMock];
            [appMetricaImpl reportECommerce:eCommerce onFailure:nil];

            AMAEvent *event = [eventStorage amatest_savedEventWithType:AMAEventTypeECommerce];
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

#if !TARGET_OS_TV
    context(@"Init web view reporting", ^{
        AMAJSController *__block jsController = nil;

        beforeEach(^{
            jsController = [AMAJSController stubbedNullMockForInit:@selector(initWithUserContentController:)];
        });

        it(@"Should init web view reporting", ^{
            WKUserContentController *controller = [WKUserContentController nullMock];
            [appMetricaImpl activateWithConfiguration:configuration];

            [[jsController should] receive:@selector(setUpWebViewReporting:withReporter:)
                             withArguments:appMetricaImpl.executor, appMetricaImpl.reporter];

            [appMetricaImpl setupWebViewReporting:jsController];
        });
    });
#endif

    context(@"External attribution", ^{
        it(@"Should report to controller", ^{
            NSDictionary *const data = @{@"A": @"B"};
            AMAAttributionSource const source = kAMAAttributionSourceAppsflyer;
            __auto_type block = ^(NSError *error) {};
            [appMetricaImpl activateWithConfiguration:configuration];
            [[externalAttributionController should] receive:@selector(processAttributionData:source:onFailure:)
                                              withArguments:data, source, kw_any()];
            [appMetricaImpl reportExternalAttribution:data source:source onFailure:block];
        });
    });

    context(@"Sends string events with custom EventType", ^{
        NSUInteger const eventType = 1234;
        it(@"Should dispatch reporter with correct event type", ^{
            [appMetricaImpl activateWithConfiguration:configuration];
            [[appMetricaImpl.reporter should] receive:@selector(reportEventWithType:
                                                                name:
                                                                value:
                                                                eventEnvironment:
                                                                appEnvironment:
                                                                extras:
                                                                onFailure:)
                                        withArguments:theValue(eventType), @"", @"", @{}, @{}, nil, nil];
            
            [appMetricaImpl reportEventWithType:eventType
                                           name:@""
                                          value:@""
                               eventEnvironment:@{}
                                 appEnvironment:@{}
                                         extras:nil
                                      onFailure:nil];
        });
        it(@"Should save event with custom EventType", ^{
            [appMetricaImpl activateWithConfiguration:configuration];
            [appMetricaImpl reportEventWithType:eventType
                                           name:@""
                                          value:@""
                               eventEnvironment:@{}
                                 appEnvironment:@{}
                                         extras:nil
                                      onFailure:nil];

            AMAEvent *event = [eventStorage amatest_savedEventWithType:eventType];
            [[event shouldNot] beNil];
        });
    });
    
    context(@"Sends binary events with custom EventType", ^{
        NSUInteger const eventType = 4321;
        NSString *const eventName = @"name";
        it(@"Should dispatch reporter with correct event type", ^{
            [appMetricaImpl activateWithConfiguration:configuration];
            
            [[appMetricaImpl.reporter should] receive:@selector(reportBinaryEventWithType:
                                                                data:
                                                                name:
                                                                gZipped:
                                                                eventEnvironment:
                                                                appEnvironment:
                                                                extras:
                                                                bytesTruncated:
                                                                onFailure:)
                                        withArguments:theValue(eventType), kw_any(), eventName, theValue(YES), @{}, @{}, nil, theValue(2), nil];
            
            [appMetricaImpl reportBinaryEventWithType:eventType
                                                 data:[NSData data]
                                                 name:eventName
                                              gZipped:YES
                                     eventEnvironment:@{}
                                       appEnvironment:@{}
                                               extras:nil
                                       bytesTruncated:2
                                            onFailure:nil];
        });
        it(@"Should save event with custom EventType", ^{
            [appMetricaImpl activateWithConfiguration:configuration];
            [appMetricaImpl reportBinaryEventWithType:eventType
                                                 data:[NSData data]
                                                 name:nil
                                              gZipped:YES
                                     eventEnvironment:@{}
                                       appEnvironment:@{}
                                               extras:nil
                                       bytesTruncated:0
                                            onFailure:nil];
            
            AMAEvent *event = [eventStorage amatest_savedEventWithType:eventType];
            [[event shouldNot] beNil];
        });
    });
    
    context(@"Sends file events with custom EventType", ^{
        NSUInteger const eventType = 2341;
        it(@"Should dispatch reporter with correct event type", ^{
            [appMetricaImpl activateWithConfiguration:configuration];
            
            [[appMetricaImpl.reporter should] receive:@selector(reportFileEventWithType:
                                                                data:
                                                                fileName:
                                                                gZipped:
                                                                encrypted:
                                                                truncated:
                                                                eventEnvironment:
                                                                appEnvironment:
                                                                extras:
                                                                onFailure:)
                                        withArguments:theValue(eventType), kw_any(), @"", theValue(YES), theValue(YES), theValue(YES), @{}, @{}, nil, nil];
            
            [appMetricaImpl reportFileEventWithType:eventType
                                               data:[NSData data]
                                           fileName:@""
                                            gZipped:YES
                                          encrypted:YES
                                          truncated:YES
                                   eventEnvironment:@{}
                                     appEnvironment:@{}
                                             extras:nil
                                          onFailure:nil];
        });
        it(@"Should save event with custom EventType", ^{
            [appMetricaImpl activateWithConfiguration:configuration];
            [appMetricaImpl reportFileEventWithType:eventType
                                               data:[NSData data]
                                           fileName:@""
                                            gZipped:YES
                                          encrypted:YES
                                          truncated:YES
                                   eventEnvironment:@{}
                                     appEnvironment:@{}
                                             extras:nil
                                          onFailure:nil];
            
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
        it(@"Sends update permissions", ^{
            [[permissionsController should] receive:@selector(updateIfNeeded)];
            hostStateProvider.hostState = AMAHostAppStateForeground;
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
    
    context(@"Extended", ^{
        context(@"Startup observer", ^{
            NSDictionary *const startupParameters = @{@"request": @{@"ab" : @"1"},
                                                      @"hosts": @[@"host_1", @1, @"host_2", @""],
            };
            NSArray *__block observers = nil;
            beforeEach(^{
                observers = @[[KWMock nullMockForProtocol:@protocol(AMAExtendedStartupObserving)],
                              [KWMock nullMockForProtocol:@protocol(AMAExtendedStartupObserving)]];
            });
            it(@"Should setup startup observers", ^{
                id startupStorageProvider = [AMAStartupStorageProvider stubbedNullMockForDefaultInit];
                id cachingStorageProvider = [AMACachingStorageProvider stubbedNullMockForDefaultInit];
                
                for (NSObject<AMAExtendedStartupObserving> *observer in observers) {
                    [observer stub:@selector(startupParameters) andReturn:startupParameters];
                    
                    [[observer should] receive:@selector(setupStartupProvider:cachingStorageProvider:)
                                 withArguments:startupStorageProvider,cachingStorageProvider];
                }
                
                [appMetricaImpl setExtendedStartupObservers:[NSSet setWithArray:observers]];
                [appMetricaImpl activateWithConfiguration:configuration];
            });
            it(@"Should add startup request parameters", ^{
                for (NSObject<AMAExtendedStartupObserving> *observer in observers) {
                    [observer stub:@selector(startupParameters) andReturn:startupParameters];
                }
                
                [[startupController should] receive:@selector(addAdditionalStartupParameters:)
                                          withCount:2
                                          arguments:startupParameters[@"request"]];
                
                [appMetricaImpl setExtendedStartupObservers:[NSSet setWithArray:observers]];
                [appMetricaImpl activateWithConfiguration:configuration];
            });
            it(@"Should add startup hosts", ^{
                [observers[1] stub:@selector(startupParameters) andReturn:@{@"hosts" : @[@"host_5", @"host_2", @"host_3"]}];
                
                [appMetricaImpl setExtendedStartupObservers:[NSSet setWithArray:observers]];
                [appMetricaImpl activateWithConfiguration:configuration];
                
                NSArray *additionalHosts = [[AMAMetricaConfiguration sharedInstance].inMemory additionalStartupHosts];
                [[additionalHosts should] equal:@[@"host_5", @"host_2", @"host_3"]];
            });
            it(@"Should add startup hosts from several observers", ^{
                [observers[0] stub:@selector(startupParameters) andReturn:startupParameters];
                [observers[1] stub:@selector(startupParameters) andReturn:@{@"hosts" : @[@"host_2", @"host_3"]}];
                
                [appMetricaImpl setExtendedStartupObservers:[NSSet setWithArray:observers]];
                [appMetricaImpl activateWithConfiguration:configuration];
                
                NSArray *additionalHosts = [[AMAMetricaConfiguration sharedInstance].inMemory additionalStartupHosts];
                [[additionalHosts should] containObjectsInArray:@[@"host_1", @"host_2", @"host_3"]];
            });
            it(@"Should not add startup parameters with invalid dictionary", ^{
                [observers[0] stub:@selector(startupParameters) andReturn:@{@"foo" : @"bar"}];
                [observers[1] stub:@selector(startupParameters) andReturn:@{@2 : @[@"host"], @"hosts" : @{}}];
                
                [[startupController shouldNot] receive:@selector(addAdditionalStartupParameters:)];
                
                [appMetricaImpl setExtendedStartupObservers:[NSSet setWithArray:observers]];
                [appMetricaImpl activateWithConfiguration:configuration];
                
                NSArray *additionalHosts = [[AMAMetricaConfiguration sharedInstance].inMemory additionalStartupHosts];
                [[additionalHosts should] equal:@[]];
            });
            it(@"Should dispatch startup response", ^{
                [startupController stub:@selector(upToDate) andReturn:theValue(YES)];
                for (NSObject<AMAExtendedStartupObserving> *observer in observers) {
                    [[observer should] receive:@selector(startupUpdatedWithParameters:)
                                 withArguments:startupParameters];
                }
                
                [appMetricaImpl setExtendedStartupObservers:[NSSet setWithArray:observers]];
                [appMetricaImpl startupUpdatedWithResponse:startupParameters];
            });
        });
        context(@"Reporter storage controller", ^{
            NSArray *__block controllers = nil;
            beforeEach(^{
                controllers = @[[KWMock nullMockForProtocol:@protocol(AMAReporterStorageControlling)],
                                [KWMock nullMockForProtocol:@protocol(AMAReporterStorageControlling)]];
            });
            it(@"Should setup reporter storage controller with main reporter", ^{
                for (NSObject<AMAReporterStorageControlling> *controller in controllers) {
                    [[controller should] receive:@selector(setupWithReporterStorage:main:forAPIKey:)
                                   withArguments:kw_any(), theValue(YES), configuration.APIKey];
                }
                
                [appMetricaImpl setExtendedReporterStorageControllers:[NSSet setWithArray:controllers]];
                [appMetricaImpl activateWithConfiguration:configuration];
            });
            it(@"Should setup reporter storage controller with secondary reporter", ^{
                for (NSObject<AMAReporterStorageControlling> *controller in controllers) {
                    [[controller should] receive:@selector(setupWithReporterStorage:main:forAPIKey:)
                                   withArguments:kw_any(), theValue(NO), configuration.APIKey];
                }
                
                [appMetricaImpl setExtendedReporterStorageControllers:[NSSet setWithArray:controllers]];
                [AMAAppMetrica activateReporterWithConfiguration:[[AMAReporterConfiguration alloc] initWithAPIKey:apiKey]];
            });
        });
        context(@"Event polling delegate", ^{
            NSArray *__block delegates = nil;
            beforeEach(^{
                delegates = @[[KWMock nullMockForProtocol:@protocol(AMAEventPollingDelegate)],
                              [KWMock nullMockForProtocol:@protocol(AMAEventPollingDelegate)]];
            });
            it(@"Should setup event polling delegate with main reporter", ^{
                for (NSObject<AMAEventPollingDelegate> *delegate in delegates) {
                    [[delegate should] receive:@selector(eventsForPreviousSession)];
                    
                    [[delegate should] receive:@selector(setupAppEnvironment:)];
                }
                
                [appMetricaImpl setEventPollingDelegates:[NSSet setWithArray:delegates]];
                [appMetricaImpl activateWithConfiguration:configuration];
            });
            it(@"Should NOT setup event polling delegate with secondary reporter", ^{
                for (NSObject<AMAEventPollingDelegate> *delegate in delegates) {
                    [[delegate shouldNot] receive:@selector(eventsForPreviousSession)];
                    
                    [[delegate shouldNot] receive:@selector(setupAppEnvironment:)];
                }
                
                [appMetricaImpl setEventPollingDelegates:[NSSet setWithArray:delegates]];
                [AMAAppMetrica activateReporterWithConfiguration:[[AMAReporterConfiguration alloc] initWithAPIKey:apiKey]];
            });
        });
    });
    context(@"Session extras", ^{
        NSString *const key = @"key";
        it(@"Should dispatch set session extras", ^{
            NSData *data = [NSData data];
            
            [[reporterTestHelper.appReporter should] receive:@selector(setSessionExtras:forKey:) withArguments:data, key];
            
            [appMetricaImpl activateWithConfiguration:configuration];
            [appMetricaImpl setSessionExtras:data forKey:key];
        });
        it(@"Should dispatch clear session extras", ^{
            [[reporterTestHelper.appReporter should] receive:@selector(clearSessionExtras)];
            
            [appMetricaImpl activateWithConfiguration:configuration];
            [appMetricaImpl clearSessionExtras];
        });
    });
    context(@"Error environment value", ^{
        NSString *const key = @"key";
        NSString *const value = @"value";
        AMAEnvironmentContainer *__block container = nil;
        beforeEach(^{
            container = [AMAReporterStoragesContainer sharedInstance].eventEnvironment;
        });
        it(@"Should sync set error environment value", ^{
            [[container should] receive:@selector(addValue:forKey:) withArguments:value, key];
            
            [AMAAppMetricaImpl syncSetErrorEnvironmentValue:value forKey:key];
        });
        it(@"Should set error environment value", ^{
            [[container should] receive:@selector(addValue:forKey:) withArguments:value, key];
            
            [appMetricaImpl setErrorEnvironmentValue:value forKey:key];
        });
    });
    
    context(@"Startup identifiers", ^{
        dispatch_queue_t __block queue = nil;
        AMAIdentifiersCompletionBlock __block identifiersBlock = nil;
        beforeEach(^{
            queue = [AMAQueuesFactory serialQueueForIdentifierObject:self domain:@"Tests"];
            identifiersBlock = ^(NSDictionary<NSString *,id> * identifiers,
                                 NSError * error) {};
        });
        it(@"Should dispatch request identifiers with all keys", ^{
            [[appMetricaImpl should] receive:@selector(requestStartupIdentifiersWithKeys:
                                                       completionQueue:
                                                       completionBlock:
                                                       notifyOnError:)
            withArguments:[AMAStartupItemsChangedNotifier allIdentifiersKeys], queue, identifiersBlock, theValue(YES)];
            
            [appMetricaImpl requestStartupIdentifiersWithCompletionQueue:queue
                                                         completionBlock:identifiersBlock
                                                           notifyOnError:YES];
        });
        
        it(@"Should request identifiers from startup notifier with notify on error enabled", ^{
            NSArray *keys = @[@"key1", @"key2"];
            NSDictionary *options = @{ kAMARequestIdentifiersOptionCallbackModeKey :
                                           kAMARequestIdentifiersOptionCallbackInAnyCase };
            
            [[startupNotifier should] receive:@selector(requestStartupItemsWithKeys:options:queue:completion:)
                         withArguments:keys, options, queue, identifiersBlock];
            
            [appMetricaImpl requestStartupIdentifiersWithKeys:keys
                                              completionQueue:queue
                                              completionBlock:identifiersBlock
                                                notifyOnError:YES];
        });
        
        it(@"Should request identifiers from startup notifier with notify on error disabled", ^{
            NSArray *keys = @[@"key1", @"key2"];
            NSDictionary *options = @{ kAMARequestIdentifiersOptionCallbackModeKey :
                                           kAMARequestIdentifiersOptionCallbackOnSuccess };
            
            [[startupNotifier should] receive:@selector(requestStartupItemsWithKeys:options:queue:completion:)
                         withArguments:keys, options, queue, identifiersBlock];
            
            [appMetricaImpl requestStartupIdentifiersWithKeys:keys
                                              completionQueue:queue
                                              completionBlock:identifiersBlock
                                                notifyOnError:NO];
        });
        
        it(@"Should update startup controller on request identifiers", ^{
            [[startupController should] receive:@selector(update)];
            
            [appMetricaImpl requestStartupIdentifiersWithKeys:@[]
                                              completionQueue:queue
                                              completionBlock:identifiersBlock
                                                notifyOnError:NO];
        });
        
        it(@"Should request predefined identifiers keys for empty keys list", ^{
            NSDictionary *options = @{ kAMARequestIdentifiersOptionCallbackModeKey :
                                           kAMARequestIdentifiersOptionCallbackOnSuccess };
            [[startupNotifier should] receive:@selector(requestStartupItemsWithKeys:options:queue:completion:)
                                withArguments:[AMAStartupItemsChangedNotifier allIdentifiersKeys], options, queue, identifiersBlock];
            
            [appMetricaImpl requestStartupIdentifiersWithKeys:@[]
                                              completionQueue:queue
                                              completionBlock:identifiersBlock
                                                notifyOnError:NO];
        });
    });
    
    context(@"Protocols", ^{
        it(@"Should conform to AMAStartupControllerDelegate", ^{
            [[appMetricaImpl should] conformToProtocol:@protocol(AMAStartupControllerDelegate)];
        });
        it(@"Should conform to AMADispatcherDelegate", ^{
            [[appMetricaImpl should] conformToProtocol:@protocol(AMADispatcherDelegate)];
        });
        it(@"Should conform to AMADispatchStrategyDelegate", ^{
            [[appMetricaImpl should] conformToProtocol:@protocol(AMADispatchStrategyDelegate)];
        });
        it(@"Should conform to AMAHostStateProviderDelegate", ^{
            [[appMetricaImpl should] conformToProtocol:@protocol(AMAHostStateProviderDelegate)];
        });
        it(@"Should conform to AMAReporterDelegate", ^{
            [[appMetricaImpl should] conformToProtocol:@protocol(AMAReporterDelegate)];
        });
        it(@"Should conform to AMAExtendedStartupObservingDelegate", ^{
            [[appMetricaImpl should] conformToProtocol:@protocol(AMAExtendedStartupObservingDelegate)];
        });
    });
});

SPEC_END
