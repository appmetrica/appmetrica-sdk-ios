#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AppMetrica.pb-c.h"
#import "AMAAppStateManagerTestHelper.h"
#import "AMAApplicationStateManager.h"
#import "AMAEncryptedFileStorageFactory.h"
#import "AMAEnvironmentContainer.h"
#import "AMAEvent.h"
#import "AMALocationManager.h"
#import "AMAMetricaConfigurationTestUtilities.h"
#import "AMAReportEventsBatch.h"
#import "AMAReportPayload.h"
#import "AMAReportPayloadEncoderFactory.h"
#import "AMAReportPayloadProvider.h"
#import "AMAReportRequest.h"
#import "AMAReportRequestModel.h"
#import "AMAReportRequestProvider.h"
#import "AMAReporter.h"
#import "AMAReporterStateStorage.h"
#import "AMAReporterStorage.h"
#import "AMAReporterTestHelper.h"
#import "AMAReporterTestHelper.h"
#import "AMAReportsController.h"
#import "AMASessionStorage.h"
#import "AMASessionsCleaner.h"
#import <AppMetricaPlatform/AppMetricaPlatform.h>
#import "AMABundleInfoProviderMock.h"

SPEC_BEGIN(AMAReportRequestTests)

describe(@"AMAReportRequestTests", ^{
    NSString *const apiKey = [AMAReporterTestHelper defaultApiKey];
    NSString *const attributionID = @"1";
    NSString *const requestIdentifier = @"42";
    NSString *const appID = @"com.appmetrica.mobile.test";
    NSString *const extID = @"com.appmetrica.mobile.test.ext";
    NSString *const host = @"http://www.appmetrica.io";
    NSArray *const additionalAPIKeys = @[@"additional_api_key_1", @"additional_api_key_2"];
    AMABundleInfoProviderMock *appMock = [[AMABundleInfoProviderMock alloc] initWithAppID:appID
                                                                           appBuildNumber:@"1"
                                                                               appVersion:@"1.0.0"
                                                                           appVersionName:@"1.0.0"];
    AMABundleInfoProviderMock *extensionMock = [[AMABundleInfoProviderMock alloc] initWithAppID:extID
                                                                                 appBuildNumber:@"1"
                                                                                     appVersion:@"1.0.0"
                                                                                 appVersionName:@"1.0.0"];
    
    AMAReporterTestHelper *__block reporterTestHelper = nil;
    beforeEach(^{
        [AMAMetricaConfigurationTestUtilities stubConfigurationWithNullMock];
        reporterTestHelper = [[AMAReporterTestHelper alloc] init];
        NSObject<AMADataEncoding> *encoder = [KWMock nullMockForProtocol:@protocol(AMADataEncoding)];
        [AMAReportPayloadEncoderFactory stub:@selector(encoder) andReturn:encoder];
        [encoder stub:@selector(encodeData:error:) withBlock:^(NSArray *params) {
            return params[0];
        }];
        [AMAPlatformDescription stub:@selector(mainAppInfo) andReturn:appMock];
        [AMAPlatformDescription stub:@selector(extensionAppInfo) andReturn:extensionMock];
        [AMAPlatformDescription stub:@selector(currentAppInfo) andReturn:extensionMock];
    });
    afterEach(^{
        [AMAMetricaConfigurationTestUtilities destubConfiguration];
        [AMAPlatformDescription clearStubs];
        [reporterTestHelper destub];
        [AMAReportPayloadEncoderFactory clearStubs];
        
        [AMALocationManager clearStubs];
        [AMALocationManager.sharedManager clearStubs];
        
        [AMAMetricaConfiguration clearStubs];
        [AMAMetricaConfiguration.sharedInstance clearStubs];
        [AMAMetricaConfiguration.sharedInstance.inMemory clearStubs];
        
        [AMAEncryptedFileStorageFactory clearStubs];
    });
    AMAReportEventsBatch *(^createEventBatch)(void) = ^AMAReportEventsBatch *(void) {
        AMASession *session =
            [[reporterTestHelper appReporter].reporterStorage.sessionStorage newGeneralSessionCreatedAt:[NSDate date]
                                                                                                  error:nil];
        AMAEvent *event = [[AMAEvent alloc] init];
        return [[AMAReportEventsBatch alloc] initWithSession:session
                                              appEnvironment:nil
                                                      events:@[event]];
    };
    AMAReportRequest *(^createReportRequest)(void) = ^AMAReportRequest *(void) {
        AMAApplicationState *state = AMAApplicationStateManager.applicationState;
        AMAReportEventsBatch *eventBatch = createEventBatch();
        AMAReportRequestModel *requestModel = [AMAReportRequestModel reportRequestModelWithApiKey:apiKey
                                                                                    attributionID:attributionID
                                                                                   appEnvironment:@{}
                                                                                         appState:state
                                                                                 inMemoryDatabase:YES
                                                                                additionalAPIKeys:additionalAPIKeys
                                                                                    eventsBatches:@[eventBatch]];
        requestModel = [requestModel copyWithAppState:AMAApplicationStateManager.applicationState];
        AMAReportPayloadProvider *provider = [[AMAReportPayloadProvider alloc] init];
        AMAReportPayload *payload = [provider generatePayloadWithRequestModel:requestModel error:nil];
        AMAReportRequest *request = [AMAReportRequest reportRequestWithPayload:payload
                                                             requestIdentifier:requestIdentifier
                                                      requestParametersOptions:AMARequestParametersDefault];
        request.host = host;
        return request;
    };

    context(@"Sets correct GET parameters", ^{
        NSString *const deviceType = @"device";
        void (^stubPlatformDescription)(void) = ^{
            [AMAPlatformDescription stub:@selector(deviceType) andReturn:deviceType];
        };
        NSDictionary * __block GETParameters = nil;
        AMAAppStateManagerTestHelper * __block helper = nil;

        beforeEach(^{
            stubPlatformDescription();
            helper = [[AMAAppStateManagerTestHelper alloc] init];
            [helper stubApplicationState];
            AMAReportRequest *request = createReportRequest();
            GETParameters = [request GETParameters];
        });
        afterEach(^{
            [AMAPlatformDescription clearStubs];
            [helper destubApplicationState];
        });

        it(@"Should add app_platform to GET parameters", ^{
            [[GETParameters[@"app_platform"] should] equal:[AMAPlatformDescription OSName]];
        });
        it(@"Should add device_type to GET parameters", ^{
            [[GETParameters[@"device_type"] should] equal:deviceType];
        });
        it(@"Should add manufacturer to GET parameters", ^{
            [[GETParameters[@"manufacturer"] should] equal:[AMAPlatformDescription manufacturer]];
        });
        it(@"Should add model to GET parameters", ^{
            [[GETParameters[@"model"] should] equal:[AMAPlatformDescription model]];
        });
        it(@"Should add os_version to GET parameters", ^{
            [[GETParameters[@"os_version"] should] equal:helper.OSVersion];
        });
        it(@"Should add screen_width to GET parameters", ^{
            [[GETParameters[@"screen_width"] should] equal:[AMAPlatformDescription screenWidth]];
        });
        it(@"Should add screen_height to GET parameters", ^{
            [[GETParameters[@"screen_height"] should] equal:[AMAPlatformDescription screenHeight]];
        });
        it(@"Should add locale to GET parameters", ^{
            [[GETParameters[@"locale"] should] equal:helper.locale];
        });
        it(@"Should add scalefactor to GET parameters", ^{
            [[GETParameters[@"scalefactor"] should] equal:[AMAPlatformDescription scalefactor]];
        });
#if !TARGET_OS_TV
        it(@"Should add screen_dpi to GET parameters", ^{
            [[GETParameters[@"screen_dpi"] should] equal:[AMAPlatformDescription screenDPI]];
        });
#endif
        it(@"Should add is_rooted to GET parameters", ^{
            [[GETParameters[@"is_rooted"] should] equal:(helper.isRooted ? @"1" : @"0")];
        });
        it(@"Should add app_version_name to GET parameters", ^{
            [[GETParameters[@"app_version_name"] should] equal:helper.appVersionName];
        });
        it(@"Should add app_build_number to GET parameters", ^{
            [[GETParameters[@"app_build_number"] should] equal:[@(helper.appBuildNumber) stringValue]];
        });
        it(@"Should add uuid to GET parameters", ^{
            [[GETParameters[@"uuid"] should] equal:helper.UUID];
        });
        it(@"Should add deviceid to GET parameters", ^{
            [[GETParameters[@"deviceid"] should] equal:helper.deviceID];
        });
        it(@"Should add ifv to GET parameters", ^{
            [[GETParameters[@"ifv"] should] equal:helper.IFV];
        });
        it(@"Should not add analytics_sdk_version to GET parameters", ^{
            [[GETParameters[@"analytics_sdk_version"] should] beNil];
        });
        it(@"Should add analytics_sdk_version_name to GET parameters", ^{
            [[GETParameters[@"analytics_sdk_version_name"] should] equal:helper.kitVersionName];
        });
        it(@"Should add app_id to GET parameters", ^{
            [[GETParameters[@"app_id"] should] equal:extID];
        });
        it(@"Should add mai to GET parameters", ^{
            [[GETParameters[@"mai"] should] equal:appID];
        });
        it(@"Should add eai to GET parameters", ^{
            [[GETParameters[@"eai"] should] equal:extID];
        });
        it(@"Should add api_key_128 to GET parameters", ^{
            [[GETParameters[@"api_key_128"] should] equal:apiKey];
        });
        it(@"Should add encrypted_request to GET parameters", ^{
            [[GETParameters[@"encrypted_request"] should] equal:@"1"];
        });
        it(@"Should add attribution_id to GET parameters", ^{
            [[GETParameters[@"attribution_id"] should] equal:attributionID];
        });
        it(@"Should add request_id to GET parameters", ^{
            [[GETParameters[@"request_id"] should] equal:requestIdentifier];
        });
    });

    context(@"Resets headers", ^{
        AMAReportRequest *__block request = nil;
        AMAAppStateManagerTestHelper *__block helper = nil;
        
        beforeEach(^{
            helper = [[AMAAppStateManagerTestHelper alloc] init];
            helper.UUID = @"";
            [helper stubApplicationState];
            [reporterTestHelper initReporterAndSendEventWithParameters:nil];
            AMAReportRequestProvider *provider =
            [reporterTestHelper appReporter].reporterStorage.reportRequestProvider;
            NSArray *requestModels = [provider requestModels];
            AMAReportRequestModel *requestModel =
                [requestModels[0] copyWithAppState:AMAApplicationStateManager.applicationState];
            AMAReportPayloadProvider *payloadProvider = [[AMAReportPayloadProvider alloc] init];
            AMAReportPayload *payload = [payloadProvider generatePayloadWithRequestModel:requestModel error:nil];
            request = [AMAReportRequest reportRequestWithPayload:payload
                                               requestIdentifier:@"1"
                                        requestParametersOptions:AMARequestParametersDefault];
            request.host = host;
        });
        afterEach(^{
            [helper destubApplicationState];
            [reporterTestHelper destub];
            [AMAPlatformDescription clearStubs];
        });
        
        it(@"Should fill send time headers", ^{
            NSURLRequest *urlRequest = [request buildURLRequest];

            [[urlRequest.allHTTPHeaderFields[@"Send-Timestamp"] should] beNonNil];
            [[urlRequest.allHTTPHeaderFields[@"Send-Timezone"] should] beNonNil];
        });
        it(@"Should set correct User-Agent header", ^{
            NSString *userAgent = [AMAPlatformDescription SDKUserAgent];
            [AMAPlatformDescription stub:@selector(SDKUserAgent) andReturn:userAgent];
            NSURLRequest *urlRequest = [request buildURLRequest];
            NSDictionary *userAgentHeader = urlRequest.allHTTPHeaderFields;
            [[userAgentHeader[@"User-Agent"] should] equal:userAgent];
        });
    });

    context(@"Generates correct payload", ^{
        beforeEach(^{
            [[reporterTestHelper appReporter].reporterStorage.stateStorage.appEnvironment clearEnvironment];
        });
        afterEach(^{
            [AMALocationManager.sharedManager clearStubs];
            [AMAPlatformDescription clearStubs];
        });
        Ama__ReportMessage * __block message = NULL;
        NSDictionary * __block GETParameters = nil;
        void (^generatePayloadWithBlock)(dispatch_block_t) = ^(void (^block)(void)) {
            [[AMALocationManager sharedManager] stub:@selector(currentLocation) andReturn:nil];
            [AMAPlatformDescription stub:@selector(appID) andReturn:appID];
            AMAAppStateManagerTestHelper *helper = [[AMAAppStateManagerTestHelper alloc] init];
            [helper stubApplicationState];
            AMAApplicationState *state = AMAApplicationStateManager.applicationState;
            block();
            AMAReportRequestProvider *requestProvider =
                [reporterTestHelper appReporter].reporterStorage.reportRequestProvider;
            NSArray *requestModels = [requestProvider requestModels];
            AMAReportRequestModel *requestModel =
                [requestModels[0] copyWithAppState:AMAApplicationStateManager.applicationState];
            AMAReportPayloadProvider *payloadProvider = [[AMAReportPayloadProvider alloc] init];
            AMAReportPayload *payload = [payloadProvider generatePayloadWithRequestModel:requestModel error:nil];
            AMAReportRequest *request = [AMAReportRequest reportRequestWithPayload:payload
                                                                 requestIdentifier:@"23"
                                                          requestParametersOptions:AMARequestParametersDefault];
            request.host = host;
            GETParameters = [request GETParameters];
            NSURLRequest *URLRequest = [request buildURLRequest];
            NSData *body = [URLRequest HTTPBody];
            size_t len = (size_t)[body length];
            message = ama__report_message__unpack(NULL, len, [body bytes]);
        };
        context(@"One session", ^{
            beforeEach(^{
                generatePayloadWithBlock(^{
                    [reporterTestHelper initReporterAndSendEventWithParameters:nil];
                });
            });
            afterEach(^{
                free(message);
            });
            it(@"Should create correct body with one session", ^{
                NSUInteger sessionsNumber = message->n_sessions;
                [[theValue(sessionsNumber) should] equal:theValue(1)];
            });
            it(@"Should create correct body with 3 events", ^{
                Ama__ReportMessage__Session *session = message->sessions[0];
                NSUInteger eventsNumber = session->n_events;
                [[theValue(eventsNumber) should] equal:theValue(3)];
            });
        });
        context(@"Two sessions", ^{
            beforeEach(^{
                generatePayloadWithBlock(^{
                    [reporterTestHelper initReporterTwice];
                });
            });
            afterEach(^{
                free(message);
            });
            it(@"Should create correct body with two sessions", ^{
                NSUInteger sessionsNumber = message->n_sessions;
                [[theValue(sessionsNumber) should] equal:theValue(2)];
            });
            it(@"Should create correct body with 3 events in first session", ^{
                Ama__ReportMessage__Session *session = message->sessions[0];
                NSUInteger eventsNumber = session->n_events;
                [[theValue(eventsNumber) should] equal:theValue(3)];
            });
            it(@"Should create correct body with 1 event in second session", ^{
                Ama__ReportMessage__Session *session = message->sessions[1];
                NSUInteger eventsNumber = session->n_events;
                [[theValue(eventsNumber) should] equal:theValue(1)];
            });
        });
        context(@"Trims events", ^{
            NSUInteger const minimalReportSize = 135;
            NSUInteger const eventSize = 30;

            context(@"One session", ^{
                afterEach(^{
                    free(message);
                });
                it(@"Should remove 2 events for one session with 3 events", ^{
                    generatePayloadWithBlock(^{
                        [reporterTestHelper initReporterAndSendEventWithParameters:nil];
                        [reporterTestHelper sendEvent];
                        [[AMAMetricaConfiguration sharedInstance].inMemory stub:@selector(maxProtobufMsgSize)
                                                                      andReturn:theValue(minimalReportSize + eventSize)];
                    });
                    Ama__ReportMessage__Session *session = message->sessions[0];
                    [[theValue(session->n_events) should] equal:theValue(1)];
                });
                it(@"Should remove 3 events for one session with 4 events", ^{
                    generatePayloadWithBlock(^{
                        [reporterTestHelper initReporterAndSendEventWithParameters:nil];
                        [reporterTestHelper sendEvent];
                        [reporterTestHelper sendEvent];
                        [[AMAMetricaConfiguration sharedInstance].inMemory stub:@selector(maxProtobufMsgSize)
                                                                      andReturn:theValue(minimalReportSize + eventSize)];
                    });
                    Ama__ReportMessage__Session *session = message->sessions[0];
                    [[theValue(session->n_events) should] equal:theValue(1)];
                });
                it(@"Should remove 1 events for one session with 4 events and limit 100", ^{
                    generatePayloadWithBlock(^{
                        [reporterTestHelper initReporterAndSendEventWithParameters:nil];
                        [reporterTestHelper sendEvent];
                        [reporterTestHelper sendEvent];
                        [[AMAMetricaConfiguration sharedInstance].inMemory stub:@selector(maxProtobufMsgSize)
                                                                      andReturn:theValue(minimalReportSize + eventSize * 3)];
                    });
                    Ama__ReportMessage__Session *session = message->sessions[0];
                    [[theValue(session->n_events) should] equal:theValue(3)];
                });
            });
            context(@"Two sessions", ^{
                beforeEach(^{
                    generatePayloadWithBlock(^{
                        [reporterTestHelper initReporterTwice];
                        [[AMAMetricaConfiguration sharedInstance].inMemory stub:@selector(maxProtobufMsgSize)
                                                                      andReturn:theValue(minimalReportSize + eventSize * 2)];
                    });
                });
                afterEach(^{
                    free(message);
                });
                it(@"Should remove 2 events for first session", ^{
                    Ama__ReportMessage__Session *session = message->sessions[0];
                    [[theValue(session->n_events) should] equal:theValue(2)];
                });
                it(@"Should remove all event for second session and session itself", ^{
                    [[theValue(message->n_sessions) should] equal:theValue(1)];
                });
            });
            context(@"Big event value", ^{
                NSUInteger const kMaxValueLength = 230 * 1024;
                NSUInteger const kBigDataSize = 300 * 1024;
                NSUInteger const kEventIndex = 1;
                
                let(bigData, ^{
                    NSMutableData *randomData = [NSMutableData dataWithLength:kBigDataSize];
                    uint8_t *bytes = randomData.mutableBytes;
                    for (NSUInteger i = 0; i < kBigDataSize; i++) {
                        bytes[i] = (uint8_t)arc4random_uniform(95);
                    }
                    return randomData;
                });
                
                void(^reportEvent)(BOOL) = ^(BOOL gZipped) {
                    [reporterTestHelper.appReporter reportBinaryEventWithType:AMAEventTypeClient
                                                                         data:bigData
                                                                         name:nil
                                                                      gZipped:gZipped
                                                             eventEnvironment:nil
                                                               appEnvironment:nil
                                                                       extras:nil
                                                               bytesTruncated:0
                                                                    onFailure:nil];
                };
                
                context(@"Big event deflated value truncation", ^{
                    beforeEach(^{
                        generatePayloadWithBlock(^{
                            reportEvent(YES);
                        });
                    });

                    it(@"Should truncate big event value", ^{
                        Ama__ReportMessage__Session *session = message->sessions[0];
                        Ama__ReportMessage__Session__Event *event = session->events[kEventIndex];
                        [[theValue(event->value.len) should] beLessThanOrEqualTo:theValue(kMaxValueLength)];
                    });
                    
                    it(@"bytes_truncated should be equal to gzipped event length for big event value", ^{
                        Ama__ReportMessage__Session *session = message->sessions[0];
                        Ama__ReportMessage__Session__Event *event = session->events[kEventIndex];
                        
                        // assuming gzip with 96 values range gives 16% compression of `kBigDataSize`
                        [[theValue(event->bytes_truncated) should] beBetween:theValue(250000) and:theValue(260000)];
                    });
                    
                    it(@"Should set has_bytes_truncated to YES for big event value", ^{
                        Ama__ReportMessage__Session *session = message->sessions[0];
                        Ama__ReportMessage__Session__Event *event = session->events[kEventIndex];
                        [[theValue(event->has_bytes_truncated) should] beYes];
                    });
                });
                
                context(@"Big event truncation", ^{
                    beforeEach(^{
                        generatePayloadWithBlock(^{
                            reportEvent(NO);
                        });
                    });

                    it(@"Should truncate big event value", ^{
                        Ama__ReportMessage__Session *session = message->sessions[0];
                        Ama__ReportMessage__Session__Event *event = session->events[kEventIndex];
                        [[theValue(event->value.len) should] beLessThanOrEqualTo:theValue(kMaxValueLength)];
                    });
                    
                    it(@"bytes_truncated should be equal to bytesTruncated for big event value", ^{
                        Ama__ReportMessage__Session *session = message->sessions[0];
                        Ama__ReportMessage__Session__Event *event = session->events[kEventIndex];
                        
                        NSUInteger bytesTruncated = bigData.length - kMaxValueLength;
                        [[theValue(event->bytes_truncated) should] equal:theValue(bytesTruncated)];
                    });
                    
                    it(@"Should set has_bytes_truncated to YES for big event value", ^{
                        Ama__ReportMessage__Session *session = message->sessions[0];
                        Ama__ReportMessage__Session__Event *event = session->events[kEventIndex];
                        [[theValue(event->has_bytes_truncated) should] beYes];
                    });
                });
            });
        });
        context(@"Sending location in event", ^{
            double delta = 0.0001f;
            CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(122.0f, 321.0f);
            CLLocation *locatonFix = [[CLLocation alloc] initWithCoordinate:coordinate altitude:-12.0 horizontalAccuracy:100 verticalAccuracy:-100 course:-19.0f speed:123.0f timestamp:[NSDate date]];
            NSUInteger eventIndex = 0; // EVENT_START, EVENT_CLIENT <-
            void (^generatePayloadBlock)(void) = ^{
                [[AMALocationManager sharedManager] stub:@selector(currentLocation) andReturn:locatonFix];
                [reporterTestHelper initReporterAndSendEventWithParameters:nil];
            };
            it(@"Should send latitude in protobuf", ^{
                generatePayloadWithBlock(generatePayloadBlock);
                Ama__ReportMessage__Session__Event *event = message->sessions[0]->events[eventIndex];

                [[theValue(event->location->lat) should] equal:locatonFix.coordinate.latitude withDelta:delta];
            });

            it(@"Should send longitude in protobuf", ^{
                generatePayloadWithBlock(generatePayloadBlock);
                Ama__ReportMessage__Session__Event *event = message->sessions[0]->events[eventIndex];

                [[theValue(event->location->lon) should] equal:locatonFix.coordinate.longitude withDelta:delta];
            });
            it(@"Should send timestamp", ^{
                generatePayloadWithBlock(generatePayloadBlock);
                Ama__ReportMessage__Session__Event *event = message->sessions[0]->events[eventIndex];

                [[theValue(event->location->timestamp) should] equal:[locatonFix.timestamp timeIntervalSince1970] withDelta:delta];
            });

            it(@"Should not send altitude", ^{
                generatePayloadWithBlock(generatePayloadBlock);
                Ama__ReportMessage__Session__Event *event = message->sessions[0]->events[eventIndex];

                [[theValue(event->location->altitude) should] equal:0.0f withDelta:delta];
            });

            it(@"Should not send course", ^{
                generatePayloadWithBlock(generatePayloadBlock);
                Ama__ReportMessage__Session__Event *event = message->sessions[0]->events[eventIndex];

                [[theValue(event->location->direction) should] equal:0.0f withDelta:delta];
            });

#if !TARGET_OS_TV
            it(@"Should send speed", ^{
                generatePayloadWithBlock(generatePayloadBlock);
                Ama__ReportMessage__Session__Event *event = message->sessions[0]->events[eventIndex];

                [[theValue(event->location->speed) should] equal:locatonFix.speed withDelta:delta];
            });
#endif

        });
        context(@"Send request parameters", ^{
            AMAAppStateManagerTestHelper *__block helper = nil;
            beforeEach(^{
                helper = [[AMAAppStateManagerTestHelper alloc] init];
                [helper stubApplicationState];

                generatePayloadWithBlock(^{
                    [reporterTestHelper initReporterAndSendEventWithParameters:nil];
                });
            });
            it(@"Should set device_id", ^{
                NSString *deviceID = [NSString stringWithUTF8String:message->report_request_parameters->device_id];
                [[deviceID should] equal:helper.deviceID];
            });
            it(@"Should set uuid", ^{
                NSString *uuid = [NSString stringWithUTF8String:message->report_request_parameters->uuid];
                [[uuid should] equal:helper.UUID];
            });
        });
        context(@"Send app environment", ^{
            it(@"Shouldn't set empty environment", ^{
                generatePayloadWithBlock(^{
                    [reporterTestHelper initReporterAndSendEventWithParameters:nil];
                });
                [[theValue(message->n_app_environment) should] equal:theValue(0)];
            });
            it(@"Should set nonempty app environment", ^{
                generatePayloadWithBlock(^{
                    AMAReporter *reporter = [reporterTestHelper appReporter];
                    [reporter setAppEnvironmentValue:@"fizz" forKey:@"buzz"];
                    [reporter reportEvent:@"test" onFailure:nil];
                });
                [[theValue(message->n_app_environment) should] equal:theValue(1)];

                NSString *value = [NSString stringWithCString:message->app_environment[0]->value
                                                     encoding:NSUTF8StringEncoding];
                NSString *key = [NSString stringWithCString:message->app_environment[0]->name
                                                   encoding:NSUTF8StringEncoding];
                [[value should] equal:@"fizz"];
                [[key should] equal:@"buzz"];
            });
        });
        context(@"GET parameters", ^{
            it(@"Should update uuid", ^{
                NSString *UUID = @"1111222233334444";
                [[AMALocationManager sharedManager] stub:@selector(currentLocation) andReturn:nil];
                [AMAPlatformDescription stub:@selector(appID) andReturn:appID];
                AMAAppStateManagerTestHelper *helper = [[AMAAppStateManagerTestHelper alloc] init];
                helper.UUID = @"";
                [helper stubApplicationState];
                [reporterTestHelper initReporterAndSendEventWithParameters:nil];
                AMAReportRequestProvider *provider =
                    [reporterTestHelper appReporter].reporterStorage.reportRequestProvider;
                helper.UUID = UUID;
                [helper stubApplicationState];
                NSArray *requestModels = [provider requestModels];
                AMAReportRequestModel *requestModel =
                    [requestModels[0] copyWithAppState:AMAApplicationStateManager.applicationState];
                AMAReportPayloadProvider *payloadProvider = [[AMAReportPayloadProvider alloc] init];
                AMAReportPayload *payload = [payloadProvider generatePayloadWithRequestModel:requestModel error:nil];
                AMAReportRequest *request = [AMAReportRequest reportRequestWithPayload:payload
                                                                     requestIdentifier:@"1"
                                                              requestParametersOptions:AMARequestParametersDefault];
                request.host = host;
                NSURLRequest *URLRequest = [request buildURLRequest];
                NSString *expectedString = [NSString stringWithFormat:@"uuid=%@", UUID];
                [[[[URLRequest URL] query] should] containString:expectedString];
                
                [helper destubApplicationState];
                [AMAPlatformDescription clearStubs];
                [AMALocationManager.sharedManager clearStubs];
            });
        });
        context(@"No file for file storage type event", ^{
            AMAReportPayloadProvider *__block payloadProvider = nil;
            AMAReportRequestModel *__block requestModel = nil;
            AMAAppStateManagerTestHelper *__block helper = nil;
            beforeEach(^{
                helper = [[AMAAppStateManagerTestHelper alloc] init];
                [helper stubApplicationState];
                
                [reporterTestHelper.appReporter reportEvent:@"EVENT" onFailure:nil];
                [reporterTestHelper.appReporter resumeSession];
                NSArray *models = [reporterTestHelper.appReporter.reporterStorage.reportRequestProvider requestModels];
                AMASessionsCleaner *sessionCleaner = reporterTestHelper.appReporter.reporterStorage.sessionsCleaner;
                [sessionCleaner purgeSessionWithRequestModel:models.firstObject
                                                      reason:AMAEventsCleanupReasonTypeSuccessfulReport];
                
                NSObject<AMAFileStorage> *storage = [KWMock nullMockForProtocol:@protocol(AMAFileStorage)];
                [AMAEncryptedFileStorageFactory stub:@selector(fileStorageForEncryptionType:filePath:)
                                           andReturn:storage];
                [storage stub:@selector(writeData:error:) andReturn:theValue(YES)];
                
                
                [reporterTestHelper.appReporter reportFileEventWithType:AMAEventTypeClient
                                                                   data:[@"RANDOM_DATA" dataUsingEncoding:kCFStringEncodingUTF8]
                                                               fileName:@""
                                                                   date:nil
                                                                gZipped:YES
                                                              encrypted:YES
                                                              truncated:YES
                                                       eventEnvironment:@{}
                                                         appEnvironment:@{}
                                                               appState:nil
                                                                 extras:nil
                                                              onFailure:nil];
                
                AMAReportRequestProvider *requestProvider =
                reporterTestHelper.appReporter.reporterStorage.reportRequestProvider;
                NSArray *requestModels = [requestProvider requestModels];
                requestModel = requestModels[0];
                payloadProvider = [[AMAReportPayloadProvider alloc] init];
            });
            afterEach(^{
                [helper destubApplicationState];
            });
            it(@"Should have nil payload", ^{
                AMAReportPayload *payload = [payloadProvider generatePayloadWithRequestModel:requestModel error:nil];
                [[payload should] beNil];
            });
            it(@"Should return valid error", ^{
                NSError *error = nil;
                [payloadProvider generatePayloadWithRequestModel:requestModel error:&error];
                [[error should] equal:[NSError errorWithDomain:kAMAReportPayloadProviderErrorDomain
                                                          code:AMAReportPayloadProviderErrorAllSessionsAreEmpty
                                                      userInfo:nil]];
            });
        });
    });
    it(@"Should be subclass of AMAGenericRequest", ^{
        [[createReportRequest() should] beKindOfClass:AMAGenericRequest.class];
    });
});

SPEC_END
