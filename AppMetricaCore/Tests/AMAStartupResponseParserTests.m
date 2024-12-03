
#import <Kiwi/Kiwi.h>
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMAStartupResponseParser.h"
#import "AMAStartupParametersConfiguration.h"
#import "AMAMetricaConfigurationTestUtilities.h"
#import "AMAStartupResponseEncoderFactory.h"
#import "AMAStartupPermission.h"
#import "AMAStartupPermissionSerializer.h"
#import "AMAAttributionModelParser.h"
#import "AMAAttributionModelConfiguration.h"

SPEC_BEGIN(AMAStartupResponseParserTests)

describe(@"AMAStartupResponseParser", ^{

    AMAAttributionModelParser *__block attributionModelParser = nil;
    AMAStartupResponseParser *__block parser = nil;

    beforeEach(^{
        [AMAMetricaConfigurationTestUtilities stubConfiguration];
        attributionModelParser = [AMAAttributionModelParser nullMock];
        parser = [[AMAStartupResponseParser alloc] initWithAttributionModelParser:attributionModelParser];
    });

    context(@"response", ^{
        NSString *response = @"{"
            "\"features\" : {"
                "\"list\" : {"
                    "\"permissions_collecting\" : {"
                        "\"enabled\" : true"
                    "},"
                    "\"extensions_collecting\" : {"
                        "\"enabled\" : true"
                    "},"
                "}"
            "},"
            "\"locale\" : {"
                "\"country\" : {"
                    "\"value\" : \"by\","
                    "\"reliable\" : true"
                "},"
                "\"language\" : {"
                    "\"value\" : \"by\""
                "}"
            "},"
            "\"queries\" : {"
                "\"list\" : {"
                    "\"applications\" : {"
                        "\"url\" : \"https://startup.tst.mobile.appmetrica.io/app.bin\""
                    "},"
                    "\"host\" : {"
                        "\"url\" : \"https://startup.tst.mobile.appmetrica.io/host.bin\""
                    "}"
                "}"
            "},"
            "\"query_hosts\" : {"
                "\"list\" : {"
                    "\"some_arbitrary_key1\" : {"
                        "\"urls\" : [\"http://appmetrica.heroism.com\"]"
                    "},"
                    "\"some_arbitrary_key2\" : {"
                        "\"urls\" : ["
                            "\"http://host1.other_sdk.appmetrica.io\","
                            "\"http://host2.other_sdk.appmetrica.io\""
                        "]"
                    "},"
                    "\"get_ad\" : {"
                       "\"urls\" : [\"https://https://mobile-ads-beta.appmetrica.io:4443\"]"
                    "},"
                    "\"report\" : {"
                        "\"urls\" : ["
                            "\"http://appmetrica.heroism.com\","
                            "\"http://another.heroism.com\""
                        "]"
                    "},"
                    "\"report_ad\" : {"
                        "\"urls\" : [\"https://https://mobile-ads-beta.appmetrica.io:4443\"]"
                    "},"
                    "\"redirect\" : {"
                        "\"urls\" : [\"https://redirect.appmetrica.metrica-test.haze.com\"]"
                    "},"
                    "\"location\" : {"
                        "\"urls\" : ["
                            "\"foo\","
                            "\"bar\""
                        "]"
                    "}"
                "}"
            "},"
            "\"stat_sending\":{"
                "\"disabled_reporting_interval_seconds\": 10823"
            "},"
            "\"uuid\" : {"
                "\"value\" : \"  369f5c559986d404dd6a2cd61d8ab82a  \""
           " },"
            "\"device_id\" : {"
                "\"hash\" : \"  9636906516878715833  \","
                "\"value\" : \"  369f5c559986d404dd6a2cd61d8ab82a  \""
            " },"
            "\"permissions\" : {"
                "\"list\" : ["
                    "{"
                        "\"name\" : \"NSLocationDescription\","
                        "\"enabled\" : true"
                    "}"
                "]"
            "},"
            "\"permissions_collecting\" : {"
                "\"force_send_interval_seconds\" : 86400,"
                "\"list\": ["
                    "{"
                        "\"enabled\": false,"
                        "\"name\": \"NSLocationAlwaysUsageDescription\""
                    "},"
                    "{"
                        "\"enabled\": true,"
                        "\"name\": \"NSLocationWhenInUseUsageDescription\""
                    "}"
                "]"
            "},"
            "\"extensions_collecting\" : {"
                "\"min_collecting_interval_seconds\" : 1300,"
                "\"min_collecting_delay_after_launch_seconds\" : 4"
            "},"
            "\"foreground_location_collection\" : {"
                "\"min_update_interval_seconds\": 4,"
                "\"min_update_distance_meters\": 8,"
                "\"records_count_to_force_flush\": 15,"
                "\"max_records_count_in_batch\": 16,"
                "\"max_age_seconds_to_force_flush\": 23,"
                "\"max_records_to_store_locally\": 42"
            "},"
            "\"system_location_config\" : {"
                "\"default_desired_accuracy\" : 100,"
                "\"default_distance_filter\" : 350,"
                "\"accurate_desired_accuracy\" : 10,"
                "\"accurate_distance_filter\" : 120,"
                "\"pauses_location_updates_automatically\" : true"
            "},"
            "\"retry_policy\": {"
                "\"max_interval_seconds\": 600,"
                "\"exponential_multiplier\": 1"
            "},"
            "\"asa_token_reporting\" : {"
                "\"first_delay_seconds\" : 86400,"
                "\"reporting_interval_seconds\" : 43200,"
                "\"end_reporting_interval_seconds\" : 604800"
            "},"
            "\"skad_conversion_value\" : {"
                "\"key\" : \"value\""
            "},"
            "\"attribution\" : {"
                "\"deeplink_conditions\" : ["
                    "{"
                        "\"key\" : \"some key 1\","
                        "\"value\" : \"some value 1\""
                    "},"
                    "{"
                        "\"key\" : \"some key 2\","
                        "\"value\" : \"some value 2\""
                    "},"
                    "{"
                        "\"key\" : \"\","
                        "\"value\" : \"some value 3\""
                    "},"
                    "{"
                        "\"value\" : \"some value 4\""
                    "},"
                    "{"
                        "\"key\" : \"some key 5\","
                        "\"value\" : \"\""
                    "},"
                    "{"
                        "\"key\" : \"some key 6\""
                    "}"
                "]"
            "},"
            "\"external_attribution\": {"
                "\"collecting_interval_seconds\": 864000"
            "},"
            "\"startup_update\" : {"
                "\"interval_seconds\" : 100500"
            "}"
        "}";

        context(@"Parses data", ^{
            AMAStartupResponse * __block parsedResponse = nil;
            AMAAttributionModelConfiguration *__block parsedAttributionModelConfiguration = nil;
            AMAStartupParametersConfiguration *__block parsedConfiguration = nil;
            void (^setResponseWithString)(NSString *) = ^(NSString *responseString){
                NSData *data = [responseString dataUsingEncoding:NSUTF8StringEncoding];
                parsedResponse = [parser startupResponseWithHTTPResponse:nil
                                                                    data:data
                                                                   error:nil];
                parsedConfiguration = parsedResponse.configuration;
            };
            beforeEach(^{
                parsedAttributionModelConfiguration = [AMAAttributionModelConfiguration nullMock];
                NSDictionary *json = @{ @"a" : @"b" };
                [parsedAttributionModelConfiguration stub:@selector(JSON) andReturn:json];
                AMAAttributionModelConfiguration *allocedConfig = [AMAAttributionModelConfiguration nullMock];
                [AMAAttributionModelConfiguration stub:@selector(alloc) andReturn:allocedConfig];
                [allocedConfig stub:@selector(initWithJSON:) andReturn:parsedAttributionModelConfiguration withArguments:json];
                [attributionModelParser stub:@selector(parse:) andReturn:parsedAttributionModelConfiguration
                               withArguments:@{ @"key" : @"value" }];
                setResponseWithString(response);
            });

            it(@"Should parse device ID", ^{
                [[parsedResponse.deviceID should] equal:@"369f5c559986d404dd6a2cd61d8ab82a"];
            });
            it(@"Should parse device ID hash", ^{
                [[parsedResponse.deviceIDHash should] equal:@"9636906516878715833"];
            });

            it(@"Should parse reports host", ^{
                [[parsedConfiguration.reportHosts should] equal:@[
                    @"http://appmetrica.heroism.com",
                    @"http://another.heroism.com",
                ]];
            });

            it(@"Should parse redirect host", ^{
                [[parsedConfiguration.redirectHost should] equal:@"https://redirect.appmetrica.metrica-test.haze.com"];
            });
            
            it(@"Should parse the rest of the hosts", ^{
                [[parsedConfiguration.SDKsCustomHosts should] equal:@{
                    @"some_arbitrary_key1" : @[
                        @"http://appmetrica.heroism.com"
                    ],
                    @"some_arbitrary_key2" : @[
                        @"http://host1.other_sdk.appmetrica.io",
                        @"http://host2.other_sdk.appmetrica.io",
                    ],
                    @"get_ad" : @[
                        @"https://https://mobile-ads-beta.appmetrica.io:4443",
                    ],
                    @"report_ad" : @[
                        @"https://https://mobile-ads-beta.appmetrica.io:4443",
                    ],
                }];
            });
            
            it(@"Should parse report ads host", ^{
                [[parsedConfiguration.extendedParameters[@"get_ad"] should] equal:@"https://https://mobile-ads-beta.appmetrica.io:4443"];
            });
            
            it(@"Should parse get ads host", ^{
                [[parsedConfiguration.extendedParameters[@"report_ad"] should] equal:@"https://https://mobile-ads-beta.appmetrica.io:4443"];
            });

            it(@"Should parse initial country", ^{
                [[parsedConfiguration.initialCountry should] equal:@"by"];
            });

            it(@"Should parse stat sending disabled reporting interval", ^{
                [[parsedConfiguration.statSendingDisabledReportingInterval should] equal:@10823];
            });

            it(@"Should not set initial country when reliable = false", ^{
                NSString *responseWithFalseReliable = [response stringByReplacingOccurrencesOfString:@"\"locale\" : {"
                                                       "\"country\" : {"
                                                       "\"value\" : \"by\","
                                                       "\"reliable\" : true"
                                                                                          withString:@"\"locale\" : {"
                                                       "\"country\" : {"
                                                       "\"value\" : \"by\","
                                                       "\"reliable\" : false"];
                setResponseWithString(responseWithFalseReliable);
                [[parsedConfiguration.initialCountry should] beNil];
            });

            it(@"Should parse permissions", ^{
                NSString *permissionName = @"NSLocationDescription";
                AMAStartupPermission *startupPermission = [[AMAStartupPermission alloc] initWithName:permissionName
                                                                                             enabled:YES];
                NSString *expectedString =
                    [AMAStartupPermissionSerializer JSONStringWithPermissions:@{ permissionName : startupPermission }];
                [[parsedConfiguration.permissionsString should] equal:expectedString];
            });

            it(@"Should parse attribution model configuration", ^{
                [[parsedResponse.attributionModelConfiguration should] equal:parsedAttributionModelConfiguration];
            });

            context(@"Extensions collecting", ^{
                it(@"Should parse feature flag", ^{
                    [[theValue(parsedConfiguration.extensionsCollectingEnabled) should] beYes];
                });
                it(@"Should parse extensionsCollectingInterval", ^{
                    [[parsedConfiguration.extensionsCollectingInterval should] equal:@1300];
                });
                it(@"Should parse extensionsCollectingLaunchDelay", ^{
                    [[parsedConfiguration.extensionsCollectingLaunchDelay should] equal:@4];
                });
            });

            context(@"Permissions collecting", ^{
                it(@"Should parse feature flag", ^{
                    [[theValue(parsedConfiguration.permissionsCollectingEnabled) should] beYes];
                });
                it(@"Should parse permissionsCollectingForceSendInterval", ^{
                    [[parsedConfiguration.permissionsCollectingForceSendInterval should] equal:@86400];
                });
                it(@"Should parse permissionsCollectingList", ^{
                    [[parsedConfiguration.permissionsCollectingList should] equal:@[
                        @"NSLocationWhenInUseUsageDescription",
                    ]];
                });
            });

            context(@"Active location collecting", ^{
                it(@"Should parse feature flag", ^{
                    [[theValue(parsedConfiguration.locationCollectingEnabled) should] beYes];
                });
                it(@"Should parse hosts", ^{
                    [[parsedConfiguration.locationHosts should] equal:@[ @"foo", @"bar" ]];
                });
                it(@"Should parse locationMinUpdateInterval", ^{
                    [[parsedConfiguration.locationMinUpdateInterval should] equal:@4];
                });
                it(@"Should parse locationMinUpdateDistance", ^{
                    [[parsedConfiguration.locationMinUpdateDistance should] equal:@8];
                });
                it(@"Should parse locationRecordsCountToForceFlush", ^{
                    [[parsedConfiguration.locationRecordsCountToForceFlush should] equal:@15];
                });
                it(@"Should parse locationMaxRecordsCountInBatch", ^{
                    [[parsedConfiguration.locationMaxRecordsCountInBatch should] equal:@16];
                });
                it(@"Should parse locationMaxAgeToForceFlush", ^{
                    [[parsedConfiguration.locationMaxAgeToForceFlush should] equal:@23];
                });
                it(@"Should parse locationMaxRecordsToStoreLocally", ^{
                    [[parsedConfiguration.locationMaxRecordsToStoreLocally should] equal:@42];
                });
            });

            context(@"Common system location collecting config", ^{
                it(@"Should parse pauses location updates automatically flag", ^{
                    [[parsedConfiguration.locationPausesLocationUpdatesAutomatically should] beYes];
                });
                it(@"Should parse default desired accuracy", ^{
                    [[parsedConfiguration.locationDefaultDesiredAccuracy should] equal:@100];
                });
                it(@"Should parse default distance filter", ^{
                    [[parsedConfiguration.locationDefaultDistanceFilter should] equal:@350];
                });
                it(@"Should parse accurate desired accuracy", ^{
                    [[parsedConfiguration.locationAccurateDesiredAccuracy should] equal:@10];
                });
                it(@"Should parse accurate distance filter", ^{
                    [[parsedConfiguration.locationAccurateDistanceFilter should] equal:@120];
                });
            });

            context(@"Exponential backoff retry policy", ^{
                it(@"Should parse max timeout duration", ^{
                    [[parsedConfiguration.retryPolicyMaxIntervalSeconds should] equal:@600];
                });
                it(@"Should parse multiplyer", ^{
                    [[parsedConfiguration.retryPolicyExponentialMultiplier should] equal:@1];
                });
            });

            context(@"ASA token reporting config", ^{
                it(@"Should parse first execution delay", ^{
                    [[parsedConfiguration.ASATokenFirstDelay should] equal:@86400];
                });
                it(@"Should parse reporting interval", ^{
                    [[parsedConfiguration.ASATokenReportingInterval should] equal:@43200];
                });
                it(@"Should parse end reporting interval", ^{
                    [[parsedConfiguration.ASATokenEndReportingInterval should] equal:@604800];
                });
            });

            context(@"Attribution config", ^{
                it (@"Should parse", ^{
                    [[theValue(parsedConfiguration.attributionDeeplinkConditions.count) should] equal:theValue(4)];
                    [[parsedConfiguration.attributionDeeplinkConditions[0].key should] equal:@"some key 1"];
                    [[parsedConfiguration.attributionDeeplinkConditions[0].value should] equal:@"some value 1"];
                    [[parsedConfiguration.attributionDeeplinkConditions[1].key should] equal:@"some key 2"];
                    [[parsedConfiguration.attributionDeeplinkConditions[1].value should] equal:@"some value 2"];
                    [[parsedConfiguration.attributionDeeplinkConditions[2].key should] equal:@"some key 5"];
                    [[parsedConfiguration.attributionDeeplinkConditions[2].value should] equal:@""];
                    [[parsedConfiguration.attributionDeeplinkConditions[3].key should] equal:@"some key 6"];
                    [[parsedConfiguration.attributionDeeplinkConditions[3].value should] beNil];
                });
            });
            
            context(@"External attribution", ^{
                it(@"Should parse intercal", ^{
                    [[parsedConfiguration.externalAttributionCollectingInterval should] equal:@864000];
                });
            });
            
            context(@"Startup update", ^{
                it(@"Should parse interval", ^{
                    [[parsedConfiguration.startupUpdateInterval should] equal:@100500];
                });
            });
        });
        context(@"Parses headers", ^{
            AMAStartupResponse *(^responseWithDate)(NSString *) = ^AMAStartupResponse *(NSString *date) {
                NSDictionary *headers = @{ @"Date" : date };
                NSHTTPURLResponse *HTTPResponse = [NSHTTPURLResponse nullMock];
                [HTTPResponse stub:@selector(allHeaderFields) andReturn:headers];
                NSData *data = [response dataUsingEncoding:NSUTF8StringEncoding];
                AMAStartupResponse *parsedResponse = [parser startupResponseWithHTTPResponse:HTTPResponse data:data error:nil];
                return parsedResponse;
            };

            it(@"Should parse correct server time", ^{
                [NSDate stub:@selector(date) andReturn:[NSDate dateWithTimeIntervalSince1970:1425555432.0]];
                AMAStartupResponse *startupResponse = responseWithDate(@"Thu, 05 Mar 2015 10:37:12 GMT");
                [[startupResponse.configuration.serverTimeOffset should] equal:@(-60 * 60)];
            });
            it(@"Should parse correct server time with one day digit", ^{
                [NSDate stub:@selector(date) andReturn:[NSDate dateWithTimeIntervalSince1970:1425555432.0]];
                AMAStartupResponse *startupResponse = responseWithDate(@"Thu, 5 Mar 2015 10:37:12 GMT");
                [[startupResponse.configuration.serverTimeOffset should] equal:@(-60 * 60)];
            });
            it(@"Should ignore server time with four time digits", ^{
                AMAStartupResponse *startupResponse = responseWithDate(@"Thu, 5 Mar 2015 10:37 GMT");
                [[startupResponse.configuration.serverTimeOffset should] beNil];
            });
            it(@"Should ignore invalid server time", ^{
                AMAStartupResponse *startupResponse = responseWithDate(@"Thurs, 05 Mar 2015 10:37:12 GMT");
                [[startupResponse.configuration.serverTimeOffset should] beNil];
            });
        });

        context(@"Encrypted response", ^{
            AMAStartupResponse * __block parsedResponse = nil;
            NSObject<AMADataEncoding> *__block encoder = nil;
            beforeEach(^{
                NSData *data = [response dataUsingEncoding:NSUTF8StringEncoding];
                encoder = [KWMock nullMockForProtocol:@protocol(AMADataEncoding)];
                [encoder stub:@selector(decodeData:error:) andReturn:data];
                [AMAStartupResponseEncoderFactory stub:@selector(encoder) andReturn:encoder];
                NSDictionary *headers = @{ @"Content-Encoding": @"encrypted" };
                NSHTTPURLResponse *response = [NSHTTPURLResponse nullMock];
                [response stub:@selector(allHeaderFields) andReturn:headers];
                NSData *encryptedData = [@"ENCRYPTED" dataUsingEncoding:NSUTF8StringEncoding];
                parsedResponse = [parser startupResponseWithHTTPResponse:response
                                                                    data:encryptedData
                                                                   error:nil];
            });
            it(@"Should parse", ^{
                [[parsedResponse shouldNot] beNil];
            });
            it(@"Should parse deviceIDHash", ^{
                [[parsedResponse.deviceIDHash should] equal:@"9636906516878715833"];
            });
            it(@"Should parse reports host", ^{
                [[parsedResponse.configuration.reportHosts should] equal:@[
                    @"http://appmetrica.heroism.com",
                    @"http://another.heroism.com",
                ]];
            });
        });

        context(@"Invalid response", ^{
            it(@"Should not throw if nil startup", ^{
                [[theBlock(^{
                    [parser startupResponseWithHTTPResponse:nil data:nil error:nil];
                }) shouldNot] raise];
            });

            it(@"Should not raise with empty string", ^{
                [[theBlock(^{
                    [parser startupResponseWithHTTPResponse:nil data:[NSData data] error:nil];
                }) shouldNot] raise];
            });

            it(@"Should not raise with missing keys", ^{
                [[theBlock(^{
                    NSString *otherJSON = @"{ \"key1\" : \"value1\"}";
                    NSData *data = [otherJSON dataUsingEncoding:NSUTF8StringEncoding];
                    [parser startupResponseWithHTTPResponse:nil data:data error:nil];
                }) shouldNot] raise];
            });
        });
        
        context(@"Extended response", ^{
            it(@"Should parse extended response", ^{
                NSData *data = [response dataUsingEncoding:NSUTF8StringEncoding];
                NSDictionary *expected = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                
                NSDictionary *parsedExtended = [parser extendedStartupResponseWithHTTPResponse:nil
                                                                                          data:data
                                                                                         error:nil];
                
                [[parsedExtended should] equal:expected];

            });
        });
    });
});

SPEC_END
