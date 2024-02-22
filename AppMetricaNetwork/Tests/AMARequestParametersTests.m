
#import <Kiwi/Kiwi.h>
#import <AppMetricaPlatform/AppMetricaPlatform.h>
#import <AppMetricaNetwork/AppMetricaNetwork.h>
#import "AMARequestParametersTestHelper.h"

SPEC_BEGIN(AMARequestParametersTests)

describe(@"AMARequestParameters", ^{
    NSString *const apiKey = @"550e8400-e29b-41d4-a716-446655440000";
    NSString *const attributionID = @"1";
    NSString *const requestID = @"23";
    
    context(@"Provides immutable parameters in dictionary", ^{
        NSDictionary * __block parametersDictionary = nil;
        AMARequestParametersTestHelper * __block requestParametersHelper;
        beforeEach(^{
            requestParametersHelper = [[AMARequestParametersTestHelper alloc] init];
            [requestParametersHelper configureStubs];
            AMARequestParameters *parameters = [[AMARequestParameters alloc] initWithApiKey:apiKey
                                                                              attributionID:attributionID
                                                                                  requestID:requestID
                                                                           applicationState:nil
                                                                           inMemoryDatabase:NO
                                                                                    options:AMARequestParametersDefault];
            parametersDictionary = [parameters dictionaryRepresentation];
        });
        it(@"Should provide device_type tablet in dictionary representation", ^{
            requestParametersHelper.isIPad = YES;
            [requestParametersHelper configureStubs];
            AMARequestParameters *parameters =
            [[AMARequestParameters alloc] initWithApiKey:apiKey
                                           attributionID:attributionID
                                               requestID:requestID
                                        applicationState:nil
                                        inMemoryDatabase:NO
                                                 options:AMARequestParametersDefault];
            parametersDictionary = [parameters dictionaryRepresentation];
            [[parametersDictionary[@"device_type"] should] equal:@"tablet"];
        });
        it(@"Should provide device_type phone in dictionary representation", ^{
            requestParametersHelper.isIPad = NO;
            [requestParametersHelper configureStubs];
            AMARequestParameters *parameters =
            [[AMARequestParameters alloc] initWithApiKey:apiKey
                                           attributionID:attributionID
                                               requestID:requestID
                                        applicationState:nil
                                        inMemoryDatabase:NO
                                                 options:AMARequestParametersDefault];
            parametersDictionary = [parameters dictionaryRepresentation];
            [[parametersDictionary[@"device_type"] should] equal:@"phone"];
        });
        it(@"Should provide app_platform in dictionary representation", ^{
            [[parametersDictionary[@"app_platform"] should] equal:requestParametersHelper.appPlatform];
        });
        it(@"Should provide manufacturer in dictionary representation", ^{
            [[parametersDictionary[@"manufacturer"] should] equal:requestParametersHelper.manufacturer];
        });
        it(@"Should provide model in dictionary representation", ^{
            [[parametersDictionary[@"model"] should] equal:requestParametersHelper.model];
        });
        it(@"Should provide screen_width in dictionary representation", ^{
            [[parametersDictionary[@"screen_width"] should] equal:requestParametersHelper.screenWidth];
        });
        it(@"Should provide screen_height in dictionary representation", ^{
            [[parametersDictionary[@"screen_height"] should] equal:requestParametersHelper.screenHeight];
        });
        it(@"Should provide scalefactor in dictionary representation", ^{
            [[parametersDictionary[@"scalefactor"] should] equal:requestParametersHelper.scalefactor];
        });
        it(@"Should provide screen_dpi in dictionary representation", ^{
            [[parametersDictionary[@"screen_dpi"] should] equal:requestParametersHelper.screenDPI];
        });
        it(@"Should provide app_id in dictionary representation", ^{
            [[parametersDictionary[@"app_id"] should] equal:requestParametersHelper.appID];
        });
        it(@"Should provide api_key_128 in dictionary representation", ^{
            [[parametersDictionary[@"api_key_128"] should] equal:apiKey];
        });
        it(@"Should provide app_framework in dictionary representation", ^{
            [[parametersDictionary[@"app_framework"] should] equal:requestParametersHelper.appFramework];
        });
        it(@"Should provide attribution_id in dictionary representation", ^{
            [[parametersDictionary[@"attribution_id"] should] equal:attributionID];
        });
        it(@"Should provide request_id in dictionary representation", ^{
            [[parametersDictionary[@"request_id"] should] equal:requestID];
        });
        context(@"Storage type", ^{
            it(@"Should have no storage_type", ^{
                [[parametersDictionary[@"storage_type"] should] beNil];
            });
            context(@"In memory", ^{
                beforeEach(^{
                    AMARequestParameters *parameters = [[AMARequestParameters alloc] initWithApiKey:apiKey
                                                                                      attributionID:attributionID
                                                                                          requestID:requestID
                                                                                   applicationState:nil
                                                                                   inMemoryDatabase:YES
                                                                                            options:AMARequestParametersDefault];
                    parametersDictionary = [parameters dictionaryRepresentation];
                });
                it(@"Should have no storage_type", ^{
                    [[parametersDictionary[@"storage_type"] should] equal:@"inmemory"];
                });
            });
        });
    });
    context(@"Provides all parameters", ^{
        NSDictionary * __block parametersDictionary = nil;
        AMAApplicationState * __block appState = nil;
        AMARequestParametersTestHelper * __block requestParametersHelper;
        AMARequestParameters * __block parameters = nil;
        beforeEach(^{
            requestParametersHelper = [[AMARequestParametersTestHelper alloc] init];
            [requestParametersHelper configureStubs];
            appState = [[AMAApplicationState alloc] init];
            parameters = [[AMARequestParameters alloc] initWithApiKey:apiKey
                                                        attributionID:attributionID
                                                            requestID:requestID
                                                     applicationState:appState
                                                     inMemoryDatabase:NO
                                                              options:AMARequestParametersAllowIDFA];
            parametersDictionary = [parameters dictionaryRepresentation];
        });
        context(@"Provides application state in request parameters", ^{
            it(@"Should provide app state keys in request parameters", ^{
                NSArray *requestParametersKeys = [parametersDictionary allKeys];
                NSArray *appStateKeys = [[appState dictionaryRepresentation] allKeys];
                [[requestParametersKeys should] containObjectsInArray:appStateKeys];
            });
            it(@"Should provide app state values in request parameters", ^{
                NSArray *requestParametersValues = [parametersDictionary allValues];
                NSArray *appStateValues = [[appState dictionaryRepresentation] allValues];
                [[requestParametersValues should] containObjectsInArray:appStateValues];
            });
        });
    });
    context(@"Provides parameters without IDFA", ^{
        NSDictionary * __block parametersDictionary = nil;
        AMAApplicationState * __block appState = nil;
        AMARequestParametersTestHelper * __block requestParametersHelper;
        AMARequestParameters * __block parameters = nil;
        beforeEach(^{
            requestParametersHelper = [[AMARequestParametersTestHelper alloc] init];
            [requestParametersHelper configureStubs];
            appState = [[AMAApplicationState alloc] init];
            parameters = [[AMARequestParameters alloc] initWithApiKey:apiKey
                                                        attributionID:attributionID
                                                            requestID:requestID
                                                     applicationState:appState
                                                     inMemoryDatabase:NO
                                                              options:AMARequestParametersDefault];
            parametersDictionary = [parameters dictionaryRepresentation];
        });
        context(@"Provides application state in request parameters", ^{
            it(@"Should provide app state keys in request parameters", ^{
                NSMutableDictionary *appStateDictionary = appState.dictionaryRepresentation.mutableCopy;
                [appStateDictionary removeObjectForKey: kAMALATKey];
                [appStateDictionary removeObjectForKey:kAMAIFAKey];
                
                NSArray *requestParametersKeys = [parametersDictionary allKeys];
                NSArray *appStateKeys = [appStateDictionary allKeys];
                [[requestParametersKeys should] containObjectsInArray:appStateKeys];
            });
            it(@"Should provide app state values in request parameters", ^{
                NSArray *requestParametersValues = [parametersDictionary allValues];
                NSArray *appStateValues = [[appState dictionaryRepresentation] allValues];
                [[requestParametersValues should] containObjectsInArray:appStateValues];
            });
        });
    });
});

SPEC_END
