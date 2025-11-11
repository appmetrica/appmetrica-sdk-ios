
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaNetwork/AppMetricaNetwork.h>

SPEC_BEGIN(AMAHTTPSessionProviderTests)

describe(@"AMAHTTPSessionProvider", ^{
    AMAHTTPSessionProvider *__block provider = nil;

    beforeEach(^{
        provider = [[AMAHTTPSessionProvider alloc] init];
    });

    it(@"Should return same session", ^{
        NSURLSession *first = provider.session;
        NSURLSession *second = provider.session;
        [[first should] equal:second];
    });
    it(@"Should ignore local cache data", ^{
        NSURLSessionConfiguration *configuration = provider.session.configuration;
        [[theValue(configuration.requestCachePolicy) should] equal:theValue(NSURLRequestReloadIgnoringLocalCacheData)];
    });
    it(@"Should not use URLCache", ^{
        NSURLSessionConfiguration *configuration = provider.session.configuration;
        [[configuration.URLCache should] beNil];
    });
    it(@"Should use correct timout", ^{
        NSURLSessionConfiguration *configuration = provider.session.configuration;
        [[theValue(configuration.timeoutIntervalForRequest) should] equal:60.0 withDelta:0.001];
    });
    context(@"Invalidation", ^{
        it(@"Should create new session after invalidation of the first one", ^{
            NSURLSession *first = provider.session;
            [provider performSelector:@selector(URLSession:didBecomeInvalidWithError:) withObject:first withObject:nil];
            NSURLSession *second = provider.session;
            [[second shouldNot] equal:first];
        });
        it(@"Should not create new session after invalidation of unknown session", ^{
            NSURLSession *first = provider.session;
            NSURLSession *other =
            [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
            [provider performSelector:@selector(URLSession:didBecomeInvalidWithError:) withObject:other withObject:nil];
            NSURLSession *second = provider.session;
            [[second should] equal:first];
        });
    });
});

SPEC_END

