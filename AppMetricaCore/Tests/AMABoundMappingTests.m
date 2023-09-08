
#import <Kiwi/Kiwi.h>
#import "AMABoundMapping.h"

SPEC_BEGIN(AMABoundMappingTests)

describe(@"AMABoundMapping", ^{

    context(@"Init with JSON", ^{
        it(@"Should return nil for nil json", ^{
            [[[[AMABoundMapping alloc] initWithJSON:nil] should] beNil];
        });
        it(@"Should return non nil for filled json", ^{
            NSDictionary *json = @{
                @"bound" : @"45.67",
                @"value" : @7
            };
            AMABoundMapping *mapping = [[AMABoundMapping alloc] initWithJSON:json];
            [[mapping.bound should] equal:[NSDecimalNumber decimalNumberWithString:@"45.67"]];
            [[mapping.value should] equal:@7];
        });
    });
    context(@"JSON", ^{
        AMABoundMapping *mapping = [[AMABoundMapping alloc] initWithBound:[NSDecimalNumber decimalNumberWithString:@"45.56"]
                                                                    value:@8];
        NSDictionary *expectedJSON = @{
            @"bound" : @"45.67",
            @"value" : @7
        };
        [[[mapping JSON] should] equal:expectedJSON];
    });
    context(@"Compare", ^{
        it(@"Equal", ^{
            AMABoundMapping *first = [[AMABoundMapping alloc] initWithBound:[NSDecimalNumber decimalNumberWithString:@"45.56"]
                                                                      value:@8];
            AMABoundMapping *second = [[AMABoundMapping alloc] initWithBound:[NSDecimalNumber decimalNumberWithString:@"45.56"]
                                                                       value:@4];
            [[theValue([first compare:second]) should] equal:theValue(NSOrderedSame)];
        });
        it(@"First is greater", ^{
            AMABoundMapping *first = [[AMABoundMapping alloc] initWithBound:[NSDecimalNumber decimalNumberWithString:@"45.57"]
                                                                      value:@8];
            AMABoundMapping *second = [[AMABoundMapping alloc] initWithBound:[NSDecimalNumber decimalNumberWithString:@"45.56"]
                                                                       value:@4];
            [[theValue([first compare:second]) should] equal:theValue(NSOrderedDescending)];
        });
        it(@"First is less", ^{
            AMABoundMapping *first = [[AMABoundMapping alloc] initWithBound:[NSDecimalNumber decimalNumberWithString:@"45.55"]
                                                                      value:@8];
            AMABoundMapping *second = [[AMABoundMapping alloc] initWithBound:[NSDecimalNumber decimalNumberWithString:@"45.56"]
                                                                       value:@4];
            [[theValue([first compare:second]) should] equal:theValue(NSOrderedAscending)];
        });
    });
});

SPEC_END
