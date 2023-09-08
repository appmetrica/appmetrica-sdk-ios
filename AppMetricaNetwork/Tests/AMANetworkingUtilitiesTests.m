
#import <Kiwi/Kiwi.h>
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>
#import <AppMetricaPlatform/AppMetricaPlatform.h>
#import <AppMetricaNetwork/AppMetricaNetwork.h>

SPEC_BEGIN(AMANetworkingUtilitiesTests)

describe(@"AMANetworkingUtilities", ^{

    context(@"User Agent", ^{
        it(@"Should append headers", ^{
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            [AMANetworkingUtilities addUserAgentHeadersToDictionary:dict];

            [[dict[@"User-Agent"] should] equal:[AMAPlatformDescription SDKUserAgent]];
        });
    });

    context(@"Send time headers", ^{
        it(@"Should append headers", ^{
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            NSString *date = @"19.06.1865";
            [AMATimeUtilities stub:@selector(timestampForDate:) andReturn:date];
            
            [AMANetworkingUtilities addSendTimeHeadersToDictionary:dict date:[NSDate date]];

            NSString *timestamp = [AMATimeUtilities timestampForDate:nil];
            NSTimeZone *zone = [NSTimeZone systemTimeZone];
            NSString *differenceString = [NSString stringWithFormat:@"%d", (int)[zone secondsFromGMT]];

            [[theValue(dict[@"Send-Timestamp"]) should] equal:theValue(timestamp)];
            [[theValue(dict[@"Send-Timezone"]) should] equal:theValue(differenceString)];
        });
    });
});

SPEC_END
