
#import <AppMetricaKiwi/AppMetricaKiwi.h>

#import "AMADeepLinkPayloadFactory.h"
#import "AMAErrorsFactory.h"

SPEC_BEGIN(AMADeepLinkPayloadFactoryTests)

describe(@"AMADeepLinkPayloadFactory", ^{

    it(@"Should return nil for nil URL", ^{
        NSDictionary *payload = [AMADeepLinkPayloadFactory deepLinkPayloadForURL:nil ofType:@"type" isAuto:NO error:nil];
        [[payload should] beNil];
    });

    it(@"Should return nil for nil type", ^{
        NSString *urlString = @"some://thing";
        NSURL *url = [NSURL URLWithString:urlString];
        NSDictionary *payload = [AMADeepLinkPayloadFactory deepLinkPayloadForURL:url ofType:nil isAuto:NO error:nil];
        [[payload should] beNil];
    });

    it(@"Should return nil for nil URL and nil type", ^{
        NSDictionary *payload = [AMADeepLinkPayloadFactory deepLinkPayloadForURL:nil ofType:nil isAuto:NO error:nil];
        [[payload should] beNil];
    });

    it(@"Should return empty URL error for nil URL", ^{
        NSError *error = nil;
        NSString *type = @"type";
        [AMADeepLinkPayloadFactory deepLinkPayloadForURL:nil ofType:type isAuto:NO error:&error];
        [[error should] equal:[AMAErrorsFactory emptyDeepLinkUrlOfTypeError:type]];
    });

    it(@"Should return empty URL of unknown type error for nil URL nil type", ^{
        NSError *error = nil;
        [AMADeepLinkPayloadFactory deepLinkPayloadForURL:nil ofType:nil isAuto:NO error:&error];
        [[error should] equal:[AMAErrorsFactory emptyDeepLinkUrlOfUnknownTypeError]];
    });

    it(@"Should return URL of unknown type error for not nil URL and nil type", ^{
        NSError *error = nil;
        NSString *urlString = @"some://thing";
        NSURL *url = [NSURL URLWithString:urlString];
        [AMADeepLinkPayloadFactory deepLinkPayloadForURL:url ofType:nil isAuto:NO error:&error];
        [[error should] equal:[AMAErrorsFactory deepLinkUrlOfUnknownTypeError:urlString]];
    });

    it(@"Should return valid payload for valid URL", ^{
        NSString *URLString = @"some://thing";
        NSString *type = @"type";

        NSURL *URL = [NSURL URLWithString:URLString];
        NSDictionary *payload = [AMADeepLinkPayloadFactory deepLinkPayloadForURL:URL ofType:type isAuto:YES error:nil];
        [[payload should] equal:@{ @"link" : URLString, @"type" : type, @"auto" : @YES}];
    });

});

SPEC_END
