
#import <Foundation/Foundation.h>
#import <Kiwi/Kiwi.h>
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>
#import <AppMetricaStorageUtils/AppMetricaStorageUtils.h>
#import "AMAAttributionSerializer.h"

SPEC_BEGIN(AMAAttributtionSerializerTests)

describe(@"AMAAttributtionSerializer", ^{

    context(@"toJsonArray", ^{

        NSArray<AMAPair *> *__block input = nil;
        NSArray *__block result = nil;

        context(@"Nil array", ^{

            beforeEach(^{
                input = nil;
                result = [AMAAttributionSerializer toJsonArray:input];
            });

            it(@"Result should be empty", ^{
                [[result shouldNot] beNil];
                [[theValue(result.count) should] beZero];
            });
            it (@"Result should be immutable", ^{
                [[result shouldNot] beKindOfClass: [NSMutableArray class]];
            });
        });

        context(@"Empty array", ^{

            beforeEach(^{
                input = @[];
                result = [AMAAttributionSerializer toJsonArray:input];
            });

            it(@"Result should be empty", ^{
                [[result shouldNot] beNil];
                [[theValue(result.count) should] beZero];
            });
            it (@"Result should be immutable", ^{
                [[result shouldNot] beKindOfClass: [NSMutableArray class]];
            });
        });

        context(@"Has single element", ^{

            NSString *key = @"some key";
            NSString *value = @"some value";

            beforeEach(^{
                input = @[ [[AMAPair alloc] initWithKey:key value:value] ];
                result = [AMAAttributionSerializer toJsonArray:input];
            });

            it(@"Result should have one element", ^{
                [[theValue(result.count) should] equal:theValue(1)];
            });
            it(@"Result should have the right element", ^{
                [[result should] equal:@[ @{ @"key" : key, @"value" : value } ]];
            });
            it (@"Result should be immutable", ^{
                [[result shouldNot] beKindOfClass: [NSMutableArray class]];
            });
        });

        context(@"Has multiple elements", ^{

            NSString *firstKey = @"some key 1";
            NSString *firstValue = @"some value 1";
            NSString *secondKey = @"some key 2";
            NSString *secondValue = @"some value 2";

            beforeEach(^{
                input = @[
                    [[AMAPair alloc] initWithKey:firstKey value:firstValue],
                    [[AMAPair alloc] initWithKey:secondKey value:secondValue]
                ];
                result = [AMAAttributionSerializer toJsonArray:input];
            });

            it(@"Result should have two elements", ^{
                [[theValue(result.count) should] equal:theValue(2)];
            });
            it(@"Result should have the right element", ^{
                [[result should] equal:@[
                    @{ @"key" : firstKey, @"value" : firstValue },
                    @{ @"key" : secondKey, @"value" : secondValue }
                ]];
            });
            it (@"Result should be immutable", ^{
                [[result shouldNot] beKindOfClass: [NSMutableArray class]];
            });
        });

        context(@"Element has nil key", ^{

            NSString *value = @"some value";

            beforeEach(^{
                input = @[ [[AMAPair alloc] initWithKey:nil value:value] ];
                result = [AMAAttributionSerializer toJsonArray:input];
            });

            it(@"Result should have one element", ^{
                [[theValue(result.count) should] equal:theValue(1)];
            });
            it(@"Result should have the right element", ^{
                [[result should] equal:@[ @{ @"value" : value } ]];
            });
            it (@"Result should be immutable", ^{
                [[result shouldNot] beKindOfClass: [NSMutableArray class]];
            });
        });

        context(@"Element has nil value", ^{

            NSString *key = @"some key";

            beforeEach(^{
                input = @[ [[AMAPair alloc] initWithKey:key value:nil] ];
                result = [AMAAttributionSerializer toJsonArray:input];
            });

            it(@"Result should have one element", ^{
                [[theValue(result.count) should] equal:theValue(1)];
            });
            it(@"Result should have the right element", ^{
                [[result should] equal:@[ @{ @"key" : key } ]];
            });
            it (@"Result should be immutable", ^{
                [[result shouldNot] beKindOfClass: [NSMutableArray class]];
            });
        });

        context(@"Element has nil key and nil value", ^{

            beforeEach(^{
                input = @[ [[AMAPair alloc] initWithKey:nil value:nil] ];
                result = [AMAAttributionSerializer toJsonArray:input];
            });

            it(@"Result should have one element", ^{
                [[theValue(result.count) should] equal:theValue(1)];
            });
            it(@"Result should have the right element", ^{
                [[result should] equal:@[ @{ } ]];
            });
            it (@"Result should be immutable", ^{
                [[result shouldNot] beKindOfClass: [NSMutableArray class]];
            });
        });

    });

    context(@"fromJsonArray", ^{

        NSArray *__block input = nil;
        NSArray<AMAPair *> *__block result = nil;

        context(@"Nil array", ^{

            beforeEach(^{
                input = nil;
                result = [AMAAttributionSerializer fromJsonArray:input];
            });

            it(@"Result should be empty", ^{
                [[result shouldNot] beNil];
                [[theValue(result.count) should] beZero];
            });
            it (@"Result should be immutable", ^{
                [[result shouldNot] beKindOfClass: [NSMutableArray class]];
            });
        });

        context(@"Empty array", ^{

            beforeEach(^{
                input = @[];
                result = [AMAAttributionSerializer fromJsonArray:input];
            });

            it(@"Result should be empty", ^{
                [[result shouldNot] beNil];
                [[theValue(result.count) should] beZero];
            });
            it (@"Result should be immutable", ^{
                [[result shouldNot] beKindOfClass: [NSMutableArray class]];
            });
        });

        context(@"Has single element", ^{

            NSString *key = @"some key";
            NSString *value = @"some value";

            beforeEach(^{
                input = @[ @{ @"key" : key, @"value" : value } ];
                result = [AMAAttributionSerializer fromJsonArray:input];
            });

            it(@"Result should have one element", ^{
                [[theValue(result.count) should] equal:theValue(1)];
            });
            it(@"Result should have the right element", ^{
                [[result[0].key should] equal:key];
                [[result[0].value should] equal:value];
            });
            it (@"Result should be immutable", ^{
                [[result shouldNot] beKindOfClass: [NSMutableArray class]];
            });
        });

        context(@"Has multiple elements", ^{

            NSString *firstKey = @"some key 1";
            NSString *firstValue = @"some value 1";
            NSString *secondKey = @"some key 2";
            NSString *secondValue = @"some value 2";

            beforeEach(^{
                input = @[
                    @{ @"key" : firstKey, @"value" : firstValue },
                    @{ @"key" : secondKey, @"value" : secondValue }
                ];
                result = [AMAAttributionSerializer fromJsonArray:input];
            });

            it(@"Result should have two elements", ^{
                [[theValue(result.count) should] equal:theValue(2)];
            });
            it(@"Result should have the right element", ^{
                [[result[0].key should] equal:firstKey];
                [[result[0].value should] equal:firstValue];
                [[result[1].key should] equal:secondKey];
                [[result[1].value should] equal:secondValue];
            });
            it (@"Result should be immutable", ^{
                [[result shouldNot] beKindOfClass: [NSMutableArray class]];
            });
        });

        context(@"Element has nil key", ^{

            NSString *value = @"some value";

            beforeEach(^{
                input = @[ @{ @"value" : value } ];
                result = [AMAAttributionSerializer fromJsonArray:input];
            });

            it(@"Result should have one element", ^{
                [[theValue(result.count) should] equal:theValue(1)];
            });
            it(@"Result should have the right element", ^{
                [[result[0].key should] beNil];
                [[result[0].value should] equal:value];
            });
            it (@"Result should be immutable", ^{
                [[result shouldNot] beKindOfClass: [NSMutableArray class]];
            });
        });

        context(@"Element has nil value", ^{

            NSString *key = @"some key";

            beforeEach(^{
                input = @[ @{ @"key" : key } ];
                result = [AMAAttributionSerializer fromJsonArray:input];
            });

            it(@"Result should have one element", ^{
                [[theValue(result.count) should] equal:theValue(1)];
            });
            it(@"Result should have the right element", ^{
                [[result[0].key should] equal:key];
                [[result[0].value should] beNil];
            });
            it (@"Result should be immutable", ^{
                [[result shouldNot] beKindOfClass: [NSMutableArray class]];
            });
        });
        context(@"Element has nil key and nil value", ^{

            beforeEach(^{
                input = @[ @{} ];
                result = [AMAAttributionSerializer fromJsonArray:input];
            });

            it(@"Result should have one element", ^{
                [[theValue(result.count) should] equal:theValue(1)];
            });
            it(@"Result should have the right element", ^{
                [[result[0].key should] beNil];
                [[result[0].value should] beNil];
            });
            it (@"Result should be immutable", ^{
                [[result shouldNot] beKindOfClass: [NSMutableArray class]];
            });
        });

        context(@"Element has non-string key and value", ^{

            beforeEach(^{
                input = @[ @{ @"key" : @12, @"value" : @13 } ];
                result = [AMAAttributionSerializer fromJsonArray:input];
            });

            it(@"Result should be empty", ^{
                [[result shouldNot] beNil];
                [[theValue(result.count) should] beZero];
            });
            it (@"Result should be immutable", ^{
                [[result shouldNot] beKindOfClass: [NSMutableArray class]];
            });
        });

        context(@"Has single non dictionary element", ^{

            beforeEach(^{
                input = @[ @"key", @"value" ];
                result = [AMAAttributionSerializer fromJsonArray:input];
            });

            it(@"Result should be empty", ^{
                [[result shouldNot] beNil];
                [[theValue(result.count) should] beZero];
            });
            it (@"Result should be immutable", ^{
                [[result shouldNot] beKindOfClass: [NSMutableArray class]];
            });
        });

    });

});

SPEC_END
