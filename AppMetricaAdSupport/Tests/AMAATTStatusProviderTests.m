
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppTrackingTransparency/AppTrackingTransparency.h>
#import <AdSupport/AdSupport.h>
#import "AMAATTStatusProvider.h"

SPEC_BEGIN(AMAATTStatusProviderTests)

describe(@"AMAATTStatusProvider", ^{
    
    let(attStatusProvider, ^id{
        return [[AMAATTStatusProvider alloc] init];
    });
    
    afterEach(^{
        if (@available(tvOS 14, *)) {
            [ATTrackingManager clearStubs];
        }
        [ASIdentifierManager clearStubs];
        [[ASIdentifierManager sharedManager] clearStubs];
    });

    if (@available(iOS 14.0, tvOS 14.0, *)) {
        it(@"Should return ATTStatus", ^{
            NSUInteger statusValue = arc4random_uniform(4);

            [ATTrackingManager stub:@selector(trackingAuthorizationStatus) andReturn:theValue(statusValue)];

            [[theValue([attStatusProvider ATTStatus]) should]
             equal:theValue((AMATrackingManagerAuthorizationStatus)statusValue)];
        });
    }

    it(@"Should return tracking enabled if status is AuthorizationStatusAuthorized", ^{
        if (@available(iOS 14, tvOS 14, *)) {
            [ATTrackingManager stub:@selector(trackingAuthorizationStatus)
                          andReturn:theValue(AMATrackingManagerAuthorizationStatusAuthorized)];

            [[theValue([attStatusProvider isAdvertisingTrackingEnabled]) should] beYes];
        }
        else {
            [[ASIdentifierManager sharedManager] stub:@selector(isAdvertisingTrackingEnabled) andReturn:theValue(YES)];

            [[theValue([attStatusProvider isAdvertisingTrackingEnabled]) should] beYes];
        }
    });
    it(@"Should return tracking disabled if status is not AuthorizationStatusAuthorized", ^{
        if (@available(iOS 14, tvOS 14, *)) {
            NSUInteger notAuthorizedValue = arc4random_uniform(3);
            [ATTrackingManager stub:@selector(trackingAuthorizationStatus)
                          andReturn:theValue((AMATrackingManagerAuthorizationStatus)notAuthorizedValue)];

            [[theValue([attStatusProvider isAdvertisingTrackingEnabled]) should] beNo];
        }
        else {
            [[ASIdentifierManager sharedManager] stub:@selector(isAdvertisingTrackingEnabled) andReturn:theValue(NO)];

            [[theValue([attStatusProvider isAdvertisingTrackingEnabled]) should] beNo];
        }
    });
});

SPEC_END
