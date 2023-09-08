
#import <Kiwi/Kiwi.h>
#import "AMAECommerceTruncator.h"
#import "AMAECommerce+Internal.h"

SPEC_BEGIN(AMAECommerceTruncatorTests)

describe(@"AMAECommerceTruncator", ^{

    AMAECommerce *__block event = nil;
    AMAECommerceTruncator *__block truncator = nil;

    __auto_type screen = ^{
        return [[AMAECommerceScreen alloc] initWithName:@"NAME"
                                     categoryComponents:@[ @"A", @"B", @"C"]
                                            searchQuery:@"QUERY"
                                                payload:@{ @"A": @"B" }];
    };
    __auto_type number = ^{
        return [[NSDecimalNumber alloc] initWithInt:23];
    };
    __auto_type amount = ^{
        return [[AMAECommerceAmount alloc] initWithUnit:@"UNIT"
                                                  value:number()];
    };
    __auto_type price = ^{
        return [[AMAECommercePrice alloc] initWithFiat:amount()
                                    internalComponents:@[ amount(), amount() ]];
    };
    __auto_type product = ^{
        return [[AMAECommerceProduct alloc] initWithSKU:@"SKU"
                                                   name:@"NAME"
                                     categoryComponents:@[ @"B", @"C", @"D"]
                                                payload:@{ @"B": @"C" }
                                            actualPrice:price()
                                          originalPrice:price()
                                             promoCodes:@[ @"C", @"D", @"E"]];
    };
    __auto_type referrer = ^{
        return [[AMAECommerceReferrer alloc] initWithType:@"TYPE"
                                               identifier:@"IDENTIFIER"
                                                   screen:screen()];
    };
    __auto_type cartItem = ^{
        return [[AMAECommerceCartItem alloc] initWithProduct:product()
                                                    quantity:number()
                                                     revenue:price()
                                                    referrer:referrer()];
    };
    __auto_type order = ^{
        return [[AMAECommerceOrder alloc] initWithIdentifier:@"IDENTIFIER"
                                                   cartItems:@[ cartItem(), cartItem() ]
                                                     payload:@{ @"C": @"D" }];
    };

    beforeEach(^{
        event = [[AMAECommerce alloc] initWithEventType:AMAECommerceEventTypePurchase
                                                 screen:screen()
                                                product:product()
                                               referrer:referrer()
                                               cartItem:cartItem()
                                                  order:order()
                                         bytesTruncated:0];
        truncator = [[AMAECommerceTruncator alloc] init];
    });

    __auto_type truncated = ^{
        return [truncator truncatedECommerce:event];
    };
    __auto_type longString = ^(NSUInteger length) {
        NSMutableString *result = [NSMutableString stringWithCapacity:length];
        for (NSUInteger idx = 0; idx < length; ++idx) {
            [result appendFormat:@"%c", (char)('a' + (idx % ('z' - 'a')))];
        }
        return result;
    };
    __auto_type longArray = ^(NSUInteger count, id(^itemProvider)(void)) {
        NSMutableArray *result = [NSMutableArray array];
        for (NSUInteger idx = 0; idx < count; ++idx) {
            [result addObject:itemProvider()];
        }
        return result;
    };

    context(@"Screen", ^{
        context(@"Name", ^{
            context(@"Within limits", ^{
                beforeEach(^{
                    [event.screen stub:@selector(name) andReturn:longString(100)];
                });
                it(@"Should not truncate within limits", ^{
                    [[truncated().screen.name should] equal:event.screen.name];
                });
                it(@"Should not update bytesTruncated", ^{
                    [[theValue(truncated().bytesTruncated) should] beZero];
                });
            });
            context(@"Out of limits", ^{
                beforeEach(^{
                    [event.screen stub:@selector(name) andReturn:longString(103)];
                });
                it(@"Should truncate within limits", ^{
                    [[truncated().screen.name should] equal:longString(100)];
                });
                it(@"Should update bytesTruncated", ^{
                    [[theValue(truncated().bytesTruncated) should] equal:theValue(3)];
                });
            });
            context(@"Out of limits with unicode", ^{
                NSString *__block expectedValue = nil;
                beforeEach(^{
                    NSMutableString *value = [longString(99) mutableCopy];
                    [value appendString:@"й"];
                    expectedValue = [value copy];
                    [value appendString:@"йⅧが"];
                    [event.screen stub:@selector(name) andReturn:value];
                });
                it(@"Should truncate within limits", ^{
                    [[truncated().screen.name should] equal:expectedValue];
                });
                it(@"Should update bytesTruncated", ^{
                    [[theValue(truncated().bytesTruncated) should] equal:theValue(8)];
                });
            });
        });
        context(@"Category Components", ^{
            context(@"Item size", ^{
                context(@"Within limits", ^{
                    beforeEach(^{
                        [event.screen stub:@selector(categoryComponents) andReturn:@[ longString(100) ]];
                    });
                    it(@"Should not truncate within limits", ^{
                        [[truncated().screen.categoryComponents should] equal:event.screen.categoryComponents];
                    });
                    it(@"Should not update bytesTruncated", ^{
                        [[theValue(truncated().bytesTruncated) should] beZero];
                    });
                });
                context(@"Out of limits", ^{
                    beforeEach(^{
                        [event.screen stub:@selector(categoryComponents) andReturn:@[ longString(105) ]];
                    });
                    it(@"Should truncate within limits", ^{
                        [[truncated().screen.categoryComponents should] equal:@[ longString(100) ]];
                    });
                    it(@"Should update bytesTruncated", ^{
                        [[theValue(truncated().bytesTruncated) should] equal:theValue(5)];
                    });
                });
            });
            context(@"Count", ^{
                context(@"Within limits", ^{
                    beforeEach(^{
                        [event.screen stub:@selector(categoryComponents) andReturn:longArray(20, ^{ return @"A"; })];
                    });
                    it(@"Should not truncate within limits", ^{
                        [[truncated().screen.categoryComponents should] equal:event.screen.categoryComponents];
                    });
                    it(@"Should not update bytesTruncated", ^{
                        [[theValue(truncated().bytesTruncated) should] beZero];
                    });
                });
                context(@"Out of limits", ^{
                    beforeEach(^{
                        [event.screen stub:@selector(categoryComponents) andReturn:longArray(21, ^{ return @"A"; })];
                    });
                    it(@"Should truncate within limits", ^{
                        [[truncated().screen.categoryComponents should] equal:longArray(20, ^{ return @"A"; })];
                    });
                    it(@"Should update bytesTruncated", ^{
                        [[theValue(truncated().bytesTruncated) should] equal:theValue(1)];
                    });
                });
            });
        });
        context(@"Search query", ^{
            context(@"Within limits", ^{
                beforeEach(^{
                    [event.screen stub:@selector(searchQuery) andReturn:longString(1000)];
                });
                it(@"Should not truncate within limits", ^{
                    [[truncated().screen.searchQuery should] equal:event.screen.searchQuery];
                });
                it(@"Should not update bytesTruncated", ^{
                    [[theValue(truncated().bytesTruncated) should] beZero];
                });
            });
            context(@"Out of limits", ^{
                beforeEach(^{
                    [event.screen stub:@selector(searchQuery) andReturn:longString(1005)];
                });
                it(@"Should truncate within limits", ^{
                    [[truncated().screen.searchQuery should] equal:longString(1000)];
                });
                it(@"Should update bytesTruncated", ^{
                    [[theValue(truncated().bytesTruncated) should] equal:theValue(5)];
                });
            });
        });
        context(@"Payload", ^{
            context(@"Key size", ^{
                context(@"Within limits", ^{
                    beforeEach(^{
                        [event.screen.internalPayload stub:@selector(pairs) andReturn:@{ longString(100): @"A" }];
                    });
                    it(@"Should not truncate within limits", ^{
                        [[truncated().screen.payload should] equal:event.screen.payload];
                    });
                    it(@"Should not update bytesTruncated", ^{
                        [[theValue(truncated().bytesTruncated) should] beZero];
                    });
                });
                context(@"Out of limits", ^{
                    beforeEach(^{
                        [event.screen.internalPayload stub:@selector(pairs) andReturn:@{ longString(107): @"A" }];
                    });
                    it(@"Should truncate within limits", ^{
                        [[truncated().screen.payload should] equal:@{ longString(100): @"A" }];
                    });
                    it(@"Should update bytesTruncated", ^{
                        [[theValue(truncated().bytesTruncated) should] equal:theValue(7)];
                    });
                });
            });
            context(@"Value size", ^{
                context(@"Within limits", ^{
                    beforeEach(^{
                        [event.screen.internalPayload stub:@selector(pairs) andReturn:@{ @"A": longString(1000) }];
                    });
                    it(@"Should not truncate within limits", ^{
                        [[truncated().screen.payload should] equal:event.screen.payload];
                    });
                    it(@"Should not update bytesTruncated", ^{
                        [[theValue(truncated().bytesTruncated) should] beZero];
                    });
                });
                context(@"Out of limits", ^{
                    beforeEach(^{
                        [event.screen.internalPayload stub:@selector(pairs) andReturn:@{ @"A": longString(1008) }];
                    });
                    it(@"Should truncate within limits", ^{
                        [[truncated().screen.payload should] equal:@{ @"A": longString(1000) }];
                    });
                    it(@"Should update bytesTruncated", ^{
                        [[theValue(truncated().bytesTruncated) should] equal:theValue(8)];
                    });
                });
            });
            context(@"Total size", ^{
                __auto_type keyAt = ^(NSUInteger index) {
                    return longString(24 + index);
                };
                __auto_type valueAt = ^(NSUInteger index) {
                    return longString(1000 - index);
                };
                NSMutableDictionary<NSString *, NSString *> *__block payload = nil;
                NSMutableDictionary<NSString *, NSString *> *__block expectedPayload = nil;
                beforeEach(^{
                    payload = [NSMutableDictionary dictionary];
                    for (NSUInteger idx = 0; idx < 20; ++idx) {
                        payload[keyAt(idx)] = valueAt(idx);
                    }
                    // Size of each pair (key + value) is always 1024 bytes (see `keyAt` and `valueAt`).
                    // The total size of this payload is 20 Kb.
                });

                context(@"Within limits", ^{
                    beforeEach(^{
                        expectedPayload = [payload mutableCopy];
                        [event.screen.internalPayload stub:@selector(pairs) andReturn:payload];
                    });
                    it(@"Should not truncate within limits", ^{
                        [[truncated().screen.payload should] equal:expectedPayload];
                    });
                    it(@"Should not update bytesTruncated", ^{
                        [[theValue(truncated().bytesTruncated) should] beZero];
                    });
                    it(@"Should not update truncated pairs count", ^{
                        [[theValue(truncated().screen.internalPayload.truncatedPairsCount) should] beZero];
                    });
                });
                context(@"Out of limits", ^{
                    beforeEach(^{
                        // Increase the size of 10-th value
                        payload[keyAt(10)] = [payload[keyAt(10)] stringByAppendingString:@"A"];
                        expectedPayload = [payload mutableCopy];
                        expectedPayload[keyAt(0)] = nil; // We drop the max-sized pair, everything else fits
                        [event.screen.internalPayload stub:@selector(pairs) andReturn:payload];
                    });
                    it(@"Should truncate within limits", ^{
                        [[truncated().screen.payload should] equal:expectedPayload];
                    });
                    it(@"Should update bytesTruncated", ^{
                        // Should drop one pair = 1024 bytes
                        [[theValue(truncated().bytesTruncated) should] equal:theValue(1024)];
                    });
                    it(@"Should update truncated pairs count", ^{
                        [[theValue(truncated().screen.internalPayload.truncatedPairsCount) should] equal:theValue(1)];
                    });
                });
                context(@"Out of limits with smaller pairs", ^{
                    beforeEach(^{
                        // Increase the size of 10-th value
                        payload[keyAt(10)] = [payload[keyAt(10)] stringByAppendingString:@"A"];
                        // And add 256 pairs of 4 bytes each (1024 B)
                        for (NSUInteger idx = 0; idx < 256; ++idx) {
                            NSString *key = [NSString stringWithFormat:@"%c%c",
                                             (char)('A' + idx / ('Z' - 'A') % ('Z' - 'A')),
                                             (char)('A' + idx % ('Z' - 'A'))];
                            payload[key] = @"XX";
                        }

                        // So now the first 2 pairs should not fit (largest ones, see `valueAt`)
                        expectedPayload = [payload mutableCopy];
                        expectedPayload[keyAt(0)] = nil;
                        expectedPayload[keyAt(1)] = nil;

                        [event.screen.internalPayload stub:@selector(pairs) andReturn:payload];
                    });
                    it(@"Should truncate within limits", ^{
                        [[truncated().screen.payload should] equal:expectedPayload];
                    });
                    it(@"Should update bytesTruncated", ^{
                        // Should drop two pairs = 2 * 1024 bytes
                        [[theValue(truncated().bytesTruncated) should] equal:theValue(2048)];
                    });
                    it(@"Should update truncated pairs count", ^{
                        [[theValue(truncated().screen.internalPayload.truncatedPairsCount) should] equal:theValue(2)];
                    });
                });
                context(@"Out of limits with keys and values out of limit", ^{
                    NSUInteger __block expectedBytesTruncated = 0;
                    beforeEach(^{
                        expectedBytesTruncated = 0;

                        // Leave place for extra pairs
                        payload[keyAt(0)] = nil;
                        payload[keyAt(1)] = nil;

                        // This pair has the biggest value so it will be truncated
                        payload[@"A"] = longString(1002);
                        expectedBytesTruncated += 1 + 1002;

                        // For this pair only value will be truncated
                        payload[@"B"] = longString(1001);
                        expectedBytesTruncated += 1;

                        // For this pair key will be truncated
                        NSString *truncatedKey = [longString(99) stringByAppendingString:@"ы"];
                        NSString *longKey = [truncatedKey stringByAppendingString:@"й"];
                        payload[longKey] = @"B";
                        expectedBytesTruncated += 2; // size of 'й'

                        expectedPayload = [payload mutableCopy];
                        // First pair is truncated
                        expectedPayload[@"A"] = nil;

                        // Second pair has truncated value
                        expectedPayload[@"B"] = longString(1000);

                        // Update truncated key
                        expectedPayload[truncatedKey] = expectedPayload[longKey];
                        expectedPayload[longKey] = nil;

                        [event.screen.internalPayload stub:@selector(pairs) andReturn:payload];
                    });
                    it(@"Should truncate within limits", ^{
                        [[truncated().screen.payload should] equal:expectedPayload];
                    });
                    it(@"Should update bytesTruncated", ^{
                        [[theValue(truncated().bytesTruncated) should] equal:theValue(expectedBytesTruncated)];
                    });
                    it(@"Should update truncated pairs count", ^{
                        [[theValue(truncated().screen.internalPayload.truncatedPairsCount) should] equal:theValue(1)];
                    });
                });
            });
        });
    });

    context(@"Product", ^{
        context(@"SKU", ^{
            context(@"Within limits", ^{
                beforeEach(^{
                    [event.product stub:@selector(sku) andReturn:longString(100)];
                });
                it(@"Should not truncate within limits", ^{
                    [[truncated().product.sku should] equal:event.product.sku];
                });
                it(@"Should not update bytesTruncated", ^{
                    [[theValue(truncated().bytesTruncated) should] beZero];
                });
            });
            context(@"Out of limits", ^{
                beforeEach(^{
                    [event.product stub:@selector(sku) andReturn:longString(103)];
                });
                it(@"Should truncate within limits", ^{
                    [[truncated().product.sku should] equal:longString(100)];
                });
                it(@"Should update bytesTruncated", ^{
                    [[theValue(truncated().bytesTruncated) should] equal:theValue(3)];
                });
            });
        });
        context(@"Name", ^{
            context(@"Within limits", ^{
                beforeEach(^{
                    [event.product stub:@selector(name) andReturn:longString(1000)];
                });
                it(@"Should not truncate within limits", ^{
                    [[truncated().product.name should] equal:event.product.name];
                });
                it(@"Should not update bytesTruncated", ^{
                    [[theValue(truncated().bytesTruncated) should] beZero];
                });
            });
            context(@"Out of limits", ^{
                beforeEach(^{
                    [event.product stub:@selector(name) andReturn:longString(1003)];
                });
                it(@"Should truncate within limits", ^{
                    [[truncated().product.name should] equal:longString(1000)];
                });
                it(@"Should update bytesTruncated", ^{
                    [[theValue(truncated().bytesTruncated) should] equal:theValue(3)];
                });
            });
        });
        context(@"Category Components", ^{
            context(@"Item size", ^{
                context(@"Out of limits", ^{
                    beforeEach(^{
                        [event.product stub:@selector(categoryComponents) andReturn:@[ longString(105) ]];
                    });
                    it(@"Should truncate within limits", ^{
                        [[truncated().product.categoryComponents should] equal:@[ longString(100) ]];
                    });
                    it(@"Should update bytesTruncated", ^{
                        [[theValue(truncated().bytesTruncated) should] equal:theValue(5)];
                    });
                });
            });
            context(@"Count", ^{
                context(@"Out of limits", ^{
                    beforeEach(^{
                        [event.product stub:@selector(categoryComponents) andReturn:longArray(21, ^{ return @"й"; })];
                    });
                    it(@"Should truncate within limits", ^{
                        [[truncated().product.categoryComponents should] equal:longArray(20, ^{ return @"й"; })];
                    });
                    it(@"Should update bytesTruncated", ^{
                        [[theValue(truncated().bytesTruncated) should] equal:theValue(2)];
                    });
                });
            });
        });
        context(@"Payload", ^{
            context(@"Key size", ^{
                context(@"Out of limits", ^{
                    beforeEach(^{
                        [event.product.internalPayload stub:@selector(pairs) andReturn:@{ longString(107): @"A" }];
                    });
                    it(@"Should truncate within limits", ^{
                        [[truncated().product.payload should] equal:@{ longString(100): @"A" }];
                    });
                    it(@"Should update bytesTruncated", ^{
                        [[theValue(truncated().bytesTruncated) should] equal:theValue(7)];
                    });
                });
            });
            context(@"Value size", ^{
                context(@"Out of limits", ^{
                    beforeEach(^{
                        [event.product.internalPayload stub:@selector(pairs) andReturn:@{ @"A": longString(1008) }];
                    });
                    it(@"Should truncate within limits", ^{
                        [[truncated().product.payload should] equal:@{ @"A": longString(1000) }];
                    });
                    it(@"Should update bytesTruncated", ^{
                        [[theValue(truncated().bytesTruncated) should] equal:theValue(8)];
                    });
                });
            });
        });
        context(@"Actual Price", ^{
            context(@"Fiat", ^{
                context(@"Unit", ^{
                    context(@"Within limits", ^{
                        beforeEach(^{
                            [event.product.actualPrice.fiat stub:@selector(unit) andReturn:longString(20)];
                        });
                        it(@"Should not truncate within limits", ^{
                            [[truncated().product.actualPrice.fiat.unit should] equal:event.product.actualPrice.fiat.unit];
                        });
                        it(@"Should not update bytesTruncated", ^{
                            [[theValue(truncated().bytesTruncated) should] beZero];
                        });
                    });
                    context(@"Out of limits", ^{
                        beforeEach(^{
                            [event.product.actualPrice.fiat stub:@selector(unit) andReturn:longString(23)];
                        });
                        it(@"Should truncate within limits", ^{
                            [[truncated().product.actualPrice.fiat.unit should] equal:longString(20)];
                        });
                        it(@"Should update bytesTruncated", ^{
                            [[theValue(truncated().bytesTruncated) should] equal:theValue(3)];
                        });
                    });
                });
            });
            context(@"Internal components", ^{
                context(@"Unit", ^{
                    context(@"Out of limits", ^{
                        beforeEach(^{
                            [event.product.actualPrice.internalComponents.firstObject stub:@selector(unit) andReturn:longString(24)];
                        });
                        it(@"Should truncate within limits", ^{
                            [[truncated().product.actualPrice.internalComponents.firstObject.unit should] equal:longString(20)];
                        });
                        it(@"Should update bytesTruncated", ^{
                            [[theValue(truncated().bytesTruncated) should] equal:theValue(4)];
                        });
                    });
                });
                context(@"Count", ^{
                    context(@"Within limits", ^{
                        beforeEach(^{
                            [event.product.actualPrice stub:@selector(internalComponents)
                                                  andReturn:longArray(30, ^{ return amount(); })];
                        });
                        it(@"Should not truncate within limits", ^{
                            [[theValue(truncated().product.actualPrice.internalComponents.count) should] equal:theValue(30)];
                        });
                        it(@"Should not update bytesTruncated", ^{
                            [[theValue(truncated().bytesTruncated) should] beZero];
                        });
                    });
                    context(@"Out of limits", ^{
                        beforeEach(^{
                            [event.product.actualPrice stub:@selector(internalComponents)
                                                  andReturn:longArray(31, ^{ return amount(); })];
                        });
                        it(@"Should truncate within limits", ^{
                            [[theValue(truncated().product.actualPrice.internalComponents.count) should] equal:theValue(30)];
                        });
                        it(@"Should update bytesTruncated", ^{
                            [[theValue(truncated().bytesTruncated) should] equal:theValue(12 + amount().unit.length)];
                        });
                    });
                });
            });
        });
        context(@"Original Price", ^{
            context(@"Fiat", ^{
                context(@"Unit", ^{
                    context(@"Out of limits", ^{
                        beforeEach(^{
                            [event.product.originalPrice.fiat stub:@selector(unit) andReturn:longString(23)];
                        });
                        it(@"Should truncate within limits", ^{
                            [[truncated().product.originalPrice.fiat.unit should] equal:longString(20)];
                        });
                        it(@"Should update bytesTruncated", ^{
                            [[theValue(truncated().bytesTruncated) should] equal:theValue(3)];
                        });
                    });
                });
            });
        });
        context(@"Promo Codes", ^{
            context(@"Item size", ^{
                context(@"Within limits", ^{
                    beforeEach(^{
                        [event.product stub:@selector(promoCodes) andReturn:@[ longString(100) ]];
                    });
                    it(@"Should not truncate within limits", ^{
                        [[truncated().product.promoCodes should] equal:event.product.promoCodes];
                    });
                    it(@"Should not update bytesTruncated", ^{
                        [[theValue(truncated().bytesTruncated) should] beZero];
                    });
                });
                context(@"Out of limits", ^{
                    beforeEach(^{
                        [event.product stub:@selector(promoCodes) andReturn:@[ longString(123) ]];
                    });
                    it(@"Should truncate within limits", ^{
                        [[truncated().product.promoCodes should] equal:@[ longString(100) ]];
                    });
                    it(@"Should update bytesTruncated", ^{
                        [[theValue(truncated().bytesTruncated) should] equal:theValue(23)];
                    });
                });
            });
            context(@"Count", ^{
                context(@"Within limits", ^{
                    beforeEach(^{
                        [event.product stub:@selector(promoCodes) andReturn:longArray(20, ^{ return @"A"; })];
                    });
                    it(@"Should not truncate within limits", ^{
                        [[truncated().product.promoCodes should] equal:event.product.promoCodes];
                    });
                    it(@"Should not update bytesTruncated", ^{
                        [[theValue(truncated().bytesTruncated) should] beZero];
                    });
                });
                context(@"Out of limits", ^{
                    beforeEach(^{
                        [event.product stub:@selector(promoCodes) andReturn:longArray(22, ^{ return @"Й"; })];
                    });
                    it(@"Should truncate within limits", ^{
                        [[truncated().product.promoCodes should] equal:longArray(20, ^{ return @"Й"; })];
                    });
                    it(@"Should update bytesTruncated", ^{
                        [[theValue(truncated().bytesTruncated) should] equal:theValue(4)];
                    });
                });
            });
        });
    });

    context(@"Referrer", ^{
        context(@"Type", ^{
            context(@"Within limits", ^{
                beforeEach(^{
                    [event.referrer stub:@selector(type) andReturn:longString(100)];
                });
                it(@"Should not truncate within limits", ^{
                    [[truncated().referrer.type should] equal:event.referrer.type];
                });
                it(@"Should not update bytesTruncated", ^{
                    [[theValue(truncated().bytesTruncated) should] beZero];
                });
            });
            context(@"Out of limits", ^{
                beforeEach(^{
                    [event.referrer stub:@selector(type) andReturn:longString(107)];
                });
                it(@"Should truncate within limits", ^{
                    [[truncated().referrer.type should] equal:longString(100)];
                });
                it(@"Should update bytesTruncated", ^{
                    [[theValue(truncated().bytesTruncated) should] equal:theValue(7)];
                });
            });
        });
        context(@"Identifier", ^{
            context(@"Within limits", ^{
                beforeEach(^{
                    [event.referrer stub:@selector(identifier) andReturn:longString(2048)];
                });
                it(@"Should not truncate within limits", ^{
                    [[truncated().referrer.identifier should] equal:event.referrer.identifier];
                });
                it(@"Should not update bytesTruncated", ^{
                    [[theValue(truncated().bytesTruncated) should] beZero];
                });
            });
            context(@"Out of limits", ^{
                beforeEach(^{
                    [event.referrer stub:@selector(identifier) andReturn:longString(2050)];
                });
                it(@"Should truncate within limits", ^{
                    [[truncated().referrer.identifier should] equal:longString(2048)];
                });
                it(@"Should update bytesTruncated", ^{
                    [[theValue(truncated().bytesTruncated) should] equal:theValue(2)];
                });
            });
        });
        context(@"Screen", ^{
            context(@"Name", ^{
                context(@"Within limits", ^{
                    beforeEach(^{
                        [event.referrer.screen stub:@selector(name) andReturn:longString(100)];
                    });
                    it(@"Should not truncate within limits", ^{
                        [[truncated().referrer.screen.name should] equal:event.referrer.screen.name];
                    });
                    it(@"Should not update bytesTruncated", ^{
                        [[theValue(truncated().bytesTruncated) should] beZero];
                    });
                });
                context(@"Out of limits", ^{
                    beforeEach(^{
                        [event.referrer.screen stub:@selector(name) andReturn:longString(106)];
                    });
                    it(@"Should truncate within limits", ^{
                        [[truncated().referrer.screen.name should] equal:longString(100)];
                    });
                    it(@"Should update bytesTruncated", ^{
                        [[theValue(truncated().bytesTruncated) should] equal:theValue(6)];
                    });
                });
            });
        });
    });

    context(@"Cart Item", ^{
        context(@"Product", ^{
            context(@"SKU", ^{
                context(@"Out of limits", ^{
                    beforeEach(^{
                        [event.cartItem.product stub:@selector(sku) andReturn:longString(105)];
                    });
                    it(@"Should truncate within limits", ^{
                        [[truncated().cartItem.product.sku should] equal:longString(100)];
                    });
                    it(@"Should update bytesTruncated", ^{
                        [[theValue(truncated().bytesTruncated) should] equal:theValue(5)];
                    });
                    it(@"Should update bytesTruncated in cart item", ^{
                        [[theValue(truncated().cartItem.bytesTruncated) should] equal:theValue(5)];
                    });
                });
            });
        });
        context(@"Referrer", ^{
            context(@"Type", ^{
                context(@"Out of limits", ^{
                    beforeEach(^{
                        [event.cartItem.referrer stub:@selector(type) andReturn:longString(109)];
                    });
                    it(@"Should truncate within limits", ^{
                        [[truncated().cartItem.referrer.type should] equal:longString(100)];
                    });
                    it(@"Should update bytesTruncated", ^{
                        [[theValue(truncated().bytesTruncated) should] equal:theValue(9)];
                    });
                    it(@"Should update bytesTruncated in cart item", ^{
                        [[theValue(truncated().cartItem.bytesTruncated) should] equal:theValue(9)];
                    });
                });
            });
        });
        context(@"Revenue", ^{
            context(@"Fiat", ^{
                context(@"Unit", ^{
                    context(@"Out of limits", ^{
                        beforeEach(^{
                            [event.cartItem.revenue.fiat stub:@selector(unit) andReturn:longString(23)];
                        });
                        it(@"Should truncate within limits", ^{
                            [[truncated().cartItem.revenue.fiat.unit should] equal:longString(20)];
                        });
                        it(@"Should update bytesTruncated", ^{
                            [[theValue(truncated().bytesTruncated) should] equal:theValue(3)];
                        });
                        it(@"Should update bytesTruncated in cart item", ^{
                            [[theValue(truncated().cartItem.bytesTruncated) should] equal:theValue(3)];
                        });
                    });
                });
            });
        });
    });

    context(@"Order", ^{
        context(@"Identifier", ^{
            context(@"Within limits", ^{
                beforeEach(^{
                    [event.order stub:@selector(identifier) andReturn:longString(100)];
                });
                it(@"Should not truncate within limits", ^{
                    [[truncated().order.identifier should] equal:event.order.identifier];
                });
                it(@"Should not update bytesTruncated", ^{
                    [[theValue(truncated().bytesTruncated) should] beZero];
                });
            });
            context(@"Out of limits", ^{
                beforeEach(^{
                    [event.order stub:@selector(identifier) andReturn:longString(108)];
                });
                it(@"Should truncate within limits", ^{
                    [[truncated().order.identifier should] equal:longString(100)];
                });
                it(@"Should update bytesTruncated", ^{
                    [[theValue(truncated().bytesTruncated) should] equal:theValue(8)];
                });
            });
        });
        context(@"Cart Items", ^{
            context(@"Product", ^{
                context(@"SKU", ^{
                    context(@"Out of limits", ^{
                        beforeEach(^{
                            [event.order.cartItems.firstObject.product stub:@selector(sku) andReturn:longString(102)];
                        });
                        it(@"Should truncate within limits", ^{
                            [[truncated().order.cartItems.firstObject.product.sku should] equal:longString(100)];
                        });
                        it(@"Should update bytesTruncated", ^{
                            [[theValue(truncated().bytesTruncated) should] equal:theValue(2)];
                        });
                        it(@"Should update bytesTruncated in cart item", ^{
                            [[theValue(truncated().order.cartItems.firstObject.bytesTruncated) should] equal:theValue(2)];
                        });
                    });
                });
            });
        });
        context(@"Payload", ^{
            context(@"Key size", ^{
                context(@"Out of limits", ^{
                    beforeEach(^{
                        [event.order.internalPayload stub:@selector(pairs) andReturn:@{ longString(107): @"A" }];
                    });
                    it(@"Should truncate within limits", ^{
                        [[truncated().order.payload should] equal:@{ longString(100): @"A" }];
                    });
                    it(@"Should update bytesTruncated", ^{
                        [[theValue(truncated().bytesTruncated) should] equal:theValue(7)];
                    });
                });
            });
            context(@"Value size", ^{
                context(@"Out of limits", ^{
                    beforeEach(^{
                        [event.order.internalPayload stub:@selector(pairs) andReturn:@{ @"A": longString(1008) }];
                    });
                    it(@"Should truncate within limits", ^{
                        [[truncated().order.payload should] equal:@{ @"A": longString(1000) }];
                    });
                    it(@"Should update bytesTruncated", ^{
                        [[theValue(truncated().bytesTruncated) should] equal:theValue(8)];
                    });
                });
            });
        });
    });

});

SPEC_END
