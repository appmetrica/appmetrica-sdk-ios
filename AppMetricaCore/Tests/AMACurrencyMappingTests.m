
#import <Foundation/Foundation.h>
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMACore.h"
#import "AMACurrencyMapping.h"

SPEC_BEGIN(AMACurrencyMappingTests)

describe(@"AMACurrencyMapping", ^{

    context(@"Init with JSON", ^{
        it(@"Should return non nil for nil JSON", ^{
            [[[[AMACurrencyMapping alloc] initWithJSON:nil] shouldNot] beNil];
        });
        it(@"Should return valid object for valid json", ^{
            NSDictionary *json = @{
                @"mapping" : @{
                    @"USD" : @"1000000",
                    @"BYN" : @"2500000"
                }
            };
            AMACurrencyMapping *mapping = [[AMACurrencyMapping alloc] initWithJSON:json];
            NSDecimalNumber *convertedUSD = [mapping convert:[NSDecimalNumber decimalNumberWithString:@"2"]
                                                    currency:@"USD"
                                                       scale:1000000 error:nil];
            NSDecimalNumber *convertedBYN = [mapping convert:[NSDecimalNumber decimalNumberWithString:@"10"]
                                                    currency:@"BYN"
                                                       scale:1000000 error:nil];
            [[convertedUSD should] equal:[NSDecimalNumber decimalNumberWithString:@"2"]];
            [[convertedBYN should] equal:[NSDecimalNumber decimalNumberWithString:@"4"]];
        });
    });
    context(@"JSON", ^{
        it(@"Empty mapping", ^{
            NSDictionary *expectedJSON = @{
                @"mapping" : @{}
            };
            AMACurrencyMapping *mapping = [[AMACurrencyMapping alloc] initWithMapping:@{}];
            [[[mapping JSON] should] equal:expectedJSON];

        });
        it(@"Filled mapping", ^{
            NSDictionary *expectedJSON = @{
                @"mapping" : @{
                    @"USD" : @"1000000",
                    @"BYN" : @"2500000"
                }
            };
            AMACurrencyMapping *mapping = [[AMACurrencyMapping alloc] initWithMapping:@{
                @"USD" : [NSDecimalNumber decimalNumberWithString:@"1000000"],
                @"BYN" : [NSDecimalNumber decimalNumberWithString:@"2500000"]
            }];
            [[[mapping JSON] should] equal:expectedJSON];
        });
    });
    context(@"Convert", ^{
        AMACurrencyMapping *mapping = [[AMACurrencyMapping alloc] initWithMapping:@{
            @"USD" : [NSDecimalNumber decimalNumberWithString:@"1000000"],
            @"BYN" : [NSDecimalNumber decimalNumberWithString:@"2500000"]
        }];
        it(@"Should be zero for bad currency", ^{
            NSError *error = nil;
            NSDecimalNumber *result = [mapping convert:[NSDecimalNumber decimalNumberWithString:@"777"]
                                              currency:@"RUB"
                                                 scale:1000000
                                                 error:&error];
            [[result should] equal:[NSDecimalNumber zero]];
            [[error shouldNot] beNil];
        });
        it(@"Should proxy to AMADecimalUtils", ^{
            NSDecimalNumber *number = [NSDecimalNumber decimalNumberWithString:@"55667788"];
            NSDecimalNumber *scaledNumber = [NSDecimalNumber decimalNumberWithString:@"666777888"];
            [AMADecimalUtils stub:@selector(decimalNumber:bySafelyMultiplyingBy:or:) andReturn:scaledNumber];
            [[AMADecimalUtils should] receive:@selector(decimalNumber:bySafelyMultiplyingBy:or:)
                                withArguments:number, [NSDecimalNumber decimalNumberWithString:@"1000000"], [NSDecimalNumber zero]];
            [[AMADecimalUtils should] receive:@selector(decimalNumber:bySafelyDividingBy:or:)
                                withArguments:scaledNumber, [NSDecimalNumber decimalNumberWithString:@"1000000"], [NSDecimalNumber zero]];
            [mapping convert:number
                    currency:@"USD"
                       scale:1000000
                       error:nil];
        });
        it(@"Scale is 1 for USD", ^{
            NSError *error = nil;
            NSDecimalNumber *result = [mapping convert:[NSDecimalNumber decimalNumberWithString:@"55667788"]
                                              currency:@"USD"
                                                 scale:1
                                                 error:&error];
            [[result should] equal:[NSDecimalNumber decimalNumberWithString:@"55.667788"]];
            [[error should] beNil];
        });
        it(@"Scale is 1 for BYN", ^{
            NSError *error = nil;
            NSDecimalNumber *result = [mapping convert:[NSDecimalNumber decimalNumberWithString:@"55667000"]
                                              currency:@"BYN"
                                                 scale:1
                                                 error:&error];
            [[result should] equal:[NSDecimalNumber decimalNumberWithString:@"22.2668"]];
            [[error should] beNil];
        });
        it(@"Scale is 1000000 for USD", ^{
            NSError *error = nil;
            NSDecimalNumber *result = [mapping convert:[NSDecimalNumber decimalNumberWithString:@"55667788"]
                                              currency:@"USD"
                                                 scale:1000000
                                                 error:&error];
            [[result should] equal:[NSDecimalNumber decimalNumberWithString:@"55667788"]];
            [[error should] beNil];
        });
        it(@"Scale is 1000000 for BYN", ^{
            NSError *error = nil;
            NSDecimalNumber *result = [mapping convert:[NSDecimalNumber decimalNumberWithString:@"55667000"]
                                              currency:@"BYN"
                                                 scale:1000000
                                                 error:&error];
            [[result should] equal:[NSDecimalNumber decimalNumberWithString:@"22266800"]];
            [[error should] beNil];
        });
    });
    
    it(@"Should conform to AMAJSONSerializable", ^{
        AMACurrencyMapping *mapping = [[AMACurrencyMapping alloc] init];
        [[mapping should] conformToProtocol:@protocol(AMAJSONSerializable)];
    });
});

SPEC_END
