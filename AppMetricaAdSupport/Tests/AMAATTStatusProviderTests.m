
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppTrackingTransparency/AppTrackingTransparency.h>
#import "AMAATTStatusProvider.h"

SPEC_BEGIN(AMAATTStatusProviderTests)

describe(@"AMAATTStatusProvider", ^{
    
    let(attStatusProvider, ^id{
        return [[AMAATTStatusProvider alloc] init];
    });
    
    afterEach(^{
        [ATTrackingManager clearStubs];
    });

    it(@"Should return ATTStatus", ^{
        NSUInteger statusValue = arc4random_uniform(4);

        [ATTrackingManager stub:@selector(trackingAuthorizationStatus) andReturn:theValue(statusValue)];

        [[theValue([attStatusProvider ATTStatus]) should]
         equal:theValue((AMATrackingManagerAuthorizationStatus)statusValue)];
    });

    it(@"Should return tracking enabled if status is AuthorizationStatusAuthorized", ^{
        [ATTrackingManager stub:@selector(trackingAuthorizationStatus)
                      andReturn:theValue(AMATrackingManagerAuthorizationStatusAuthorized)];

        [[theValue([attStatusProvider isAdvertisingTrackingEnabled]) should] beYes];
    });
    for (NSNumber *status in @[ @(AMATrackingManagerAuthorizationStatusNotDetermined),
                                @(AMATrackingManagerAuthorizationStatusRestricted),
                                @(AMATrackingManagerAuthorizationStatusDenied) ]) {
        it([NSString stringWithFormat:@"Should return tracking disabled for ATT status %@", status], ^{
            [ATTrackingManager stub:@selector(trackingAuthorizationStatus) andReturn:status];

            [[theValue([attStatusProvider isAdvertisingTrackingEnabled]) should] beNo];
        });
    }

});

SPEC_END
