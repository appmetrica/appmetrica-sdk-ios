
#import <Kiwi/Kiwi.h>
#import "AMAReachability+TestUtilities.h"

SPEC_BEGIN(AMAReachabilityTestsSpec)

describe(@"AMAReachabilityTests", ^{
	context(@"Provides correct network status", ^{
        it(@"Should return unknown status initially", ^{
            [AMAReachability amatest_stubSharedInstance];
            AMAReachability *reachability = [AMAReachability sharedInstance];
            [[theValue([reachability status]) should] equal:theValue(AMAReachabilityStatusUnknown)];
        });
        it(@"Should return any reachable status if kSCNetworkReachabilityFlagsReachable exists", ^{
            [AMAReachability amatest_stubSharedInstance];
            AMAReachability *reachability = [AMAReachability sharedInstance];
            [reachability stub:@selector(isStarted) andReturn:theValue(YES)];
            [reachability setFlags:kSCNetworkReachabilityFlagsReachable];
            [[theValue([reachability status]) shouldNot] equal:theValue(AMAReachabilityStatusNotReachable)];
        });
        it(@"Should return unreachable status if kSCNetworkReachabilityFlagsConnectionRequired exists", ^{
            [AMAReachability amatest_stubSharedInstance];
            AMAReachability *reachability = [AMAReachability sharedInstance];
            [reachability stub:@selector(isStarted) andReturn:theValue(YES)];
            [reachability setFlags:kSCNetworkReachabilityFlagsConnectionRequired];
            [[theValue([reachability status]) should] equal:theValue(AMAReachabilityStatusNotReachable)];
        });
        it(@"Should return unreachable status if kSCNetworkReachabilityFlagsTransientConnection exists", ^{
            [AMAReachability amatest_stubSharedInstance];
            AMAReachability *reachability = [AMAReachability sharedInstance];
            [reachability stub:@selector(isStarted) andReturn:theValue(YES)];
            [reachability setFlags:kSCNetworkReachabilityFlagsTransientConnection];
            [[theValue([reachability status]) should] equal:theValue(AMAReachabilityStatusNotReachable)];
        });
        it(@"Should return reachable via wi-fi status if kSCNetworkReachabilityFlagsIsWWAN does not exist", ^{
            [AMAReachability amatest_stubSharedInstance];
            AMAReachability *reachability = [AMAReachability sharedInstance];
            [reachability stub:@selector(isStarted) andReturn:theValue(YES)];
            [reachability setFlags:kSCNetworkReachabilityFlagsReachable];
            [[theValue([reachability status]) should] equal:theValue(AMAReachabilityStatusReachableViaWiFi)];
        });
        it(@"Should return reachable via wi-fi status if kSCNetworkReachabilityFlagsIsWWAN does not exist", ^{
            [AMAReachability amatest_stubSharedInstance];
            AMAReachability *reachability = [AMAReachability sharedInstance];
            [reachability stub:@selector(isStarted) andReturn:theValue(YES)];
            [reachability setFlags:kSCNetworkReachabilityFlagsReachable | kSCNetworkReachabilityFlagsIsWWAN];
            [[theValue([reachability status]) should] equal:theValue(AMAReachabilityStatusReachableViaWWAN)];
        });
        it(@"Should not be unknown if flags update occured", ^{
            [AMAReachability amatest_stubSharedInstance];
            AMAReachability *reachability = [AMAReachability sharedInstance];
            [reachability stub:@selector(isStarted) andReturn:theValue(YES)];
            [reachability setFlags:0];
            [[theValue([reachability status]) shouldNot] equal:theValue(AMAReachabilityStatusUnknown)];
        });
    });
    context(@"Starts and shuts down", ^{
        it(@"Should create reachability ref on start", ^{
            AMAReachability *reachability = [AMAReachability sharedInstance];
            [reachability start];
            [[(id)reachability.reachabilityRef shouldNot] beNil];
        });
        it(@"Should set reachability ref to nil on shutdown", ^{
            AMAReachability *reachability = [AMAReachability sharedInstance];
            [reachability start];
            [reachability shutdown];
            [[(id)reachability.reachabilityRef should] beNil];
        });
    });
    context(@"Notifications", ^{
        it(@"Should notify if status changed", ^{
            __block BOOL isNotificationsReceived = NO;
            [[NSNotificationCenter defaultCenter] addObserverForName:kAMAReachabilityStatusDidChange
                                                              object:nil
                                                               queue:[NSOperationQueue mainQueue]
                                                          usingBlock:^(NSNotification *note) {
                                                              isNotificationsReceived = YES;
                                                          }];
            AMAReachability *reachability = [AMAReachability sharedInstance];
            [reachability stub:@selector(isStarted) andReturn:theValue(YES)];
            reachability.flags = kSCNetworkReachabilityFlagsReachable | kSCNetworkReachabilityFlagsIsWWAN;

            [[theValue(isNotificationsReceived) should] equal:theValue(YES)];
        });
        it(@"Shouldn't notify for same status", ^{
            __block BOOL isNotificationsReceived = NO;

            AMAReachability *reachability = [AMAReachability sharedInstance];
            [reachability stub:@selector(isStarted) andReturn:theValue(YES)];
            reachability.flags = kSCNetworkReachabilityFlagsReachable | kSCNetworkReachabilityFlagsIsWWAN;

            [[NSNotificationCenter defaultCenter] addObserverForName:kAMAReachabilityStatusDidChange
                                                              object:nil
                                                               queue:[NSOperationQueue mainQueue]
                                                          usingBlock:^(NSNotification *note) {
                                                              isNotificationsReceived = YES;
                                                          }];

            reachability.flags = kSCNetworkReachabilityFlagsReachable | kSCNetworkReachabilityFlagsIsWWAN;

            [[theValue(isNotificationsReceived) should] equal:theValue(NO)];
        });
    });
});

SPEC_END
