
#import <Kiwi/Kiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMASearchAdsController.h"
#import "AMASearchAdsRequester.h"
#import "AMASearchAdsReporter.h"
#import "AMAReporterStateStorage.h"

@interface AMASearchAdsController (Test) <AMASearchAdsRequesterDelegate>

@end

SPEC_BEGIN(AMASearchAdsControllerTests)

describe(@"AMASearchAdsController", ^{

    id<AMAAsyncExecuting> __block executor = nil;
    AMASearchAdsRequester *__block requester = nil;
    AMASearchAdsReporter *__block reporter = nil;
    AMAReporterStateStorage *__block stateStorage = nil;
    AMASearchAdsController *__block controller = nil;

    beforeEach(^{
        executor = [[AMACurrentQueueExecutor alloc] init];
        reporter = [AMASearchAdsReporter nullMock];

        requester = [AMASearchAdsRequester nullMock];
        [AMASearchAdsRequester stub:@selector(isAPIAvailable) andReturn:theValue(YES)];

        stateStorage = [AMAReporterStateStorage nullMock];
        [stateStorage stub:@selector(referrerEventSent) andReturn:theValue(NO)];
        [stateStorage stub:@selector(emptyReferrerEventSent) andReturn:theValue(NO)];

        controller = [[AMASearchAdsController alloc] initWithExecutor:executor
                                                 reporterStateStorage:stateStorage
                                                            requester:requester
                                                             reporter:reporter];
    });

    it(@"Should construct nil controller for nil reporter", ^{
        AMASearchAdsController *nilController = [[AMASearchAdsController alloc] initWithExecutor:executor
                                                                            reporterStateStorage:stateStorage
                                                                                       requester:requester
                                                                                        reporter:nil];
        [[nilController should] beNil];
    });

    context(@"Trigger", ^{

        it(@"Should report attempt", ^{
            [[reporter should] receive:@selector(reportAttributionAttempt)];
            [controller trigger];
        });

        it(@"Should request", ^{
            [[requester should] receive:@selector(request)];
            [controller trigger];
        });

        context(@"In Progress", ^{

            beforeEach(^{
                [controller trigger];
            });

            it(@"Should not report attempt", ^{
                [[reporter shouldNot] receive:@selector(reportAttributionAttempt)];
                [controller trigger];
            });

            it(@"Should not request", ^{
                [[requester shouldNot] receive:@selector(request)];
                [controller trigger];
            });

        });

        context(@"API Unavailable", ^{

            beforeEach(^{
                [AMASearchAdsRequester stub:@selector(isAPIAvailable) andReturn:theValue(NO)];
            });

            it(@"Should not report try", ^{
                [[reporter shouldNot] receive:@selector(reportAttributionAttempt)];
                [controller trigger];
            });

            it(@"Should not request", ^{
                [[requester shouldNot] receive:@selector(request)];
                [controller trigger];
            });

        });

        context(@"Referrer has been sent", ^{

            beforeEach(^{
                [stateStorage stub:@selector(referrerEventSent) andReturn:theValue(YES)];
            });

            it(@"Should not report attempt", ^{
                [[reporter shouldNot] receive:@selector(reportAttributionAttempt)];
                [controller trigger];
            });

            it(@"Should not request", ^{
                [[requester shouldNot] receive:@selector(request)];
                [controller trigger];
            });

        });

        context(@"Empty referrer has been received", ^{

            beforeEach(^{
                [stateStorage stub:@selector(emptyReferrerEventSent) andReturn:theValue(YES)];
            });

            it(@"Should not report attempt", ^{
                [[reporter shouldNot] receive:@selector(reportAttributionAttempt)];
                [controller trigger];
            });

            it(@"Should not request", ^{
                [[requester shouldNot] receive:@selector(request)];
                [controller trigger];
            });

        });

    });

    context(@"Attribution Success", ^{

        NSDictionary *attributionInfo = @{ @"foo": @"bar" };

        it(@"Should report attribution", ^{
            [[reporter should] receive:@selector(reportAttributionSuccessWithInfo:) withArguments:attributionInfo];
            [controller searchAdsRequester:requester didSucceededWithInfo:attributionInfo];
        });

        it(@"Should not mark refferer event as sent", ^{
            [[stateStorage shouldNot] receive:@selector(markReferrerEventSent)];
            [controller searchAdsRequester:requester didSucceededWithInfo:attributionInfo];
        });

        it(@"Should allow next request", ^{
            [controller searchAdsRequester:requester didSucceededWithInfo:attributionInfo];
            [[requester should] receive:@selector(request)];
            [controller trigger];
        });

        it(@"Should report next request attempt", ^{
            [controller searchAdsRequester:requester didSucceededWithInfo:attributionInfo];
            [[reporter should] receive:@selector(reportAttributionAttempt)];
            [controller trigger];
        });

    });

    context(@"Attribution Failure", ^{

        NSString *const description = @"DESCRIPTION";
        NSError *__block error = nil;

        context(@"Unknown", ^{

            beforeEach(^{
                error = [NSError errorWithDomain:kAMASearchAdsRequesterErrorDomain
                                            code:AMASearchAdsRequesterErrorUnknown
                                        userInfo:@{ kAMASearchAdsRequesterErrorDescriptionKey : description }];
            });

            it(@"Should report error", ^{
                [[reporter should] receive:@selector(reportAttributionErrorWithCode:description:)
                             withArguments:theValue(AMASearchAdsRequesterErrorUnknown), description];
                [controller searchAdsRequester:requester didFailedWithError:error];
            });

            it(@"Should not mark refferer event as sent", ^{
                [[stateStorage shouldNot] receive:@selector(markReferrerEventSent)];
                [controller searchAdsRequester:requester didFailedWithError:error];
            });

            it(@"Should not mark empty refferer event as received", ^{
                [[stateStorage shouldNot] receive:@selector(markEmptyReferrerEventSent)];
                [controller searchAdsRequester:requester didFailedWithError:error];
            });

            it(@"Should allow next request", ^{
                [controller searchAdsRequester:requester didFailedWithError:error];
                [[requester should] receive:@selector(request)];
                [controller trigger];
            });

            it(@"Should report next request attempt", ^{
                [controller searchAdsRequester:requester didFailedWithError:error];
                [[reporter should] receive:@selector(reportAttributionAttempt)];
                [controller trigger];
            });

        });

        context(@"Try Later", ^{

            beforeEach(^{
                error = [NSError errorWithDomain:kAMASearchAdsRequesterErrorDomain
                                            code:AMASearchAdsRequesterErrorTryLater
                                        userInfo:@{ kAMASearchAdsRequesterErrorDescriptionKey : description }];
            });

            it(@"Should report error", ^{
                [[reporter should] receive:@selector(reportAttributionErrorWithCode:description:)
                             withArguments:theValue(AMASearchAdsRequesterErrorTryLater), description];
                [controller searchAdsRequester:requester didFailedWithError:error];
            });

            it(@"Should not mark refferer event as sent", ^{
                [[stateStorage shouldNot] receive:@selector(markReferrerEventSent)];
                [controller searchAdsRequester:requester didFailedWithError:error];
            });

            it(@"Should not mark empty refferer event as received", ^{
                [[stateStorage shouldNot] receive:@selector(markEmptyReferrerEventSent)];
                [controller searchAdsRequester:requester didFailedWithError:error];
            });

            it(@"Should allow next request", ^{
                [controller searchAdsRequester:requester didFailedWithError:error];
                [[requester should] receive:@selector(request)];
                [controller trigger];
            });

            it(@"Should report next request attempt", ^{
                [controller searchAdsRequester:requester didFailedWithError:error];
                [[reporter should] receive:@selector(reportAttributionAttempt)];
                [controller trigger];
            });

        });

        context(@"Limited Ad Tracking", ^{

            beforeEach(^{
                error = [NSError errorWithDomain:kAMASearchAdsRequesterErrorDomain
                                            code:AMASearchAdsRequesterErrorAdTrackingLimited
                                        userInfo:@{ kAMASearchAdsRequesterErrorDescriptionKey : description }];
            });

            it(@"Should report error", ^{
                [[reporter should] receive:@selector(reportAttributionErrorWithCode:description:)
                             withArguments:theValue(AMASearchAdsRequesterErrorAdTrackingLimited), description];
                [controller searchAdsRequester:requester didFailedWithError:error];
            });

            it(@"Should mark empty refferer event as received", ^{
                [[stateStorage should] receive:@selector(markEmptyReferrerEventSent)];
                [controller searchAdsRequester:requester didFailedWithError:error];
            });

        });

    });
    
    it(@"Should conform to AMASearchAdsRequesterDelegate", ^{
        [[controller should] conformToProtocol:@protocol(AMASearchAdsRequesterDelegate)];
    });
});

SPEC_END
