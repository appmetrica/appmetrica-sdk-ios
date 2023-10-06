#import <Kiwi/Kiwi.h>
#import "AMAErrorEnvironment.h"

SPEC_BEGIN(AMAErrorEnvironmentTests)

describe(@"AMAErrorEnvironment", ^{
    let(sut, ^id{ return [[AMAErrorEnvironment alloc] init]; });

    it(@"Should start with an empty environment", ^{
        NSDictionary *result = [sut currentEnvironment];
        [[result should] beEmpty];
    });

    context(@"When adding key-value pairs", ^{
        it(@"Should correctly add a key-value pair", ^{
            [sut addValue:@"value1" forKey:@"key1"];
            NSDictionary *result = [sut currentEnvironment];
            [[result should] haveCountOf:1];
            [[[result objectForKey:@"key1"] should] equal:@"value1"];
        });

        it(@"Should not increase the count when adding a duplicate key", ^{
            [sut addValue:@"value1" forKey:@"key1"];
            [sut addValue:@"value2" forKey:@"key1"];
            NSDictionary *result = [sut currentEnvironment];
            [[result should] haveCountOf:1];
        });

        it(@"Should respect key-pair count limit of 30", ^{
            for (int i = 0; i < 35; ++i) {
                [sut addValue:[NSString stringWithFormat:@"value%d", i] forKey:[NSString stringWithFormat:@"key%d", i]];
            }
            NSDictionary *result = [sut currentEnvironment];
            [[result should] haveCountOf:30];
        });
    });

    context(@"When dealing with key or value length", ^{
        it(@"Should truncate keys longer than 50 characters", ^{
            NSString *longKey = [@"" stringByPaddingToLength:60 withString:@"a" startingAtIndex:0];
            NSString *expectedKey = [longKey substringToIndex:50];

            [sut addValue:@"value" forKey:longKey];
            NSDictionary *result = [sut currentEnvironment];

            [[result.allKeys.firstObject should] equal:expectedKey];
        });

        it(@"Should correctly handle a key that is exactly 50 characters long", ^{
            NSString *edgeKey = [@"" stringByPaddingToLength:50 withString:@"f" startingAtIndex:0];
            [sut addValue:@"value" forKey:edgeKey];
            NSDictionary *result = [sut currentEnvironment];
            [[result.allKeys.firstObject should] equal:edgeKey];
        });

        it(@"Should truncate values longer than 4000 characters", ^{
            NSString *longValue = [@"" stringByPaddingToLength:4500 withString:@"b" startingAtIndex:0];
            NSString *expectedValue = [longValue substringToIndex:4000];

            [sut addValue:longValue forKey:@"key"];
            NSDictionary *result = [sut currentEnvironment];

            [[result.allValues.firstObject should] equal:expectedValue];
        });

        it(@"Should correctly handle a value that is exactly 4000 characters long", ^{
            NSString *edgeValue = [@"" stringByPaddingToLength:4000 withString:@"e" startingAtIndex:0];
            [sut addValue:edgeValue forKey:@"key"];
            NSDictionary *result = [sut currentEnvironment];
            [[result.allValues.firstObject should] equal:edgeValue];
        });

        it(@"Should not add a new pair if adding it will exceed the total length limit of 4500", ^{
            NSString *almostLimitKey = [@"" stringByPaddingToLength:50 withString:@"a" startingAtIndex:0];
            NSString *almostLimitValue = [@"" stringByPaddingToLength:4000 withString:@"b" startingAtIndex:0];
            NSString *smallKey = [@"" stringByPaddingToLength:50 withString:@"c" startingAtIndex:0];
            NSString *smallValue = [@"" stringByPaddingToLength:400 withString:@"d" startingAtIndex:0];

            [sut addValue:almostLimitValue forKey:almostLimitKey];
            [sut addValue:smallValue forKey:smallKey];

            NSDictionary *result = [sut currentEnvironment];
            [[result should] haveCountOf:2];
            [[result should] haveValue:almostLimitValue forKey:almostLimitKey];
            [[result should] haveValue:smallValue forKey:smallKey];

            [sut addValue:@"ThisIsExtraValue" forKey:@"EV"];

            result = [sut currentEnvironment];
            [[result should] haveCountOf:2];
            [[result should] haveValue:almostLimitValue forKey:almostLimitKey];
            [[result should] haveValue:smallValue forKey:smallKey];
        });
    });

    context(@"When clearing the environment", ^{
        it(@"Should clear the environment correctly", ^{
            [sut addValue:@"value" forKey:@"key"];
            [sut clearEnvironment];
            NSDictionary *result = [sut currentEnvironment];
            [[result should] beEmpty];
        });

        it(@"Should correctly clear a partially filled environment", ^{
            [sut addValue:@"value" forKey:@"key"];
            [sut clearEnvironment];
            [sut addValue:@"new_value" forKey:@"new_key"];
            NSDictionary *result = [sut currentEnvironment];
            [[result should] haveCountOf:1];
            [[[result objectForKey:@"new_key"] should] equal:@"new_value"];
        });
    });

    context(@"When working with nil values", ^{
        it(@"Should not change the environment if the key is nil", ^{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
            [sut addValue:@"value" forKey:nil];
            NSDictionary *result = [sut currentEnvironment];
            [[result should] beEmpty];
#pragma clang diagnostic pop

        });

        it(@"Should not change the environment if the value is nil", ^{
            [sut addValue:nil forKey:@"key"];
            NSDictionary *result = [sut currentEnvironment];
            [[result should] beEmpty];
        });
    });

    context(@"When updating values", ^{
        it(@"Should update the value for an existing key", ^{
            [sut addValue:@"old_value" forKey:@"key"];
            [sut addValue:@"new_value" forKey:@"key"];
            NSDictionary *result = [sut currentEnvironment];
            [[[result objectForKey:@"key"] should] equal:@"new_value"];
        });

        it(@"Should not affect limits when replacing a value for an existing key", ^{
            [sut addValue:@"old_value" forKey:@"key"];
            NSString *limitValue = [@"" stringByPaddingToLength:4000 withString:@"g" startingAtIndex:0];
            [sut addValue:limitValue forKey:@"limit_key"];
            [sut addValue:@"new_value" forKey:@"key"];
            NSDictionary *result = [sut currentEnvironment];
            [[result should] haveCountOf:2];
        });
    });
});

SPEC_END
