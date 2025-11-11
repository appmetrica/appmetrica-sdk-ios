
#import <Foundation/Foundation.h>
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMAClientEventCondition.h"

SPEC_BEGIN(AMAClientEventConditionTest)

describe(@"AMAClientEventCondition", ^{

    context(@"Init with JSON", ^{
        it(@"Should return nil for nil json", ^{
            [[[[AMAClientEventCondition alloc] initWithJSON:nil] should] beNil];
        });
        it(@"Should return valid object for filled json", ^{
            NSDictionary *json = @{
                @"name" : @"some name"
            };
            AMAClientEventCondition *condition = [[AMAClientEventCondition alloc] initWithJSON:json];
            [[theValue([condition checkEvent:@"some name"]) should] beYes];
        });
    });
    context(@"JSON", ^{
        AMAClientEventCondition *condition = [[AMAClientEventCondition alloc] initWithName:@"some name"];
        [[[condition JSON] should] equal:@{
            @"name" : @"some name"
        }];
    });
    context(@"Convert", ^{
        AMAClientEventCondition *condition = [[AMAClientEventCondition alloc] initWithName:@"some name"];
        it(@"Should be YES for right name", ^{
            [[theValue([condition checkEvent:@"some name"]) should] beYes];
        });
        it(@"Should be NO for wrong name", ^{
            [[theValue([condition checkEvent:@"wrong name"]) should] beNo];
        });
    });
    
    it(@"Should conform to AMAJSONSerializable", ^{
        AMAClientEventCondition *condition = [[AMAClientEventCondition alloc] init];
        [[condition should] conformToProtocol:@protocol(AMAJSONSerializable)];
    });
});

SPEC_END
