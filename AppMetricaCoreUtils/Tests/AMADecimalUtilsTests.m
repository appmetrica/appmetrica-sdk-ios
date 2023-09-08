
#import <Kiwi/Kiwi.h>
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>

SPEC_BEGIN(AMADecimalUtilsTests)

describe(@"AMADecimalUtils", ^{

    NSString *bigNumberString = @"1230000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";

    context(@"Fill mantissa and exponent", ^{
        BOOL __block result = NO;
        int64_t __block mantissa = 0;
        int32_t __block exponent = 0;

        __auto_type fillAll = ^(NSDecimalNumber *number) {
            mantissa = 0;
            exponent = 0;
            result = [AMADecimalUtils fillMantissa:&mantissa exponent:&exponent withDecimal:number];
        };
        __auto_type fillAllWithString = ^(NSString *string) {
            fillAll([NSDecimalNumber decimalNumberWithString:string locale:@{ NSLocaleDecimalSeparator: @"." }]);
        };

        context(@"0", ^{
            beforeEach(^{
                fillAllWithString(@"0");
            });
            it(@"Should have valid result", ^{
                [[theValue(result) should] beYes];
            });
            it(@"Should have valid mantissa", ^{
                [[theValue(mantissa) should] equal:theValue(0)];
            });
            it(@"Should have valid exponent", ^{
                [[theValue(exponent) should] equal:theValue(0)];
            });
        });

        context(@"-1", ^{
            beforeEach(^{
                fillAllWithString(@"-1");
            });
            it(@"Should have valid result", ^{
                [[theValue(result) should] beYes];
            });
            it(@"Should have valid mantissa", ^{
                [[theValue(mantissa) should] equal:theValue(-1)];
            });
            it(@"Should have valid exponent", ^{
                [[theValue(exponent) should] equal:theValue(0)];
            });
        });

        context(@"1", ^{
            beforeEach(^{
                fillAllWithString(@"1");
            });
            it(@"Should have valid result", ^{
                [[theValue(result) should] beYes];
            });
            it(@"Should have valid mantissa", ^{
                [[theValue(mantissa) should] equal:theValue(1)];
            });
            it(@"Should have valid exponent", ^{
                [[theValue(exponent) should] equal:theValue(0)];
            });
        });

        context(@"-0.1", ^{
            beforeEach(^{
                fillAllWithString(@"-0.1");
            });
            it(@"Should have valid result", ^{
                [[theValue(result) should] beYes];
            });
            it(@"Should have valid mantissa", ^{
                [[theValue(mantissa) should] equal:theValue(-1)];
            });
            it(@"Should have valid exponent", ^{
                [[theValue(exponent) should] equal:theValue(-1)];
            });
        });

        context(@"0.1", ^{
            beforeEach(^{
                fillAllWithString(@"0.1");
            });
            it(@"Should have valid result", ^{
                [[theValue(result) should] beYes];
            });
            it(@"Should have valid mantissa", ^{
                [[theValue(mantissa) should] equal:theValue(1)];
            });
            it(@"Should have valid exponent", ^{
                [[theValue(exponent) should] equal:theValue(-1)];
            });
        });

        context(@"-10", ^{
            beforeEach(^{
                fillAllWithString(@"-10");
            });
            it(@"Should have valid result", ^{
                [[theValue(result) should] beYes];
            });
            it(@"Should have valid mantissa", ^{
                [[theValue(mantissa) should] equal:theValue(-1)];
            });
            it(@"Should have valid exponent", ^{
                [[theValue(exponent) should] equal:theValue(1)];
            });
        });

        context(@"10", ^{
            beforeEach(^{
                fillAllWithString(@"10");
            });
            it(@"Should have valid result", ^{
                [[theValue(result) should] beYes];
            });
            it(@"Should have valid mantissa", ^{
                [[theValue(mantissa) should] equal:theValue(1)];
            });
            it(@"Should have valid exponent", ^{
                [[theValue(exponent) should] equal:theValue(1)];
            });
        });

        context(@"1234567890123456789012345678901234567890", ^{
            beforeEach(^{
                fillAllWithString(@"1234567890123456789012345678901234567890");
            });
            it(@"Should have valid result", ^{
                [[theValue(result) should] beYes];
            });
            it(@"Should have valid mantissa", ^{
                [[theValue(mantissa) should] equal:theValue(1234567890123456789)];
            });
            it(@"Should have valid exponent", ^{
                [[theValue(exponent) should] equal:theValue(21)];
            });
        });

        context(@"-0.1234567890123456789012345678901234567890", ^{
            beforeEach(^{
                fillAllWithString(@"-0.1234567890123456789012345678901234567890");
            });
            it(@"Should have valid result", ^{
                [[theValue(result) should] beYes];
            });
            it(@"Should have valid mantissa", ^{
                [[theValue(mantissa) should] equal:theValue(-1234567890123456789)];
            });
            it(@"Should have valid exponent", ^{
                [[theValue(exponent) should] equal:theValue(-19)];
            });
        });

        context(@"LONG_LONG_MAX", ^{
            beforeEach(^{
                fillAll([NSDecimalNumber decimalNumberWithMantissa:LONG_LONG_MAX exponent:0 isNegative:NO]);
            });
            it(@"Should have valid result", ^{
                [[theValue(result) should] beYes];
            });
            it(@"Should have valid mantissa", ^{
                [[theValue(mantissa) should] equal:theValue(LONG_LONG_MAX)];
            });
            it(@"Should have valid exponent", ^{
                [[theValue(exponent) should] equal:theValue(0)];
            });
        });

        context(@"LONG_LONG_MIN", ^{
            beforeEach(^{
                fillAll([NSDecimalNumber decimalNumberWithMantissa:((unsigned long long)LONG_LONG_MAX) + 1
                                                          exponent:0
                                                        isNegative:YES]);
            });
            it(@"Should have valid result", ^{
                [[theValue(result) should] beYes];
            });
            it(@"Should have valid mantissa", ^{
                [[theValue(mantissa) should] equal:theValue(LONG_LONG_MIN)];
            });
            it(@"Should have valid exponent", ^{
                [[theValue(exponent) should] equal:theValue(0)];
            });
        });

        context(@"LONG_LONG_MAX + 1", ^{
            beforeEach(^{
                fillAll([NSDecimalNumber decimalNumberWithMantissa:((unsigned long long)LONG_LONG_MAX) + 1
                                                          exponent:0
                                                        isNegative:NO]);
            });
            it(@"Should have valid result", ^{
                [[theValue(result) should] beYes];
            });
            it(@"Should have valid mantissa", ^{
                [[theValue(mantissa) should] equal:theValue(LONG_LONG_MAX / 10)];
            });
            it(@"Should have valid exponent", ^{
                [[theValue(exponent) should] equal:theValue(1)];
            });
        });

        context(@"LONG_LONG_MIN - 1", ^{
            beforeEach(^{
                fillAll([NSDecimalNumber decimalNumberWithMantissa:((unsigned long long)LONG_LONG_MAX) + 2
                                                          exponent:0
                                                        isNegative:YES]);
            });
            it(@"Should have valid result", ^{
                [[theValue(result) should] beYes];
            });
            it(@"Should have valid mantissa", ^{
                [[theValue(mantissa) should] equal:theValue(LONG_LONG_MIN / 10)];
            });
            it(@"Should have valid exponent", ^{
                [[theValue(exponent) should] equal:theValue(1)];
            });
        });

        context(@"1127.69", ^{ // See https://nda.ya.ru/t/DHz0txEb6fHaJa for the story about this number
            beforeEach(^{
                fillAll([[NSDecimalNumber alloc] initWithDouble:1127.69]);
            });
            it(@"Should have valid result", ^{
                [[theValue(result) should] beYes];
            });
            it(@"Should have valid mantissa", ^{
                [[theValue(mantissa) should] equal:theValue(1127690000000000204)];
            });
            it(@"Should have valid exponent", ^{
                [[theValue(exponent) should] equal:theValue(-15)];
            });
        });

        context(@"Min Decimal", ^{
            beforeEach(^{
                fillAll(NSDecimalNumber.minimumDecimalNumber);
            });
            it(@"Should have valid result", ^{
                [[theValue(result) should] beYes];
            });
            it(@"Should have valid mantissa", ^{
                [[theValue(mantissa) should] equal:theValue(-3402823669209384634)];
            });
            it(@"Should have valid exponent", ^{
                [[theValue(exponent) should] equal:theValue(147)];
            });
        });

        context(@"Max Decimal", ^{
            beforeEach(^{
                fillAll(NSDecimalNumber.maximumDecimalNumber);
            });
            it(@"Should have valid result", ^{
                [[theValue(result) should] beYes];
            });
            it(@"Should have valid mantissa", ^{
                [[theValue(mantissa) should] equal:theValue(3402823669209384634)];
            });
            it(@"Should have valid exponent", ^{
                [[theValue(exponent) should] equal:theValue(147)];
            });
        });

        context(@"NaN", ^{
            beforeEach(^{
                fillAll(NSDecimalNumber.notANumber);
            });
            it(@"Should have valid result", ^{
                [[theValue(result) should] beNo];
            });
            it(@"Should have valid mantissa", ^{
                [[theValue(mantissa) should] beZero];
            });
            it(@"Should have valid exponent", ^{
                [[theValue(exponent) should] beZero];
            });
        });

        context(@"DBL_EPSILON", ^{
            beforeEach(^{
                NSDecimalNumber *num = [[NSDecimalNumber alloc] initWithDouble:DBL_EPSILON];
                fillAll(num);
            });
            it(@"Should have valid result", ^{
                [[theValue(result) should] beYes];
            });
            it(@"Should have valid mantissa", ^{
                [[theValue(mantissa) should] equal:theValue(222044604925031296)];
            });
            it(@"Should have valid exponent", ^{
                [[theValue(exponent) should] equal:theValue(-33)];
            });
        });

        context(@"INFINITY", ^{
            beforeEach(^{
                fillAll([[NSDecimalNumber alloc] initWithDouble:INFINITY]);
            });
            it(@"Should have valid result", ^{
                [[theValue(result) should] beYes];
            });
            it(@"Should have valid mantissa", ^{
                [[theValue(mantissa) should] equal:theValue(1844674407370955161)];
            });
            it(@"Should have valid exponent", ^{
                [[theValue(exponent) should] equal:theValue(128)];
            });
        });
    });
    context(@"decimalNumberWithString", ^{
        NSDecimalNumber *defaultNumber = [NSDecimalNumber decimalNumberWithString:@"42"];
        it(@"String is nil", ^{
            [[[AMADecimalUtils decimalNumberWithString:nil or:defaultNumber] should] equal:defaultNumber];
        });
        it(@"String is empty", ^{
            [[[AMADecimalUtils decimalNumberWithString:@"" or:defaultNumber] should] equal:defaultNumber];
        });
        it(@"String is not a number", ^{
            [[[AMADecimalUtils decimalNumberWithString:@"not a number" or:defaultNumber] should] equal:defaultNumber];
        });
        it(@"String is valid number", ^{
            [[[AMADecimalUtils decimalNumberWithString:@"666777.9899" or:defaultNumber] should]
                equal:[NSDecimalNumber decimalNumberWithString:@"666777.9899"]];
        });
        it(@"String is valid negative number", ^{
            [[[AMADecimalUtils decimalNumberWithString:@"-666777.9899" or:defaultNumber] should]
                equal:[NSDecimalNumber decimalNumberWithString:@"-666777.9899"]];
        });
        it(@"String is a very big number", ^{
            [[[AMADecimalUtils decimalNumberWithString:@"847653847568934765948769487694587698476538475689347659487694876945876984765384756893476594876948769458769847653847568934765948769487694587698476538475689347659487694876945876984765384756893476594876948769458769.84765384756893476594876948769458769847653847568934765948769487694587698476538475689347659487694876945876984765384756893476594876948769458769847653847568934765948769487694587698476538475689347659487694876945876984765384756893476594876948769458769847653847568934765948769487694587698476538475689347659487694876945876984765384756893476594876948769458769847653847568934765948769487694587698476538475689347659487694876945876984765384756893476594876948769458769" or:defaultNumber] should]
                equal:defaultNumber];
        });
    });
    context(@"bySafelyMultiplyingBy", ^{
        NSDecimalNumber *defaultNumber = [NSDecimalNumber decimalNumberWithString:@"42"];
        it(@"Number is nil", ^{
            NSDecimalNumber *result = [AMADecimalUtils decimalNumber:nil
                                               bySafelyMultiplyingBy:[NSDecimalNumber decimalNumberWithString:@"1"]
                                                                  or:defaultNumber];
            [[result should] equal:defaultNumber];
        });
        it(@"Number is nan", ^{
            NSDecimalNumber *result = [AMADecimalUtils decimalNumber:[NSDecimalNumber notANumber]
                                               bySafelyMultiplyingBy:[NSDecimalNumber decimalNumberWithString:@"1"]
                                                                  or:defaultNumber];
            [[result should] equal:defaultNumber];
        });
        it(@"Multiplier is nil", ^{
            NSDecimalNumber *result = [AMADecimalUtils decimalNumber:[NSDecimalNumber decimalNumberWithString:@"1"]
                                               bySafelyMultiplyingBy:nil
                                                                  or:defaultNumber];
            [[result should] equal:defaultNumber];
        });
        it(@"Multiplier is nan", ^{
            NSDecimalNumber *result = [AMADecimalUtils decimalNumber:[NSDecimalNumber decimalNumberWithString:@"1"]
                                               bySafelyMultiplyingBy:[NSDecimalNumber notANumber]
                                                                  or:defaultNumber];
            [[result should] equal:defaultNumber];
        });
        it(@"Overflow", ^{
            NSDecimalNumber *firstNumber = [NSDecimalNumber decimalNumberWithString:bigNumberString];
            NSDecimalNumber *secondNumber = [NSDecimalNumber decimalNumberWithString:@"100000000000000000000000000000"];
            NSDecimalNumber *result = [AMADecimalUtils decimalNumber:firstNumber
                                               bySafelyMultiplyingBy:secondNumber
                                                                  or:defaultNumber];
            [[result should] equal:defaultNumber];
        });
        it(@"Success", ^{
            NSDecimalNumber *firstNumber = [NSDecimalNumber decimalNumberWithString:@"12"];
            NSDecimalNumber *secondNumber = [NSDecimalNumber decimalNumberWithString:@"78"];
            NSDecimalNumber *result = [AMADecimalUtils decimalNumber:firstNumber
                                               bySafelyMultiplyingBy:secondNumber
                                                                  or:defaultNumber];
            [[result should] equal:[NSDecimalNumber decimalNumberWithString:@"936"]];
        });
    });
    context(@"bySafelyDividingBy", ^{
        NSDecimalNumber *defaultNumber = [NSDecimalNumber decimalNumberWithString:@"42"];
        it(@"Number is nil", ^{
            NSDecimalNumber *result = [AMADecimalUtils decimalNumber:nil
                                                  bySafelyDividingBy:[NSDecimalNumber decimalNumberWithString:@"1"]
                                                                  or:defaultNumber];
            [[result should] equal:defaultNumber];
        });
        it(@"Number is nan", ^{
            NSDecimalNumber *result = [AMADecimalUtils decimalNumber:[NSDecimalNumber notANumber]
                                                  bySafelyDividingBy:[NSDecimalNumber decimalNumberWithString:@"1"]
                                                                  or:defaultNumber];
            [[result should] equal:defaultNumber];
        });
        it(@"Divisor is nil", ^{
            NSDecimalNumber *result = [AMADecimalUtils decimalNumber:[NSDecimalNumber decimalNumberWithString:@"1"]
                                                  bySafelyDividingBy:nil
                                                                  or:defaultNumber];
            [[result should] equal:defaultNumber];
        });
        it(@"Divisor is nan", ^{
            NSDecimalNumber *result = [AMADecimalUtils decimalNumber:[NSDecimalNumber decimalNumberWithString:@"1"]
                                                  bySafelyDividingBy:[NSDecimalNumber notANumber]
                                                                  or:defaultNumber];
            [[result should] equal:defaultNumber];
        });
        it(@"Divisor is zero", ^{
            NSDecimalNumber *firstNumber = [NSDecimalNumber decimalNumberWithString:@"34785647856348756"];
            NSDecimalNumber *secondNumber = [NSDecimalNumber zero];
            NSDecimalNumber *result = [AMADecimalUtils decimalNumber:firstNumber
                                                  bySafelyDividingBy:secondNumber
                                                                  or:defaultNumber];
            [[result should] equal:defaultNumber];
        });
        it(@"Success", ^{
            NSDecimalNumber *firstNumber = [NSDecimalNumber decimalNumberWithString:@"50"];
            NSDecimalNumber *secondNumber = [NSDecimalNumber decimalNumberWithString:@"25"];
            NSDecimalNumber *result = [AMADecimalUtils decimalNumber:firstNumber
                                                  bySafelyDividingBy:secondNumber
                                                                  or:defaultNumber];
            [[result should] equal:[NSDecimalNumber decimalNumberWithString:@"2"]];
        });
    });
    context(@"bySafelyAdding", ^{
        NSDecimalNumber *defaultNumber = [NSDecimalNumber decimalNumberWithString:@"42"];
        it(@"Number is nil", ^{
            NSDecimalNumber *result = [AMADecimalUtils decimalNumber:nil
                                                      bySafelyAdding:[NSDecimalNumber decimalNumberWithString:@"1"]
                                                                  or:defaultNumber];
            [[result should] equal:defaultNumber];
        });
        it(@"Number is nan", ^{
            NSDecimalNumber *result = [AMADecimalUtils decimalNumber:[NSDecimalNumber notANumber]
                                                      bySafelyAdding:[NSDecimalNumber decimalNumberWithString:@"1"]
                                                                  or:defaultNumber];
            [[result should] equal:defaultNumber];
        });
        it(@"Another number is nil", ^{
            NSDecimalNumber *result = [AMADecimalUtils decimalNumber:[NSDecimalNumber decimalNumberWithString:@"1"]
                                                      bySafelyAdding:nil
                                                                  or:defaultNumber];
            [[result should] equal:defaultNumber];
        });
        it(@"Another number is nan", ^{
            NSDecimalNumber *result = [AMADecimalUtils decimalNumber:[NSDecimalNumber decimalNumberWithString:@"1"]
                                                      bySafelyAdding:[NSDecimalNumber notANumber]
                                                                  or:defaultNumber];
            [[result should] equal:defaultNumber];
        });
        it(@"Overflow", ^{
            NSDecimalNumber *firstNumber = [NSDecimalNumber decimalNumberWithString:bigNumberString];
            NSDecimalNumber *secondNumber = [NSDecimalNumber decimalNumberWithString:bigNumberString];
            NSDecimalNumber *result = [AMADecimalUtils decimalNumber:firstNumber
                                               bySafelyMultiplyingBy:secondNumber
                                                                  or:defaultNumber];
            [[result should] equal:defaultNumber];
        });
        it(@"Success", ^{
            NSDecimalNumber *firstNumber = [NSDecimalNumber decimalNumberWithString:@"12"];
            NSDecimalNumber *secondNumber = [NSDecimalNumber decimalNumberWithString:@"78"];
            NSDecimalNumber *result = [AMADecimalUtils decimalNumber:firstNumber
                                                      bySafelyAdding:secondNumber
                                                                  or:defaultNumber];
            [[result should] equal:[NSDecimalNumber decimalNumberWithString:@"90"]];
        });
    });
    context(@"bySafelySubtracting", ^{
        NSDecimalNumber *defaultNumber = [NSDecimalNumber decimalNumberWithString:@"42"];
        it(@"Number is nil", ^{
            NSDecimalNumber *result = [AMADecimalUtils decimalNumber:nil
                                                 bySafelySubtracting:[NSDecimalNumber decimalNumberWithString:@"1"]
                                                                  or:defaultNumber];
            [[result should] equal:defaultNumber];
        });
        it(@"Number is nan", ^{
            NSDecimalNumber *result = [AMADecimalUtils decimalNumber:[NSDecimalNumber notANumber]
                                                 bySafelySubtracting:[NSDecimalNumber decimalNumberWithString:@"1"]
                                                                  or:defaultNumber];
            [[result should] equal:defaultNumber];
        });
        it(@"Another number is nil", ^{
            NSDecimalNumber *result = [AMADecimalUtils decimalNumber:[NSDecimalNumber decimalNumberWithString:@"1"]
                                                 bySafelySubtracting:nil
                                                                  or:defaultNumber];
            [[result should] equal:defaultNumber];
        });
        it(@"Another number is nan", ^{
            NSDecimalNumber *result = [AMADecimalUtils decimalNumber:[NSDecimalNumber decimalNumberWithString:@"1"]
                                                 bySafelySubtracting:[NSDecimalNumber notANumber]
                                                                  or:defaultNumber];
            [[result should] equal:defaultNumber];
        });
        it(@"Success", ^{
            NSDecimalNumber *firstNumber = [NSDecimalNumber decimalNumberWithString:@"100"];
            NSDecimalNumber *secondNumber = [NSDecimalNumber decimalNumberWithString:@"40"];
            NSDecimalNumber *result = [AMADecimalUtils decimalNumber:firstNumber
                                                 bySafelySubtracting:secondNumber
                                                                  or:defaultNumber];
            [[result should] equal:[NSDecimalNumber decimalNumberWithString:@"60"]];
        });
    });
    context(@"Decimal from mantissa and exponent", ^{
        context(@"Normal numbers", ^{
            it(@"Both positive", ^{
                [[[AMADecimalUtils decimalFromMantissa:222333444555 exponent:7] should]
                    equal:[NSDecimalNumber decimalNumberWithString:@"2223334445550000000"]];
            });
            it(@"Negative exponent", ^{
                [[[AMADecimalUtils decimalFromMantissa:222333444555 exponent:-7] should]
                    equal:[NSDecimalNumber decimalNumberWithString:@"22233.3444555"]];
            });
            it(@"Negative numbers", ^{
                [[[AMADecimalUtils decimalFromMantissa:-222333444555 exponent:-7] should]
                    equal:[NSDecimalNumber decimalNumberWithString:@"-22233.3444555"]];
            });
            it(@"Negative mantissa", ^{
                [[[AMADecimalUtils decimalFromMantissa:-222333444555 exponent:7] should]
                    equal:[NSDecimalNumber decimalNumberWithString:@"-2223334445550000000"]];
            });
        });
        context(@"Big numbers", ^{
            it(@"Both positive", ^{
                [[[AMADecimalUtils decimalFromMantissa:LONG_LONG_MAX exponent:SHRT_MAX + 5] should]
                    equal:[NSDecimalNumber decimalNumberWithMantissa:(unsigned long long)LONG_LONG_MAX * 100000
                                                            exponent:SHRT_MAX
                                                          isNegative:NO]];
            });
            it(@"Negative exponent", ^{
                [[[AMADecimalUtils decimalFromMantissa:LONG_LONG_MAX exponent:-(SHRT_MAX + 5)] should]
                    equal:[NSDecimalNumber decimalNumberWithMantissa:(unsigned long long)LONG_LONG_MAX / 10000
                                                            exponent:-(SHRT_MAX + 1)
                                                          isNegative:NO]];
            });
            it(@"Negative numbers", ^{
                unsigned long long unsignedLongLongMin = ((unsigned long long) -(LONG_LONG_MIN + 1)) + 1;
                [[[AMADecimalUtils decimalFromMantissa:LONG_LONG_MIN exponent:-(SHRT_MAX + 5)] should]
                    equal:[NSDecimalNumber decimalNumberWithMantissa:unsignedLongLongMin / 10000
                                                            exponent:-(SHRT_MAX + 1)
                                                          isNegative:YES]];
            });
            it(@"Negative mantissa", ^{
                unsigned long long unsignedLongLongMin = ((unsigned long long) -(LONG_LONG_MIN + 1)) + 1;
                [[[AMADecimalUtils decimalFromMantissa:LONG_LONG_MIN exponent:SHRT_MAX + 5] should]
                    equal:[NSDecimalNumber decimalNumberWithMantissa:unsignedLongLongMin * 100000
                                                            exponent:SHRT_MAX
                                                          isNegative:YES]];
            });
        });
    });
});

SPEC_END
