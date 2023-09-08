
#import <Kiwi/Kiwi.h>
#import "AMARevenueEventCondition.h"

SPEC_BEGIN(AMARevenueEventConditionTests)

describe(@"AMARevenueEventCondition", ^{

    context(@"Init with JSON", ^{
        it(@"Should be nil for nil JSON", ^{
            [[[[AMARevenueEventCondition alloc] initWithJSON:nil] should] beNil];
        });
        it(@"Type API", ^{
            NSDictionary *json = @{ @"source" : @0 };
            AMARevenueEventCondition *condition = [[AMARevenueEventCondition alloc] initWithJSON:json];
            [[theValue([condition checkEvent:NO]) should] beYes];
        });
        it(@"Type auto", ^{
            NSDictionary *json = @{ @"source" : @1 };
            AMARevenueEventCondition *condition = [[AMARevenueEventCondition alloc] initWithJSON:json];
            [[theValue([condition checkEvent:YES]) should] beYes];
        });
    });
    context(@"JSON", ^{
        it(@"Type API", ^{
            AMARevenueEventCondition *condition = [[AMARevenueEventCondition alloc] initWithSource:AMARevenueSourceAPI];
            NSDictionary *expectedJSON = @{ @"source" : @0 };
            [[[condition JSON] should] equal:expectedJSON];
        });
        it(@"Type auto", ^{
            AMARevenueEventCondition *condition = [[AMARevenueEventCondition alloc] initWithSource:AMARevenueSourceAuto];
            NSDictionary *expectedJSON = @{ @"source" : @1 };
            [[[condition JSON] should] equal:expectedJSON];
        });
    });
    context(@"Check event", ^{
        it(@"Should be NO for type API and auto", ^{
            AMARevenueEventCondition *condition = [[AMARevenueEventCondition alloc] initWithSource:AMARevenueSourceAPI];
            [[theValue([condition checkEvent:YES]) should] beNo];
        });
        it(@"Should be YES for type auto and auto", ^{
            AMARevenueEventCondition *condition = [[AMARevenueEventCondition alloc] initWithSource:AMARevenueSourceAuto];
            [[theValue([condition checkEvent:YES]) should] beYes];
        });
        it(@"Should be NO for type auto and manual", ^{
            AMARevenueEventCondition *condition = [[AMARevenueEventCondition alloc] initWithSource:AMARevenueSourceAuto];
            [[theValue([condition checkEvent:NO]) should] beNo];
        });
        it(@"Should be YES for type API and manual", ^{
            AMARevenueEventCondition *condition = [[AMARevenueEventCondition alloc] initWithSource:AMARevenueSourceAPI];
            [[theValue([condition checkEvent:NO]) should] beYes];
        });
    });
});

SPEC_END
