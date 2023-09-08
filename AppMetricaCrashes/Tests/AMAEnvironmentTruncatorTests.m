
#import <Kiwi/Kiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMAEnvironmentTruncator.h"

SPEC_BEGIN(AMAEnvironmentTruncatorTests)

describe(@"AMAEnvironmentTruncator", ^{

    AMAEnvironmentTruncator *__block truncator;
    AMATestTruncator *__block keyTruncator;
    AMATestTruncator *__block valueTruncator;
    NSString *truncatedKey1 = @"truncated key 1";
    NSString *truncatedValue1 = @"truncated value 1";
    NSString *truncatedKey2 = @"truncated key 2";
    NSString *truncatedValue2 = @"truncated value 2";
    NSString *truncatedKey3 = @"truncated key 3";
    NSString *truncatedValue3 = @"truncated value 3";
    NSUInteger key1BytesTruncated = 10;
    NSUInteger key2BytesTruncated = 12;
    NSUInteger value1BytesTruncated = 15;
    NSUInteger value2BytesTruncated = 17;
    NSUInteger __block bytesTruncated;
    NSDictionary *__block input;
    NSDictionary *__block result;

    beforeEach(^{
        bytesTruncated = 0;
        keyTruncator = [[AMATestTruncator alloc] init];
        valueTruncator = [[AMATestTruncator alloc] init];
        truncator =
            [[AMAEnvironmentTruncator alloc] initWithParameterKeyTruncator:keyTruncator
                                                   parameterValueTruncator:valueTruncator
                                                        maxParametersCount:2];
    });

    context(@"Key truncation", ^{
        beforeEach(^{
            input = @{ @"key 1" : @"value 1", @"key 2" : @"value 2" };
            [keyTruncator enableTruncationWithResult:truncatedKey1 forArgument:@"key 1" bytesTruncated:key1BytesTruncated];
            [keyTruncator enableTruncationWithResult:truncatedKey2 forArgument:@"key 2" bytesTruncated:key2BytesTruncated];
            result = [truncator truncatedDictionary:input onTruncation:^(NSUInteger newBytesTruncated) {
                bytesTruncated += newBytesTruncated;
            }];
        });
        it(@"Should have valid value", ^{
            [[result should] equal:@{ truncatedKey1 : @"value 1", truncatedKey2 : @"value 2" }];
        });
        it(@"Should fill bytes truncated", ^{
            [[theValue(bytesTruncated) should] equal:theValue(key1BytesTruncated + key2BytesTruncated)];
        });
    });
    context(@"Value truncation", ^{
        beforeEach(^{
            input = @{ @"key 1" : @"value 1", @"key 2" : @"value 2" };
            [valueTruncator enableTruncationWithResult:truncatedValue1 forArgument:@"value 1" bytesTruncated:value1BytesTruncated];
            [valueTruncator enableTruncationWithResult:truncatedValue2 forArgument:@"value 2" bytesTruncated:value2BytesTruncated];
            result = [truncator truncatedDictionary:input onTruncation:^(NSUInteger newBytesTruncated) {
                bytesTruncated += newBytesTruncated;
            }];
        });
        it(@"Should have valid value", ^{
            [[result should] equal:@{ @"key 1" : truncatedValue1, @"key 2" : truncatedValue2 }];
        });
        it(@"Should fill bytes truncated", ^{
            [[theValue(bytesTruncated) should] equal:theValue(value1BytesTruncated + value2BytesTruncated)];
        });
    });
    context(@"Pairs truncation", ^{
        beforeEach(^{
            input = @{ @"key 1" : @"value 1", @"key 2" : @"value 2", @"key 3" : @"value 3" };
            result = [truncator truncatedDictionary:input onTruncation:^(NSUInteger newBytesTruncated) {
                bytesTruncated += newBytesTruncated;
            }];
        });
        it(@"Should have correct count", ^{
            [[theValue(result.count) should] equal:theValue(2)];
        });
        it(@"Should fill bytes truncated", ^{
            [[theValue(bytesTruncated) should] equal:theValue(2 * sizeof(uintptr_t))];
        });
    });
    context(@"Several truncations", ^{
        beforeEach(^{
            input = @{ @"key 1" : @"value 1", @"key 2" : @"value 2", @"key 3" : @"value 3" };
            [keyTruncator enableTruncationWithResult:truncatedKey1 forArgument:@"key 1" bytesTruncated:key1BytesTruncated];
            [keyTruncator enableTruncationWithResult:truncatedKey2 forArgument:@"key 2" bytesTruncated:key1BytesTruncated];
            [keyTruncator enableTruncationWithResult:truncatedKey3 forArgument:@"key 3" bytesTruncated:key1BytesTruncated];
            [valueTruncator enableTruncationWithResult:truncatedValue1 forArgument:@"value 1" bytesTruncated:value1BytesTruncated];
            [valueTruncator enableTruncationWithResult:truncatedValue2 forArgument:@"value 2" bytesTruncated:value1BytesTruncated];
            [valueTruncator enableTruncationWithResult:truncatedValue3 forArgument:@"value 3" bytesTruncated:value1BytesTruncated];
            result = [truncator truncatedDictionary:input onTruncation:^(NSUInteger newBytesTruncated) {
                bytesTruncated += newBytesTruncated;
            }];
        });
        it(@"Should have valid value", ^{
            [[theValue(result.count) should] equal:theValue(2)];
        });
        it(@"Should fill bytes truncated", ^{
            [[theValue(bytesTruncated) should] equal:theValue(2 * sizeof(uintptr_t) + 2 * key1BytesTruncated + 2 * value1BytesTruncated)];
        });
    });
});

SPEC_END
