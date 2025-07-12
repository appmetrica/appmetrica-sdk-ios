#import <Kiwi/Kiwi.h>
#import <AppMetricaWebKit/AppMetricaWebKit.h>
#import <AppMetricaPlatform/AppMetricaPlatform.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMAAppMetrica+TestUtilities.h"
#import "AMAAdProvider.h"
#import "AMAAppMetricaImplTestFactory.h"
#import "AMAAppMetrica+Internal.h"
#import "AMALocationManager.h"
#import "AMAAppStateManagerTestHelper.h"
#import "AMADataSendingRestrictionController.h"
#import "AMAEventPollingDelegate.h"
#import "AMAFailureDispatcherTestHelper.h"
#import "AMAInternalEventsReporter.h"
#import "AMALocationManager.h"
#import "AMAMetricaConfigurationTestUtilities.h"
#import "AMAReporter.h"
#import "AMAReporterTestHelper.h"
#import "AMAStartupHostProvider.h"
#import "AMAStartupItemsChangedNotifier+Tests.h"
#import "AMAStartupResponseParser.h"
#import "AMATimeoutRequestsController.h"
#import "AMAIdentifierProviderMock.h"
#import "AMAIdentifiersTestUtilities.h"
#import "AMAAdResolver.h"
#import "AMAAdRevenueSourceContainer.h"

@interface AMAAppMetricaImpl () <AMAStartupControllerDelegate>

@property (nonatomic, strong) AMAStartupItemsChangedNotifier *startupItemsNotifier;
@property (nonatomic, strong) AMAStartupController *startupController;

@end

SPEC_BEGIN(AMAAppMetricaTests)

describe(@"AMAAppMetrica", ^{
    NSString *const apiKey = [AMAReporterTestHelper defaultApiKey];
    NSString *const anonymousApiKey = @"629a824d-c717-4ba5-bc0f-3f3968554d01";
    
    AMAAppStateManagerTestHelper *__block stateHelper = nil;
    AMAReporterTestHelper *__block reporterTestHelper = nil;
    AMAAppMetricaImpl *__block impl = nil;
    AMAIdentifierProviderMock *__block identifierManagerMock = nil;
    AMAAdResolver *__block adResolver = nil;
    
    beforeEach(^{
        adResolver = [AMAAdResolver nullMock];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
        [AMAAppMetrica registerAdProvider:nil]; // reset adProvider
#pragma clang diagnostic pop
        [AMAAppMetrica stub:@selector(createAdResolverIfNeeded) andReturn:adResolver];
        [[AMAMetricaConfiguration sharedInstance] stub:@selector(identifierProvider) andReturn:identifierManagerMock];
        [AMATestNetwork stubHTTPRequestWithBlock:nil];
    });
    afterEach(^{
        [AMAAppMetrica clearStubs];
    });
    
    void (^stubMetricaDependencies)(void) = ^{
        [AMAMetricaConfigurationTestUtilities stubConfigurationWithAppVersion:stateHelper.appVersionName
                                                                  buildNumber:stateHelper.appBuildNumber];
        stateHelper = [[AMAAppStateManagerTestHelper alloc] init];
        [stateHelper stubApplicationState];
        identifierManagerMock = [AMAIdentifiersTestUtilities stubIdentifierProviderIfNeeded];
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
        [impl stub:@selector(apiKey) andReturn:apiKey];
        
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
        [AMAAppMetrica activateWithConfiguration:[[AMAAppMetricaConfiguration alloc] initWithAPIKey:apiKey]];
    };
    void (^activateAnonymously)(void) = ^{
        [AMAAppMetrica activate];
    };
    void (^activateAnonymouslyWithAdTrackingEnabled)(BOOL) = ^(BOOL trackingEnabled){
        [AMAAppMetrica activateWithAdIdentifierTrackingEnabled:trackingEnabled];
    };
    void (^stubMetricaStarted)(BOOL) = ^(BOOL started) {
        [[AMAMetricaConfiguration sharedInstance].inMemory stub:@selector(appMetricaStarted)
                                                      andReturn:theValue(started)];
    };
    void (^stubMetricaStartedAnonymously)(BOOL) = ^(BOOL started) {
        [[AMAMetricaConfiguration sharedInstance].inMemory stub:@selector(appMetricaStartedAnonymously)
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
            
            [AMAAppMetrica activateWithConfiguration:[[AMAAppMetricaConfiguration alloc] initWithAPIKey:@"---"]];
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
            [AMAAppMetrica setCustomLocation:location];
            AMALocationManager *locationManager = [AMALocationManager sharedManager];
            [[theValue([location test_isEqualToLocation:[locationManager currentLocation]]) should] beYes];
        });
        
        it(@"Should set location tracking enabled", ^{
            AMALocationManager *locationManager = [AMALocationManager sharedManager];
            [[locationManager should] receive:@selector(setTrackLocationEnabled:)
                                withArguments:theValue(YES)];
            
            [AMAAppMetrica setLocationTrackingEnabled:YES];
        });
        
        it(@"Should set accurate location tracking enabled", ^{
            AMALocationManager *locationManager = [AMALocationManager sharedManager];
            [[locationManager should] receive:@selector(setAccurateLocationEnabled:)
                                withArguments:theValue(YES)];
            
            [AMAAppMetrica setAccurateLocationTrackingEnabled:YES];
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
            AMAAppMetricaConfiguration *configuration = [[AMAAppMetricaConfiguration alloc] initWithAPIKey:apiKey];
            NSUInteger maxReportsCount = 3;
            configuration.maxReportsCount = maxReportsCount;
            [AMAAppMetrica activateWithConfiguration:configuration];
            NSUInteger currentMaxReportsCount = [AMAAppMetrica maxReportsCount];
            [[theValue(currentMaxReportsCount) should] equal:theValue(maxReportsCount)];
        });
        it(@"Should set dispatch period before activateWithApiKey", ^{
            stubMetrica();
            AMAAppMetricaConfiguration *configuration = [[AMAAppMetricaConfiguration alloc] initWithAPIKey:apiKey];
            NSUInteger dispatchPeriod = 33;
            configuration.dispatchPeriod = dispatchPeriod;
            [AMAAppMetrica activateWithConfiguration:configuration];
            NSUInteger currentDispatchPeriod = [AMAAppMetrica dispatchPeriod];
            [[theValue(currentDispatchPeriod) should] equal:theValue(dispatchPeriod)];
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
                [[AMAMutableReporterConfiguration alloc] initWithAPIKey:reporterApiKey];
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
                [[AMAMutableReporterConfiguration alloc] initWithAPIKey:reporterApiKey];
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
                [[AMAMutableReporterConfiguration alloc] initWithAPIKey:reporterApiKey];
                mutableConfig.sessionTimeout = newSessionTimeout;
                [AMAAppMetrica activateReporterWithConfiguration:[mutableConfig copy]];
                
                AMAReporterConfiguration *sameConfig =
                [[AMAMetricaConfiguration sharedInstance] configurationForApiKey:reporterApiKey];
                [[theValue(sameConfig.sessionTimeout) should] equal:theValue(expectedSessionTimeout)];
            });
        });
    });
    context(@"Open URL handling", ^{
        AMAAppMetricaImpl *__block mockedImpl = nil;
        NSURL *const URL = [NSURL URLWithString:@"https://some.url"];
        beforeEach(^{
            mockedImpl = [AMAAppMetricaImpl nullMock];
            [mockedImpl stub:@selector(activateWithConfiguration:) withBlock:^id(NSArray *params) {
                [[AMAMetricaConfiguration sharedInstance].inMemory markAppMetricaStarted];
                return nil;
            }];

            stubMetrica();
            [AMAAppMetrica stub:@selector(sharedImpl) andReturn:mockedImpl];
        });
        it(@"Should not call impl if metrica is not started", ^{
            [[mockedImpl shouldNot] receive:@selector(reportUrl:ofType:isAuto:)];
            [AMAAppMetrica trackOpeningURL:URL];
        });
        it(@"Should call impl with URL of type \"open\"", ^{
            activate();
            [[mockedImpl should] receive:@selector(reportUrl:ofType:isAuto:)
                           withArguments:URL, @"open", theValue(NO)];
            [AMAAppMetrica trackOpeningURL:URL];
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
            
            it(@"Should return restriction value", ^{
                [impl stub:@selector(isAllowedToSendData:)
                                  andReturn:theValue(NO)
                              withArguments:apiKey];
                
                [[theValue([AMAAppMetrica shouldReportToApiKey:apiKey]) should] beNo];
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
                    [[AMAAppMetricaConfiguration alloc] initWithAPIKey:@"550e8400-e29b-41d4-a716-446655440001"];
                    [AMAAppMetrica activateWithConfiguration:configuration];
                });
                
                [[[[AMAAppMetrica sharedImpl] apiKey] should] equal:apiKey];
            });
            it(@"Should allow getting manual reporter for main api key", ^{
                activate();
                
                id reporter = [AMAAppMetrica reporterForAPIKey:apiKey];
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
                                          eventEnvironment:@{}
                                            appEnvironment:@{}
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
                context(@"Event with type", ^{
                    NSUInteger const eventType = 1234;
                    NSString *const eventName = @"name";
                    NSString *const eventValue = @"value";
                    NSDictionary *const eventEnvironment = @{ @"c": @"d" };
                    NSDictionary *const appEnvironment = @{ @"a": @"b" };
                    NSDictionary *const extras = @{ @"foo" : [NSData data] };
                    
                    it(@"Should report event with custom type", ^{
                        activate();
                        AMAReporter *reporter = reporterTestHelper.appReporter;
                        [[reporter should] receive:@selector(reportEventWithType:
                                                             name:
                                                             value:
                                                             eventEnvironment:
                                                             appEnvironment:
                                                             extras:
                                                             onFailure:)
                                     withArguments:theValue(eventType), eventName, eventValue, eventEnvironment, appEnvironment, extras, nil];
                        
                        [AMAAppMetrica reportEventWithType:eventType
                                                      name:eventName
                                                     value:eventValue
                                          eventEnvironment:eventEnvironment
                                            appEnvironment:appEnvironment
                                                    extras:extras
                                                 onFailure:nil];
                    });
                    
                    
                    it(@"Should not report event with custom type if metrica is not activated", ^{
                        AMAReporter *reporter = reporterTestHelper.appReporter;
                        [[reporter shouldNot] receive:@selector(reportEventWithType:
                                                                name:
                                                                value:
                                                                eventEnvironment:
                                                                appEnvironment:
                                                                extras:
                                                                onFailure:)];

                        [AMAAppMetrica reportEventWithType:eventType
                                                      name:eventName
                                                     value:eventValue
                                          eventEnvironment:eventEnvironment
                                            appEnvironment:appEnvironment
                                                    extras:extras
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
                                                            name:nil
                                                         gZipped:NO
                                                eventEnvironment:nil
                                                  appEnvironment:nil
                                                          extras:nil
                                                  bytesTruncated:0
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
                    NSDictionary *const eventEnvironment = @{ @"a": @"b" };
                    NSDictionary *const appEnvironment = @{ @"c": @"d" };
                    NSString *const eventName = @"foo";
                    NSData *data = [NSData data];
                    
                    it(@"Should report event with custom type", ^{
                        activate();
                        AMAReporter *reporter = reporterTestHelper.appReporter;
                        [[reporter should] receive:@selector(reportBinaryEventWithType:
                                                             data:
                                                             name:
                                                             gZipped:
                                                             eventEnvironment:
                                                             appEnvironment:
                                                             extras:
                                                             bytesTruncated:
                                                             onFailure:)
                                     withArguments:theValue(eventType), data, eventName, theValue(YES), eventEnvironment, appEnvironment, nil, theValue(8), nil];
                        [AMAAppMetrica reportBinaryEventWithType:eventType
                                                            data:data
                                                            name:eventName
                                                         gZipped:YES
                                                eventEnvironment:eventEnvironment
                                                  appEnvironment:appEnvironment
                                                          extras:nil
                                                  bytesTruncated:8
                                                       onFailure:nil];
                    });
                    
                    
                    it(@"Should not report event with custom type if metrica is not activated", ^{
                        AMAReporter *reporter = reporterTestHelper.appReporter;
                        [[reporter shouldNot] receive:@selector(reportBinaryEventWithType:
                                                                data:
                                                                name:
                                                                gZipped:
                                                                eventEnvironment:
                                                                appEnvironment:
                                                                extras:
                                                                bytesTruncated:
                                                                onFailure:)];
                        [AMAAppMetrica reportBinaryEventWithType:eventType
                                                            data:data
                                                            name:nil
                                                         gZipped:YES
                                                eventEnvironment:eventEnvironment
                                                  appEnvironment:appEnvironment
                                                          extras:nil
                                                  bytesTruncated:0
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
                                              eventEnvironment:nil
                                                appEnvironment:nil
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
                                                             eventEnvironment:
                                                             appEnvironment:
                                                             extras:
                                                             onFailure:)
                                     withArguments:theValue(eventType), data, fileName, theValue(YES), theValue(YES), theValue(YES), environment, environment, nil, nil];
                        [AMAAppMetrica reportFileEventWithType:eventType
                                                          data:data
                                                      fileName:fileName
                                                       gZipped:YES
                                                     encrypted:YES
                                                     truncated:YES
                                              eventEnvironment:environment
                                                appEnvironment:environment
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
                                                                eventEnvironment:
                                                                appEnvironment:
                                                                extras:
                                                                onFailure:)];
                        [AMAAppMetrica reportFileEventWithType:eventType
                                                          data:data
                                                      fileName:fileName
                                                       gZipped:YES
                                                     encrypted:YES
                                                     truncated:YES
                                              eventEnvironment:environment
                                                appEnvironment:environment
                                                        extras:nil
                                                     onFailure:nil];
                    });
                });
            });
        });
        context(@"System SDK event", ^{
            NSString *const eventName = @"eventName";
            
            beforeEach(^{
                stubMetricaStarted(YES);
            });
            it(@"Should report event", ^{
                [[impl should] receive:@selector(reportSystemEvent:onFailure:)
                         withArguments:eventName, nil];
                
                [AMAAppMetrica reportSystemEvent:eventName onFailure:nil];
            });
            
            it(@"Should not report event if metrica is not started", ^{
                stubMetricaStarted(NO);
                
                [[impl shouldNot] receive:@selector(reportSystemEvent:onFailure:)];
                
                [AMAAppMetrica reportSystemEvent:eventName onFailure:nil];
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
                [[impl should] receive:@selector(reportAdRevenue:isAutocollected:onFailure:)
                         withArguments:adRevenueInfo, theValue(NO), nil];
                
                [AMAAppMetrica reportAdRevenue:adRevenueInfo onFailure:nil];
            });
            it(@"Should report event if metrica is started with autocollected", ^{
                [[impl should] receive:@selector(reportAdRevenue:isAutocollected:onFailure:)
                         withArguments:adRevenueInfo, theValue(YES), nil];
                
                [AMAAppMetrica reportAdRevenue:adRevenueInfo isAutocollected:YES onFailure:nil];
            });
            it(@"Should not report event if metrica is not started", ^{
                stubMetricaStarted(NO);
                
                [[impl shouldNot] receive:@selector(reportAdRevenue:isAutocollected:onFailure:)];
                
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
#if !TARGET_OS_TV
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
#endif
        context(@"External attribution", ^{
            NSDictionary *const data = @{@"a": @"b"};
            AMAAttributionSource const source = kAMAAttributionSourceAppsflyer;

            beforeEach(^{
                stubMetricaStarted(YES);
            });

            it(@"Should report", ^{
                [[impl should] receive:@selector(reportExternalAttribution:source:onFailure:)
                         withArguments:data, source, kw_any()];

                [AMAAppMetrica reportExternalAttribution:data
                                                  source:source
                                               onFailure:nil];
            });

            it(@"Should not report if metrica is not started", ^{
                stubMetricaStarted(NO);

                [[impl shouldNot] receive:@selector(reportExternalAttribution:source:onFailure:)];

                [AMAAppMetrica reportExternalAttribution:data
                                                  source:source
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
                [AMAAppMetrica stub:@selector(reporterForAPIKey:) withBlock:^id(NSArray *params) {
                    result = YES;
                    return nil;
                }];
                
                [AMAAppMetrica reporterForAPIKey:apiKey];
                [[theValue(result) should] beYes];
            });
            it(@"Should return the same result as reporterForApiKey:", ^{
                NSObject *returnObject = [NSObject new];
                [AMAAppMetrica stub:@selector(reporterForAPIKey:) andReturn:returnObject];
                
                BOOL result =
                [AMAAppMetrica reporterForAPIKey:apiKey] == [AMAAppMetrica reporterForAPIKey:apiKey];
                [[theValue(result) should] beYes];
            });
        });
        context(@"Startup identifiers", ^{

            beforeEach(^{
                stubMetrica();
                stubMetricaStarted(YES);
                [AMAAppMetrica setDataSendingEnabled:YES];
            });
            
            context(@"No identifiers", ^{
                beforeEach(^{
                    AMAMetricaPersistentConfiguration *conf = [AMAMetricaConfiguration sharedInstance].persistent;
                    identifierManagerMock.mockMetricaUUID = nil;
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
                    [[[AMAAppMetrica UUID] should] beNil];
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
                    identifierManagerMock.mockMetricaUUID = uuid;
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
                    [[[AMAAppMetrica UUID] should] equal:uuid];
                });
                it(@"Should migrate before return UUID", ^{
                    AMAMetricaConfiguration *configuration = [AMAMetricaConfiguration nullMock];
                    [AMAMetricaConfiguration stub:@selector(sharedInstance) andReturn:configuration];
                    [[configuration should] receive:@selector(ensureMigrated)];
                    
                    [AMAAppMetrica UUID];
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
                    identifierManagerMock.mockMetricaUUID = uuid;
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
                    [[[AMAAppMetrica UUID] should] equal:uuid];
                });
                it(@"Should return deviceID sync", ^{
                    [[[AMAAppMetrica deviceID] should] equal:deviceID];
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
            AMAModuleActivationConfiguration *__block activationConfiguration = nil;
            AMATestAssertionHandler *__block handler = nil;
            
            beforeEach(^{
                activationConfiguration = [AMAModuleActivationConfiguration stubbedNullMockForInit:@selector(initWithApiKey:appVersion:appBuildNumber:)];
                
                handler = [AMATestAssertionHandler new];
            });
            
            it(@"Should activate anonymously if not activated as main", ^{
                stubMetricaStarted(NO);
                stubMetricaStartedAnonymously(NO);
                
                [[impl should] receive:@selector(scheduleAnonymousActivationIfNeeded)];
                
                activateAnonymously();
            });
            it(@"Should not activate anonymously if activated as main", ^{
                stubMetricaStarted(YES);
                
                [[impl shouldNot] receive:@selector(scheduleAnonymousActivationIfNeeded)];
                
                activateAnonymously();
            });
            it(@"Should not activate anonymously if activated anonymously", ^{
                stubMetricaStartedAnonymously(YES);
                
                [[impl shouldNot] receive:@selector(scheduleAnonymousActivationIfNeeded)];
                
                activateAnonymously();
            });
            it(@"Should activate delegate for anonymous activation", ^{
                id activationDelegate = [KWMock nullMock];
    
                [AMAAppMetrica addActivationDelegate:activationDelegate];
                
                [[activationConfiguration should] receive:@selector(initWithApiKey:appVersion:appBuildNumber:)
                                                withCount:2
                                                arguments:anonymousApiKey, kw_any(), kw_any()];
                
                [[activationDelegate should] receive:@selector(didActivateWithConfiguration:) withArguments:activationConfiguration];
                [[activationDelegate should] receive:@selector(willActivateWithConfiguration:) withArguments:activationConfiguration];
                
                activateAnonymously();
            });
            it(@"Should register activation delegate", ^{
                id activationDelegate = [KWMock nullMock];
    
                [AMAAppMetrica addActivationDelegate:activationDelegate];
    
                [[activationDelegate should] receive:@selector(didActivateWithConfiguration:) withArguments:activationConfiguration];
                [[activationDelegate should] receive:@selector(willActivateWithConfiguration:) withArguments:activationConfiguration];
                
                activate();
            });
            it(@"Should activate delegate for anonymous activation on shared executor", ^{
                [AMAAppMetrica stub:@selector(sharedExecutor) andReturn:nil];
                
                id activationDelegate = [KWMock nullMock];
                
                [AMAAppMetrica addActivationDelegate:activationDelegate];
                
                [[activationConfiguration shouldNot] receive:@selector(initWithApiKey:appVersion:appBuildNumber:)
                                                   withCount:2
                                                   arguments:anonymousApiKey, kw_any(), kw_any()];
                
                [[activationDelegate shouldNot] receive:@selector(didActivateWithConfiguration:) withArguments:activationConfiguration];
                [[activationDelegate shouldNot] receive:@selector(willActivateWithConfiguration:) withArguments:activationConfiguration];
                
                activateAnonymously();
            });
            it(@"Should register activation delegate on shared executor", ^{
                [AMAAppMetrica stub:@selector(sharedExecutor) andReturn:nil];
                
                id activationDelegate = [KWMock nullMock];
    
                [AMAAppMetrica addActivationDelegate:activationDelegate];
    
                [[activationDelegate shouldNot] receive:@selector(didActivateWithConfiguration:) withArguments:activationConfiguration];
                [[activationDelegate shouldNot] receive:@selector(willActivateWithConfiguration:) withArguments:activationConfiguration];
                
                activate();
            });
            it(@"Should not add activation delegate if metrica is activated", ^{
                [handler beginAssertIgnoring];
                
                stubMetricaStarted(YES);

                id activationDelegate = [KWMock nullMock];

                [AMAAppMetrica addActivationDelegate:activationDelegate];

                [[activationDelegate shouldNot] receive:@selector(didActivateWithConfiguration:)];
                [[activationDelegate shouldNot] receive:@selector(willActivateWithConfiguration:)];

                activate();
                
                [handler endAssertIgnoring];
            });
            it(@"Should register event flushable delegate", ^{
                AMAModuleActivationConfiguration *configuration = [AMAModuleActivationConfiguration stubbedNullMockForInit:@selector(initWithApiKey:appVersion:appBuildNumber:)];
                id eventFlushableDelegate = [KWMock nullMock];
    
                [AMAAppMetrica addEventFlushableDelegate:eventFlushableDelegate];
                
                [[eventFlushableDelegate should] receive:@selector(sendEventsBuffer)];
                
                stubMetricaStarted(YES);
    
                [AMAAppMetrica sendEventsBuffer];
            });
            it(@"Should not add event flushable delegate if metrica is activated", ^{
                [handler beginAssertIgnoring];
                
                stubMetricaStarted(YES);

                id eventFlushableDelegate = [KWMock nullMock];

                [AMAAppMetrica addEventFlushableDelegate:eventFlushableDelegate];

                [[eventFlushableDelegate shouldNot] receive:@selector(sendEventsBuffer)];

                activate();
                
                [handler endAssertIgnoring];
            });
            it(@"Should register event polling delegate", ^{
                id delegate = [KWMock nullMock];
                
                [AMAAppMetrica addEventPollingDelegate:delegate];
                [[AMAAppMetrica.eventPollingDelegates should] contain:delegate];
            });
            it(@"Should not add event polling delegate if metrica is activated", ^{
                stubMetricaStarted(YES);
                
                id delegate = [KWMock nullMock];
                
                [AMAAppMetrica addEventPollingDelegate:delegate];
                [[AMAAppMetrica.eventPollingDelegates shouldNot] contain:delegate];
            });
            it(@"Should return extended reporter", ^{
                stubMetricaStarted(NO);
                
                activate();
                
                id extendedReporter = [AMAAppMetrica extendedReporterForApiKey:apiKey];
                id reporter = [AMAAppMetrica reporterForAPIKey:apiKey];
                
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
                
                [AMAAppMetrica activateReporterWithConfiguration:[[AMAReporterConfiguration alloc] initWithAPIKey:apiKey]];
            });
            it(@"Should not setup external services on main activation if already configured", ^{
                stubMetricaStarted(NO);
                [[AMAMetricaConfiguration sharedInstance].inMemory stub:@selector(externalServicesConfigured) andReturn:theValue(YES)];
    
                [[[AMAMetricaConfiguration sharedInstance].inMemory shouldNot] receive:@selector(markExternalServicesConfigured)];
                [[impl shouldNot] receive:@selector(setExtendedStartupObservers:)];
                [[impl shouldNot] receive:@selector(setExtendedReporterStorageControllers:)];
                [[adResolver shouldNot] receive:@selector(setAdProvider:)];
                
                activate();
            });
            it(@"Should not setup external services on secondary reporter activation if already configured", ^{
                stubMetricaStarted(NO);
                [[AMAMetricaConfiguration sharedInstance].inMemory stub:@selector(externalServicesConfigured) andReturn:theValue(YES)];
    
                [[[AMAMetricaConfiguration sharedInstance].inMemory shouldNot] receive:@selector(markExternalServicesConfigured)];
                [[impl shouldNot] receive:@selector(setExtendedStartupObservers:)];
                [[impl shouldNot] receive:@selector(setExtendedReporterStorageControllers:)];
                [[adResolver shouldNot] receive:@selector(setAdProvider:)];
                
                [AMAAppMetrica activateReporterWithConfiguration:[[AMAReporterConfiguration alloc] initWithAPIKey:apiKey]];
            });
            context(@"Service Configuration", ^{
                context(@"Startup observer", ^{
                    id<AMAExtendedStartupObserving> __block startupObserver = nil;
                    AMAServiceConfiguration *__block config = nil;
                    beforeAll(^{
                        startupObserver = [KWMock nullMockForProtocol:@protocol(AMAExtendedStartupObserving)];
                        config = [[AMAServiceConfiguration alloc] initWithStartupObserver:startupObserver
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
                        
                        [AMAAppMetrica activateReporterWithConfiguration:[[AMAReporterConfiguration alloc] initWithAPIKey:apiKey]];
                        
                        [[spy.argument should] equal:[NSMutableSet setWithObject:startupObserver]];
                    });
                    it(@"Should register Startup observer on activation anonymous reporter", ^{
                        [AMAAppMetrica registerExternalService:config];
                        
                        KWCaptureSpy *spy = [impl captureArgument:@selector(setExtendedStartupObservers:) atIndex:0];
                        
                        [[impl should] receive:@selector(setExtendedStartupObservers:)];
                        
                        activateAnonymously();
                        
                        [[spy.argument should] equal:[NSMutableSet setWithObject:startupObserver]];
                    });
                    it(@"Should register Startup observer on activation anonymous reporter", ^{
                        [AMAAppMetrica registerExternalService:config];
                        
                        KWCaptureSpy *spy = [impl captureArgument:@selector(setExtendedStartupObservers:) atIndex:0];
                        
                        [[impl should] receive:@selector(setExtendedStartupObservers:)];
                        
                        id reporter = [AMAAppMetrica reporterForAPIKey:apiKey];
                        
                        [[spy.argument should] equal:[NSMutableSet setWithObject:startupObserver]];
                    });
                });
                context(@"Reporter storage controller", ^{
                    id<AMAReporterStorageControlling> __block reporterStorageController = nil;
                    AMAServiceConfiguration *__block config = nil;
                    beforeAll(^{
                        reporterStorageController = [KWMock nullMockForProtocol:@protocol(AMAReporterStorageControlling)];
                        config = [[AMAServiceConfiguration alloc] initWithStartupObserver:nil
                                                                reporterStorageController:reporterStorageController];
                    });
                    it(@"Should register reporter storage controller when activating main reporter", ^{
                        [AMAAppMetrica registerExternalService:config];
                        
                        KWCaptureSpy *spy = [impl captureArgument:@selector(setExtendedReporterStorageControllers:) atIndex:0];
                        
                        [[impl should] receive:@selector(setExtendedReporterStorageControllers:)];
                        
                        activate();
                        
                        [[spy.argument should] equal:[NSMutableSet setWithObject:reporterStorageController]];
                    });
                    it(@"Should register reporter storage controller when activating secondary reporter", ^{
                        [AMAAppMetrica registerExternalService:config];
                        
                        KWCaptureSpy *spy = [impl captureArgument:@selector(setExtendedReporterStorageControllers:) atIndex:0];
                        
                        [[impl should] receive:@selector(setExtendedReporterStorageControllers:)];
                        
                        [AMAAppMetrica activateReporterWithConfiguration:[[AMAReporterConfiguration alloc] initWithAPIKey:apiKey]];
                        
                        [[spy.argument should] equal:[NSMutableSet setWithObject:reporterStorageController]];
                    });
                    it(@"Should register reporter storage controller when activating anonymous reporter", ^{
                        [AMAAppMetrica registerExternalService:config];
                        
                        KWCaptureSpy *spy = [impl captureArgument:@selector(setExtendedReporterStorageControllers:) atIndex:0];
                        
                        [[impl should] receive:@selector(setExtendedReporterStorageControllers:)];
                        
                        activateAnonymously();
                        
                        [[spy.argument should] equal:[NSMutableSet setWithObject:reporterStorageController]];
                    });
                    it(@"Should register reporter storage controller when create reporter", ^{
                        [AMAAppMetrica registerExternalService:config];
                        
                        KWCaptureSpy *spy = [impl captureArgument:@selector(setExtendedReporterStorageControllers:) atIndex:0];
                        
                        [[impl should] receive:@selector(setExtendedReporterStorageControllers:)];
                        
                        id reporter = [AMAAppMetrica reporterForAPIKey:apiKey];
                        
                        [[spy.argument should] equal:[NSMutableSet setWithObject:reporterStorageController]];
                    });
                });
            });
            it(@"Should not register external AdController before activate", ^{
                id adController = [KWMock nullMockForProtocol:@protocol(AMAAdProviding)];

                [[adResolver shouldNot] receive:@selector(setAdProvider:) withArguments:adController];
                [AMAAppMetrica registerAdProvider:adController];
            });
            it(@"Should register external AdController", ^{
                id adController = [KWMock nullMockForProtocol:@protocol(AMAAdProviding)];

                [[adResolver should] receive:@selector(setAdProvider:) withArguments:adController];
                [AMAAppMetrica registerAdProvider:adController];
                
                activate();
            });
            it(@"Should not register external AdController if setAdProviderEnabled called", ^{
                id adController = [KWMock nullMockForProtocol:@protocol(AMAAdProviding)];

                [[adResolver should] receive:@selector(setAdProvider:) withArguments:adController];
                
                [AMAAppMetrica setAdProviderEnabled:NO];
                [AMAAppMetrica registerAdProvider:adController];
                
                activate();
            });
            it(@"Should register external AdController when activating secondary reporter", ^{
                id adController = [KWMock nullMockForProtocol:@protocol(AMAAdProviding)];

                [AMAAppMetrica registerAdProvider:adController];

                [[adResolver should] receive:@selector(setAdProvider:) withArguments:adController];

                [AMAAppMetrica activateReporterWithConfiguration:[[AMAReporterConfiguration alloc] initWithAPIKey:apiKey]];
            });
            it(@"Should register external AdController when activating anonymous reporter", ^{
                id adController = [KWMock nullMockForProtocol:@protocol(AMAAdProviding)];

                [AMAAppMetrica registerAdProvider:adController];

                [[adResolver should] receive:@selector(setAdProvider:) withArguments:adController];

                activateAnonymously();
            });
            it(@"Should call setAdProviderEnabled in resolver", ^{
                id adController = [KWMock nullMockForProtocol:@protocol(AMAAdProviding)];

                [[adResolver should] receive:@selector(setEnabledAdProvider:) withArguments:theValue(NO)];
                
                [AMAAppMetrica setAdProviderEnabled:NO];
                
                activate();
            });
            it(@"Should call setEnabledForAnomimousActivation in resolver", ^{
                id adController = [KWMock nullMockForProtocol:@protocol(AMAAdProviding)];

                [[adResolver should] receive:@selector(setEnabledForAnonymousActivation:) withArguments:theValue(NO)];
                
                activateAnonymouslyWithAdTrackingEnabled(NO);
            });
            it(@"Should return yes if api key is valid", ^{
                [AMAIdentifierValidator stub:@selector(isValidUUIDKey:) andReturn:theValue(YES)];
                
                [[theValue([AMAAppMetrica isAPIKeyValid:@"api-key"]) should] beYes];
            });
            it(@"Should return yes if AppMetrica started with main api key", ^{
                stubMetricaStarted(YES);
                
                [[theValue([AMAAppMetrica isActivatedAsMain]) should] beYes];
            });
            it(@"Should return YES if AppMetrica was started by any method", ^{
                stubMetricaStartedAnonymously(YES);
                
                [[theValue([AMAAppMetrica isActivated]) should] beYes];
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
            [[mockedImpl should] receive:@selector(clearSessionExtras)];
            
            [AMAAppMetrica clearSessionExtras];
        });
    });
    
    context(@"LibaryAdapter report", ^{
        AMAAppMetricaImpl *__block mockedImpl = nil;
        NSString *eventName = @"test_event_name";
        NSDictionary *parameters = @{
            @"key1": @"value1",
        };
        
        afterEach(^{
            [AMAAppMetrica clearStubs];
        });
        
        it(@"reportLibraryAdapterAdRevenueRelatedEvent", ^{
            mockedImpl = [AMAAppMetricaImpl nullMock];
            stubMetrica();
            [AMAAppMetrica stub:@selector(sharedImpl) andReturn:mockedImpl];
            
            [[mockedImpl should] receive:@selector(reportLibraryAdapterAdRevenueRelatedEvent:parameters:onFailure:)
                           withArguments:eventName, parameters, kw_any()];
            
            stubMetricaStarted(YES);
            [AMAAppMetrica reportLibraryAdapterAdRevenueRelatedEvent:eventName
                                                          parameters:parameters
                                                           onFailure:nil];
        });
        
        it(@"registerAdRevenueNativeSource", ^{
            NSString *nativeSource = @"native_source";
            NSArray *expected = @[
                @"yandex",
                @"native_source",
            ];
            
            [AMAAppMetrica registerAdRevenueNativeSource:nativeSource];
            [[[AMAAdRevenueSourceContainer sharedInstance].nativeSupportedSources should] equal:expected];
        });
    });
});

SPEC_END
