
#import <Kiwi/Kiwi.h>
#import <AppMetricaNetwork/AppMetricaNetwork.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import <AppMetricaPlatform/AppMetricaPlatform.h>
#import "AMATime.h"
#import "AMAStartupController.h"
#import "AMAMetricaConfigurationTestUtilities.h"
#import "AMAStartupResponse.h"
#import "AMAAppStateManagerTestHelper.h"
#import "AMACore.h"
#import "AMAHostProviderMock.h"
#import "AMAStartupResponseParser.h"
#import "AMATimeoutRequestsController.h"
#import "AMAAttributionController.h"
#import "AMAAttributionModelConfiguration.h"
#import "AMAStartupRequest.h"
#import "AMAIdentifierProviderMock.h"
#import "AMAIdentifiersTestUtilities.h"

@interface AMAStartupController()

- (void)handleStartupResponse:(id)object;
- (AMAStartupResponse *)parseResponse:(NSHTTPURLResponse *)response data:(NSData *)data;

@end

SPEC_BEGIN(AMAStartupControllerTests)

describe(@"AMAStartupController", ^{

    AMATimeoutRequestsController *__block timeoutController = nil;
    AMAStartupResponseParser *__block startupResponseParser = nil;
    AMAAppStateManagerTestHelper *__block appStateManagerTestHelper;
    
    void (^stubAppState)(void) = ^{
        appStateManagerTestHelper = [[AMAAppStateManagerTestHelper alloc] init];
        [appStateManagerTestHelper stubApplicationState];
        [AMAPlatformDescription stub:@selector(appID) andReturn:@"io.appmetrica.test"];
        [AMAPlatformDescription stub:@selector(appVersion) andReturn:@"1.00"];
    };
    void (^destubAppState)(void) = ^{
        [appStateManagerTestHelper destubApplicationState];
        [AMAPlatformDescription clearStubs];
    };
    __auto_type currentQueueStartupController = ^AMAStartupController *() {
        id<AMACancelableExecuting> executor = [[AMACurrentQueueExecutor alloc] init];
        id<AMAResettableIterable> hostProvider =
        [[AMAHostProviderMock alloc] initWithItems:@[@"1"]];
        startupResponseParser = [AMAStartupResponseParser nullMock];
        return [[AMAStartupController alloc] initWithExecutor:executor
                                                 hostProvider:hostProvider
                                    timeoutRequestsController:timeoutController
                                        startupResponseParser:startupResponseParser];
    };
    beforeAll(^{

        [AMATestNetwork stubHTTPRequestWithBlock:nil];
    });
    beforeEach(^{
        [AMAMetricaConfigurationTestUtilities stubConfiguration];
        timeoutController = [AMATimeoutRequestsController nullMock];
        [timeoutController stub:@selector(isAllowed) andReturn:theValue(YES)];
    });

    context(@"Handles startup response",^{
        NSNumber *offset = @60;
        void (^handleStartupResponse)(void) = ^() {
            AMAStartupController *controller = currentQueueStartupController();
            AMAStartupParametersConfiguration *configuration = [AMAStartupParametersConfiguration nullMock];
            AMAStartupResponse *response = [[AMAStartupResponse alloc] initWithStartupConfiguration:configuration];
            [configuration stub:@selector(serverTimeOffset) andReturn:offset];
            [controller handleStartupResponse:response];
        };
        BOOL (^handleDeviceIdStartupResponse)(NSString *) = ^BOOL(NSString *deviceId) {
            BOOL __block hit = NO;
            [[AMAMetricaConfiguration sharedInstance].persistent stub:@selector(setDeviceID:) withBlock:^id(NSArray *params) {
                hit = YES;
                return nil;
            }];

            AMAStartupController *controller = currentQueueStartupController();
            AMAStartupResponse *response = [AMAStartupResponse nullMock];
            [response stub:@selector(deviceID) andReturn:deviceId];
            [controller handleStartupResponse:response];

            return hit;
        };
        it(@"Should save server time offset to configuration", ^{
            handleStartupResponse();
            [[[AMAMetricaConfiguration sharedInstance].startup.serverTimeOffset should] equal:offset];
        });
        it(@"Should overwrite server time offset in configuration", ^{
            [AMAMetricaConfiguration sharedInstance].startup.serverTimeOffset = @2;
            handleStartupResponse();
            [[[AMAMetricaConfiguration sharedInstance].startup.serverTimeOffset should] equal:offset];
        });
        it(@"Should save first startup update date to configuration", ^{
            NSDate *firstUpdateWithOffset = [NSDate dateWithTimeIntervalSinceNow:offset.doubleValue];
            [NSDate stub:@selector(dateWithTimeIntervalSinceNow:) andReturn:firstUpdateWithOffset];

            handleStartupResponse();
            [[[AMAMetricaConfiguration sharedInstance].persistent.firstStartupUpdateDate should] equal:firstUpdateWithOffset];
        });
        it(@"Should save hadFirstStartup as true to configuration", ^{
            handleStartupResponse();
            [[theValue([AMAMetricaConfiguration sharedInstance].persistent.hadFirstStartup) should] beYes];
        });
        it(@"Should use actual server time offset for first startup update date", ^{
            KWCaptureSpy *spy = [NSDate captureArgument:@selector(dateWithTimeIntervalSinceNow:) atIndex:0];

            handleStartupResponse();
            [[spy.argument should] equal:offset.doubleValue withDelta:0.01];
        });
        it(@"Should replace deviceId with value received from startup if not nil", ^{
            BOOL result = handleDeviceIdStartupResponse(@"deviceId");
            [[theValue(result) should] beYes];
        });
        it(@"Should not replace deviceId when deviceId from startup is nil", ^{
            BOOL result = handleDeviceIdStartupResponse(nil);
            [[theValue(result) should] beNo];
        });
        context(@"Attribution model", ^{
            AMAAttributionController *__block attributionController = nil;
            AMAMetricaConfiguration *__block configuration = nil;
            AMAAttributionModelConfiguration *__block attributionConfig = nil;
            AMAStartupResponse *__block response = nil;
            beforeEach(^{
                [AMAMetricaConfigurationTestUtilities stubConfiguration];
                configuration = [AMAMetricaConfiguration sharedInstance];
                attributionConfig = [AMAAttributionModelConfiguration nullMock];
                attributionController = [AMAAttributionController nullMock];
                [AMAAttributionController stub:@selector(sharedInstance) andReturn:attributionController];
                response = [AMAStartupResponse nullMock];
                [response stub:@selector(attributionModelConfiguration) andReturn:attributionConfig];
            });
            context(@"Has first startup", ^{
                beforeEach(^{
                    [configuration.persistent stub:@selector(hadFirstStartup) andReturn:theValue(YES)];
                });
                it(@"Should not update persistent", ^{
                    [[configuration.persistent shouldNot] receive:@selector(setAttributionModelConfiguration:)];
                    AMAStartupController *startupController = currentQueueStartupController();
                    [startupController handleStartupResponse:response];
                });
                it(@"Should update attribution controller", ^{
                    [[attributionController should] receive:@selector(setConfig:) withArguments:attributionConfig];
                    [configuration.persistent stub:@selector(attributionModelConfiguration) andReturn:attributionConfig];
                    AMAStartupController *startupController = currentQueueStartupController();
                    [startupController handleStartupResponse:response];
                });
            });
            context(@"Did not have first startup", ^{
                beforeEach(^{
                    [configuration.persistent stub:@selector(hadFirstStartup) andReturn:theValue(NO)];
                });
                it(@"Should update persistent", ^{
                    [[configuration.persistent should] receive:@selector(setAttributionModelConfiguration:)
                                                 withArguments:attributionConfig];
                    AMAStartupController *startupController = currentQueueStartupController();
                    [startupController handleStartupResponse:response];
                });
                it(@"Should update attribution controller", ^{
                    [[attributionController should] receive:@selector(setConfig:) withArguments:attributionConfig];
                    [configuration.persistent stub:@selector(attributionModelConfiguration) andReturn:attributionConfig];
                    AMAStartupController *startupController = currentQueueStartupController();
                    [startupController handleStartupResponse:response];
                });
            });
        });
    });

    context(@"Sends startup", ^{
        AMAMetricaConfiguration * __block configuration = nil;
        AMAIdentifierProviderMock *__block identifierProvider;
        
        beforeEach(^{
            configuration = [AMAMetricaConfiguration sharedInstance];
            stubAppState();
            identifierProvider = [AMAIdentifiersTestUtilities stubIdentifierProviderIfNeeded];
            [identifierProvider fillRandom];
        });
        afterEach(^{
            [AMAIdentifiersTestUtilities destubIdentifierProvider];
        });
        it(@"Should ask timeout controller for permission", ^{
            [[timeoutController should] receive:@selector(isAllowed)];
            [currentQueueStartupController() update];
        });
        it(@"Should not send startup if timeout permission denied", ^{
            __block BOOL sent = NO;
            [AMATestNetwork stubHTTPRequestWithBlock:^id(NSArray *params) {
                sent = YES;
                return nil;
            }];

            [timeoutController stub:@selector(isAllowed) andReturn:theValue(NO)];
            [currentQueueStartupController() update];

            [[theValue(sent) should] beNo];
        });
        it(@"Should send startup", ^{
            __block BOOL sent = NO;
            [AMATestNetwork stubHTTPRequestWithBlock:^id(NSArray *params) {
                sent = YES;
                return nil;
            }];

            [currentQueueStartupController() update];
            [[theValue(sent) should] beYes];
        });
        it(@"Should not send startup if it is up to date", ^{
            __block BOOL sent = NO;
            [AMATestNetwork stubHTTPRequestWithBlock:^id(NSArray *params) {
                sent = YES;
                return nil;
            }];

            AMAStartupController *controller = currentQueueStartupController();
            [controller stub:@selector(upToDate) andReturn:theValue(YES)];
            [controller update];

            [[theValue(sent) should] beNo];
        });
        it(@"Should not send startup if it has already been sent", ^{
            NSUInteger __block count = 0;
            [AMATestNetwork stubHTTPRequestWithBlock:^id(NSArray *params) {
                ++count;
                return nil;
            }];

            AMAStartupController *controller = currentQueueStartupController();
            [controller update];
            [controller update];

            [[theValue(count) should] equal:theValue(1)];
        });
        context(@"Sends startup when some of identifiers are nil or last sent date is nil", ^{
            __block BOOL sent;
            AMAStartupController * __block controller = nil;
            AMAIdentifierProviderMock *__block identifierProvider;
            
            beforeEach(^{
                NSDate *previousDate = [[NSDate date] dateByAddingTimeInterval:-60 * 60 * 24 * 2];
                
                identifierProvider = [AMAIdentifiersTestUtilities stubIdentifierProviderIfNeeded];
                [identifierProvider fillRandom];
                configuration.persistent.startupUpdatedAt = previousDate;
                
                sent = NO;
                [AMATestNetwork stubHTTPRequestWithBlock:^id(NSArray *params) {
                    sent = YES;
                    return nil;
                }];
                controller = currentQueueStartupController();
            });
            afterEach(^{
                [[AMAMetricaConfiguration sharedInstance].persistent clearStubs];
                [[AMAMetricaConfiguration sharedInstance] clearStubs];
            });
            it(@"Should send startup if uuid is nil", ^{
                identifierProvider.mockMetricaUUID = nil;
                [controller update];

                [[theValue(sent) should] beYes];
            });
            it(@"Should send startup if deviceIDHash is nil", ^{
                identifierProvider.mockDeviceHashID = nil;
                [controller update];

                [[theValue(sent) should] beYes];
            });
            it(@"Should send startup if last sent date is nil", ^{
                configuration.persistent.startupUpdatedAt = nil;
                [controller update];

                [[theValue(sent) should] beYes];
            });
        });

        __auto_type testStartup = ^BOOL(NSTimeInterval interval, NSNumber *config) {
            __block BOOL sent = NO;
            [AMATestNetwork stubHTTPRequestWithBlock:^id(NSArray *params) {
                sent = YES;
                return nil;
            }];

            AMAStartupController *controller = currentQueueStartupController();
            NSDate *pastDate = [NSDate dateWithTimeIntervalSinceNow:-interval];

            configuration.persistent.startupUpdatedAt = pastDate;
            configuration.startup.startupUpdateInterval = config;
            [controller update];

            return sent;
        };

        it(@"Should send startup if last sent date is more than 24 hours before with default config", ^{
            [[theValue(testStartup(1 * AMA_DAYS + 1, nil)) should] beYes];
        });

        it(@"Should not send startup if last sent date is less than 24 hours before with default config", ^{
            [[theValue(testStartup(1 * AMA_DAYS - 1, nil)) should] beNo];
        });

        it(@"Should send startup if last sent date is more than in config", ^{
            NSTimeInterval config = 8 * AMA_HOURS;
            [[theValue(testStartup(config + 1, @(config))) should] beYes];
        });

        it(@"Should not send startup if last sent date is less than  in config", ^{
            NSTimeInterval config = 8 * AMA_HOURS;
            [[theValue(testStartup(config - 1, @(config))) should] beNo];
        });
    });

    context(@"Host provider check", ^{
        AMAHostProviderMock * __block hostProvider = nil;
        AMAStartupController * __block startupController = nil;
        NSArray * __block hosts = nil;

        beforeEach(^{
            stubAppState();

            id<AMACancelableExecuting> executor = [[AMACurrentQueueExecutor alloc] init];

            hosts = @[@"https://1.test", @"https://2.test", @"https://3.test"];
            hostProvider = [[AMAHostProviderMock alloc] initWithItems:hosts];

            startupController = [[AMAStartupController alloc] initWithExecutor:executor
                                                                  hostProvider:hostProvider
                                                     timeoutRequestsController:timeoutController
                                                         startupResponseParser:startupResponseParser];
        });
        afterEach(^{
            destubAppState();
        });

        it(@"Should not change host if if timeout permission denied", ^{
            [timeoutController stub:@selector(isAllowed) andReturn:theValue(NO)];
            [startupController update];
            [[theValue(hostProvider.numberOfTimesHitNext) should] beZero];
        });

        it(@"Should not change host if if timeout permission denied and there is no internet", ^{
            NSError *error = [NSError errorWithDomain:AMAStartupRequestsErrorDomain
                                                 code:NSURLErrorNotConnectedToInternet
                                             userInfo:nil];
            [AMATestNetwork stubHTTPRequestToFinishWithError:error];
            [timeoutController stub:@selector(isAllowed) andReturn:theValue(NO)];
            [startupController update];
            [[theValue(hostProvider.numberOfTimesHitNext) should] beZero];
        });

        it(@"Shoud change host and make network requests number of times before reporting error and failure", ^{
            NSError *error = [NSError errorWithDomain:@"test error" code:400 userInfo:nil];
            BOOL __block correctRequests = NO;

            [AMAHTTPRequestor stub:@selector(requestorWithRequest:) withBlock:^id(NSArray *params) {
                AMAHTTPRequestor *httpRequestor = [[AMAHTTPRequestor alloc] initWithRequest:params[0]];

                BOOL hostValid = [httpRequestor.request.host isEqualToString:hostProvider.current];
                if (hostProvider.numberOfTimesHitNext == 0) {
                    correctRequests = hostValid;
                }
                else {
                    correctRequests = correctRequests && hostValid;
                }

                [httpRequestor stub:@selector(start) withBlock:^id(NSArray *params) {
                    [httpRequestor.delegate httpRequestor:httpRequestor didFinishWithError:error response:nil];

                    return nil;
                }];

                return httpRequestor;
            }];

            [[timeoutController should] receive:@selector(reportOfFailure)];
            [startupController update];

            BOOL result = hostProvider.numberOfTimesHitNext == hosts.count && correctRequests;

            [[theValue(result) should] beYes];
        });
        
        it(@"Shoud stop changing hosts and make network requests if startup received and report of success", ^{
            NSError *error = [NSError errorWithDomain:@"test error" code:400 userInfo:nil];
            NSUInteger succesfullHostIndex = 1;

            AMAStartupResponse *response = [AMAStartupResponse nullMock];
            [startupController stub:@selector(parseResponse:data:) andReturn:response];

            [AMAHTTPRequestor stub:@selector(requestorWithRequest:)
                       withBlock:^id(NSArray *params) {
                AMAHTTPRequestor *httpRequestor = [[AMAHTTPRequestor alloc] initWithRequest:params[0]];

                [httpRequestor stub:@selector(start) withBlock:^id(NSArray *params) {
                    if ([hostProvider.current isEqualToString:hosts[succesfullHostIndex]]) {
                        NSHTTPURLResponse *response =
                            [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:hostProvider.current]
                                                        statusCode:200
                                                       HTTPVersion:(__bridge NSString *)kCFHTTPVersion1_1
                                                      headerFields:nil];
                        [httpRequestor.delegate httpRequestor:httpRequestor didFinishWithData:nil response:response];
                    }
                    else {
                        [httpRequestor.delegate httpRequestor:httpRequestor didFinishWithError:error response:nil];
                    }

                    return nil;
                }];

                return httpRequestor;
            }];

            [[timeoutController should] receive:@selector(reportOfSuccess)];
            [startupController update];

            BOOL result =
                [hostProvider.current isEqualToString:hosts[succesfullHostIndex]] &&
                hostProvider.numberOfTimesHitNext == 1 &&
                hostProvider.numberOfTimesHitReset == 1;
            [[theValue(result) should] beYes];
        });

        it(@"Shoud change host and make network requests number of times if not able to parse successfull response"
           "and eventually report of failure", ^{
            [startupResponseParser stub:@selector(startupResponseWithHTTPResponse:data:error:)
                                 andReturn:nil];

            [AMAHTTPRequestor stub:@selector(requestorWithRequest:) withBlock:^id(NSArray *params) {
                AMAHTTPRequestor *httpRequestor = [[AMAHTTPRequestor alloc] initWithRequest:params[0]];
                
                [httpRequestor stub:@selector(start) withBlock:^id(NSArray *params) {
                    [httpRequestor.delegate httpRequestor:httpRequestor didFinishWithData:nil response:nil];
                    return nil;
                }];

                return httpRequestor;
            }];

            [[timeoutController should] receive:@selector(reportOfFailure)];
            [startupController update];

            BOOL result = hostProvider.numberOfTimesHitNext == hosts.count &&
                          hostProvider.numberOfTimesHitReset == 1;

            [[theValue(result) should] beYes];
        });
        
        it(@"Shoud dispatch extended startup to observer", ^{
            NSDictionary *extendedResponse = [NSDictionary dictionary];
            AMAStartupResponse *response = [AMAStartupResponse nullMock];
            [startupController stub:@selector(parseResponse:data:) andReturn:response];
            [startupController stub:@selector(parseExtendedResponse:data:) andReturn:extendedResponse];
            
            [AMAHTTPRequestor stub:@selector(requestorWithRequest:)
                         withBlock:^id(NSArray *params) {
                AMAHTTPRequestor *httpRequestor = [[AMAHTTPRequestor alloc] initWithRequest:params[0]];
                
                [httpRequestor stub:@selector(start) withBlock:^id(NSArray *params) {
                    NSHTTPURLResponse *response =
                    [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:hostProvider.current]
                                                statusCode:200
                                               HTTPVersion:(__bridge NSString *)kCFHTTPVersion1_1
                                              headerFields:nil];
                    [httpRequestor.delegate httpRequestor:httpRequestor
                                        didFinishWithData:nil
                                                 response:response];
                    return nil;
                }];
                return httpRequestor;
            }];
            
            id observer = [KWMock nullMockForProtocol:@protocol(AMAExtendedStartupObservingDelegate)];
            
            startupController.extendedDelegate = observer;
            
            [[(NSObject *)observer should] receive:@selector(startupUpdatedWithResponse:)
                                     withArguments:extendedResponse];
            [startupController update];
        });

        it(@"Shoud not change host if network is not available and should not report of failure", ^{
            NSError *error = [NSError errorWithDomain:@"test error"
                                                 code:NSURLErrorNotConnectedToInternet
                                             userInfo:nil];
            [AMATestNetwork stubHTTPRequestToFinishWithError:error];

            [[timeoutController shouldNot] receive:@selector(reportOfFailure)];
            [startupController update];

            [[theValue(hostProvider.numberOfTimesHitNext) should] equal:theValue(0)];
        });

        it(@"Shoud hit reload once during update cycle and report of failure", ^{
            NSError *error = [NSError errorWithDomain:@"test error" code:400 userInfo:nil];
            [AMATestNetwork stubHTTPRequestToFinishWithError:error];

            [[timeoutController should] receive:@selector(reportOfFailure)];
            [startupController update];

            BOOL result =
                hostProvider.numberOfTimesHitNext == hosts.count &&
                hostProvider.numberOfTimesHitReset == 1;

            [[theValue(result) should] beYes];
        });
    });
    context(@"Extended startup parameters", ^{
        it(@"Should add additional startup parameters", ^{
            NSDictionary *parameters = @{@"er":@"ee"};
            AMAStartupRequest *request = [AMAStartupRequest stubbedNullMockForDefaultInit];
            AMAStartupController *controller = currentQueueStartupController();
            
            [[request should] receive:@selector(addAdditionalStartupParameters:)
                        withArguments:parameters];
            [controller addAdditionalStartupParameters:parameters];
        });
    });
});

SPEC_END
