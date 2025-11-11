
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMABoundMappingChecker.h"
#import "AMABoundMapping.h"

SPEC_BEGIN(AMABoundMappingCheckerTests)

describe(@"AMABoundMappingChecker", ^{

    AMABoundMappingChecker *checker = [[AMABoundMappingChecker alloc] init];

    context(@"Check", ^{
        it(@"Should be nil for nil mappings", ^{
            NSNumber *result = [checker check:[NSDecimalNumber decimalNumberWithString:@"1"] mappings:nil];
            [[result should] beNil];
        });
        it(@"Should be nil for empty mappings", ^{
            NSNumber *result = [checker check:[NSDecimalNumber decimalNumberWithString:@"1"] mappings:@[]];
            [[result should] beNil];
        });
        context(@"Single element", ^{
            NSArray *mapping = @[
                [[AMABoundMapping alloc] initWithBound:[NSDecimalNumber decimalNumberWithString:@"3"] value:@2]
            ];
            it(@"Input is less", ^{
                NSNumber *result = [checker check:[NSDecimalNumber decimalNumberWithString:@"1"] mappings:mapping];
                [[result should] beNil];
            });
            it(@"Input is the same", ^{
                NSNumber *result = [checker check:[NSDecimalNumber decimalNumberWithString:@"3"] mappings:mapping];
                [[result should] equal:@2];
            });
            it(@"Input is the greater", ^{
                NSNumber *result = [checker check:[NSDecimalNumber decimalNumberWithString:@"4"] mappings:mapping];
                [[result should] equal:@2];
            });
        });
        context(@"Odd number of elements", ^{
            NSArray *mapping = @[
                [[AMABoundMapping alloc] initWithBound:[NSDecimalNumber decimalNumberWithString:@"3"] value:@2],
                [[AMABoundMapping alloc] initWithBound:[NSDecimalNumber decimalNumberWithString:@"4.1"] value:@3],
                [[AMABoundMapping alloc] initWithBound:[NSDecimalNumber decimalNumberWithString:@"5.21"] value:@4],
                [[AMABoundMapping alloc] initWithBound:[NSDecimalNumber decimalNumberWithString:@"6"] value:@5],
                [[AMABoundMapping alloc] initWithBound:[NSDecimalNumber decimalNumberWithString:@"8"] value:@10]
            ];
            it(@"Input is less than everything", ^{
                NSNumber *result = [checker check:[NSDecimalNumber decimalNumberWithString:@"2.9"] mappings:mapping];
                [[result should] beNil];
            });
            it(@"Input is equal to first element", ^{
                NSNumber *result = [checker check:[NSDecimalNumber decimalNumberWithString:@"3"] mappings:mapping];
                [[result should] equal:@2];
            });
            it(@"Input is between first and second element", ^{
                NSNumber *result = [checker check:[NSDecimalNumber decimalNumberWithString:@"4"] mappings:mapping];
                [[result should] equal:@2];
            });
            it(@"Input is equal to second element", ^{
                NSNumber *result = [checker check:[NSDecimalNumber decimalNumberWithString:@"4.1"] mappings:mapping];
                [[result should] equal:@3];
            });
            it(@"Input is between second and third element", ^{
                NSNumber *result = [checker check:[NSDecimalNumber decimalNumberWithString:@"4.2"] mappings:mapping];
                [[result should] equal:@3];
            });
            it(@"Input is equal to third element", ^{
                NSNumber *result = [checker check:[NSDecimalNumber decimalNumberWithString:@"5.21"] mappings:mapping];
                [[result should] equal:@4];
            });
            it(@"Input is between third and fourth element", ^{
                NSNumber *result = [checker check:[NSDecimalNumber decimalNumberWithString:@"5.9999"] mappings:mapping];
                [[result should] equal:@4];
            });
            it(@"Input is equal to fourth element", ^{
                NSNumber *result = [checker check:[NSDecimalNumber decimalNumberWithString:@"6"] mappings:mapping];
                [[result should] equal:@5];
            });
            it(@"Input is between fourth and fifth element", ^{
                NSNumber *result = [checker check:[NSDecimalNumber decimalNumberWithString:@"6.777"] mappings:mapping];
                [[result should] equal:@5];
            });
            it(@"Input is equal to fifth element", ^{
                NSNumber *result = [checker check:[NSDecimalNumber decimalNumberWithString:@"8"] mappings:mapping];
                [[result should] equal:@10];
            });
            it(@"Input is greater than everything", ^{
                NSNumber *result = [checker check:[NSDecimalNumber decimalNumberWithString:@"8.1"] mappings:mapping];
                [[result should] equal:@10];
            });
        });
        context(@"Event number of elements", ^{
            NSArray *mapping = @[
                [[AMABoundMapping alloc] initWithBound:[NSDecimalNumber decimalNumberWithString:@"3"] value:@2],
                [[AMABoundMapping alloc] initWithBound:[NSDecimalNumber decimalNumberWithString:@"4.1"] value:@3],
                [[AMABoundMapping alloc] initWithBound:[NSDecimalNumber decimalNumberWithString:@"5.21"] value:@4],
                [[AMABoundMapping alloc] initWithBound:[NSDecimalNumber decimalNumberWithString:@"6"] value:@5],
                [[AMABoundMapping alloc] initWithBound:[NSDecimalNumber decimalNumberWithString:@"8"] value:@10],
                [[AMABoundMapping alloc] initWithBound:[NSDecimalNumber decimalNumberWithString:@"9"] value:@11]
            ];
            it(@"Input is less than everything", ^{
                NSNumber *result = [checker check:[NSDecimalNumber decimalNumberWithString:@"2.9"] mappings:mapping];
                [[result should] beNil];
            });
            it(@"Input is equal to first element", ^{
                NSNumber *result = [checker check:[NSDecimalNumber decimalNumberWithString:@"3"] mappings:mapping];
                [[result should] equal:@2];
            });
            it(@"Input is between first and second element", ^{
                NSNumber *result = [checker check:[NSDecimalNumber decimalNumberWithString:@"4"] mappings:mapping];
                [[result should] equal:@2];
            });
            it(@"Input is equal to second element", ^{
                NSNumber *result = [checker check:[NSDecimalNumber decimalNumberWithString:@"4.1"] mappings:mapping];
                [[result should] equal:@3];
            });
            it(@"Input is between second and third element", ^{
                NSNumber *result = [checker check:[NSDecimalNumber decimalNumberWithString:@"4.2"] mappings:mapping];
                [[result should] equal:@3];
            });
            it(@"Input is equal to third element", ^{
                NSNumber *result = [checker check:[NSDecimalNumber decimalNumberWithString:@"5.21"] mappings:mapping];
                [[result should] equal:@4];
            });
            it(@"Input is between third and fourth element", ^{
                NSNumber *result = [checker check:[NSDecimalNumber decimalNumberWithString:@"5.9999"] mappings:mapping];
                [[result should] equal:@4];
            });
            it(@"Input is equal to fourth element", ^{
                NSNumber *result = [checker check:[NSDecimalNumber decimalNumberWithString:@"6"] mappings:mapping];
                [[result should] equal:@5];
            });
            it(@"Input is between fourth and fifth element", ^{
                NSNumber *result = [checker check:[NSDecimalNumber decimalNumberWithString:@"6.777"] mappings:mapping];
                [[result should] equal:@5];
            });
            it(@"Input is equal to fifth element", ^{
                NSNumber *result = [checker check:[NSDecimalNumber decimalNumberWithString:@"8"] mappings:mapping];
                [[result should] equal:@10];
            });
            it(@"Input is between fifth and sixth element", ^{
                NSNumber *result = [checker check:[NSDecimalNumber decimalNumberWithString:@"8.1"] mappings:mapping];
                [[result should] equal:@10];
            });
            it(@"Input is equal to sixth element", ^{
                NSNumber *result = [checker check:[NSDecimalNumber decimalNumberWithString:@"9"] mappings:mapping];
                [[result should] equal:@11];
            });
            it(@"Input is greater than everything", ^{
                NSNumber *result = [checker check:[NSDecimalNumber decimalNumberWithString:@"9.1"] mappings:mapping];
                [[result should] equal:@11];
            });
        });
    });
});

SPEC_END
