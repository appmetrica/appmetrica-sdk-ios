
#import <Kiwi/Kiwi.h>
#import "AMASearchAdsReporter.h"
#import "AMAReporter.h"
#import "AMAInternalEventsReporter.h"
#import "AMAAppMetrica+Internal.h"
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>

SPEC_BEGIN(AMASearchAdsReporterTests)

describe(@"AMASearchAdsReporter", ^{

    NSString *const apiKey = @"APIKEY";

    AMAReporter *__block appReporter = nil;
    AMAInternalEventsReporter *__block internalReporter = nil;
    AMASearchAdsReporter *__block reporter = nil;

    beforeEach(^{
        appReporter = [AMAReporter nullMock];
        [AMAAppMetrica stub:@selector(reporterForAPIKey:) andReturn:appReporter withArguments:apiKey];

        internalReporter = [AMAInternalEventsReporter nullMock];
        [AMAAppMetrica stub:@selector(sharedInternalEventsReporter) andReturn:internalReporter];

        reporter = [[AMASearchAdsReporter alloc] initWithApiKey:apiKey];
    });

    it(@"Should construct nil reporter for empty apiKey", ^{
        AMASearchAdsReporter *nilReporter = [[AMASearchAdsReporter alloc] initWithApiKey:@""];
        [[nilReporter should] beNil];
    });

    context(@"Report Attempt", ^{

        it(@"Should internally report try", ^{
            [[internalReporter should] receive:@selector(reportSearchAdsAttempt)];
            [reporter reportAttributionAttempt];
        });

        it(@"Should not report referrer", ^{
            [[appReporter shouldNot] receive:@selector(reportReferrerEventWithValue:onFailure:)];
            [reporter reportAttributionAttempt];
        });

    });

    context(@"Report Success", ^{

        NSDictionary *__block attributionInfo = nil;

        context(@"Serializable data", ^{

            beforeEach(^{
                attributionInfo = @{ @"foo": @"bar" };
            });

            it(@"Should report referrer with valid data", ^{
                KWCaptureSpy *spy = [appReporter captureArgument:@selector(reportReferrerEventWithValue:onFailure:)
                                                         atIndex:0];
                [reporter reportAttributionSuccessWithInfo:attributionInfo];
                NSString *eventValue = spy.argument;
                NSDictionary *eventValueDictionary =
                [NSJSONSerialization JSONObjectWithData:[eventValue dataUsingEncoding:NSUTF8StringEncoding]
                                                options:0
                                                  error:NULL];
                [[eventValueDictionary should] equal:@{ @"status": @"success", @"data": attributionInfo }];
            });

        });

        context(@"Non-serializable data", ^{

            beforeEach(^{
                [AMATestUtilities stubAssertions];
                attributionInfo = @{ @{ @"foo": @"bar" }: @"foo" };
            });

            it(@"Should not report referrer", ^{
                [[appReporter shouldNot] receive:@selector(reportReferrerEventWithValue:onFailure:)];
                [reporter reportAttributionSuccessWithInfo:attributionInfo];
            });

            it(@"Should internally report error with valid name", ^{
                [[internalReporter should] receive:@selector(reportSearchAdsCompletionWithType:parameters:)
                                     withArguments:@"json-error", kw_any()];
                [reporter reportAttributionSuccessWithInfo:attributionInfo];
            });

            it(@"Should internally report error with valid parameters", ^{
                KWCaptureSpy *spy = [internalReporter captureArgument:@selector(reportSearchAdsCompletionWithType:parameters:)
                                                              atIndex:1];
                [reporter reportAttributionSuccessWithInfo:attributionInfo];
                NSDictionary *parameters = spy.argument;

                [[parameters[@"code"] should] equal:@(AMAAppMetricaInternalEventJsonSerializationError)];
                [[parameters[@"domain"] should] equal:kAMAAppMetricaErrorDomain];
                [[parameters[@"data"] should] containString:@"foo = bar"];
            });

        });

    });

    context(@"Report failure", ^{

        NSString *const description = @"DESCRIPTION";
        NSDictionary *const parameters = @{ @"description": description };

        context(@"Unknown error", ^{

            it(@"Should internally report error", ^{
                [[internalReporter should] receive:@selector(reportSearchAdsCompletionWithType:parameters:)
                                     withArguments:@"unknown", parameters];
                [reporter reportAttributionErrorWithCode:AMASearchAdsRequesterErrorUnknown description:description];
            });

            it(@"Should not report referrer", ^{
                [[appReporter shouldNot] receive:@selector(reportReferrerEventWithValue:onFailure:)];
                [reporter reportAttributionErrorWithCode:AMASearchAdsRequesterErrorUnknown description:description];
            });

        });

        context(@"Limited Ad Tracking", ^{

            it(@"Should internally report error", ^{
                [[internalReporter should] receive:@selector(reportSearchAdsCompletionWithType:parameters:)
                                     withArguments:@"lat", parameters];
                [reporter reportAttributionErrorWithCode:AMASearchAdsRequesterErrorAdTrackingLimited
                                             description:description];
            });

            it(@"Should report referrer with valid data", ^{
                KWCaptureSpy *spy = [appReporter captureArgument:@selector(reportReferrerEventWithValue:onFailure:)
                                                         atIndex:0];
                [reporter reportAttributionErrorWithCode:AMASearchAdsRequesterErrorAdTrackingLimited
                                             description:description];
                NSString *eventValue = spy.argument;
                NSDictionary *eventValueDictionary =
                    [NSJSONSerialization JSONObjectWithData:[eventValue dataUsingEncoding:NSUTF8StringEncoding]
                                                    options:0
                                                      error:NULL];
                [[eventValueDictionary should] equal:@{ @"status": @"failure", @"error": @"lat" }];
            });

        });

        context(@"Try Later", ^{

            it(@"Should internally report error", ^{
                [[internalReporter should] receive:@selector(reportSearchAdsCompletionWithType:parameters:)
                                     withArguments:@"try-later", parameters];
                [reporter reportAttributionErrorWithCode:AMASearchAdsRequesterErrorTryLater
                                             description:description];
            });

            it(@"Should not report referrer", ^{
                [[appReporter shouldNot] receive:@selector(reportReferrerEventWithValue:onFailure:)];
                [reporter reportAttributionErrorWithCode:AMASearchAdsRequesterErrorTryLater
                                             description:description];
            });

        });

    });

});

SPEC_END
