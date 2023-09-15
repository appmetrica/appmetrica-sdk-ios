
#import <Kiwi/Kiwi.h>
#import <AppMetricaWebKit/AppMetricaWebKit.h>
#import <AppMetricaPlatform/AppMetricaPlatform.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMAReporter.h"
#import "AMAAppMetricaImplTestFactory.h"
#import "AMAAppMetrica+TestUtilities.h"
#import "AMALocationManager.h"
#import "AMATestNetwork.h"
#import "AMAAppStateManagerTestHelper.h"
#import "AMAMetricaConfigurationTestUtilities.h"
#import "AMAFailureDispatcherTestHelper.h"
#import "AMAStartupItemsChangedNotifier+Tests.h"
#import "AMAInternalEventsReporter.h"
#import "AMAStartupHostProvider.h"
#import "AMAReporterTestHelper.h"
#import "AMATimeoutRequestsController.h"
#import "AMAUUIDProvider.h"
#import "AMAStartupResponseParser.h"
#import "AMAAppMetricaPluginsImpl.h"
#import "AMAAdProvider.h"
#import "AMADataSendingRestrictionController.h"

@interface AMAAppMetricaImpl () <AMAStartupControllerDelegate>

@property (nonatomic, strong) AMAStartupItemsChangedNotifier *startupItemsNotifier;
@property (nonatomic, strong) AMAStartupController *startupController;

@end

SPEC_BEGIN(AMAAppMetricaTests)

describe(@"AMAAppMetrica", ^{
    NSString *const apiKey = [AMAReporterTestHelper defaultApiKey];
    
    AMAAppStateManagerTestHelper *__block stateHelper = nil;
    AMAReporterTestHelper *__block reporterTestHelper = nil;
    AMAAppMetricaImpl *__block impl = nil;
    AMAAdProvider *__block adProvider = nil;
    
    beforeEach(^{
        [AMATestNetwork stubHTTPRequestWithBlock:nil];
    });
    void (^stubMetricaDependencies)(void) = ^{
        [AMAMetricaConfigurationTestUtilities stubConfigurationWithAppVersion:stateHelper.appVersionName
                                                                  buildNumber:stateHelper.appBuildNumber];
        stateHelper = [[AMAAppStateManagerTestHelper alloc] init];
        [stateHelper stubApplicationState];
        [AMAFailureDispatcherTestHelper stubFailureDispatcher];
        adProvider = [AMAAdProvider nullMock];
        [AMAAdProvider stub:@selector(sharedInstance) andReturn:adProvider];
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
    void (^stubMetricaStarted)(BOOL) = ^(BOOL started) {
        [[AMAMetricaConfiguration sharedInstance].inMemory stub:@selector(appMetricaStarted)
                                                      andReturn:theValue(started)];
    };
    
    context(@"Handling Invalid APIKey", ^{
        __block AMATestAssertionHandler *handler = nil;
        beforeEach(^{
            stubMetrica();
            handler = [AMATestAssertionHandler new];
            [handler beginAssertIgnoring];
        });
        afterEach(^{
            [handler endAssertIgnoring];
        });
        
        it(@"Should not activate if APIKey is not valid", ^{
            [[impl shouldNot] receive:@selector(activateWithConfiguration:)];
            
            [AMAAppMetrica activateWithConfiguration:[[AMAAppMetricaConfiguration alloc] initWithApiKey:@"---"]];
        });
        it(@"Should not activate if APIKey is not valid", ^{
            stubMetricaStarted(YES);
            [[impl shouldNot] receive:@selector(activateWithConfiguration:)];
            
            activate();
        });
        it(@"Should not activate if reporter is created for api key", ^{
            [AMAAppMetrica stub:@selector(isReporterCreatedForAPIKey:) andReturn:theValue(YES)];
            [[impl shouldNot] receive:@selector(activateWithConfiguration:)];
            
            activate();
        });
    });
    context(@"Location Manager", ^{
        it(@"Should set location to location manager", ^{
            stubMetrica();
            CLLocation *location = [[CLLocation alloc] initWithLatitude:11.0 longitude:12.0];
            [AMAAppMetrica setLocation:location];
            AMALocationManager *locationManager = [AMALocationManager sharedManager];
            [[theValue([location test_isEqualToLocation:[locationManager currentLocation]]) should] beYes];
        });
        
        it(@"Should set location tracking enabled", ^{
            AMALocationManager *locationManager = [AMALocationManager sharedManager];
            [[locationManager should] receive:@selector(setTrackLocationEnabled:)
                                withArguments:theValue(YES)];
            
            [AMAAppMetrica setLocationTracking:YES];
        });
        
        it(@"Should set accurate location tracking enabled", ^{
            AMALocationManager *locationManager = [AMALocationManager sharedManager];
            [[locationManager should] receive:@selector(setAccurateLocationEnabled:)
                                withArguments:theValue(YES)];
            
            [AMAAppMetrica setAccurateLocationTracking:YES];
        });
        
        it(@"Should set allows background location updates", ^{
            AMALocationManager *locationManager = [AMALocationManager sharedManager];
            [[locationManager should] receive:@selector(setAllowsBackgroundLocationUpdates:)
                                withArguments:theValue(YES)];
            
            [AMAAppMetrica setAllowsBackgroundLocationUpdates:YES];
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
            [[mockedImpl should] receive:@selector(reportUrl:ofType:isAuto:)
                           withArguments:URL, @"open", theValue(NO)];
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
            
            [AMAAppMetrica reportReferralUrl:url];
        });
        it(@"Should call impl with URL of type \"referral\"", ^{
            activate();
            [[mockedImpl should] receive:@selector(reportUrl:ofType:isAuto:)
                           withArguments:url, @"referral", theValue(NO)];
            
            [AMAAppMetrica reportReferralUrl:url];
        });
    });
    
    context(@"Public", ^{
        beforeEach(^{
            stubMetrica();
        });
        
        context(@"Should set data sending enabled", ^{
            AMADataSendingRestrictionController *__block restrictionController = nil;
            
            beforeEach(^{
                restrictionController = [AMADataSendingRestrictionController stubbedNullMockForDefaultInit];
                [AMADataSendingRestrictionController stub:@selector(sharedInstance) andReturn:restrictionController];
            });
            
            it(@"Should set allowed restriction", ^{
                [[restrictionController should] receive:@selector(setMainApiKeyRestriction:) withArguments:theValue(AMADataSendingRestrictionAllowed)];
                
                [AMAAppMetrica setDataSendingEnabled:YES];
            });
            
            it(@"Should set forbidden restriction", ^{
                [[restrictionController should] receive:@selector(setMainApiKeyRestriction:) withArguments:theValue(AMADataSendingRestrictionForbidden)];
                
                [AMAAppMetrica setDataSendingEnabled:NO];
            });
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
                stubMetricaStarted(YES);
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
            context(@"String event", ^{
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
                context(@"Event with type", ^{
                    NSUInteger const eventType = 1234;
                    NSString *const eventName = @"name";
                    NSString *const eventValue = @"value";
                    NSDictionary *const environment = @{ @"a": @"b" };
                    
                    it(@"Should report event with custom type", ^{
                        activate();
                        AMAReporter *reporter = reporterTestHelper.appReporter;
                        [[reporter should] receive:@selector(reportEventWithType:name:value:environment:extras:onFailure:)
                                     withArguments:theValue(eventType), eventName, eventValue, environment, nil, nil];
                        [AMAAppMetrica reportEventWithType:eventType
                                                      name:eventName
                                                     value:eventValue
                                               environment:environment
                                                 onFailure:nil];
                    });
                    
                    
                    it(@"Should not report event with custom type if metrica is not activated", ^{
                        AMAReporter *reporter = reporterTestHelper.appReporter;
                        [[reporter shouldNot] receive:@selector(reportEventWithType:name:value:environment:extras:onFailure:)];
                        [AMAAppMetrica reportEventWithType:eventType
                                                      name:eventName
                                                     value:eventValue
                                               environment:environment
                                                 onFailure:nil];
                    });
                });
            });
            context(@"Binary event", ^{
                context(@"Not activated Metrica", ^{
                    NSError *(^errorFromReporting)(void) = ^NSError * {
                        NSError *__block resultError = nil;
                        [AMAAppMetrica reportBinaryEventWithType:0
                                                            data:[NSData data]
                                                         gZipped:NO
                                                     environment:nil
                                                          extras:nil
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
                context(@"Event with binary type", ^{
                    NSUInteger const eventType = 1234;
                    NSDictionary *const environment = @{ @"a": @"b" };
                    NSData *data = [NSData data];
                    
                    it(@"Should report event with custom type", ^{
                        activate();
                        AMAReporter *reporter = reporterTestHelper.appReporter;
                        [[reporter should] receive:@selector(reportBinaryEventWithType:
                                                             data:
                                                             gZipped:
                                                             environment:
                                                             extras:
                                                             onFailure:)
                                     withArguments:theValue(eventType), data, theValue(YES), environment, nil, nil];
                        [AMAAppMetrica reportBinaryEventWithType:eventType
                                                            data:data
                                                         gZipped:YES
                                                     environment:environment
                                                          extras:nil
                                                       onFailure:nil];
                    });
                    
                    
                    it(@"Should not report event with custom type if metrica is not activated", ^{
                        AMAReporter *reporter = reporterTestHelper.appReporter;
                        [[reporter shouldNot] receive:@selector(reportBinaryEventWithType:
                                                                data:
                                                                gZipped:
                                                                environment:
                                                                extras:
                                                                onFailure:)];
                        [AMAAppMetrica reportBinaryEventWithType:eventType
                                                            data:data
                                                         gZipped:YES
                                                     environment:environment
                                                          extras:nil
                                                       onFailure:nil];
                    });
                });
            });
            context(@"File event", ^{
                context(@"Not activated Metrica", ^{
                    NSError *(^errorFromReporting)(void) = ^NSError * {
                        NSError *__block resultError = nil;
                        [AMAAppMetrica reportFileEventWithType:0
                                                          data:[NSData data]
                                                      fileName:@""
                                                       gZipped:YES
                                                     encrypted:NO
                                                     truncated:NO
                                                   environment:nil
                                                        extras:nil
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
                context(@"Event with binary type", ^{
                    NSUInteger const eventType = 1234;
                    NSDictionary *const environment = @{ @"a": @"b" };
                    NSData *data = [NSData data];
                    NSString *fileName = @"file:///";
                    
                    it(@"Should report event with custom type", ^{
                        activate();
                        AMAReporter *reporter = reporterTestHelper.appReporter;
                        [[reporter should] receive:@selector(reportFileEventWithType:
                                                             data:
                                                             fileName:
                                                             gZipped:
                                                             encrypted:
                                                             truncated:
                                                             environment:
                                                             extras:
                                                             onFailure:)
                                     withArguments:theValue(eventType), data, fileName, theValue(YES), theValue(YES), theValue(YES), environment, nil, nil];
                        [AMAAppMetrica reportFileEventWithType:eventType
                                                          data:data
                                                      fileName:fileName
                                                       gZipped:YES
                                                     encrypted:YES
                                                     truncated:YES
                                                   environment:environment
                                                        extras:nil
                                                     onFailure:nil];
                    });
                    
                    it(@"Should not report event with custom type if metrica is not activated", ^{
                        AMAReporter *reporter = reporterTestHelper.appReporter;
                        [[reporter shouldNot] receive:@selector(reportFileEventWithType:
                                                                data:
                                                                fileName:
                                                                gZipped:
                                                                encrypted:
                                                                truncated:
                                                                environment:
                                                                extras:
                                                                onFailure:)];
                        [AMAAppMetrica reportFileEventWithType:eventType
                                                          data:data
                                                      fileName:fileName
                                                       gZipped:YES
                                                     encrypted:YES
                                                     truncated:YES
                                                   environment:environment
                                                        extras:nil
                                                     onFailure:nil];
                    });
                });
            });
        });
        context(@"Profile event type", ^{
            AMAUserProfile *__block profile = nil;
            
            beforeEach(^{
                stubMetricaStarted(YES);
                profile = [AMAUserProfile nullMock];
                [profile stub:@selector(copy) andReturn:profile];
            });
            it(@"Should report event", ^{
                [[impl should] receive:@selector(reportUserProfile:onFailure:)
                         withArguments:profile, nil];
                
                [AMAAppMetrica reportUserProfile:profile onFailure:nil];
            });
            
            it(@"Should not report event if metrica is not started", ^{
                stubMetricaStarted(NO);
                
                [[impl shouldNot] receive:@selector(reportUserProfile:onFailure:)];
                
                [AMAAppMetrica reportUserProfile:profile onFailure:nil];
            });
        });
        context(@"Revenue event type", ^{
            AMARevenueInfo *__block revenueInfo = nil;
            
            beforeEach(^{
                stubMetricaStarted(YES);
                revenueInfo = [AMARevenueInfo nullMock];
                [revenueInfo stub:@selector(copy) andReturn:revenueInfo];
            });
            it(@"Should report event", ^{
                [[impl should] receive:@selector(reportRevenue:onFailure:)
                         withArguments:revenueInfo, nil];
                
                [AMAAppMetrica reportRevenue:revenueInfo onFailure:nil];
            });
            
            it(@"Should not report event if metrica is not started", ^{
                stubMetricaStarted(NO);
                
                [[impl shouldNot] receive:@selector(reportRevenue:onFailure:)];
                
                [AMAAppMetrica reportRevenue:revenueInfo onFailure:nil];
            });
        });
        context(@"Ecommerce event type", ^{
            AMAECommerce *__block ecommerce = nil;
            
            beforeEach(^{
                stubMetricaStarted(YES);
                ecommerce = [AMAECommerce nullMock];
                [ecommerce stub:@selector(copy) andReturn:ecommerce];
            });
            it(@"Should report event", ^{
                [[impl should] receive:@selector(reportECommerce:onFailure:)
                         withArguments:ecommerce, nil];
                
                [AMAAppMetrica reportECommerce:ecommerce onFailure:nil];
            });
            
            it(@"Should not report event if metrica is not started", ^{
                stubMetricaStarted(NO);
                
                [[impl shouldNot] receive:@selector(reportECommerce:onFailure:)];
                
                [AMAAppMetrica reportECommerce:ecommerce onFailure:nil];
            });
        });
        context(@"AdRevenue event type", ^{
            AMAAdRevenueInfo *__block adRevenueInfo = nil;
            
            beforeEach(^{
                stubMetricaStarted(YES);
                adRevenueInfo = [AMAAdRevenueInfo nullMock];
                [adRevenueInfo stub:@selector(copy) andReturn:adRevenueInfo];
            });
            
            it(@"Should report event if metrica is started", ^{
                [[impl should] receive:@selector(reportAdRevenue:onFailure:)
                         withArguments:adRevenueInfo, nil];
                
                [AMAAppMetrica reportAdRevenue:adRevenueInfo onFailure:nil];
            });
            it(@"Should not report event if metrica is not started", ^{
                stubMetricaStarted(NO);
                
                [[impl shouldNot] receive:@selector(reportAdRevenue:onFailure:)];
                
                [AMAAppMetrica reportAdRevenue:adRevenueInfo onFailure:nil];
            });
        });
        context(@"Should report event", ^{
            NSString *const message = @"msg";
            NSDictionary *const parameters = @{@"key": @"value"};
            
            beforeEach(^{
                stubMetricaStarted(YES);
            });
            
            it(@"Should call report event with parameters", ^{
                [[AMAAppMetrica should] receive:@selector(reportEvent:parameters:onFailure:)
                         withArguments:message, nil, kw_any()];
                
                [AMAAppMetrica reportEvent:message onFailure:nil];
            });
            
            it(@"Should report event if metrica is started", ^{
                [[impl should] receive:@selector(reportEvent:parameters:onFailure:)
                         withArguments:message, parameters, kw_any()];
                
                [AMAAppMetrica reportEvent:message parameters:parameters onFailure:nil];
            });
            it(@"Should not report event if metrica is not started", ^{
                stubMetricaStarted(NO);
                
                [[impl shouldNot] receive:@selector(reportEvent:parameters:onFailure:)];
                
                [AMAAppMetrica reportEvent:message parameters:parameters onFailure:nil];
            });
        });
        context(@"Init web view reporting", ^{
            AMAJSController *__block jsController = nil;
            
            beforeEach(^{
                stubMetricaStarted(YES);
                
                WKUserContentController *controller = [WKUserContentController nullMock];
                jsController = [[AMAJSController alloc] initWithUserContentController:controller];
            });
            
            it(@"Should init", ^{
                [[impl should] receive:@selector(setupWebViewReporting:)
                         withArguments:jsController];

                [AMAAppMetrica setupWebViewReporting:jsController
                                              onFailure:nil];
            });
            it(@"Should not init if metrica is not started", ^{
                stubMetricaStarted(NO);

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
                stubMetricaStarted(YES);
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
                    stubMetricaStarted(YES);
                });
                it(@"Should sendEventsBuffer if metrica is started", ^{
                    [[impl should] receive:@selector(sendEventsBuffer)];
                    
                    [AMAAppMetrica sendEventsBuffer];
                });
                
                it(@"Should not sendEventsBuffer if metrica is started", ^{
                    stubMetricaStarted(NO);
                    
                    [[impl shouldNot] receive:@selector(sendEventsBuffer)];
                    
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
                    stubMetricaStarted(YES);
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
                
                it(@"Should return library version", ^{
                    NSString *version = @"11.22.63";
                    [AMAPlatformDescription stub:@selector(SDKVersionName) andReturn:version];
                    
                    [[[AMAAppMetrica libraryVersion] should] equal:version];
                });
                
                context(@"Environment", ^{
                    NSString *const value = @"value";
                    NSString *const key = @"value";
                    beforeEach(^{
                        [[AMAMetricaConfiguration sharedInstance].inMemory stub:@selector(appMetricaImplCreated)
                                                                      andReturn:theValue(YES)];
                    });
                    it(@"Should set error environment if metrica impl is started", ^{
                        [[impl should] receive:@selector(setErrorEnvironmentValue:forKey:)
                                 withArguments:value, key];
                        
                        [AMAAppMetrica setErrorEnvironmentValue:value forKey:key];
                    });
                    it(@"Should sync error environment if metrica is not started", ^{
                        [[AMAMetricaConfiguration sharedInstance].inMemory stub:@selector(appMetricaImplCreated)
                                                                      andReturn:theValue(NO)];
                        [[impl shouldNot] receive:@selector(setErrorEnvironmentValue:forKey:)];
                        [[AMAAppMetricaImpl should] receive:@selector(syncSetErrorEnvironmentValue:forKey:)
                                 withArguments:value, key];

                        [AMAAppMetrica setErrorEnvironmentValue:value forKey:key];
                    });
                    
                    it(@"Should set app environment", ^{
                        [[impl should] receive:@selector(setAppEnvironmentValue:forKey:)
                                 withArguments:value, key];
                        
                        [AMAAppMetrica setAppEnvironmentValue:value forKey:key];
                    });
                    
                    it(@"Should clear app environment", ^{
                        [[impl should] receive:@selector(clearAppEnvironment)];
                        
                        [AMAAppMetrica clearAppEnvironment];
                    });
                });
            });
        });
        
        context(@"Extended Availability", ^{
            it(@"Should register activation delegate", ^{
                AMAModuleActivationConfiguration *configuration = [AMAModuleActivationConfiguration stubbedNullMockForInit:@selector(initWithApiKey:appVersion:appBuildNumber:)];
                id activationDelegate = [KWMock nullMock];
    
                [AMAAppMetrica addActivationDelegate:activationDelegate];
    
                [[activationDelegate should] receive:@selector(didActivateWithConfiguration:) withArguments:configuration];
    
    
                id startupObserver = [KWMock nullMockForProtocol:@protocol(AMAExtendedStartupObserving)];
                id reporterStorageController = [KWMock nullMockForProtocol:@protocol(AMAReporterStorageControlling)];
    
                __auto_type *config = [[AMAServiceConfiguration alloc] initStartupObserver:startupObserver
                                                                 reporterStorageController:reporterStorageController];
                
                activate();
            });
            it(@"Should register event flushable delegate", ^{
                stubMetricaStarted(YES);
    
                AMAModuleActivationConfiguration *configuration = [AMAModuleActivationConfiguration stubbedNullMockForInit:@selector(initWithApiKey:appVersion:appBuildNumber:)];
                id eventFlushableDelegate = [KWMock nullMock];
    
                [AMAAppMetrica addEventFlushableDelegate:eventFlushableDelegate];
    
                [[eventFlushableDelegate should] receive:@selector(sendEventsBuffer)];
    
                [AMAAppMetrica sendEventsBuffer];
            });
            it(@"Should return extended reporter", ^{
                stubMetricaStarted(NO);
                
                activate();
                
                id extendedReporter = [AMAAppMetrica extendedReporterForApiKey:apiKey];
                id reporter = [AMAAppMetrica reporterForApiKey:apiKey];
                
                [[extendedReporter should] beNonNil];
                [[extendedReporter should] equal:reporter];
            });
            it(@"Should mark external services configured on main reporter activation", ^{
                stubMetricaStarted(NO);
                [[AMAMetricaConfiguration sharedInstance].inMemory stub:@selector(externalServicesConfigured) andReturn:theValue(NO)];
    
                [[[AMAMetricaConfiguration sharedInstance].inMemory should] receive:@selector(markExternalServicesConfigured)];
                
                activate();
            });
            it(@"Should mark external services configured on secondary reporter activation", ^{
                stubMetricaStarted(NO);
                [[AMAMetricaConfiguration sharedInstance].inMemory stub:@selector(externalServicesConfigured) andReturn:theValue(NO)];
    
                [[[AMAMetricaConfiguration sharedInstance].inMemory should] receive:@selector(markExternalServicesConfigured)];
                
                [AMAAppMetrica activateReporterWithConfiguration:[[AMAReporterConfiguration alloc] initWithApiKey:apiKey]];
            });
            it(@"Should not setup external services on main activation if already configured", ^{
                stubMetricaStarted(NO);
                [[AMAMetricaConfiguration sharedInstance].inMemory stub:@selector(externalServicesConfigured) andReturn:theValue(YES)];
    
                [[[AMAMetricaConfiguration sharedInstance].inMemory shouldNot] receive:@selector(markExternalServicesConfigured)];
                [[impl shouldNot] receive:@selector(setExtendedStartupObservers:)];
                [[impl shouldNot] receive:@selector(setExtendedReporterStorageControllers:)];
                [[adProvider shouldNot] receive:@selector(setupAdProvider:)];
                
                activate();
            });
            it(@"Should not setup external services on secondary reporter activation if already configured", ^{
                stubMetricaStarted(NO);
                [[AMAMetricaConfiguration sharedInstance].inMemory stub:@selector(externalServicesConfigured) andReturn:theValue(YES)];
    
                [[[AMAMetricaConfiguration sharedInstance].inMemory shouldNot] receive:@selector(markExternalServicesConfigured)];
                [[impl shouldNot] receive:@selector(setExtendedStartupObservers:)];
                [[impl shouldNot] receive:@selector(setExtendedReporterStorageControllers:)];
                [[adProvider shouldNot] receive:@selector(setupAdProvider:)];
                
                [AMAAppMetrica activateReporterWithConfiguration:[[AMAReporterConfiguration alloc] initWithApiKey:apiKey]];
            });
            context(@"Service Configuration", ^{
                context(@"Startup observer", ^{
                    id<AMAExtendedStartupObserving> __block startupObserver = nil;
                    AMAServiceConfiguration *__block config = nil;
                    beforeAll(^{
                        startupObserver = [KWMock nullMockForProtocol:@protocol(AMAExtendedStartupObserving)];
                        config = [[AMAServiceConfiguration alloc] initStartupObserver:startupObserver
                                                            reporterStorageController:nil];
                    });
                    it(@"Should register Startup observer on activation main reporter", ^{
                        [AMAAppMetrica registerExternalService:config];
                        
                        KWCaptureSpy *spy = [impl captureArgument:@selector(setExtendedStartupObservers:) atIndex:0];
                        
                        [[impl should] receive:@selector(setExtendedStartupObservers:)];
                        
                        activate();
                        
                        [[spy.argument should] equal:[NSMutableSet setWithObject:startupObserver]];
                    });
                    it(@"Should register Startup observer on activation secondary reporter", ^{
                        [AMAAppMetrica registerExternalService:config];
                        
                        KWCaptureSpy *spy = [impl captureArgument:@selector(setExtendedStartupObservers:) atIndex:0];
                        
                        [[impl should] receive:@selector(setExtendedStartupObservers:)];
                        
                        [AMAAppMetrica activateReporterWithConfiguration:[[AMAReporterConfiguration alloc] initWithApiKey:apiKey]];
                        
                        [[spy.argument should] equal:[NSMutableSet setWithObject:startupObserver]];
                    });
                });
                context(@"Reporter storage controller", ^{
                    id<AMAReporterStorageControlling> __block reporterStorageController = nil;
                    AMAServiceConfiguration *__block config = nil;
                    beforeAll(^{
                        reporterStorageController = [KWMock nullMockForProtocol:@protocol(AMAReporterStorageControlling)];
                        config = [[AMAServiceConfiguration alloc] initStartupObserver:nil
                                                            reporterStorageController:reporterStorageController];
                    });
                    it(@"Should register reporter storage controller on activation main reporter", ^{
                        [AMAAppMetrica registerExternalService:config];
                        
                        KWCaptureSpy *spy = [impl captureArgument:@selector(setExtendedReporterStorageControllers:) atIndex:0];
                        
                        [[impl should] receive:@selector(setExtendedReporterStorageControllers:)];
                        
                        activate();
                        
                        [[spy.argument should] equal:[NSMutableSet setWithObject:reporterStorageController]];
                    });
                    it(@"Should register reporter storage controller on activation secondary reporter", ^{
                        [AMAAppMetrica registerExternalService:config];
                        
                        KWCaptureSpy *spy = [impl captureArgument:@selector(setExtendedReporterStorageControllers:) atIndex:0];
                        
                        [[impl should] receive:@selector(setExtendedReporterStorageControllers:)];
                        
                        [AMAAppMetrica activateReporterWithConfiguration:[[AMAReporterConfiguration alloc] initWithApiKey:apiKey]];
                        
                        [[spy.argument should] equal:[NSMutableSet setWithObject:reporterStorageController]];
                    });
                });
            });
            it(@"Should register external AdController on activate main reporter", ^{
                id adController = [KWMock nullMockForProtocol:@protocol(AMAAdProviding)];

                [AMAAppMetrica registerAdProvider:adController];

                [[adProvider should] receive:@selector(setupAdProvider:) withArguments:adController];

                activate();
            });
            it(@"Should register external AdController on activate reporter", ^{
                id adController = [KWMock nullMockForProtocol:@protocol(AMAAdProviding)];

                [AMAAppMetrica registerAdProvider:adController];

                [[adProvider should] receive:@selector(setupAdProvider:) withArguments:adController];

                [AMAAppMetrica activateReporterWithConfiguration:[[AMAReporterConfiguration alloc] initWithApiKey:apiKey]];
            });
            it(@"Should return yes if api key is valid", ^{
                [AMAIdentifierValidator stub:@selector(isValidUUIDKey:) andReturn:theValue(YES)];
                
                [[theValue([AMAAppMetrica isAPIKeyValid:@"api-key"]) should] beYes];
            });
            it(@"Should return yes if AppMetrica started", ^{
                stubMetricaStarted(YES);
                
                [[theValue([AMAAppMetrica isAppMetricaStarted]) should] beYes];
            });
            it(@"Should return yes if reporter is created for api key", ^{
                [[AMAMetricaConfiguration sharedInstance].inMemory stub:@selector(appMetricaImplCreated)
                                                              andReturn:theValue(YES)];
                [impl stub:@selector(isReporterCreatedForAPIKey:) andReturn:theValue(YES)];
                
                [[theValue([AMAAppMetrica isReporterCreatedForAPIKey:@"api-key"]) should] beYes];
            });
        });
    });
    
    context(@"Session Extras", ^{
        AMAAppMetricaImpl *__block mockedImpl = nil;
        beforeEach(^{
            mockedImpl = [AMAAppMetricaImpl nullMock];
            stubMetrica();
            [AMAAppMetrica stub:@selector(sharedImpl) andReturn:mockedImpl];
        });
        
        it(@"Should set session extras", ^{
            NSData *data = [NSData nullMock];
            NSString *key = @"sesion.extras";
            
            [[mockedImpl should] receive:@selector(setSessionExtras:forKey:) withArguments:data, key];
            
            [AMAAppMetrica setSessionExtras:data forKey:key];
        });
        
        it(@"Should clear session extras", ^{
            [[mockedImpl should] receive:@selector(clearSessionExtra)];
            
            [AMAAppMetrica clearSessionExtra];
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
