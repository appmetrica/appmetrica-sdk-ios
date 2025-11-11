
#import <AppMetricaKiwi/AppMetricaKiwi.h>
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
        
        it(@"Should append additional parameters correctly", ^{
            NSDictionary *firstExtendedParatemers = @{@"ab": @"1",
                                                      @"eg": @"101",
                                                      @"wrng": @7,
                                                      @"features": @"ab,eg,sp,ab"};
            NSDictionary *secondExtendedParatemers = @{@"sp": @"0",
                                                       @"": @"empty",
                                                       @"empty": @"",
                                                       @"wrongDict": @{},
                                                       @"wrongArray": @[],
                                                       @19: @"qwe",
                                                       @"features": @[@"qq,ww,tt"]};
            
            [request addAdditionalStartupParameters:firstExtendedParatemers];
            [request addAdditionalStartupParameters:secondExtendedParatemers];
            
            NSArray *allFeatures = [[[AMAStartupParameters parameters][@"features"]
                                     stringByAppendingString:@",ab,eg,sp"]
                                     componentsSeparatedByString:@","];
            NSString *expectedUniqueFeatures = [[[NSSet setWithArray:allFeatures] allObjects] componentsJoinedByString:@","];
            
            NSDictionary *getParameters = [request GETParameters];
            
            [[getParameters[@"features"] should] equal:expectedUniqueFeatures];
            
            [[getParameters[@"ab"] should] equal:@"1"];
            [[getParameters[@"eg"] should] equal:@"101"];
            [[getParameters[@"sp"] should] equal:@"0"];
            
            NSArray *keys = [getParameters allKeys];
            [[keys shouldNot] contain:@"wrng"];
            [[keys shouldNot] contain:@"wrongDict"];
            [[keys shouldNot] contain:@"wrongArray"];
            [[keys shouldNot] contain:@19];
            [[keys shouldNot] contain:@""];
            [[keys shouldNot] contain:@"empty"];
        });
        it(@"Should be subclass of AMAGenericRequest", ^{
            [[request should] beKindOfClass:AMAGenericRequest.class];
        });
    });
});

SPEC_END
