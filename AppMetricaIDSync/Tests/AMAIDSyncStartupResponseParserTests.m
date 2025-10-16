
#import <Kiwi/Kiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>
#import "AMAIDSyncStartupResponseParser.h"
#import "AMAIDSyncStartupController.h"
#import "AMAIDSyncStartupResponse.h"
#import "AMAIDSyncStartupConfiguration.h"

SPEC_BEGIN(AMAIDSyncStartupResponseParserTests)

describe(@"AMAIDSyncStartupResponseParser", ^{
    
    AMAIDSyncStartupResponseParser *__block parser = nil;
    id<AMAKeyValueStoring> __block storage = nil;
    
    beforeEach(^{
        storage = [[AMAKeyValueStorageMock alloc] init];
        [[AMAIDSyncStartupController sharedInstance] stub:@selector(storage) andReturn:storage];
        parser = [[AMAIDSyncStartupResponseParser alloc] init];
    });
    
    afterEach(^{
        [[AMAIDSyncStartupController sharedInstance] clearStubs];
    });
    
    context(@"response", ^{
        NSString *response = @"{"
            "\"features\" : {"
                "\"list\" : {"
                    "\"id_sync\" : {"
                        "\"enabled\" : true"
                    "},"
                "}"
            "},"
            "\"id_sync\" : {"
                "\"launch_delay_seconds\" : 600,"
                "\"requests\" : ["
                    "{"
                        "\"type\": \"novatiq_hyper_id\","
                        "\"preconditions\": {"
                            "\"network\": \"cell\""
                        "},"
                        "\"url\": \"https://spadsync.com/sync?sptoken=100500&sspid=200500&ssphost=300500\","
                        "\"headers\": {\"key\": [\"value\"]},"
                        "\"resend_interval_for_valid_response\": 86400,"
                        "\"resend_interval_for_invalid_response\": 3600,"
                        "\"valid_response_codes\": [200]"
                    "}"
                "]"
            "}"
        "}";
        
        context(@"Parses data", ^{
            AMAIDSyncStartupResponse * __block parsedResponse = nil;
            AMAIDSyncStartupConfiguration *__block parsedConfiguration = nil;
            void (^setResponseWithString)(NSString *) = ^(NSString *responseString){
                NSDictionary *startupResponse = [AMAJSONSerialization dictionaryWithJSONString:responseString error:nil];
                parsedResponse = [parser parseStartupResponse:startupResponse];
                parsedConfiguration = parsedResponse.configuration;
            };
            beforeEach(^{
                setResponseWithString(response);
            });
            
            context(@"id sync config", ^{
                it(@"Should parse feature flag", ^{
                    [[theValue(parsedConfiguration.idSyncEnabled) should] beYes];
                });
                it(@"Should parse launch delay seconds", ^{
                    [[parsedConfiguration.launchDelaySeconds should] equal:@600];
                });
                it(@"Should parse config repeated delay", ^{
                    NSDictionary *expectedRequest = @{
                        @"type": @"novatiq_hyper_id",
                        @"preconditions": @{
                            @"network": @"cell"
                        },
                        @"url": @"https://spadsync.com/sync?sptoken=100500&sspid=200500&ssphost=300500",
                        @"headers": @{
                            @"key": @[@"value"]
                        },
                        @"resend_interval_for_valid_response": @86400,
                        @"resend_interval_for_invalid_response": @3600,
                        @"valid_response_codes": @[@200]
                    };
                    
                    [[parsedConfiguration.requests should] equal:@[expectedRequest]];
                });
            });
        });
    });
});

SPEC_END
