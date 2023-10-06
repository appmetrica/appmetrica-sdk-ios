
#import <Kiwi/Kiwi.h>
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>

SPEC_BEGIN(AMACollectionUtilitiesTests)

describe(@"AMACollectionUtilities", ^{

    context(@"dictionaryByRemovingEmptyStringValuesForDictionary:", ^{
        it(@"Should return empty for empty dictionary", ^{
            NSDictionary *result = [AMACollectionUtilities dictionaryByRemovingEmptyStringValuesForDictionary:@{}];
            [[result should] equal:@{}];
        });
        it(@"Should remove one empty value", ^{
            NSDictionary *source = @{ @"foo": @"", @"bar": @"foo" };
            NSDictionary *result = [AMACollectionUtilities dictionaryByRemovingEmptyStringValuesForDictionary:source];
            [[result should] equal:@{ @"bar": @"foo" }];
        });
        it(@"Should remove two empty values", ^{
            NSDictionary *source = @{ @"foo1": @"", @"foo2": @"", @"bar": @"foo" };
            NSDictionary *result = [AMACollectionUtilities dictionaryByRemovingEmptyStringValuesForDictionary:source];
            [[result should] equal:@{ @"bar": @"foo" }];
        });
        it(@"Should not change valid dictionary", ^{
            NSDictionary *source = @{ @"bar1": @1, @"bar2": @[], @"bar3": @"foo" };
            NSDictionary *result = [AMACollectionUtilities dictionaryByRemovingEmptyStringValuesForDictionary:source];
            [[result should] equal:source];
        });
        it(@"Should leave non-strings", ^{
            NSDictionary *source = @{ @"foo1": @"", @"bar1": @1, @"bar2": @[], @"bar3": [NSNull null] };
            NSDictionary *result = [AMACollectionUtilities dictionaryByRemovingEmptyStringValuesForDictionary:source];
            [[result should] equal:@{ @"bar1": @1, @"bar2": @[], @"bar3": [NSNull null] }];
        });
    });

    context(@"areAllItemsOfDictionary:matchBlock:", ^{
        it(@"Should return YES for empty dictionary", ^{
            BOOL result = [AMACollectionUtilities areAllItemsOfDictionary:@{} matchBlock:^BOOL(id key, id value) {
                return NO;
            }];
            [[theValue(result) should] beYes];
        });
        it(@"Should return YES for constant-YES block", ^{
            NSDictionary *source = @{ @"foo": @"bar", @"bar": @"foo" };
            BOOL result = [AMACollectionUtilities areAllItemsOfDictionary:source matchBlock:^BOOL(id key, id value) {
                return YES;
            }];
            [[theValue(result) should] beYes];
        });
        it(@"Should return NO for constant-NO block", ^{
            NSDictionary *source = @{ @"foo": @"bar", @"bar": @"foo" };
            BOOL result = [AMACollectionUtilities areAllItemsOfDictionary:source matchBlock:^BOOL(id key, id value) {
                return NO;
            }];
            [[theValue(result) should] beNo];
        });
        it(@"Should return NO for single-NO-returning block", ^{
            NSDictionary *source = @{ @"foo": @"bar", @"bar1": @"foo", @"bar2": @"foo" };
            BOOL result = [AMACollectionUtilities areAllItemsOfDictionary:source matchBlock:^BOOL(id key, id value) {
                return [key isEqualToString:@"foo"] == NO;
            }];
            [[theValue(result) should] beNo];
        });
        it(@"Should pass all key-value pairs through constant-YES block", ^{
            NSDictionary *source = @{ @"foo": @"bar", @"bar": @"foo" };
            NSMutableArray *keyValuePairs = [NSMutableArray array];
            [AMACollectionUtilities areAllItemsOfDictionary:source matchBlock:^BOOL(id key, id value) {
                [keyValuePairs addObject:@[ key, value ]];
                return YES;
            }];
            [[keyValuePairs should] equal:@[ @[@"foo", @"bar"], @[@"bar", @"foo"] ]];
        });
    });

    context(@"mapArray:withBlock:", ^{
        it(@"Should return empty for empty array", ^{
            NSArray *result = [AMACollectionUtilities mapArray:@[] withBlock:^id(NSString *item) {
                return item;
            }];
            [[result should] equal:@[]];
        });
        it(@"Should return correct mapped array", ^{
            NSArray *source = @[ @"1", @"3", @"5" ];
            NSArray *result = [AMACollectionUtilities mapArray:source withBlock:^id(NSString *item) {
                return @([item integerValue]);
            }];
            [[result should] equal:@[ @1, @3, @5 ]];
        });
        it(@"Should remove nil-mapped items", ^{
            NSArray *source = @[ @"1", @"3", @"5" ];
            NSArray *result = [AMACollectionUtilities mapArray:source withBlock:^id(NSString *item) {
                if ([item isEqualToString:@"3"]) {
                    return nil;
                }
                return @([item integerValue]);
            }];
            [[result should] equal:@[ @1, @5 ]];
        });
    });

    context(@"areAllItemsOfArray:matchBlock:", ^{
        it(@"Should return YES for empty dictionary", ^{
            BOOL result = [AMACollectionUtilities areAllItemsOfArray:@[] matchBlock:^BOOL(id item) {
                return NO;
            }];
            [[theValue(result) should] beYes];
        });
        it(@"Should return YES for constant-YES block", ^{
            NSArray *source = @[ @"foo", @"bar" ];
            BOOL result = [AMACollectionUtilities areAllItemsOfArray:source matchBlock:^BOOL(id item) {
                return YES;
            }];
            [[theValue(result) should] beYes];
        });
        it(@"Should return NO for constant-NO block", ^{
            NSArray *source = @[ @"foo", @"bar" ];
            BOOL result = [AMACollectionUtilities areAllItemsOfArray:source matchBlock:^BOOL(id item) {
                return NO;
            }];
            [[theValue(result) should] beNo];
        });
        it(@"Should return NO for single-NO-returning block", ^{
            NSArray *source = @[ @"foo", @"bar", @"foobar" ];
            BOOL result = [AMACollectionUtilities areAllItemsOfArray:source matchBlock:^BOOL(id item) {
                return [item isEqual:@"foo"] == NO;
            }];
            [[theValue(result) should] beNo];
        });
        it(@"Should pass all key-value pairs through constant-YES block", ^{
            NSArray *source = @[ @"foo", @"bar", @"foobar" ];
            NSMutableArray *passedItems = [NSMutableArray array];
            [AMACollectionUtilities areAllItemsOfArray:source matchBlock:^BOOL(id item) {
                [passedItems addObject:item];
                return YES;
            }];
            [[passedItems should] equal:source];
        });
    });

    context(@"removeItemsFromArray:withBlock:", ^{
        it(@"Should not raise for empty array", ^{
            [[theBlock(^{
                [AMACollectionUtilities removeItemsFromArray:[NSMutableArray array]
                                                   withBlock:^(id item, BOOL *remove) {}];
            }) shouldNot] raise];
        });
        it(@"Should not change array if nothing is marked to be removed", ^{
            NSMutableArray *array = [@[ @1, @2, @3 ] mutableCopy];
            [AMACollectionUtilities removeItemsFromArray:array withBlock:^(NSNumber *item, BOOL *remove) {}];
            [[[array copy] should] equal:@[ @1, @2, @3 ]];
        });
        it(@"Should remove single element", ^{
            NSMutableArray *array = [@[ @1, @2, @3 ] mutableCopy];
            [AMACollectionUtilities removeItemsFromArray:array withBlock:^(NSNumber *item, BOOL *remove) {
                if ([item isEqualToNumber:@2]) {
                    *remove = YES;
                }
            }];
            [[[array copy] should] equal:@[ @1, @3 ]];
        });
        it(@"Should remove odd elements", ^{
            NSMutableArray *array = [@[ @1, @2, @3, @4, @5 ] mutableCopy];
            [AMACollectionUtilities removeItemsFromArray:array withBlock:^(NSNumber *item, BOOL *remove) {
                if (item.integerValue % 2 == 0) {
                    *remove = YES;
                }
            }];
            [[[array copy] should] equal:@[ @1, @3, @5 ]];
        });
        it(@"Should remove single element", ^{
            NSMutableArray *array = [@[ @1, @2, @3 ] mutableCopy];
            [AMACollectionUtilities removeItemsFromArray:array withBlock:^(NSNumber *item, BOOL *remove) {
                *remove = YES;
            }];
            [[[array copy] should] beEmpty];
        });
    });

    context(@"mapValuesOfDictionary:withBlock:", ^{
        it(@"Should return empty for empty dictionary", ^{
            NSDictionary *result = [AMACollectionUtilities compactMapValuesOfDictionary:@{}
                                                                              withBlock:^id(id key, id value) {
                return value;
            }];
            [[result should] equal:@{}];
        });
        it(@"Should return correct mapped dictionary", ^{
            NSDictionary *source = @{ @"a" : @"1", @"b" : @"3", @"c" : @"5" };
            NSDictionary *result = [AMACollectionUtilities compactMapValuesOfDictionary:source
                                                                              withBlock:^id(id key, id value) {
                return @([value integerValue]);
            }];
            [[result should] equal:@{ @"a" : @1, @"b" : @3, @"c" : @5 }];
        });
        it(@"Should remove nil-mapped items", ^{
            NSDictionary *source = @{ @"a" : @"1", @"b" : @"3", @"c" : @"5" };
            NSDictionary *result = [AMACollectionUtilities compactMapValuesOfDictionary:source
                                                                              withBlock:^id(id key, id value) {
                return [key isEqual:@"a"] ? nil : @([value integerValue]);
            }];
            [[result should] equal:@{ @"b" : @3, @"c" : @5 }];
        });
        it(@"Should return empty dictionary for all values mapsed to nil", ^{
            NSDictionary *source = @{ @"a" : @"1", @"b" : @"3", @"c" : @"5" };
            NSDictionary *result = [AMACollectionUtilities compactMapValuesOfDictionary:source
                                                                              withBlock:^id(id key, id value) {
                return nil;
            }];
            [[result should] equal:@{}];
        });
    });

    context(@"filteredDictionary:withKeys:", ^{
        it(@"Should return empty dictionary for empty source dictionary", ^{
            NSDictionary *result = [AMACollectionUtilities filteredDictionary:@{} withKeys:[NSSet set]];
            [[result should] equal:@{}];
        });
        it(@"Should return empty dictionary for non-matching keys", ^{
            NSDictionary *source = @{ @"key1": @"value1", @"key2": @"value2" };
            NSDictionary *result = [AMACollectionUtilities filteredDictionary:source
                                                                     withKeys:[NSSet setWithArray:@[@"key3"]]];
            [[result should] equal:@{}];
        });
        it(@"Should filter dictionary with one matching key", ^{
            NSDictionary *source = @{ @"key1": @"value1", @"key2": @"value2", @"key3": @"value3" };
            NSDictionary *result = [AMACollectionUtilities filteredDictionary:source
                                                                     withKeys:[NSSet setWithArray:@[@"key1"]]];
            [[result should] equal:@{ @"key1": @"value1" }];
        });
        it(@"Should filter dictionary with multiple matching keys", ^{
            NSDictionary *source = @{ @"key1": @"value1", @"key2": @"value2", @"key3": @"value3" };
            NSDictionary *result = [AMACollectionUtilities filteredDictionary:source
                                                                     withKeys:[NSSet setWithArray:@[@"key1", @"key3"]]];
            [[result should] equal:@{ @"key1": @"value1", @"key3": @"value3" }];
        });
    });

    context(@"flatMapArray:withBlock:", ^{
        it(@"Should return empty array for empty source", ^{
            NSArray *result = [AMACollectionUtilities flatMapArray:@[] withBlock:^NSArray *(id item) {
                return @[item, item];
            }];
            [[result should] equal:@[]];
        });
        it(@"Should flatten and map items correctly", ^{
            NSArray *source = @[ @"a", @"b" ];
            NSArray *result = [AMACollectionUtilities flatMapArray:source withBlock:^NSArray *(NSString *item) {
                return @[item, [item stringByAppendingString:item]];
            }];
            [[result should] equal:@[ @"a", @"aa", @"b", @"bb" ]];
        });
        it(@"Should exclude items resulting in empty arrays", ^{
            NSArray *source = @[ @"a", @"b", @"c" ];
            NSArray *result = [AMACollectionUtilities flatMapArray:source withBlock:^NSArray *(NSString *item) {
                return [item isEqualToString:@"b"] ? @[] : @[item];
            }];
            [[result should] equal:@[ @"a", @"c" ]];
        });
    });

    context(@"filteredArray:withPredicate:", ^{
        it(@"Should return empty array for empty source", ^{
            NSArray *result = [AMACollectionUtilities filteredArray:@[] withPredicate:^BOOL(id item) {
                return YES;
            }];
            [[result should] equal:@[]];
        });
        it(@"Should return source array for constant-YES predicate", ^{
            NSArray *source = @[ @1, @2, @3 ];
            NSArray *result = [AMACollectionUtilities filteredArray:source withPredicate:^BOOL(NSNumber *item) {
                return YES;
            }];
            [[result should] equal:source];
        });
        it(@"Should return empty array for constant-NO predicate", ^{
            NSArray *source = @[ @1, @2, @3 ];
            NSArray *result = [AMACollectionUtilities filteredArray:source withPredicate:^BOOL(NSNumber *item) {
                return NO;
            }];
            [[result should] equal:@[]];
        });
        it(@"Should filter out non-matching items", ^{
            NSArray *source = @[ @1, @2, @3, @4 ];
            NSArray *result = [AMACollectionUtilities filteredArray:source withPredicate:^BOOL(NSNumber *item) {
                return item.intValue % 2 == 0;
            }];
            [[result should] equal:@[ @2, @4 ]];
        });
    });
});

SPEC_END
