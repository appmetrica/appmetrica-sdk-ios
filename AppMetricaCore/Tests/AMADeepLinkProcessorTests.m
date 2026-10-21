
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaCore/AppMetricaCore.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMADeepLinkProcessor.h"
#import "AMADeepLinkPayloadFactory.h"
#import "AMAMetricaConfiguration.h"
#import "AMAStartupParametersConfiguration.h"

SPEC_BEGIN(AMADeepLinkProcessorTests)

describe(@"AMADeepLinkProcessor", ^{

    AMADeepLinkProcessor *__block processor = nil;

    NSString *const type = @"type";
    NSURL *const URL = [NSURL URLWithString:@"app://path?foo=bar"];
    NSDictionary *const payload = @{ @"link": URL.absoluteString };

    beforeEach(^{
        processor = [[AMADeepLinkProcessor alloc] init];
        [AMADeepLinkPayloadFactory stub:@selector(deepLinkPayloadForURL:ofType:isAuto:error:) andReturn:payload];
    });
    afterEach(^{
        [AMADeepLinkPayloadFactory clearStubs];
    });

    it(@"Should format and return payload", ^{
        [[AMADeepLinkPayloadFactory should] receive:@selector(deepLinkPayloadForURL:ofType:isAuto:error:)
                                      withArguments:URL, type, theValue(YES), kw_any()];
        NSDictionary *result = [processor consumeURL:URL ofType:type isAuto:YES reattribution:NULL];
        [[result should] equal:payload];
    });

    it(@"Should deduplicate nonconsecutive URLs across manual and automatic tracking", ^{
        [[[processor consumeURL:URL ofType:type isAuto:YES reattribution:NULL] should] equal:payload];
        [[[processor consumeURL:[NSURL URLWithString:@"https://different.url.com"]
                          ofType:type isAuto:NO reattribution:NULL] should] equal:payload];
        BOOL reattribution = YES;
        [[[processor consumeURL:URL ofType:type isAuto:NO reattribution:&reattribution] should] beNil];
        [[theValue(reattribution) should] beNo];
    });

    it(@"Should keep consumed URLs independent between processors", ^{
        [processor consumeURL:URL ofType:type isAuto:NO reattribution:NULL];
        AMADeepLinkProcessor *otherProcessor = [[AMADeepLinkProcessor alloc] init];
        [[[otherProcessor consumeURL:URL ofType:type isAuto:NO reattribution:NULL] should] equal:payload];
    });

    it(@"Should ignore invalid input without consuming a valid URL", ^{
        [AMADeepLinkPayloadFactory clearStubs];
        BOOL reattribution = YES;
        [[[processor consumeURL:nil ofType:type isAuto:NO reattribution:&reattribution] should] beNil];
        [[theValue(reattribution) should] beNo];
        [[[processor consumeURL:[NSURL URLWithString:@""] ofType:type isAuto:NO reattribution:NULL] should] beNil];
        [[[processor consumeURL:URL ofType:@"" isAuto:NO reattribution:NULL] should] beNil];
        NSDictionary *result = [processor consumeURL:URL ofType:type isAuto:NO reattribution:NULL];
        [[result should] equal:@{ @"link": URL.absoluteString, @"type": type, @"auto": @NO }];
    });

    context(@"Reattribution", ^{

        AMAStartupParametersConfiguration *__block startup = nil;

        beforeEach(^{
            AMAMetricaConfiguration *metricaConfiguration = [AMAMetricaConfiguration nullMock];
            startup = [AMAStartupParametersConfiguration nullMock];
            [AMAMetricaConfiguration stub:@selector(sharedInstance) andReturn:metricaConfiguration];
            [metricaConfiguration stub:@selector(startup) andReturn:startup];
        });
        afterEach(^{
            [AMAMetricaConfiguration clearStubs];
        });

        context(@"Null conditions", ^{
            beforeEach(^{
                [startup stub:@selector(attributionDeeplinkConditions) andReturn:nil];
            });
            it(@"Should be YES for reattribution=1", ^{
                BOOL reattribution = NO;
                NSDictionary *result = [processor consumeURL:[NSURL URLWithString:@"appmetrica://?referrer=reattribution%3D1"] ofType:type isAuto:NO reattribution:&reattribution];
                [[result should] equal:payload];
                [[theValue(reattribution) should] equal:theValue(YES)];
            });
            it(@"Should be NO for reattribution=2", ^{
                BOOL reattribution = YES;
                NSDictionary *result = [processor consumeURL:[NSURL URLWithString:@"appmetrica://?referrer=reattribution%3D2"] ofType:type isAuto:NO reattribution:&reattribution];
                [[result should] equal:payload];
                [[theValue(reattribution) should] equal:theValue(NO)];
            });
            it(@"Should be NO for reattribution=1 inside another parameter", ^{
                BOOL reattribution = YES;
                NSDictionary *result = [processor consumeURL:[NSURL URLWithString:@"appmetrica://?notreferrer=reattribution%3D1&referrer=something"] ofType:type isAuto:NO reattribution:&reattribution];
                [[result should] equal:payload];
                [[theValue(reattribution) should] equal:theValue(NO)];
            });
            it(@"Should be NO for reattribution=1 inside referrer inside another parameter", ^{
                BOOL reattribution = YES;
                NSDictionary *result = [processor consumeURL:[NSURL URLWithString:@"appmetrica-search-app-open://?uri=https%3A%2F%2Fcollections.appmetrica.com%2F"
                                                           "interery%2F#referrer%3Dreattribution=1"] ofType:type isAuto:NO reattribution:&reattribution];
                [[result should] equal:payload];
                [[theValue(reattribution) should] equal:theValue(NO)];
            });
            it(@"Should be NO for reattribution=1 as root parameter", ^{
                BOOL reattribution = YES;
                NSDictionary *result = [processor consumeURL:[NSURL URLWithString:@"appmetrica://?reattribution=1&referrer=something"] ofType:type isAuto:NO reattribution:&reattribution];
                [[result should] equal:payload];
                [[theValue(reattribution) should] equal:theValue(NO)];
            });
            it(@"Should be NO for reattribution=1 as encoded root parameter", ^{
                BOOL reattribution = YES;
                NSDictionary *result = [processor consumeURL:[NSURL URLWithString:@"appmetrica://?reattribution%3D1&referrer=something"] ofType:type isAuto:NO reattribution:&reattribution];
                [[result should] equal:payload];
                [[theValue(reattribution) should] equal:theValue(NO)];
            });
        });
        context(@"Empty conditions", ^{
            beforeEach(^{
                [startup stub:@selector(attributionDeeplinkConditions) andReturn:@[]];
            });
            it(@"Should be YES for reattribution=1", ^{
                BOOL reattribution = NO;
                NSDictionary *result = [processor consumeURL:[NSURL URLWithString:@"appmetrica://?referrer=reattribution%3D1"] ofType:type isAuto:NO reattribution:&reattribution];
                [[result should] equal:payload];
                [[theValue(reattribution) should] equal:theValue(YES)];
            });
            it(@"Should be NO for reattribution=2", ^{
                BOOL reattribution = YES;
                NSDictionary *result = [processor consumeURL:[NSURL URLWithString:@"appmetrica://?referrer=reattribution%3D2"] ofType:type isAuto:NO reattribution:&reattribution];
                [[result should] equal:payload];
                [[theValue(reattribution) should] equal:theValue(NO)];
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
                BOOL reattribution = NO;
                NSDictionary *result = [processor consumeURL:url ofType:type isAuto:NO reattribution:&reattribution];
                [[result should] equal:payload];
                [[theValue(reattribution) should] equal:theValue(YES)];
            });
            it(@"Should be NO for deeplink without referrer", ^{
                NSURL *url = [NSURL URLWithString:@"appmetrica-search-app-open://?uri=https%3A%2F%2Fcollections.appmetrica.com%2F"
                                                  "interery%2F#reattribution=1"];
                BOOL reattribution = YES;
                NSDictionary *result = [processor consumeURL:url ofType:type isAuto:NO reattribution:&reattribution];
                [[result should] equal:payload];
                [[theValue(reattribution) should] equal:theValue(NO)];
            });
            it(@"Should be NO for deeplink with yclid=414 outside referrer", ^{
                NSURL *url = [NSURL URLWithString:@"appmetrica-search-app-open://?uri=https%3A%2F%2Fcollections.appmetrica.com%2F"
                                                  "interery%2F&yclid=414&referrer=appmetrica_tracking_id%3D97066511625096571%26"
                                                  "ym_tracking_id%3D8842404282613596432%26"];
                BOOL reattribution = YES;
                NSDictionary *result = [processor consumeURL:url ofType:type isAuto:NO reattribution:&reattribution];
                [[result should] equal:payload];
                [[theValue(reattribution) should] equal:theValue(NO)];
            });
            it(@"Should be NO for deeplink with yclid=414 inside referrer inside another parameter", ^{
                NSURL *url = [NSURL URLWithString:@"appmetrica-search-app-open://?uri=https%3A%2F%2Fcollections.appmetrica.com%2F"
                                                  "interery%2F#referrer=yclid=414"];
                BOOL reattribution = YES;
                NSDictionary *result = [processor consumeURL:url ofType:type isAuto:NO reattribution:&reattribution];
                [[result should] equal:payload];
                [[theValue(reattribution) should] equal:theValue(NO)];
            });
            it(@"Should be YES for deeplink with yclid=415", ^{
                NSURL *url = [NSURL URLWithString:@"appmetrica-search-app-open://?uri=https%3A%2F%2Fcollections.appmetrica.com%2F"
                                                  "interery%2F&referrer=appmetrica_tracking_id%3D97066511625096571%26"
                                                  "ym_tracking_id%3D8842404282613596432%26yclid%3D415"];
                BOOL reattribution = NO;
                NSDictionary *result = [processor consumeURL:url ofType:type isAuto:NO reattribution:&reattribution];
                [[result should] equal:payload];
                [[theValue(reattribution) should] equal:theValue(YES)];
            });
            it(@"Should be NO for deeplink with yclid=416", ^{
                NSURL *url = [NSURL URLWithString:@"ya-search-app-open://?uri=https%3A%2F%2Fcollections.appmetrica.com%2F"
                                                  "interery%2F&referrer=appmetrica_tracking_id%3D97066511625096571%26"
                                                  "ym_tracking_id%3D8842404282613596432%26yclid%3D416"];
                BOOL reattribution = YES;
                NSDictionary *result = [processor consumeURL:url ofType:type isAuto:NO reattribution:&reattribution];
                [[result should] equal:payload];
                [[theValue(reattribution) should] equal:theValue(NO)];
            });
            it(@"Should be NO for deeplink with empty yclid", ^{
                NSURL *url = [NSURL URLWithString:@"appmetrica-search-app-open://?uri=https%3A%2F%2Fcollections.appmetrica.com%2F"
                                                  "interery%2F&referrer=appmetrica_tracking_id%3D97066511625096571%26"
                                                  "ym_tracking_id%3D8842404282613596432%26yclid%3D"];
                BOOL reattribution = YES;
                NSDictionary *result = [processor consumeURL:url ofType:type isAuto:NO reattribution:&reattribution];
                [[result should] equal:payload];
                [[theValue(reattribution) should] equal:theValue(NO)];
            });
            it(@"Should be NO for deeplink with yid=1", ^{
                NSURL *url = [NSURL URLWithString:@"appmetrica-search-app-open://?uri=https%3A%2F%2Fcollections.appmetrica.com%2F"
                                                  "interery%2F&referrer=appmetrica_tracking_id%3D97066511625096571%26"
                                                  "ym_tracking_id%3D8842404282613596432%26yid%3D1"];
                BOOL reattribution = YES;
                NSDictionary *result = [processor consumeURL:url ofType:type isAuto:NO reattribution:&reattribution];
                [[result should] equal:payload];
                [[theValue(reattribution) should] equal:theValue(NO)];
            });
            it(@"Should be YES for deeplink with empty yid", ^{
                NSURL *url = [NSURL URLWithString:@"appmetrica-search-app-open://?uri=https%3A%2F%2Fcollections.appmetrica.cpm%2F"
                                                  "interery%2F&referrer=appmetrica_tracking_id%3D97066511625096571%26"
                                                  "ym_tracking_id%3D8842404282613596432%26yid%3D"];
                BOOL reattribution = NO;
                NSDictionary *result = [processor consumeURL:url ofType:type isAuto:NO reattribution:&reattribution];
                [[result should] equal:payload];
                [[theValue(reattribution) should] equal:theValue(YES)];
            });
            it(@"Should be YES for deeplink with yuid=414", ^{
                NSURL *url = [NSURL URLWithString:@"appmetrica-search-app-open://?uri=https%3A%2F%2Fcollections.appmetrica.com%2F"
                                                  "interery%2F&referrer=appmetrica_tracking_id%3D97066511625096571%26"
                                                  "ym_tracking_id%3D8842404282613596432%26yuid%3D414"];
                BOOL reattribution = NO;
                NSDictionary *result = [processor consumeURL:url ofType:type isAuto:NO reattribution:&reattribution];
                [[result should] equal:payload];
                [[theValue(reattribution) should] equal:theValue(YES)];
            });
            it(@"Should be YES for deeplink with empty yuid", ^{
                NSURL *url = [NSURL URLWithString:@"appmetrica-search-app-open://?uri=https%3A%2F%2Fcollections.appmetrica.com%2F"
                                                  "interery%2F&referrer=appmetrica_tracking_id%3D97066511625096571%26"
                                                  "ym_tracking_id%3D8842404282613596432%26yuid%3D"];
                BOOL reattribution = NO;
                NSDictionary *result = [processor consumeURL:url ofType:type isAuto:NO reattribution:&reattribution];
                [[result should] equal:payload];
                [[theValue(reattribution) should] equal:theValue(YES)];
            });
            it(@"Should be YES for deeplink with null yuid", ^{
                NSURL *url = [NSURL URLWithString:@"appmetrica-search-app-open://?uri=https%3A%2F%2Fcollections.appmetrica.com%2F"
                                                  "interery%2F&referrer=appmetrica_tracking_id%3D97066511625096571%26"
                                                  "ym_tracking_id%3D8842404282613596432%26yuid"];
                BOOL reattribution = NO;
                NSDictionary *result = [processor consumeURL:url ofType:type isAuto:NO reattribution:&reattribution];
                [[result should] equal:payload];
                [[theValue(reattribution) should] equal:theValue(YES)];
            });
            it(@"Should be YES for deeplink with ydeviceid=666777", ^{
                NSURL *url = [NSURL URLWithString:@"appmetrica-search-app-open://?uri=https%3A%2F%2Fcollections.appmetrica.com%2F"
                                                  "interery%2F&referrer=appmetrica_tracking_id%3D97066511625096571%26"
                                                  "ym_tracking_id%3D8842404282613596432%26ydeviceid%3D666777"];
                BOOL reattribution = NO;
                NSDictionary *result = [processor consumeURL:url ofType:type isAuto:NO reattribution:&reattribution];
                [[result should] equal:payload];
                [[theValue(reattribution) should] equal:theValue(YES)];
            });
            it(@"Should be YES for deeplink with =12", ^{
                NSURL *url = [NSURL URLWithString:@"appmetrica-search-app-open://?uri=https%3A%2F%2Fcollections.appmetrica.com%2F"
                                                  "interery%2F&referrer=appmetrica_tracking_id%3D97066511625096571%26"
                                                  "ym_tracking_id%3D8842404282613596432%26%3D12"];
                BOOL reattribution = NO;
                NSDictionary *result = [processor consumeURL:url ofType:type isAuto:NO reattribution:&reattribution];
                [[result should] equal:payload];
                [[theValue(reattribution) should] equal:theValue(YES)];
            });
            it(@"Should be NO for deeplink with =13", ^{
                NSURL *url = [NSURL URLWithString:@"appmetrica-search-app-open://?uri=https%3A%2F%2Fcollections.appmetrica.com%2F"
                                                  "interery%2F&referrer=appmetrica_tracking_id%3D97066511625096571%26"
                                                  "ym_tracking_id%3D8842404282613596432%26%3D13"];
                BOOL reattribution = YES;
                NSDictionary *result = [processor consumeURL:url ofType:type isAuto:NO reattribution:&reattribution];
                [[result should] equal:payload];
                [[theValue(reattribution) should] equal:theValue(NO)];
            });
            it(@"Should be YES for deeplink with reattribution=1 and yclid=414", ^{
                NSURL *url = [NSURL URLWithString:@"appmetrica-search-app-open://?uri=https%3A%2F%2Fcollections.appmetrica.com%2F"
                                                  "interery%2F&referrer=appmetrica_tracking_id%3D97066511625096571%26"
                                                  "ym_tracking_id%3D8842404282613596432%26reattribution%3D1%26yclid%3D414"];
                BOOL reattribution = NO;
                NSDictionary *result = [processor consumeURL:url ofType:type isAuto:NO reattribution:&reattribution];
                [[result should] equal:payload];
                [[theValue(reattribution) should] equal:theValue(YES)];
            });
            it(@"Should be YES for deeplink with reattribution=1", ^{
                NSURL *url = [NSURL URLWithString:@"appmetrica-search-app-open://?uri=https%3A%2F%2Fcollections.appmetrica.com%2F"
                                                  "interery%2F&referrer=appmetrica_tracking_id%3D97066511625096571%26"
                                                  "ym_tracking_id%3D8842404282613596432%26reattribution%3D1"];
                BOOL reattribution = NO;
                NSDictionary *result = [processor consumeURL:url ofType:type isAuto:NO reattribution:&reattribution];
                [[result should] equal:payload];
                [[theValue(reattribution) should] equal:theValue(YES)];
            });
            it(@"Should be YES for deeplink with reattribution=1 not encoded", ^{
                NSURL *url = [NSURL URLWithString:@"appmetrica-search-app-open://?uri=https%3A%2F%2Fcollections.appmetrica.com%2F"
                                                  "interery%2F&referrer=appmetrica_tracking_id%3D97066511625096571%26"
                                                  "ym_tracking_id%3D8842404282613596432%26reattribution=1"];
                BOOL reattribution = NO;
                NSDictionary *result = [processor consumeURL:url ofType:type isAuto:NO reattribution:&reattribution];
                [[result should] equal:payload];
                [[theValue(reattribution) should] equal:theValue(YES)];
            });

        });
    });
});

SPEC_END
