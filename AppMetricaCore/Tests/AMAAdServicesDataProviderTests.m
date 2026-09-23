#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMAAdServicesDataProvider.h"

#if !TARGET_OS_TV && !TARGET_OS_SIMULATOR
#import <AdServices/AdServices.h>
#endif

SPEC_BEGIN(AMAAdServicesDataProviderTests)

describe(@"AMAAdServicesDataProvider", ^{
    let(provider, ^{ return [[AMAAdServicesDataProvider alloc] init]; });

#if TARGET_OS_TV || TARGET_OS_SIMULATOR
    it(@"Should report AdServices unavailable on tvOS and Simulator", ^{
        NSError *error = nil;
        [[[provider tokenWithError:&error] should] beNil];
        [[error shouldNot] beNil];
    });
    it(@"Should accept a null error pointer when AdServices is unavailable", ^{
        [[[provider tokenWithError:NULL] should] beNil];
    });
#else
    afterEach(^{
        [AAAttribution clearStubs];
    });
    it(@"Should return the attribution token", ^{
        [AAAttribution stub:@selector(attributionTokenWithError:) andReturn:@"token"];
        NSError *error = nil;
        [[[provider tokenWithError:&error] should] equal:@"token"];
        [[error should] beNil];
    });
    it(@"Should fill an error when AdServices returns neither a token nor an error", ^{
        [AAAttribution stub:@selector(attributionTokenWithError:) andReturn:nil];
        NSError *error = nil;
        [[[provider tokenWithError:&error] should] beNil];
        [[error shouldNot] beNil];
    });
#endif
});

SPEC_END
