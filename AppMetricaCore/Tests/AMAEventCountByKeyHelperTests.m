
#import <Kiwi/Kiwi.h>
#import "AMAMetricaConfiguration.h"
#import "AMAMetricaPersistentConfiguration.h"
#import "AMAEventCountByKeyHelper.h"

SPEC_BEGIN(AMAEventCountByKeyHelperTests)

describe(@"AMAEventCountByKeyHelper", ^{

    AMAMetricaPersistentConfiguration *__block persistentConfiguration = nil;
    AMAEventCountByKeyHelper *__block helper = nil;

    beforeEach(^{
        persistentConfiguration = [AMAMetricaPersistentConfiguration nullMock];
        AMAMetricaConfiguration *metricaConfiguration = [AMAMetricaConfiguration nullMock];
        [metricaConfiguration stub:@selector(persistent) andReturn:persistentConfiguration];
        [AMAMetricaConfiguration stub:@selector(sharedInstance) andReturn:metricaConfiguration];
        helper = [[AMAEventCountByKeyHelper alloc] init];
    });
    afterEach(^{
        [AMAMetricaConfiguration clearStubs];
    });

    context(@"Get count for key", ^{
        it(@"Should be 0 for nil map", ^{
            [persistentConfiguration stub:@selector(eventCountsByKey) andReturn:nil];
            [[theValue([helper getCountForKey:@"key"]) should] beZero];
        });
        it(@"Should be 0 if not key in map", ^{
            [persistentConfiguration stub:@selector(eventCountsByKey) andReturn:@{ @"key" : @2 }];
            [[theValue([helper getCountForKey:@"another key"]) should] beZero];
        });
        it(@"Should be 2 if has key in map", ^{
            [persistentConfiguration stub:@selector(eventCountsByKey) andReturn:@{
                @"key" : @2 ,
                @"key2" : @3
            }];
            [[theValue([helper getCountForKey:@"key"]) should] equal:theValue(2)];
        });
    });
    context(@"Set count for key", ^{
        it(@"Should set if map is nil", ^{
            [persistentConfiguration stub:@selector(eventCountsByKey) andReturn:nil];
            [[persistentConfiguration should] receive:@selector(setEventCountsByKey:) withArguments:@{ @"key" : @5 }];
            [helper setCount:5 forKey:@"key"];
        });
        it(@"Should set if map already has key", ^{
            [persistentConfiguration stub:@selector(eventCountsByKey) andReturn:@{ @"key" : @7 }];
            [[persistentConfiguration should] receive:@selector(setEventCountsByKey:) withArguments:@{ @"key" : @5 }];
            [helper setCount:5 forKey:@"key"];
        });
        it(@"Should set if map does not have key", ^{
            [persistentConfiguration stub:@selector(eventCountsByKey) andReturn:@{ @"key2" : @7 }];
            [[persistentConfiguration should] receive:@selector(setEventCountsByKey:) withArguments:@{
                @"key" : @5,
                @"key2" : @7
            }];
            [helper setCount:5 forKey:@"key"];
        });
    });
});

SPEC_END
