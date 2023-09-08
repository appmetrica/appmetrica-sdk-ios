
#import <Kiwi/Kiwi.h>
#import "AMASearchAdsRequester.h"
#import <iAd/ADClient.h>

SPEC_BEGIN(AMASearchAdsRequesterTests)

describe(@"AMASearchAdsRequester", ^{

    id<AMASearchAdsRequesterDelegate> __block delegate = nil;
    AMASearchAdsRequester *__block requester = nil;

    beforeEach(^{
        delegate = [KWMock nullMockForProtocol:@protocol(AMASearchAdsRequesterDelegate)];
        requester = [[AMASearchAdsRequester alloc] init];
        requester.delegate = delegate;
    });

    context(@"API unavailable", ^{

        beforeEach(^{
            [ADClient stub:@selector(sharedClient) andReturn:nil];
        });

        it(@"Should return NO for isAPIAvailable", ^{
            [[theValue([AMASearchAdsRequester isAPIAvailable]) should] beNo];
        });

    });

    context(@"API available", ^{

        ADClient *__block client = nil;

        beforeEach(^{
            client = [ADClient nullMock];
            [ADClient stub:@selector(sharedClient) andReturn:client];
        });

        it(@"Should return YES for isAPIAvailable", ^{
            [[theValue([AMASearchAdsRequester isAPIAvailable]) should] beYes];
        });

        it(@"Should request attribution info on request", ^{
            [[client should] receive:@selector(requestAttributionDetailsWithBlock:)];
            [requester request];
        });

        it(@"Should not notify delegate about success before callback", ^{
            [[(id)delegate shouldNot] receive:@selector(searchAdsRequester:didSucceededWithInfo:)];
            [requester request];
        });

        it(@"Should not notify delegate about failure before callback", ^{
            [[(id)delegate shouldNot] receive:@selector(searchAdsRequester:didFailedWithError:)];
            [requester request];
        });

        context(@"Callback", ^{

            NSString *const localizedDescription = @"LOCALIZED_DESCRIPTION";

            NSError *__block error = nil;
            NSDictionary *__block attributionDetails = nil;

            beforeEach(^{
                error = nil;
                attributionDetails = nil;
                [client stub:@selector(requestAttributionDetailsWithBlock:) withBlock:^id(NSArray *params) {
                    void (^block)(NSDictionary *attributionDetails, NSError *error) = params[0];
                    block(attributionDetails, error);
                    return nil;
                }];
            });

            context(@"Success", ^{

                beforeEach(^{
                    attributionDetails = @{ @"foo": @"bar" };
                });

                it(@"Should notify delegate about success", ^{
                    [[(id)delegate should] receive:@selector(searchAdsRequester:didSucceededWithInfo:)
                                     withArguments:requester, attributionDetails];
                    [requester request];
                });

                it(@"Should not notify delegate about failure", ^{
                    [[(id)delegate shouldNot] receive:@selector(searchAdsRequester:didFailedWithError:)];
                    [requester request];
                });

            });

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            if (@available(iOS 12, *)) {
                context(@"Unknown error", ^{
                    
                    beforeEach(^{
                        error = [NSError errorWithDomain:ADClientErrorDomain
                                                    code:ADClientErrorUnknown
                                                userInfo:@{ NSLocalizedDescriptionKey: localizedDescription }];
                    });
                    
                    it(@"Should not notify delegate about success", ^{
                        [[(id)delegate shouldNot] receive:@selector(searchAdsRequester:didSucceededWithInfo:)];
                        [requester request];
                    });
                    
                    it(@"Should notify delegate about failure with proper error", ^{
                        KWCaptureSpy *spy = [(id)delegate captureArgument:@selector(searchAdsRequester:didFailedWithError:)
                                                                  atIndex:1];
                        [requester request];
                        NSError *receivedError = spy.argument;
                        
                        [[receivedError.domain should] equal:kAMASearchAdsRequesterErrorDomain];
                        [[theValue(receivedError.code) should] equal:theValue(AMASearchAdsRequesterErrorTryLater)];
                        [[receivedError.userInfo[kAMASearchAdsRequesterErrorDescriptionKey] should] equal:localizedDescription];
                    });
                    
                });
                
                context(@"Limited Ad Tracking", ^{
                    
                    beforeEach(^{
                        error = [NSError errorWithDomain:ADClientErrorDomain
                                                    code:ADClientErrorLimitAdTracking
                                                userInfo:@{ NSLocalizedDescriptionKey: localizedDescription }];
                    });
                    
                    it(@"Should not notify delegate about success", ^{
                        [[(id)delegate shouldNot] receive:@selector(searchAdsRequester:didSucceededWithInfo:)];
                        [requester request];
                    });
                    
                    it(@"Should notify delegate about failure with proper error", ^{
                        KWCaptureSpy *spy = [(id)delegate captureArgument:@selector(searchAdsRequester:didFailedWithError:)
                                                                  atIndex:1];
                        [requester request];
                        NSError *receivedError = spy.argument;
                        
                        [[receivedError.domain should] equal:kAMASearchAdsRequesterErrorDomain];
                        [[theValue(receivedError.code) should] equal:theValue(AMASearchAdsRequesterErrorAdTrackingLimited)];
                        [[receivedError.userInfo[kAMASearchAdsRequesterErrorDescriptionKey] should] equal:localizedDescription];
                    });
                    
                });
                
#pragma clang diagnostic pop
                
                context(@"Unexpected error code", ^{
                    
                    beforeEach(^{
                        error = [NSError errorWithDomain:ADClientErrorDomain
                                                    code:-1
                                                userInfo:@{ NSLocalizedDescriptionKey: localizedDescription }];
                    });
                    
                    it(@"Should not notify delegate about success", ^{
                        [[(id)delegate shouldNot] receive:@selector(searchAdsRequester:didSucceededWithInfo:)];
                        [requester request];
                    });
                    
                    it(@"Should notify delegate about failure with proper error", ^{
                        KWCaptureSpy *spy = [(id)delegate captureArgument:@selector(searchAdsRequester:didFailedWithError:)
                                                                  atIndex:1];
                        [requester request];
                        NSError *receivedError = spy.argument;
                        
                        NSUInteger excpectedErrorCode =
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 140000
                        AMASearchAdsRequesterErrorTryLater;
#else
                        AMASearchAdsRequesterErrorUnknown;
#endif
                        
                        [[receivedError.domain should] equal:kAMASearchAdsRequesterErrorDomain];
                        [[theValue(receivedError.code) should] equal:theValue(excpectedErrorCode)];
                        [[receivedError.userInfo[kAMASearchAdsRequesterErrorDescriptionKey] should] equal:localizedDescription];
                    });
                    
                });
            }

        });

    });

});

SPEC_END
