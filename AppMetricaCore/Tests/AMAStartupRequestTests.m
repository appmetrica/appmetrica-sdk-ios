
#import <Kiwi/Kiwi.h>
#import "AMACore.h"
#import "AMAStartupRequest.h"
#import "AMAIdentifiersTestUtilities.h"
#import "AMAStartupClientIdentifierFactory.h"
#import "AMAStartupClientIdentifier.h"
#import "AMAStartupParameters.h"
#import <AppMetricaPlatform/AppMetricaPlatform.h>

SPEC_BEGIN(AMAStartupRequestTests)

describe(@"AMAStartupRequest", ^{
    NSString *const startupHost = @"https://appmetrica.io";
    context(@"Request", ^{
        
        void (^stubPlatformDescription)(void) = ^{
            [AMAPlatformDescription stub:@selector(appVersion) andReturn:@"1.1.1"];
        };
        AMAStartupRequest *__block request = nil;
        
        beforeEach(^{
            request = [[AMAStartupRequest alloc] init];
            request.host = startupHost;
        });
        
        it(@"Should request for json", ^{
            stubPlatformDescription();
            NSURLRequest *urlRequest = [request buildURLRequest];
            [[urlRequest.allHTTPHeaderFields[@"Accept"] should] containString:@"application/json"];
        });
        it(@"Should request for encrypted body", ^{
            stubPlatformDescription();
            NSURLRequest *urlRequest = [request buildURLRequest];
            [[urlRequest.allHTTPHeaderFields[@"Accept-Encoding"] should] containString:@"encrypted"];
        });
        it(@"Should contain startup parameters", ^{
            NSDictionary *exprectedParameters = @{ @"expected" : @"parameters" };
            [AMAStartupParameters stub:@selector(parameters) andReturn:exprectedParameters];
            [[[request GETParameters][@"expected"] should] equal:@"parameters"];
        });
        
        it(@"Should set correct User-Agent header", ^{
            NSString *userAgent = [AMAPlatformDescription SDKUserAgent];
            [AMAPlatformDescription stub:@selector(SDKUserAgent) andReturn:userAgent];
            NSURLRequest *urlRequest = [request buildURLRequest];
            NSDictionary *userAgentHeader = urlRequest.allHTTPHeaderFields;
            [[userAgentHeader[@"User-Agent"] should] equal:userAgent];
        });
        
        
        it(@"Should append additional parameters if neeeded", ^{
            NSDictionary *extendedParatemers = @{@"ab": @1,
                                                 @"eg": @18,
                                                 @"sp": @0,
                                                 @"features": @"ab,eg,sp"};
            
            [request setAdditionalStartupParameters:extendedParatemers];
            
            NSMutableString *expectedFeatures = [AMAStartupParameters parameters][@"features"];
            [expectedFeatures appendString:@",ab,eg,sp"];
            
            NSDictionary *getParameters = [request GETParameters];
            
            [[getParameters[@"features"] should] equal:expectedFeatures];
            
            [[getParameters[@"ab"] should] equal:theValue(1)];
            [[getParameters[@"eg"] should] equal:theValue(18)];
            [[getParameters[@"sp"] should] equal:theValue(0)];
        });
    });
});

SPEC_END
