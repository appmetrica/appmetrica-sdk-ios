
#import <Kiwi/Kiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMADeepLinkController.h"
#import "AMADeepLinkPayloadFactory.h"
#import "AMAReporter.h"
#import "AMAMetricaConfiguration.h"
#import "AMAStartupParametersConfiguration.h"
#import "AMAPair.h"

SPEC_BEGIN(AMADeepLinkControllerTests)

describe(@"AMADeepLinkController", ^{


    AMADeepLinkController *__block controller = nil;
    AMAReporter *__block reporter = nil;

    NSString *const type = @"type";
    NSURL *const URL = [NSURL URLWithString:@"app://path?foo=bar"];
    NSDictionary *const payload = [NSDictionary nullMock];

    beforeEach(^{
        id<AMAAsyncExecuting> executor = [[AMACurrentQueueExecutor alloc] init];
        reporter = [AMAReporter nullMock];
        controller = [[AMADeepLinkController alloc] initWithReporter:reporter executor:executor];

        [AMADeepLinkPayloadFactory stub:@selector(deepLinkPayloadForURL:ofType:isAuto:error:) andReturn:payload];

    });

    it(@"Should format payload", ^{
        [[AMADeepLinkPayloadFactory should] receive:@selector(deepLinkPayloadForURL:ofType:isAuto:error:)
                                      withArguments:URL, type, theValue(YES), kw_any()];
        [controller reportUrl:URL ofType:type isAuto:YES];
    });

    it(@"Should report payload", ^{
        [[reporter should] receive:@selector(reportOpenEvent:reattribution:onFailure:)
                     withArguments:payload, theValue(NO), kw_any()];
        [controller reportUrl:URL ofType:type isAuto:NO];
    });

    it(@"Should not report same links twice", ^{
        [controller reportUrl:URL ofType:type isAuto:YES];
        [[reporter shouldNot] receive:@selector(reportOpenEvent:reattribution:onFailure:)];
        [controller reportUrl:URL ofType:type isAuto:YES];
    });

    it(@"Should report different links", ^{
        [controller reportUrl:[NSURL URLWithString:@"https://different.url.com"] ofType:type isAuto:NO];
        [[reporter should] receive:@selector(reportOpenEvent:reattribution:onFailure:)
                     withArguments:payload, theValue(NO), kw_any()];
        [controller reportUrl:URL ofType:type isAuto:NO];
    });

    context(@"Reattribution", ^{

        AMAStartupParametersConfiguration *__block startup = nil;

        beforeEach(^{
            AMAMetricaConfiguration *metricaConfiguration = [AMAMetricaConfiguration nullMock];
            startup = [AMAStartupParametersConfiguration nullMock];
            [AMAMetricaConfiguration stub:@selector(sharedInstance) andReturn:metricaConfiguration];
            [metricaConfiguration stub:@selector(startup) andReturn:startup];
        });

        context(@"Null conditions", ^{
            beforeEach(^{
                [startup stub:@selector(attributionDeeplinkConditions) andReturn:nil];
            });
            it(@"Should be YES for reattribution=1", ^{
                [[reporter should] receive:@selector(reportOpenEvent:reattribution:onFailure:)
                             withArguments:kw_any(), theValue(YES), kw_any()];
                [controller reportUrl:[NSURL URLWithString:@"appmetrica://?referrer=reattribution%3D1"] ofType:type isAuto:NO];
            });
            it(@"Should be NO for reattribution=2", ^{
                [[reporter should] receive:@selector(reportOpenEvent:reattribution:onFailure:)
                             withArguments:kw_any(), theValue(NO), kw_any()];
                [controller reportUrl:[NSURL URLWithString:@"appmetrica://?referrer=reattribution%3D2"] ofType:type isAuto:NO];
            });
            it(@"Should be NO for reattribution=1 inside another parameter", ^{
                [[reporter should] receive:@selector(reportOpenEvent:reattribution:onFailure:)
                             withArguments:kw_any(), theValue(NO), kw_any()];
                [controller reportUrl:[NSURL URLWithString:@"appmetrica://?notreferrer=reattribution%3D1&referrer=something"] ofType:type isAuto:NO];
            });
            it(@"Should be NO for reattribution=1 inside referrer inside another parameter", ^{
                [[reporter should] receive:@selector(reportOpenEvent:reattribution:onFailure:)
                             withArguments:kw_any(), theValue(NO), kw_any()];
                [controller reportUrl:[NSURL URLWithString:@"appmetrica-search-app-open://?uri=https%3A%2F%2Fcollections.appmetrica.com%2F"
                                                           "interery%2F#referrer%3Dreattribution=1"] ofType:type isAuto:NO];
            });
            it(@"Should be NO for reattribution=1 as root parameter", ^{
                [[reporter should] receive:@selector(reportOpenEvent:reattribution:onFailure:)
                             withArguments:kw_any(), theValue(NO), kw_any()];
                [controller reportUrl:[NSURL URLWithString:@"appmetrica://?reattribution=1&referrer=something"] ofType:type isAuto:NO];
            });
            it(@"Should be NO for reattribution=1 as encoded root parameter", ^{
                [[reporter should] receive:@selector(reportOpenEvent:reattribution:onFailure:)
                             withArguments:kw_any(), theValue(NO), kw_any()];
                [controller reportUrl:[NSURL URLWithString:@"appmetrica://?reattribution%3D1&referrer=something"] ofType:type isAuto:NO];
            });
        });
        context(@"Empty conditions", ^{
            beforeEach(^{
                [startup stub:@selector(attributionDeeplinkConditions) andReturn:@[]];
            });
            it(@"Should be YES for reattribution=1", ^{
                [[reporter should] receive:@selector(reportOpenEvent:reattribution:onFailure:)
                             withArguments:kw_any(), theValue(YES), kw_any()];
                [controller reportUrl:[NSURL URLWithString:@"appmetrica://?referrer=reattribution%3D1"] ofType:type isAuto:NO];
            });
            it(@"Should be NO for reattribution=2", ^{
                [[reporter should] receive:@selector(reportOpenEvent:reattribution:onFailure:)
                             withArguments:kw_any(), theValue(NO), kw_any()];
                [controller reportUrl:[NSURL URLWithString:@"appmetrica://?referrer=reattribution%3D2"] ofType:type isAuto:NO];
            });
        });
        context(@"Non empty conditions", ^{
            beforeEach(^{
                [startup stub:@selector(attributionDeeplinkConditions) andReturn:@[
                    [[AMAPair alloc] initWithKey:@"yclid" value:@"414"],
                    [[AMAPair alloc] initWithKey:@"yclid" value:@"415"],
                    [[AMAPair alloc] initWithKey:@"yid" value:@""],
                    [[AMAPair alloc] initWithKey:@"yuid" value:nil],
                    [[AMAPair alloc] initWithKey:@"ydeviceid" value:@"666777"],
                    [[AMAPair alloc] initWithKey:@"" value:@"12"]
                ]];
            });

            it(@"Should be YES for deeplink with yclid=414", ^{
                NSURL *url = [NSURL URLWithString:@"appmetrica-search-app-open://?uri=https%3A%2F%2Fcollections.appmetrica.com%2F"
                                                  "interery%2F&referrer=appmetrica_tracking_id%3D97066511625096571%26"
                                                  "ym_tracking_id%3D8842404282613596432%26yclid%3D414"];
                [[reporter should] receive:@selector(reportOpenEvent:reattribution:onFailure:)
                             withArguments:kw_any(), theValue(YES), kw_any()];
                [controller reportUrl:url ofType:type isAuto:NO];
            });
            it(@"Should be NO for deeplink without referrer", ^{
                NSURL *url = [NSURL URLWithString:@"appmetrica-search-app-open://?uri=https%3A%2F%2Fcollections.appmetrica.com%2F"
                                                  "interery%2F#reattribution=1"];
                [[reporter should] receive:@selector(reportOpenEvent:reattribution:onFailure:)
                             withArguments:kw_any(), theValue(NO), kw_any()];
                [controller reportUrl:url ofType:type isAuto:NO];
            });
            it(@"Should be NO for deeplink with yclid=414 outside referrer", ^{
                NSURL *url = [NSURL URLWithString:@"appmetrica-search-app-open://?uri=https%3A%2F%2Fcollections.appmetrica.com%2F"
                                                  "interery%2F&yclid=414&referrer=appmetrica_tracking_id%3D97066511625096571%26"
                                                  "ym_tracking_id%3D8842404282613596432%26"];
                [[reporter should] receive:@selector(reportOpenEvent:reattribution:onFailure:)
                             withArguments:kw_any(), theValue(NO), kw_any()];
                [controller reportUrl:url ofType:type isAuto:NO];
            });
            it(@"Should be NO for deeplink with yclid=414 inside referrer inside another parameter", ^{
                NSURL *url = [NSURL URLWithString:@"appmetrica-search-app-open://?uri=https%3A%2F%2Fcollections.appmetrica.com%2F"
                                                  "interery%2F#referrer=yclid=414"];
                [[reporter should] receive:@selector(reportOpenEvent:reattribution:onFailure:)
                             withArguments:kw_any(), theValue(NO), kw_any()];
                [controller reportUrl:url ofType:type isAuto:NO];
            });
            it(@"Should be YES for deeplink with yclid=415", ^{
                NSURL *url = [NSURL URLWithString:@"appmetrica-search-app-open://?uri=https%3A%2F%2Fcollections.appmetrica.com%2F"
                                                  "interery%2F&referrer=appmetrica_tracking_id%3D97066511625096571%26"
                                                  "ym_tracking_id%3D8842404282613596432%26yclid%3D415"];
                [[reporter should] receive:@selector(reportOpenEvent:reattribution:onFailure:)
                             withArguments:kw_any(), theValue(YES), kw_any()];
                [controller reportUrl:url ofType:type isAuto:NO];
            });
            it(@"Should be NO for deeplink with yclid=416", ^{
                NSURL *url = [NSURL URLWithString:@"ya-search-app-open://?uri=https%3A%2F%2Fcollections.appmetrica.com%2F"
                                                  "interery%2F&referrer=appmetrica_tracking_id%3D97066511625096571%26"
                                                  "ym_tracking_id%3D8842404282613596432%26yclid%3D416"];
                [[reporter should] receive:@selector(reportOpenEvent:reattribution:onFailure:)
                             withArguments:kw_any(), theValue(NO), kw_any()];
                [controller reportUrl:url ofType:type isAuto:NO];
            });
            it(@"Should be NO for deeplink with empty yclid", ^{
                NSURL *url = [NSURL URLWithString:@"appmetrica-search-app-open://?uri=https%3A%2F%2Fcollections.appmetrica.com%2F"
                                                  "interery%2F&referrer=appmetrica_tracking_id%3D97066511625096571%26"
                                                  "ym_tracking_id%3D8842404282613596432%26yclid%3D"];
                [[reporter should] receive:@selector(reportOpenEvent:reattribution:onFailure:)
                             withArguments:kw_any(), theValue(NO), kw_any()];
                [controller reportUrl:url ofType:type isAuto:NO];
            });
            it(@"Should be NO for deeplink with yid=1", ^{
                NSURL *url = [NSURL URLWithString:@"appmetrica-search-app-open://?uri=https%3A%2F%2Fcollections.appmetrica.com%2F"
                                                  "interery%2F&referrer=appmetrica_tracking_id%3D97066511625096571%26"
                                                  "ym_tracking_id%3D8842404282613596432%26yid%3D1"];
                [[reporter should] receive:@selector(reportOpenEvent:reattribution:onFailure:)
                             withArguments:kw_any(), theValue(NO), kw_any()];
                [controller reportUrl:url ofType:type isAuto:NO];
            });
            it(@"Should be YES for deeplink with empty yid", ^{
                NSURL *url = [NSURL URLWithString:@"appmetrica-search-app-open://?uri=https%3A%2F%2Fcollections.appmetrica.cpm%2F"
                                                  "interery%2F&referrer=appmetrica_tracking_id%3D97066511625096571%26"
                                                  "ym_tracking_id%3D8842404282613596432%26yid%3D"];
                [[reporter should] receive:@selector(reportOpenEvent:reattribution:onFailure:)
                             withArguments:kw_any(), theValue(YES), kw_any()];
                [controller reportUrl:url ofType:type isAuto:NO];
            });
            it(@"Should be YES for deeplink with yuid=414", ^{
                NSURL *url = [NSURL URLWithString:@"appmetrica-search-app-open://?uri=https%3A%2F%2Fcollections.appmetrica.com%2F"
                                                  "interery%2F&referrer=appmetrica_tracking_id%3D97066511625096571%26"
                                                  "ym_tracking_id%3D8842404282613596432%26yuid%3D414"];
                [[reporter should] receive:@selector(reportOpenEvent:reattribution:onFailure:)
                             withArguments:kw_any(), theValue(YES), kw_any()];
                [controller reportUrl:url ofType:type isAuto:NO];
            });
            it(@"Should be YES for deeplink with empty yuid", ^{
                NSURL *url = [NSURL URLWithString:@"appmetrica-search-app-open://?uri=https%3A%2F%2Fcollections.appmetrica.com%2F"
                                                  "interery%2F&referrer=appmetrica_tracking_id%3D97066511625096571%26"
                                                  "ym_tracking_id%3D8842404282613596432%26yuid%3D"];
                [[reporter should] receive:@selector(reportOpenEvent:reattribution:onFailure:)
                             withArguments:kw_any(), theValue(YES), kw_any()];
                [controller reportUrl:url ofType:type isAuto:NO];
            });
            it(@"Should be YES for deeplink with null yuid", ^{
                NSURL *url = [NSURL URLWithString:@"appmetrica-search-app-open://?uri=https%3A%2F%2Fcollections.appmetrica.com%2F"
                                                  "interery%2F&referrer=appmetrica_tracking_id%3D97066511625096571%26"
                                                  "ym_tracking_id%3D8842404282613596432%26yuid"];
                [[reporter should] receive:@selector(reportOpenEvent:reattribution:onFailure:)
                             withArguments:kw_any(), theValue(YES), kw_any()];
                [controller reportUrl:url ofType:type isAuto:NO];
            });
            it(@"Should be YES for deeplink with ydeviceid=666777", ^{
                NSURL *url = [NSURL URLWithString:@"appmetrica-search-app-open://?uri=https%3A%2F%2Fcollections.appmetrica.com%2F"
                                                  "interery%2F&referrer=appmetrica_tracking_id%3D97066511625096571%26"
                                                  "ym_tracking_id%3D8842404282613596432%26ydeviceid%3D666777"];
                [[reporter should] receive:@selector(reportOpenEvent:reattribution:onFailure:)
                             withArguments:kw_any(), theValue(YES), kw_any()];
                [controller reportUrl:url ofType:type isAuto:NO];
            });
            it(@"Should be YES for deeplink with =12", ^{
                NSURL *url = [NSURL URLWithString:@"appmetrica-search-app-open://?uri=https%3A%2F%2Fcollections.appmetrica.com%2F"
                                                  "interery%2F&referrer=appmetrica_tracking_id%3D97066511625096571%26"
                                                  "ym_tracking_id%3D8842404282613596432%26%3D12"];
                [[reporter should] receive:@selector(reportOpenEvent:reattribution:onFailure:)
                             withArguments:kw_any(), theValue(YES), kw_any()];
                [controller reportUrl:url ofType:type isAuto:NO];
            });
            it(@"Should be NO for deeplink with =13", ^{
                NSURL *url = [NSURL URLWithString:@"appmetrica-search-app-open://?uri=https%3A%2F%2Fcollections.appmetrica.com%2F"
                                                  "interery%2F&referrer=appmetrica_tracking_id%3D97066511625096571%26"
                                                  "ym_tracking_id%3D8842404282613596432%26%3D13"];
                [[reporter should] receive:@selector(reportOpenEvent:reattribution:onFailure:)
                             withArguments:kw_any(), theValue(NO), kw_any()];
                [controller reportUrl:url ofType:type isAuto:NO];
            });
            it(@"Should be YES for deeplink with reattribution=1 and yclid=414", ^{
                NSURL *url = [NSURL URLWithString:@"appmetrica-search-app-open://?uri=https%3A%2F%2Fcollections.appmetrica.com%2F"
                                                  "interery%2F&referrer=appmetrica_tracking_id%3D97066511625096571%26"
                                                  "ym_tracking_id%3D8842404282613596432%26reattribution%3D1%26yclid%3D414"];
                [[reporter should] receive:@selector(reportOpenEvent:reattribution:onFailure:)
                             withArguments:kw_any(), theValue(YES), kw_any()];
                [controller reportUrl:url ofType:type isAuto:NO];
            });
            it(@"Should be YES for deeplink with reattribution=1", ^{
                NSURL *url = [NSURL URLWithString:@"appmetrica-search-app-open://?uri=https%3A%2F%2Fcollections.appmetrica.com%2F"
                                                  "interery%2F&referrer=appmetrica_tracking_id%3D97066511625096571%26"
                                                  "ym_tracking_id%3D8842404282613596432%26reattribution%3D1"];
                [[reporter should] receive:@selector(reportOpenEvent:reattribution:onFailure:)
                             withArguments:kw_any(), theValue(YES), kw_any()];
                [controller reportUrl:url ofType:type isAuto:NO];
            });
            it(@"Should be YES for deeplink with reattribution=1 not encoded", ^{
                NSURL *url = [NSURL URLWithString:@"appmetrica-search-app-open://?uri=https%3A%2F%2Fcollections.appmetrica.com%2F"
                                                  "interery%2F&referrer=appmetrica_tracking_id%3D97066511625096571%26"
                                                  "ym_tracking_id%3D8842404282613596432%26reattribution=1"];
                [[reporter should] receive:@selector(reportOpenEvent:reattribution:onFailure:)
                             withArguments:kw_any(), theValue(YES), kw_any()];
                [controller reportUrl:url ofType:type isAuto:NO];
            });

        });
    });
});

SPEC_END
