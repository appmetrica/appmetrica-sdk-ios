
#import <Kiwi/Kiwi.h>
#import <AppMetricaNetwork/AppMetricaNetwork.h>

SPEC_BEGIN(AMAGenericRequestTests)

describe(@"AMAGenericRequest", ^{

    AMAGenericRequest *__block request = nil;
    NSString *const url = @"http://appmetrica.io";

    beforeEach(^{
        request = [[AMAGenericRequest alloc] init];
        request.host = url;
    });

    context(@"Properties", ^{
        it(@"HTTPMethod", ^{
            [[[request method] should] equal:@"POST"];
        });

        it(@"Timeout", ^{
            [[theValue([request timeout]) should] equal:theValue(60)];
        });

        it(@"Cache policy", ^{
            [[theValue([request cachePolicy]) should] equal:theValue(NSURLRequestReloadIgnoringCacheData)];
        });

        it(@"HTTPBody", ^{
            [[[request body] should] beNil];
        });

        it(@"Path components", ^{
            [[[request pathComponents] should] equal:@[]];
        });

        it(@"Get params", ^{
            [[[request GETParameters] should] equal:@{}];
        });
    });

    context(@"Build request", ^{
        NSURLRequest *__block urlRequest = nil;

        beforeEach(^{
            urlRequest = [request buildURLRequest];
        });

        it(@"HTTPMethod", ^{
            [[urlRequest.HTTPMethod should] equal:@"POST"];
        });

        it(@"Timeout", ^{
            [[theValue(urlRequest.timeoutInterval) should] equal:theValue(60)];
        });

        it(@"Cache policy", ^{
            [[theValue(urlRequest.cachePolicy) should] equal:theValue(NSURLRequestReloadIgnoringCacheData)];
        });
    });
});

SPEC_END
