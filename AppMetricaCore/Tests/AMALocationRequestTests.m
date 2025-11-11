
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMALocationRequest.h"
#import "AMALocationRequestParameters.h"
#import <AppMetricaPlatform/AppMetricaPlatform.h>

SPEC_BEGIN(AMALocationRequestTests)

describe(@"AMALocationRequest", ^{

    NSNumber *const identifier = @23;
    NSArray *const locationIdentifiers = @[ @1, @2, @3 ];
    NSArray *const visitIdentifiers = @[ @4, @6, @8 ];
    NSData *const data = [@"DATA" dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *const requestParameters = @{ @"foo": @"bar" };

    AMALocationRequest *__block request = nil;

    beforeEach(^{
        [AMALocationRequestParameters stub:@selector(parametersWithRequestIdentifier:) andReturn:requestParameters];
        request = [[AMALocationRequest alloc] initWithRequestIdentifier:identifier
                                                    locationIdentifiers:locationIdentifiers
                                                       visitIdentifiers:visitIdentifiers
                                                                   data:data];
        request.host = @"https://appmetrica.io";
    });

    it(@"Should have valid request parameters", ^{
        [[[request GETParameters] should] equal:requestParameters];
    });

    it(@"Should have valid path", ^{
        [[[request pathComponents] should] equal:@[ @"location" ]];
    });

    context(@"URL request", ^{
        NSURLRequest *__block urlRequest = nil;
        beforeAll(^{
            urlRequest = [request buildURLRequest];
        });
        it(@"Should have valid method", ^{
            [[urlRequest.HTTPMethod should] equal:@"POST"];
        });
        it(@"Should have valid data", ^{
            [[urlRequest.HTTPBody should] equal:data];
        });

        it(@"Should set correct User-Agent header", ^{
            NSString *userAgent = [AMAPlatformDescription SDKUserAgent];
            [AMAPlatformDescription stub:@selector(SDKUserAgent) andReturn:userAgent];
            NSURLRequest *urlRequest = [request buildURLRequest];
            NSDictionary *userAgentHeader = urlRequest.allHTTPHeaderFields;
            [[userAgentHeader[@"User-Agent"] should] equal:userAgent];
        });
    });
    
    it(@"Should be subclass of AMAGenericRequest", ^{
        [[request should] beKindOfClass:AMAGenericRequest.class];
    });
});

SPEC_END

