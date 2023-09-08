
#import <AppMetricaWebKit/AppMetricaWebKit.h>
#import <Kiwi/Kiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMAReporter.h"
#import "AMAMetricaInMemoryConfiguration.h"
#import "AMAAppMetrica+Internal.h"
#import "AMAAppMetricaImplTestFactory.h"
#import "AMAAppMetrica+TestUtilities.h"
#import "AMADispatchStrategiesContainer.h"
#import "AMADispatchStrategy+Private.h"
#import "AMALocationManager.h"
#import "AMATestNetwork.h"
#import "AMAAppStateManagerTestHelper.h"
#import "AMADispatchStrategyMask.h"
#import "AMAMetricaConfigurationTestUtilities.h"
#import "AMAAppMetricaConfiguration+Extended.h"
#import "AMAEventBuilder.h"
#import "AMAFailureDispatcherTestHelper.h"
#import "AMAStartupItemsChangedNotifier+Tests.h"
#import "AMADeepLinkController.h"
#import "AMAStartupController.h"
#import "AMAInternalEventsReporter.h"
#import "AMAUserProfile.h"
#import "AMAProfileAttribute.h"
#import "AMARevenueInfo.h"
#import "AMAAdRevenueInfo.h"
#import "AMAStartupHostProvider.h"
#import "AMAReporterTestHelper.h"
#import "AMAReporterStorage.h"
#import "AMAReporterStateStorage.h"
#import "AMATimeoutRequestsController.h"
#import "AMAUUIDProvider.h"
#import "AMAStartupResponseParser.h"
#import "AMAAppMetricaPluginsImpl.h"

@interface AMAAppMetricaImpl () <AMAStartupControllerDelegate>

@property (nonatomic, strong) AMAStartupItemsChangedNotifier *startupItemsNotifier;
@property (nonatomic, strong) AMAStartupController *startupController;

@end

SPEC_BEGIN(AMAAppMetricaTests)

describe(@"AMAAppMetrica", ^{
    NSString *const apiKey = [AMAReporterTestHelper defaultApiKey];
    
    AMAAppStateManagerTestHelper *__block stateHelper = nil;
    AMAReporterTestHelper *__block reporterTestHelper = nil;
    AMAAppMetricaImpl * __block impl = nil;
    
    beforeEach(^{
        [AMATestNetwork stubHTTPRequestWithBlock:nil];
    });
    void (^stubMetricaDependencies)(void) = ^{
        [AMAMetricaConfigurationTestUtilities stubConfigurationWithAppVersion:stateHelper.appVersionName
                                                                  buildNumber:stateHelper.appBuildNumber];
        stateHelper = [[AMAAppStateManagerTestHelper alloc] init];
        [stateHelper stubApplicationState];
        [AMAFailureDispatcherTestHelper stubFailureDispatcher];
    };
    void (^stubMetrica)(void) = ^{
        stubMetricaDependencies();
        reporterTestHelper = [[AMAReporterTestHelper alloc] init];
        impl = [AMAAppMetricaImplTestFactory createCurrentQueueImplWithReporterHelper:reporterTestHelper];
        [AMAAppMetrica stub:@selector(sharedImpl) andReturn:impl];
        
        id<AMACancelableExecuting>executor = [AMACurrentQueueExecutor new];
        [AMAAppMetrica stub:@selector(sharedExecutor) andReturn:executor];
        
        executor = [AMACurrentQueueExecutor new];
        AMAStartupHostProvider *hostProvider = [AMAStartupHostProvider nullMock];
        AMATimeoutRequestsController *timeoutController = [AMATimeoutRequestsController nullMock];
        [timeoutController stub:@selector(isAllowed) andReturn:theValue(YES)];
        AMAStartupController *startupController =
        [[AMAStartupController alloc] initWithExecutor:executor
                                          hostProvider:hostProvider
                             timeoutRequestsController:timeoutController
                                 startupResponseParser:[[AMAStartupResponseParser alloc] init]];
        startupController.delegate = impl;
        [impl stub:@selector(startupController) andReturn:startupController];
        
        AMAInternalEventsReporter *internalEventsReporter = [AMAInternalEventsReporter nullMock];
        [AMAAppMetrica stub:@selector(sharedInternalEventsReporter) andReturn:internalEventsReporter];
        
        AMAStartupItemsChangedNotifier *notifier = impl.startupItemsNotifier;
        [notifier stub:@selector(dispatchBlock:withAvailableFields:toQueue:error:)
             withBlock:^id(NSArray *params) {
            AMAIdentifiersCompletionBlock block = params[0];
            block(params[1], params[3]);
            return nil;
        }];
    };
    void (^activate)(void) = ^{
        [AMAAppMetrica activateWithConfiguration:[[AMAAppMetricaConfiguration alloc] initWithApiKey:apiKey]];
    };
    context(@"Sets location", ^{
        it(@"Should set location to location manager", ^{
            stubMetrica();
            CLLocation *location = [[CLLocation alloc] initWithLatitude:11.0 longitude:12.0];
            [AMAAppMetrica setLocation:location];
            AMALocationManager *locationManager = [AMALocationManager sharedManager];
            [[theValue([location test_isEqualToLocation:[locationManager currentLocation]]) should] beYes];
        });
    });
    context(@"Set UserProfile ID", ^{
        AMAAppMetricaImpl *__block mockedImpl = nil;
        NSString *userProfileID = @"111333444";
        beforeEach(^{
            mockedImpl = [AMAAppMetricaImpl nullMock];
            stubMetrica();
            [AMAAppMetrica stub:@selector(sharedImpl) andReturn:mockedImpl];
        });
        it(@"Should call impl if metrica is not started", ^{
            [[mockedImpl should] receive:@selector(setUserProfileID:) withArguments:userProfileID];
            [AMAAppMetrica setUserProfileID:userProfileID];
        });
        it(@"Should call impl if metrica is started", ^{
            activate();
            [[mockedImpl should] receive:@selector(setUserProfileID:) withArguments:userProfileID];
            [AMAAppMetrica setUserProfileID:userProfileID];
        });
    });
    context(@"Provides correct configuration", ^{
        it(@"Should provide correct reports count for metrica", ^{
            stubMetrica();
            NSUInteger maxReportsCount = [AMAAppMetrica maxReportsCount];
            [[theValue(maxReportsCount) should] equal:theValue(7)];
        });
        it(@"Should create correct main configuration automatically", ^{
            stubMetrica();
            [AMATestNetwork stubNetworkRequestWithStatusCode:200 block:nil];
            activate();
            AMAReporterConfiguration *config = [[AMAMetricaConfiguration sharedInstance] configurationForApiKey:apiKey];
            [[theValue(config.maxReportsCount) should] equal:theValue(7)];
        });
        it(@"Should set max reports count before activateWithApiKey", ^{
            stubMetrica();
            AMAAppMetricaConfiguration *configuration = [[AMAAppMetricaConfiguration alloc] initWithApiKey:apiKey];
            NSUInteger maxReportsCount = 3;
            configuration.maxReportsCount = maxReportsCount;
            [AMAAppMetrica activateWithConfiguration:configuration];
            NSUInteger currentMaxReportsCount = [AMAAppMetrica maxReportsCount];
            [[theValue(currentMaxReportsCount) should] equal:theValue(maxReportsCount)];
        });
        it(@"Should set dispatch period before activateWithApiKey", ^{
            stubMetrica();
            AMAAppMetricaConfiguration *configuration = [[AMAAppMetricaConfiguration alloc] initWithApiKey:apiKey];
            NSUInteger dispatchPeriod = 33;
            configuration.dispatchPeriod = dispatchPeriod;
            [AMAAppMetrica activateWithConfiguration:configuration];
            NSUInteger currentDispatchPeriod = [AMAAppMetrica dispatchPeriod];
            [[theValue(currentDispatchPeriod) should] equal:theValue(dispatchPeriod)];
        });
        it(@"Should set probably unhandled crash enabled to NO by default", ^{
            stubMetrica();
            [[theValue([AMAMetricaConfiguration sharedInstance].inMemory.probablyUnhandledCrashDetectingEnabled) should] beNo];
        });
        context(@"Manual reporter", ^{
            NSString *reporterApiKey = @"73831ec2-0ab2-49ed-a573-e3116740c8be";
            beforeEach(^{
                stubMetrica();
                [AMATestNetwork stubNetworkRequestWithStatusCode:200 block:nil];
            });
            it(@"Should set dispatch period for manual reporter", ^{
                NSUInteger dispatchPeriod = 33;
                AMAMutableReporterConfiguration *mutableConfig =
                [[AMAMutableReporterConfiguration alloc] initWithApiKey:reporterApiKey];
                mutableConfig.dispatchPeriod = dispatchPeriod;
                [AMAAppMetrica activateReporterWithConfiguration:[mutableConfig copy]];
                
                AMAReporterConfiguration *sameConfig =
                [[AMAMetricaConfiguration sharedInstance] configurationForApiKey:reporterApiKey];
                [[theValue([sameConfig dispatchPeriod]) should] equal:theValue(dispatchPeriod)];
            });
            it(@"Should provide correct reports count for manual reporter", ^{
                stubMetrica();
                AMAReporterConfiguration *config =
                [[AMAMetricaConfiguration sharedInstance] configurationForApiKey:reporterApiKey];
                NSUInteger maxReportsCount = [config maxReportsCount];
                [[theValue(maxReportsCount) should] equal:theValue(1)];
            });
            it(@"Should set session timeout for manual reporter", ^{
                NSUInteger newSessionTimeout = 60;
                AMAMutableReporterConfiguration *mutableConfig =
                [[AMAMutableReporterConfiguration alloc] initWithApiKey:reporterApiKey];
                mutableConfig.sessionTimeout = newSessionTimeout;
                [AMAAppMetrica activateReporterWithConfiguration:[mutableConfig copy]];
                
                AMAReporterConfiguration *sameConfig =
                [[AMAMetricaConfiguration sharedInstance] configurationForApiKey:reporterApiKey];
                [[theValue(sameConfig.sessionTimeout) should] equal:theValue(newSessionTimeout)];
            });
            it(@"Should not allow setting session timeout less than 10 seconds", ^{
                NSUInteger newSessionTimeout = 5;
                NSUInteger expectedSessionTimeout = 10;
                
                AMAMutableReporterConfiguration *mutableConfig =
                [[AMAMutableReporterConfiguration alloc] initWithApiKey:reporterApiKey];
                mutableConfig.sessionTimeout = newSessionTimeout;
                [AMAAppMetrica activateReporterWithConfiguration:[mutableConfig copy]];
                
                AMAReporterConfiguration *sameConfig =
                [[AMAMetricaConfiguration sharedInstance] configurationForApiKey:reporterApiKey];
                [[theValue(sameConfig.sessionTimeout) should] equal:theValue(expectedSessionTimeout)];
            });
        });
    });
    context(@"User startup hosts check", ^{
        AMAAppMetricaConfiguration * __block configuration = nil;
        
        beforeEach(^{
            stubMetrica();
            stubMetricaDependencies();
            configuration = [[AMAAppMetricaConfiguration alloc] initWithApiKey:apiKey];
        });
        it(@"Should set userStartupHosts with startupHosts", ^{
            configuration.customHosts = @[@"value1", @"value2"];
            
            [AMAAppMetrica activateWithConfiguration:configuration];
            NSArray *actualValue = [AMAMetricaConfiguration sharedInstance].persistent.userStartupHosts;
            
            [[actualValue should] equal:configuration.customHosts];
        });
    });
    context(@"Open URL handling", ^{
        AMAAppMetricaImpl *__block mockedImpl = nil;
        NSURL *const URL = [NSURL URLWithString:@"https://some.url"];
        beforeEach(^{
            mockedImpl = [AMAAppMetricaImpl nullMock];
            stubMetrica();
            [AMAAppMetrica stub:@selector(sharedImpl) andReturn:mockedImpl];
        });
        it(@"Should not call impl if metrica is not started", ^{
            [[mockedImpl shouldNot] receive:@selector(reportUrl:ofType:isAuto:)];
            [AMAAppMetrica handleOpenURL:URL];
        });
        it(@"Should call impl with URL of type \"open\"", ^{
            activate();
            [[mockedImpl should] receive:@selector(reportUrl:ofType:isAuto:) withArguments:URL, @"open", theValue(NO)];
            [AMAAppMetrica handleOpenURL:URL];
        });
    });
    context(@"Referral URL handling", ^{
        AMAAppMetricaImpl *__block mockedImpl = nil;
        NSURL *const url = [NSURL URLWithString:@"https://some.url"];
        beforeEach(^{
            mockedImpl = [AMAAppMetricaImpl nullMock];
            stubMetrica();
            [AMAAppMetrica stub:@selector(sharedImpl) andReturn:mockedImpl];
        });
        it(@"Should not call impl if metrica is not started", ^{
            [[mockedImpl shouldNot] receive:@selector(reportUrl:ofType:isAuto:)];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            [AMAAppMetrica reportReferralUrl:url];
#pragma clang diagnostic pop
        });
        it(@"Should call impl with URL of type \"referral\"", ^{
            activate();
            [[mockedImpl should] receive:@selector(reportUrl:ofType:isAuto:) withArguments:url, @"referral", theValue(NO)];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            [AMAAppMetrica reportReferralUrl:url];
#pragma clang diagnostic pop
        });
    });
    
    context(@"User info", ^{
        NSString *userID = @"0834hvbiudvhepjoavhisg98ygerpihvh98ends";
        beforeEach(^{
            stubMetrica();
        });
        
        
        
        context(@"When Metrica started", ^{
            
            it(@"Should set api key", ^{
                activate();
                
                [[[[AMAAppMetrica sharedImpl] apiKey] should] equal:apiKey];
            });
            it(@"Should decline subsequent activations", ^{
                activate();
                
                AMAIgnoreAssert(^{
                    AMAAppMetricaConfiguration *configuration =
                    [[AMAAppMetricaConfiguration alloc] initWithApiKey:@"550e8400-e29b-41d4-a716-446655440001"];
                    [AMAAppMetrica activateWithConfiguration:configuration];
                });
                
                [[[[AMAAppMetrica sharedImpl] apiKey] should] equal:apiKey];
            });
            it(@"Should allow getting manual reporter for main api key", ^{
                activate();
                
                id reporter = [AMAAppMetrica reporterForApiKey:apiKey];
                [[reporter should] beNonNil];
            });
        });
        
        context(@"Passing queue to identifierChangedNotifier", ^{
            __block AMAStartupItemsChangedNotifier *identifierChangedNotifier = nil;
            __block dispatch_queue_t providedQueue = nil;
            __block KWCaptureSpy *spy = nil;
            beforeEach(^{
                providedQueue = dispatch_queue_create("queue for testing", DISPATCH_QUEUE_SERIAL);
                identifierChangedNotifier = [AMAStartupItemsChangedNotifier mock];
                spy = [identifierChangedNotifier captureArgument:@selector(requestStartupItemsWithKeys:options:queue:completion:)
                                                         atIndex:2];
                [[AMAAppMetrica sharedImpl] addStartupCompletionObserver:identifierChangedNotifier];
                [[AMAAppMetrica sharedImpl] stub:@selector(startupItemsNotifier)
                                          andReturn:identifierChangedNotifier];
                [[AMAMetricaConfiguration sharedInstance].inMemory stub:@selector(metricaStarted)
                                                              andReturn:theValue(YES)];
            });
            it(@"Should pass provided queue", ^{
                [AMAAppMetrica requestStartupIdentifiersWithCompletionQueue:providedQueue
                                                               completionBlock:^(NSDictionary *identifiers, NSError *error) {
                    //do nothing
                }];
                
                dispatch_queue_t passedQueue = (dispatch_queue_t)spy.argument;
                [[passedQueue should] equal:providedQueue];
            });
        });
        
        context(@"Custom event type", ^{
            context(@"Not activated Metrica", ^{
                NSError *(^errorFromReporting)(void) = ^NSError * {
                    NSError *__block resultError = nil;
                    [AMAAppMetrica reportEventWithType:0
                                                     name:@""
                                                    value:@""
                                              environment:@{}
                                                onFailure:^(NSError *error) {
                        resultError = error;
                    }];
                    return resultError;
                };
                
                it(@"Should call onFailure with error of actual domain", ^{
                    [[errorFromReporting().domain should] equal:kAMAAppMetricaErrorDomain];
                });
                it(@"Should call onFailure with error of actual code", ^{
                    [[theValue(errorFromReporting().code) should] equal:theValue(AMAAppMetricaEventErrorCodeInitializationError)];
                });
            });
            context(@"Activated Metrica", ^{
                it(@"Should report event with custom type", ^{
                    activate();
                    
                    NSUInteger eventType = 1234;
                    NSString *eventName = @"name";
                    NSString *eventValue = @"value";
                    NSDictionary *environment = @{ @"a": @"b" };
                    AMAReporter *reporter = reporterTestHelper.appReporter;
                    [[reporter should] receive:@selector(reportEventWithType:name:value:environment:extras:onFailure:)
                                 withArguments:theValue(eventType), eventName, eventValue, environment, nil, nil];
                    [AMAAppMetrica reportEventWithType:eventType
                                                     name:eventName
                                                    value:eventValue
                                              environment:environment
                                                onFailure:nil];
                });
            });
        });
        context(@"Profile event type", ^{
            beforeEach(^{
                [[AMAMetricaConfiguration sharedInstance].inMemory stub:@selector(metricaStarted)
                                                              andReturn:theValue(YES)];
            });
            it(@"Should report event", ^{
                AMAUserProfile *profile = [AMAUserProfile nullMock];
                [profile stub:@selector(copy) andReturn:profile];
                [[impl should] receive:@selector(reportUserProfile:onFailure:)
                         withArguments:profile, nil];
                [AMAAppMetrica reportUserProfile:profile onFailure:nil];
            });
        });
        context(@"Revenue event type", ^{
            beforeEach(^{
                [[AMAMetricaConfiguration sharedInstance].inMemory stub:@selector(metricaStarted)
                                                              andReturn:theValue(YES)];
            });
            it(@"Should report event", ^{
                AMARevenueInfo *revenueInfo = [AMARevenueInfo nullMock];
                [revenueInfo stub:@selector(copy) andReturn:revenueInfo];
                [[impl should] receive:@selector(reportRevenue:onFailure:)
                         withArguments:revenueInfo, nil];
                [AMAAppMetrica reportRevenue:revenueInfo onFailure:nil];
            });
        });
        context(@"AdRevenue event type", ^{
            it(@"Should report event if metrica is started", ^{
                [[AMAMetricaConfiguration sharedInstance].inMemory stub:@selector(metricaStarted)
                                                              andReturn:theValue(YES)];
                AMAAdRevenueInfo *adRevenueInfo = [AMAAdRevenueInfo nullMock];
                [adRevenueInfo stub:@selector(copy) andReturn:adRevenueInfo];
                [[impl should] receive:@selector(reportAdRevenue:onFailure:)
                         withArguments:adRevenueInfo, nil];
                [AMAAppMetrica reportAdRevenue:adRevenueInfo onFailure:nil];
            });
            it(@"Should not report event if metrica is not started", ^{
                [[AMAMetricaConfiguration sharedInstance].inMemory stub:@selector(metricaStarted)
                                                              andReturn:theValue(NO)];
                AMAAdRevenueInfo *adRevenueInfo = [AMAAdRevenueInfo nullMock];
                [adRevenueInfo stub:@selector(copy) andReturn:adRevenueInfo];
                [[impl shouldNot] receive:@selector(reportAdRevenue:onFailure:)];
                [AMAAppMetrica reportAdRevenue:adRevenueInfo onFailure:nil];
            });
        });
        context(@"Init web view reporting", ^{
            it(@"Should init", ^{
                [[AMAMetricaConfiguration sharedInstance].inMemory stub:@selector(metricaStarted)
                                                              andReturn:theValue(YES)];
                WKUserContentController *controller = [WKUserContentController nullMock];
                AMAJSController *jsController = [[AMAJSController alloc] initWithUserContentController:controller];

                [[impl should] receive:@selector(setupWebViewReporting:)
                         withArguments:jsController];

                [AMAAppMetrica setupWebViewReporting:jsController
                                              onFailure:nil];
            });
            it(@"Should not init if metrica is not started", ^{
                [[AMAMetricaConfiguration sharedInstance].inMemory stub:@selector(metricaStarted)
                                                              andReturn:theValue(NO)];
                WKUserContentController *controller = [WKUserContentController nullMock];
                AMAJSController *jsController = [[AMAJSController alloc] initWithUserContentController:controller];

                [[impl shouldNot] receive:@selector(setupWebViewReporting:)];

                [AMAAppMetrica setupWebViewReporting:jsController
                                              onFailure:nil];
            });
        });
        context(@"Public reporter", ^{
            NSString * __block apiKey = nil;
            beforeAll(^{
                apiKey = @"test_api_key";
            });
            it(@"Should invoke reporterForApiKey: for reporter", ^{
                BOOL __block result = NO;
                [AMAAppMetrica stub:@selector(reporterForApiKey:) withBlock:^id(NSArray *params) {
                    result = YES;
                    return nil;
                }];
                
                [AMAAppMetrica reporterForApiKey:apiKey];
                [[theValue(result) should] beYes];
            });
            it(@"Should return the same result as reporterForApiKey:", ^{
                NSObject *returnObject = [NSObject new];
                [AMAAppMetrica stub:@selector(reporterForApiKey:) andReturn:returnObject];
                
                BOOL result =
                [AMAAppMetrica reporterForApiKey:apiKey] == [AMAAppMetrica reporterForApiKey:apiKey];
                [[theValue(result) should] beYes];
            });
        });
        context(@"Startup identifiers", ^{
            AMAUUIDProvider *__block UUIDProvider = nil;
            beforeEach(^{
                stubMetrica();
                UUIDProvider = [AMAUUIDProvider nullMock];
                [AMAUUIDProvider stub:@selector(sharedInstance) andReturn:UUIDProvider];
                [[AMAMetricaConfiguration sharedInstance].inMemory stub:@selector(metricaStarted)
                                                              andReturn:theValue(YES)];
            });
            
            context(@"No identifiers", ^{
                beforeEach(^{
                    AMAMetricaPersistentConfiguration *conf = [AMAMetricaConfiguration sharedInstance].persistent;
                    [UUIDProvider stub:@selector(retrieveUUID) andReturn:nil];
                    [conf stub:@selector(deviceID) andReturn:@""];
                    [conf stub:@selector(deviceIDHash) andReturn:nil];
                });
                it(@"Should return error async", ^{
                    NSError *error = [NSError errorWithDomain:@"test_domain" code:1 userInfo:nil];
                    [AMATestNetwork stubHTTPRequestToFinishWithError:error];
                    
                    __block NSInteger result = 0;
                    AMAIdentifiersCompletionBlock callbackBlock = ^(NSDictionary *identifiers, NSError *error) {
                        result = error.code;
                    };
                    [AMAAppMetrica requestStartupIdentifiersWithCompletionQueue:nil
                                                                   completionBlock:callbackBlock];
                    [[theValue(result) should] equal:theValue(1)];
                });
                it(@"Should return nil for uuid", ^{
                    [[[AMAAppMetrica uuid] should] beNil];
                });
                it(@"Should return nil for deviceID", ^{
                    [[[AMAAppMetrica deviceID] should] beNil];
                });
            });
            context(@"Only local identifiers", ^{
                NSString *const uuid = @"uuid";
                NSString *const deviceID = @"device_id";
                beforeEach(^{
                    AMAMetricaPersistentConfiguration *conf = [AMAMetricaConfiguration sharedInstance].persistent;
                    [UUIDProvider stub:@selector(retrieveUUID) andReturn:uuid];
                    [conf stub:@selector(deviceID) andReturn:deviceID];
                    [conf stub:@selector(deviceIDHash) andReturn:nil];
                });
                it(@"Should return error async", ^{
                    NSError *error = [NSError errorWithDomain:@"test_domain" code:1 userInfo:nil];
                    [AMATestNetwork stubHTTPRequestToFinishWithError:error];
                    
                    __block NSInteger result = 0;
                    AMAIdentifiersCompletionBlock callbackBlock = ^(NSDictionary *identifiers, NSError *error) {
                        result = error.code;
                    };
                    [AMAAppMetrica requestStartupIdentifiersWithCompletionQueue:nil
                                                                   completionBlock:callbackBlock];
                    [[theValue(result) should] equal:theValue(1)];
                });
                it(@"Should return local identifiers", ^{
                    __block NSDictionary *result = nil;
                    AMAIdentifiersCompletionBlock callbackBlock = ^(NSDictionary *identifiers, NSError *error) {
                        result = identifiers;
                    };
                    [AMAAppMetrica requestStartupIdentifiersWithKeys:@[ kAMAUUIDKey, kAMADeviceIDKey ]
                                                        completionQueue:nil
                                                        completionBlock:callbackBlock];
                    [[result should] equal:@{
                        kAMAUUIDKey: uuid,
                        kAMADeviceIDKey: deviceID,
                    }];
                });
                it(@"Should return uuid", ^{
                    [[[AMAAppMetrica uuid] should] equal:uuid];
                });
                it(@"Should return deviceID", ^{
                    [[[AMAAppMetrica deviceID] should] equal:deviceID];
                });
            });
            context(@"With identifiers", ^{
                NSString *const uuid = @"uuid";
                NSString *const deviceID = @"device_id";
                NSString *const deviceIDHash = @"device_id_hash";
                beforeEach(^{
                    AMAMetricaPersistentConfiguration *conf = [AMAMetricaConfiguration sharedInstance].persistent;
                    [UUIDProvider stub:@selector(retrieveUUID) andReturn:uuid];
                    [conf stub:@selector(deviceID) andReturn:deviceID];
                    [conf stub:@selector(deviceIDHash) andReturn:deviceIDHash];
                });
                it(@"Should return identifiers async", ^{
                    __block NSDictionary *result = nil;
                    AMAIdentifiersCompletionBlock callbackBlock = ^(NSDictionary *identifiers, NSError *error) {
                        result = identifiers;
                    };
                    [AMAAppMetrica requestStartupIdentifiersWithCompletionQueue:nil
                                                                   completionBlock:callbackBlock];
                    [[result should] equal:@{
                        kAMAUUIDKey: uuid,
                        kAMADeviceIDKey: deviceID,
                        kAMADeviceIDHashKey: deviceIDHash,
                    }];
                });
                it(@"Should return UUID sync", ^{
                    [[[AMAAppMetrica uuid] should] equal:uuid];
                });
                it(@"Should return deviceID sync", ^{
                    [[[AMAAppMetrica deviceID] should] equal:deviceID];
                });
                it(@"Should return deviceIDHash async", ^{
                    NSString * __block retrievedDeviceIDHash = nil;
                    [AMAAppMetrica requestAppMetricaDeviceIDWithCompletionQueue:nil completionBlock:^(NSString * _Nullable appMetricaDeviceID, NSError * _Nullable error) {
                        retrievedDeviceIDHash = appMetricaDeviceID;
                    }];
                    [[deviceIDHash should] equal:retrievedDeviceIDHash];
                });
            });
            
            context(@"Sends events", ^{
                beforeEach(^{
                    stubMetrica();
                    [[AMAMetricaConfiguration sharedInstance].inMemory markMetricaStarted];
                });
                it(@"Should invoke delegates sendEventsBuffer method", ^{
                    [[impl should] receive:@selector(sendEventsBuffer)];
                    [AMAAppMetrica sendEventsBuffer];
                });
            });
        });
        context(@"Manual session tracking", ^{
            beforeEach(^{
                stubMetrica();
            });
            context(@"Before activation", ^{
                it(@"Should not pause", ^{
                    [[impl shouldNot] receive:@selector(pauseSession)];
                    AMAIgnoreAssert(^{
                        [AMAAppMetrica pauseSession];
                    });
                });
                it(@"Should not resume", ^{
                    [[impl shouldNot] receive:@selector(resumeSession)];
                    AMAIgnoreAssert(^{
                        [AMAAppMetrica resumeSession];
                    });
                });
            });
            context(@"After activation", ^{
                beforeEach(^{
                    [[AMAMetricaConfiguration sharedInstance].inMemory stub:@selector(metricaStarted)
                                                                  andReturn:theValue(YES)];
                });
                context(@"Auto tracking enabled", ^{
                    beforeEach(^{
                        AMAMetricaConfiguration *configuration = [AMAMetricaConfiguration sharedInstance];
                        [configuration.inMemory stub:@selector(sessionsAutoTracking) andReturn:theValue(YES)];
                    });
                    it(@"Should not pause", ^{
                        [[impl shouldNot] receive:@selector(pauseSession)];
                        AMAIgnoreAssert(^{
                            [AMAAppMetrica pauseSession];
                        });
                    });
                    it(@"Should not resume", ^{
                        [[impl shouldNot] receive:@selector(resumeSession)];
                        AMAIgnoreAssert(^{
                            [AMAAppMetrica resumeSession];
                        });
                    });
                });
                context(@"Auto tracking disabled", ^{
                    beforeEach(^{
                        AMAMetricaConfiguration *configuration = [AMAMetricaConfiguration sharedInstance];
                        [configuration.inMemory stub:@selector(sessionsAutoTracking) andReturn:theValue(NO)];
                    });
                    it(@"Should pause", ^{
                        [[impl should] receive:@selector(pauseSession)];
                        [AMAAppMetrica pauseSession];
                    });
                    it(@"Should resume", ^{
                        [[impl should] receive:@selector(resumeSession)];
                        [AMAAppMetrica resumeSession];
                    });
                });
            });
        });
    });
    context(@"Plugin extension", ^{
        AMAAppMetricaPluginsImpl *__block pluginImpl = nil;
        beforeEach(^{
            pluginImpl = [AMAAppMetricaPluginsImpl stubbedNullMockForDefaultInit];
        });
        it(@"Should return valid invariable plugin extension", ^{
            id pluginExtension = AMAAppMetrica.pluginExtension;
            [[pluginExtension should] equal:pluginImpl];
            pluginExtension = AMAAppMetrica.pluginExtension;
            [[pluginExtension should] equal:pluginImpl];
        });
    });
});

SPEC_END
