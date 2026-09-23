#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>
#import "AMASKAdNetworkRequestor.h"

#if !TARGET_OS_TV
#import <StoreKit/StoreKit.h>
#endif

SPEC_BEGIN(AMASKAdNetworkRequestorTests)

describe(@"AMASKAdNetworkRequestor", ^{
    let(requestor, ^{
        return [[AMASKAdNetworkRequestor alloc] initWithDateProvider:[[AMADateProvider alloc] init]];
    });

#if TARGET_OS_TV
    it(@"Should report conversion updates unsupported on tvOS", ^{
        [[theValue([requestor updateConversionValue:42]) should] beNo];
    });
#else
    afterEach(^{
        [SKAdNetwork clearStubs];
    });
    it(@"Should forward conversion updates to StoreKit on iOS", ^{
        [SKAdNetwork stub:@selector(updateConversionValue:)];
        [[SKAdNetwork should] receive:@selector(updateConversionValue:) withArguments:theValue(42)];
        [[theValue([requestor updateConversionValue:42]) should] beYes];
    });
#endif
});

SPEC_END
