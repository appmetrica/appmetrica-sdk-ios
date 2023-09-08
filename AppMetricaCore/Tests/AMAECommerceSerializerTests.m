
#import <Kiwi/Kiwi.h>
#import "AMACore.h"
#import "AMAECommerceSerializer.h"
#import "AMAECommerce+Internal.h"
#import "Ecommerce.pb-c.h"
#import "AMAStringEventValue.h"
#import "AMABinaryEventValue.h"
#import "AMARevenueInfoModelSerializer.h"
#import "AMARevenueInfoModel.h"
#import <AppMetricaProtobufUtils/AppMetricaProtobufUtils.h>

SPEC_BEGIN(AMAECommerceSerializerTests)

describe(@"AMAECommerceSerializer", ^{

    AMAProtobufAllocator *__block allocator = nil;
    AMAECommerceSerializer *__block serializer = nil;

    beforeEach(^{
        allocator = [[AMAProtobufAllocator alloc] init];
        serializer = [[AMAECommerceSerializer alloc] init];
    });

    afterEach(^{
        allocator = nil;
    });

    context(@"Serialilze", ^{
        AMAECommerce *__block event = nil;
        AMAECommerceSerializationResult *__block result = nil;

        __auto_type payload = ^{
            return [[AMAECommercePayload alloc] initWithPairs:@{ @"B": @"C", @"D": @"E" }
                                          truncatedPairsCount:4];
        };
        __auto_type screen = ^{
            return [[AMAECommerceScreen alloc] initWithName:@"NAME"
                                         categoryComponents:@[ @"A", @"B", @"C"]
                                                searchQuery:@"QUERY"
                                            internalPayload:payload()];
        };
        __auto_type number = ^{
            return [NSDecimalNumber decimalNumberWithString:@"-23.42"
                                                     locale:@{ NSLocaleDecimalSeparator: @"." }];
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
                                            internalPayload:payload()
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
                                                        referrer:referrer()
                                                        quantity:number()
                                                         revenue:price()
                                                  bytesTruncated:23];
        };
        __auto_type order = ^{
            return [[AMAECommerceOrder alloc] initWithIdentifier:@"IDENTIFIER"
                                                       cartItems:@[ cartItem(), cartItem() ]
                                                 internalPayload:payload()];
        };

        __auto_type eventMessage = ^{
            result = [serializer serializeECommerce:event].firstObject;
            return ama__ecommerce_event__unpack(allocator.protobufCAllocator, result.data.length, result.data.bytes);
        };
        __auto_type payloadDictionary = ^(Ama__ECommerceEvent__Payload *message) {
            NSMutableDictionary *payloadDictionary = [NSMutableDictionary dictionary];
            for (NSUInteger idx = 0; idx < message->n_pairs; ++idx) {
                NSString *key = [AMAProtobufUtilities stringForBinaryData:&message->pairs[idx]->key
                                                                      has:message->pairs[idx]->has_key];
                NSString *value = [AMAProtobufUtilities stringForBinaryData:&message->pairs[idx]->value
                                                                        has:message->pairs[idx]->has_value];
                payloadDictionary[key] = value;
            }
            return [payloadDictionary copy];
        };

        context(@"Show Screen", ^{
            beforeEach(^{
                event = [[AMAECommerce alloc] initWithEventType:AMAECommerceEventTypeScreen
                                                         screen:screen()
                                                        product:nil
                                                       referrer:nil
                                                       cartItem:nil
                                                          order:nil
                                                 bytesTruncated:23];
            });
            it(@"Should have valid bytes truncated", ^{
                eventMessage();
                [[theValue(result.bytesTruncated) should] equal:theValue(event.bytesTruncated)];
            });
            it(@"Should have type", ^{
                [[theValue(eventMessage()->has_type) should] beYes];
            });
            it(@"Should have valid type", ^{
                [[theValue(eventMessage()->type) should] equal:theValue(AMA__ECOMMERCE_EVENT__ECOMMERCE_EVENT_TYPE__ECOMMERCE_EVENT_TYPE_SHOW_SCREEN)];
            });
            it(@"Should have info", ^{
                [[thePointerValue(eventMessage()->shown_screen_info) shouldNot] equal:thePointerValue(NULL)];
            });
            context(@"Info", ^{
                it(@"Should have screen", ^{
                    [[thePointerValue(eventMessage()->shown_screen_info->screen) shouldNot] equal:thePointerValue(NULL)];
                });
                context(@"Screen", ^{
                    __auto_type screenMessage = ^{
                        return eventMessage()->shown_screen_info->screen;
                    };
                    it(@"Should have valid name", ^{
                        NSString *value = [AMAProtobufUtilities stringForBinaryData:&screenMessage()->name
                                                                                has:screenMessage()->has_name];
                        [[value should] equal:screen().name];
                    });
                    it(@"Should have category", ^{
                        [[thePointerValue(screenMessage()->category) shouldNot] equal:thePointerValue(NULL)];
                    });
                    context(@"Category", ^{
                        it(@"Should have valid number of items", ^{
                            [[theValue(screenMessage()->category->n_path) should] equal:theValue(screen().categoryComponents.count)];
                        });
                        it(@"Should have valid first item", ^{
                            NSString *value = [AMAProtobufUtilities stringForBinaryData:&screenMessage()->category->path[0]];
                            [[value should] equal:screen().categoryComponents.firstObject];
                        });
                        it(@"Should have valid last item", ^{
                            NSUInteger index = screen().categoryComponents.count - 1;
                            NSString *value = [AMAProtobufUtilities stringForBinaryData:&screenMessage()->category->path[index]];
                            [[value should] equal:screen().categoryComponents.lastObject];
                        });
                    });
                    it(@"Should have valid search query", ^{
                        NSString *value = [AMAProtobufUtilities stringForBinaryData:&screenMessage()->search_query
                                                                                has:screenMessage()->has_search_query];
                        [[value should] equal:screen().searchQuery];
                    });
                    it(@"Should have payload", ^{
                        [[thePointerValue(screenMessage()->payload) shouldNot] equal:thePointerValue(NULL)];
                    });
                    context(@"Payload", ^{
                        __auto_type payloadMessage = ^{
                            return screenMessage()->payload;
                        };
                        it(@"Should have truncated pairs count", ^{
                            [[theValue(payloadMessage()->has_truncated_pairs_count) should] beYes];
                        });
                        it(@"Should have valid truncated pairs count", ^{
                            [[theValue(payloadMessage()->truncated_pairs_count) should] equal:theValue(payload().truncatedPairsCount)];
                        });
                        it(@"Should have valid pairs count", ^{
                            [[theValue(payloadMessage()->n_pairs) should] equal:theValue(payload().pairs.count)];
                        });
                        it(@"Should have valid pairs", ^{
                            [[payloadDictionary(payloadMessage()) should] equal:payload().pairs];
                        });
                    });
                });
            });
        });

        context(@"Show Product Card", ^{
            beforeEach(^{
                event = [[AMAECommerce alloc] initWithEventType:AMAECommerceEventTypeProductCard
                                                         screen:screen()
                                                        product:product()
                                                       referrer:nil
                                                       cartItem:nil
                                                          order:nil
                                                 bytesTruncated:42];
            });
            it(@"Should have valid bytes truncated", ^{
                eventMessage();
                [[theValue(result.bytesTruncated) should] equal:theValue(event.bytesTruncated)];
            });
            it(@"Should have type", ^{
                [[theValue(eventMessage()->has_type) should] beYes];
            });
            it(@"Should have valid type", ^{
                [[theValue(eventMessage()->type) should] equal:theValue(AMA__ECOMMERCE_EVENT__ECOMMERCE_EVENT_TYPE__ECOMMERCE_EVENT_TYPE_SHOW_PRODUCT_CARD)];
            });
            it(@"Should have info", ^{
                [[thePointerValue(eventMessage()->shown_product_card_info) shouldNot] equal:thePointerValue(NULL)];
            });
            context(@"Info", ^{
                it(@"Should have screen", ^{
                    [[thePointerValue(eventMessage()->shown_product_card_info->screen) shouldNot] equal:thePointerValue(NULL)];
                });
                it(@"Should have product", ^{
                    [[thePointerValue(eventMessage()->shown_product_card_info->product) shouldNot] equal:thePointerValue(NULL)];
                });
                context(@"Product", ^{
                    __auto_type productMessage = ^{
                        return eventMessage()->shown_product_card_info->product;
                    };
                    it(@"Should have valid sku", ^{
                        NSString *value = [AMAProtobufUtilities stringForBinaryData:&productMessage()->sku
                                                                                has:productMessage()->has_sku];
                        [[value should] equal:product().sku];
                    });
                    it(@"Should have valid name", ^{
                        NSString *value = [AMAProtobufUtilities stringForBinaryData:&productMessage()->name
                                                                                has:productMessage()->has_name];
                        [[value should] equal:product().name];
                    });
                    it(@"Should have category", ^{
                        [[thePointerValue(productMessage()->category) shouldNot] equal:thePointerValue(NULL)];
                    });
                    it(@"Should have payload", ^{
                        [[thePointerValue(productMessage()->payload) shouldNot] equal:thePointerValue(NULL)];
                    });
                    it(@"Should have actual price", ^{
                        [[thePointerValue(productMessage()->actual_price) shouldNot] equal:thePointerValue(NULL)];
                    });
                    context(@"Actual price", ^{
                        __auto_type priceMessage = ^{
                            return productMessage()->actual_price;
                        };
                        context(@"Fiat", ^{
                            __auto_type amountMessage =^{
                                return priceMessage()->fiat;
                            };
                            it(@"Should have valid unit type", ^{
                                NSString *value = [AMAProtobufUtilities stringForBinaryData:&amountMessage()->unit_type
                                                                                        has:amountMessage()->has_unit_type];
                                [[value should] equal:amount().unit];
                            });
                            context(@"Value", ^{
                                it(@"Should have mantissa", ^{
                                    [[theValue(amountMessage()->value->has_mantissa) should] beYes];
                                });
                                it(@"Should have exponent", ^{
                                    [[theValue(amountMessage()->value->has_exponent) should] beYes];
                                });
                                it(@"Should have valid deciaml value", ^{
                                    Ama__ECommerceEvent__Decimal *decimalMessage = amountMessage()->value;
                                    NSDecimalNumber *decimalNumber =
                                        [NSDecimalNumber decimalNumberWithMantissa:(unsigned long long)ABS(decimalMessage->mantissa)
                                                                          exponent:decimalMessage->exponent
                                                                        isNegative:decimalMessage->mantissa < 0];
                                    [[decimalNumber should] equal:number()];
                                });
                            });
                        });
                        context(@"Internal components", ^{
                            it(@"Should have valid items count", ^{
                                [[theValue(priceMessage()->n_internal_components) should] equal:theValue(price().internalComponents.count)];
                            });
                        });
                    });
                    it(@"Should have original price", ^{
                        [[thePointerValue(productMessage()->original_price) shouldNot] equal:thePointerValue(NULL)];
                    });
                    context(@"Promo codes", ^{
                        it(@"Should have valid number of items", ^{
                            [[theValue(productMessage()->n_promo_codes) should] equal:theValue(product().promoCodes.count)];
                        });
                        it(@"Should have valid first item", ^{
                            NSString *value =
                                [AMAProtobufUtilities stringForBinaryData:&productMessage()->promo_codes[0]->code
                                                                      has:productMessage()->promo_codes[0]->has_code];
                            [[value should] equal:product().promoCodes.firstObject];
                        });
                        it(@"Should have valid last item", ^{
                            NSUInteger index = product().promoCodes.count - 1;
                            NSString *value =
                                [AMAProtobufUtilities stringForBinaryData:&productMessage()->promo_codes[index]->code
                                                                      has:productMessage()->promo_codes[index]->has_code];
                            [[value should] equal:product().promoCodes.lastObject];
                        });
                    });
                });
            });
        });

        context(@"Show Product Details", ^{
            beforeEach(^{
                event = [[AMAECommerce alloc] initWithEventType:AMAECommerceEventTypeProductDetails
                                                         screen:nil
                                                        product:product()
                                                       referrer:referrer()
                                                       cartItem:nil
                                                          order:nil
                                                 bytesTruncated:97];
            });
            it(@"Should have valid bytes truncated", ^{
                eventMessage();
                [[theValue(result.bytesTruncated) should] equal:theValue(event.bytesTruncated)];
            });
            it(@"Should have type", ^{
                [[theValue(eventMessage()->has_type) should] beYes];
            });
            it(@"Should have valid type", ^{
                [[theValue(eventMessage()->type) should] equal:theValue(AMA__ECOMMERCE_EVENT__ECOMMERCE_EVENT_TYPE__ECOMMERCE_EVENT_TYPE_SHOW_PRODUCT_DETAILS)];
            });
            it(@"Should have info", ^{
                [[thePointerValue(eventMessage()->shown_product_details_info) shouldNot] equal:thePointerValue(NULL)];
            });
            context(@"Info", ^{
                it(@"Should have product", ^{
                    [[thePointerValue(eventMessage()->shown_product_details_info->product) shouldNot] equal:thePointerValue(NULL)];
                });
                it(@"Should have referrer", ^{
                    [[thePointerValue(eventMessage()->shown_product_details_info->referrer) shouldNot] equal:thePointerValue(NULL)];
                });
                context(@"Referrer", ^{
                    __auto_type referrerMessage = ^{
                        return eventMessage()->shown_product_details_info->referrer;
                    };
                    it(@"Should have valid type", ^{
                        NSString *value = [AMAProtobufUtilities stringForBinaryData:&referrerMessage()->type
                                                                                has:referrerMessage()->has_type];
                        [[value should] equal:referrer().type];
                    });
                    it(@"Should have valid id", ^{
                        NSString *value = [AMAProtobufUtilities stringForBinaryData:&referrerMessage()->id
                                                                                has:referrerMessage()->has_id];
                        [[value should] equal:referrer().identifier];
                    });
                    it(@"Should have screen", ^{
                        [[thePointerValue(referrerMessage()->screen) shouldNot] equal:thePointerValue(NULL)];
                    });
                });
            });
        });

        context(@"Add To Cart", ^{
            beforeEach(^{
                event = [[AMAECommerce alloc] initWithEventType:AMAECommerceEventTypeAddToCart
                                                         screen:nil
                                                        product:nil
                                                       referrer:nil
                                                       cartItem:cartItem()
                                                          order:nil
                                                 bytesTruncated:3];
            });
            it(@"Should have valid bytes truncated", ^{
                eventMessage();
                [[theValue(result.bytesTruncated) should] equal:theValue(event.bytesTruncated)];
            });
            it(@"Should have type", ^{
                [[theValue(eventMessage()->has_type) should] beYes];
            });
            it(@"Should have valid type", ^{
                [[theValue(eventMessage()->type) should] equal:theValue(AMA__ECOMMERCE_EVENT__ECOMMERCE_EVENT_TYPE__ECOMMERCE_EVENT_TYPE_ADD_TO_CART)];
            });
            it(@"Should have info", ^{
                [[thePointerValue(eventMessage()->cart_action_info) shouldNot] equal:thePointerValue(NULL)];
            });
            context(@"Info", ^{
                it(@"Should have item", ^{
                    [[thePointerValue(eventMessage()->cart_action_info->item) shouldNot] equal:thePointerValue(NULL)];
                });
                context(@"Cart item", ^{
                    __auto_type cartItemMessage = ^{
                        return eventMessage()->cart_action_info->item;
                    };
                    it(@"Should have product", ^{
                        [[thePointerValue(cartItemMessage()->product) shouldNot] equal:thePointerValue(NULL)];
                    });
                    it(@"Should have referrer", ^{
                        [[thePointerValue(cartItemMessage()->referrer) shouldNot] equal:thePointerValue(NULL)];
                    });
                    context(@"Quantity", ^{
                        it(@"Should have mantissa", ^{
                            [[theValue(cartItemMessage()->quantity->has_mantissa) should] beYes];
                        });
                        it(@"Should have exponent", ^{
                            [[theValue(cartItemMessage()->quantity->has_exponent) should] beYes];
                        });
                        it(@"Should have valid deciaml value", ^{
                            Ama__ECommerceEvent__Decimal *decimalMessage = cartItemMessage()->quantity;
                            NSDecimalNumber *decimalNumber =
                                [NSDecimalNumber decimalNumberWithMantissa:(unsigned long long)ABS(decimalMessage->mantissa)
                                                                  exponent:decimalMessage->exponent
                                                                isNegative:decimalMessage->mantissa < 0];
                            [[decimalNumber should] equal:number()];
                        });
                    });
                    it(@"Should have revenue", ^{
                        [[thePointerValue(cartItemMessage()->revenue) shouldNot] equal:thePointerValue(NULL)];
                    });
                });
            });
        });

        context(@"Remove From Cart", ^{
            beforeEach(^{
                event = [[AMAECommerce alloc] initWithEventType:AMAECommerceEventTypeRemoveFromCart
                                                         screen:nil
                                                        product:nil
                                                       referrer:nil
                                                       cartItem:cartItem()
                                                          order:nil
                                                 bytesTruncated:3];
            });
            it(@"Should have valid bytes truncated", ^{
                eventMessage();
                [[theValue(result.bytesTruncated) should] equal:theValue(event.bytesTruncated)];
            });
            it(@"Should have type", ^{
                [[theValue(eventMessage()->has_type) should] beYes];
            });
            it(@"Should have valid type", ^{
                [[theValue(eventMessage()->type) should] equal:theValue(AMA__ECOMMERCE_EVENT__ECOMMERCE_EVENT_TYPE__ECOMMERCE_EVENT_TYPE_REMOVE_FROM_CART)];
            });
            it(@"Should have info", ^{
                [[thePointerValue(eventMessage()->cart_action_info) shouldNot] equal:thePointerValue(NULL)];
            });
            context(@"Info", ^{
                it(@"Should have item", ^{
                    [[thePointerValue(eventMessage()->cart_action_info->item) shouldNot] equal:thePointerValue(NULL)];
                });
            });
        });

        __auto_type createOrderContextBlock = ^(AMAECommerceEventType modelType, int protoType) {
            return ^{
                context(@"Fitting order", ^{
                    beforeEach(^{
                        event = [[AMAECommerce alloc] initWithEventType:modelType
                                                                 screen:nil
                                                                product:nil
                                                               referrer:nil
                                                               cartItem:nil
                                                                  order:order()
                                                         bytesTruncated:108];
                    });
                    it(@"Should have valid bytes truncated", ^{
                        eventMessage();
                        [[theValue(result.bytesTruncated) should] equal:theValue(event.bytesTruncated)];
                    });
                    it(@"Should have type", ^{
                        [[theValue(eventMessage()->has_type) should] beYes];
                    });
                    it(@"Should have valid type", ^{
                        [[theValue(eventMessage()->type) should] equal:theValue(protoType)];
                    });
                    it(@"Should have info", ^{
                        [[thePointerValue(eventMessage()->order_info) shouldNot] equal:thePointerValue(NULL)];
                    });
                    context(@"Info", ^{
                        it(@"Should have order", ^{
                            [[thePointerValue(eventMessage()->order_info->order) shouldNot] equal:thePointerValue(NULL)];
                        });
                        context(@"Order", ^{
                            __auto_type orderMessage = ^{
                                return eventMessage()->order_info->order;
                            };
                            it(@"Should have non-empty uuid", ^{
                                NSString *value = [AMAProtobufUtilities stringForBinaryData:&orderMessage()->uuid
                                                                                        has:orderMessage()->has_uuid];
                                [[value shouldNot] beEmpty];
                            });
                            it(@"Should have valid order id", ^{
                                NSString *value = [AMAProtobufUtilities stringForBinaryData:&orderMessage()->order_id
                                                                                        has:orderMessage()->has_order_id];
                                [[value should] equal:order().identifier];
                            });
                            it(@"Should have valid payload", ^{
                                [[payloadDictionary(orderMessage()->payload) should] equal:order().payload];
                            });
                            it(@"Should have valid items count", ^{
                                [[theValue(orderMessage()->n_items) should] equal:theValue(order().cartItems.count)];
                            });
                            context(@"Items", ^{
                                NSUInteger __block index = 0;
                                __auto_type orderCartItemMessage = ^{
                                    return orderMessage()->items[index];
                                };
                                context(@"First", ^{
                                    beforeEach(^{
                                        index = 0;
                                    });
                                    it(@"Should have number in cart", ^{
                                        [[theValue(orderCartItemMessage()->has_number_in_cart) should] beYes];
                                    });
                                    it(@"Should have valid number in cart", ^{
                                        [[theValue(orderCartItemMessage()->number_in_cart) should] equal:theValue(index)];
                                    });
                                    it(@"Should have cart item", ^{
                                        [[thePointerValue(orderCartItemMessage()->item) shouldNot] equal:thePointerValue(NULL)];
                                    });
                                });
                                context(@"Last", ^{
                                    beforeEach(^{
                                        index = order().cartItems.count - 1;
                                    });
                                    it(@"Should have number in cart", ^{
                                        [[theValue(orderCartItemMessage()->has_number_in_cart) should] beYes];
                                    });
                                    it(@"Should have valid number in cart", ^{
                                        [[theValue(orderCartItemMessage()->number_in_cart) should] equal:theValue(index)];
                                    });
                                    it(@"Should have cart item", ^{
                                        [[thePointerValue(orderCartItemMessage()->item) shouldNot] equal:thePointerValue(NULL)];
                                    });
                                });
                            });
                            it(@"Should have total items count", ^{
                                [[theValue(orderMessage()->has_total_items_count) should] beYes];
                            });
                            it(@"Should have valid total items count", ^{
                                [[theValue(orderMessage()->total_items_count) should] equal:theValue(order().cartItems.count)];
                            });
                        });
                    });
                });
                context(@"Empty order", ^{
                    AMAECommerceOrder *__block order = nil;
                    beforeEach(^{
                        order = [[AMAECommerceOrder alloc] initWithIdentifier:@"ID_FOR_EMPTY"
                                                                    cartItems:@[]
                                                                      payload:@{ @"bar": @"foo" }];
                        event = [[AMAECommerce alloc] initWithEventType:modelType
                                                                 screen:nil
                                                                product:nil
                                                               referrer:nil
                                                               cartItem:nil
                                                                  order:order
                                                         bytesTruncated:108];
                    });
                    it(@"Should have valid bytes truncated", ^{
                        eventMessage();
                        [[theValue(result.bytesTruncated) should] equal:theValue(event.bytesTruncated)];
                    });
                    it(@"Should have type", ^{
                        [[theValue(eventMessage()->has_type) should] beYes];
                    });
                    it(@"Should have valid type", ^{
                        [[theValue(eventMessage()->type) should] equal:theValue(protoType)];
                    });
                    it(@"Should have info", ^{
                        [[thePointerValue(eventMessage()->order_info) shouldNot] equal:thePointerValue(NULL)];
                    });
                    context(@"Info", ^{
                        it(@"Should have order", ^{
                            [[thePointerValue(eventMessage()->order_info->order) shouldNot] equal:thePointerValue(NULL)];
                        });
                        context(@"Order", ^{
                            __auto_type orderMessage = ^{
                                return eventMessage()->order_info->order;
                            };
                            it(@"Should have non-empty uuid", ^{
                                NSString *value = [AMAProtobufUtilities stringForBinaryData:&orderMessage()->uuid
                                                                                        has:orderMessage()->has_uuid];
                                [[value shouldNot] beEmpty];
                            });
                            it(@"Should have valid order id", ^{
                                NSString *value = [AMAProtobufUtilities stringForBinaryData:&orderMessage()->order_id
                                                                                        has:orderMessage()->has_order_id];
                                [[value should] equal:order.identifier];
                            });
                            it(@"Should have valid payload", ^{
                                [[payloadDictionary(orderMessage()->payload) should] equal:order.payload];
                            });
                            it(@"Should have valid items count", ^{
                                [[theValue(orderMessage()->n_items) should] beZero];
                            });
                            it(@"Should have total items count", ^{
                                [[theValue(orderMessage()->has_total_items_count) should] beYes];
                            });
                            it(@"Should have valid total items count", ^{
                                [[theValue(orderMessage()->total_items_count) should] beZero];
                            });
                        });
                    });
                });
                context(@"Large order", ^{
                    AMAECommerceOrder *__block order = nil;
                    NSArray<AMAECommerceSerializationResult *> *__block results = nil;
                    Ama__ECommerceEvent *__block eventMessage = nil;

                    __auto_type largeString = ^(NSUInteger length) {
                        NSMutableString *result = [NSMutableString stringWithCapacity:length];
                        for (NSUInteger idx = 0; idx < length; ++idx) {
                            [result appendFormat:@"%c", (char)('a' + (idx % ('z' - 'a')))];
                        }
                        return result;
                    };
                    __auto_type largeCartItem = ^{
                        AMAECommerceProduct *product = [[AMAECommerceProduct alloc] initWithSKU:largeString(60000)];
                        AMAECommerceAmount *fiat =
                            [[AMAECommerceAmount alloc] initWithUnit:@"USD"
                                                               value:[[NSDecimalNumber alloc] initWithInt:42]];
                        return [[AMAECommerceCartItem alloc] initWithProduct:product
                                                                    referrer:nil
                                                                    quantity:[[NSDecimalNumber alloc] initWithInt:23]
                                                                     revenue:[[AMAECommercePrice alloc] initWithFiat:fiat]
                                                              bytesTruncated:23];
                    };
                    beforeEach(^{
                        order = [[AMAECommerceOrder alloc] initWithIdentifier:@"ID" cartItems:@[
                            // In first result
                            largeCartItem(),
                            largeCartItem(),
                            largeCartItem(),

                            // In second result
                            largeCartItem(),
                            largeCartItem(),
                        ] payload:@{ @"foo": @"bar" }];
                        event = [[AMAECommerce alloc] initWithEventType:modelType
                                                                 screen:nil
                                                                product:nil
                                                               referrer:nil
                                                               cartItem:nil
                                                                  order:order
                                                         bytesTruncated:321];
                        results = [serializer serializeECommerce:event];
                    });
                    __auto_type eventMessageFor = ^(NSUInteger idx) {
                        return ama__ecommerce_event__unpack(allocator.protobufCAllocator,
                                                            results[idx].data.length,
                                                            results[idx].data.bytes);
                    };
                    it(@"Should have 2 results", ^{
                        [[results should] haveCountOf:2];
                    });
                    it(@"Should have the same uuid", ^{
                        NSString *first = [AMAProtobufUtilities stringForBinaryData:&eventMessageFor(0)->order_info->order->uuid];
                        NSString *second = [AMAProtobufUtilities stringForBinaryData:&eventMessageFor(1)->order_info->order->uuid];
                        [[first should] equal:second];
                    });
                    context(@"First", ^{
                        beforeEach(^{
                            eventMessage = eventMessageFor(0);
                        });

                        it(@"Should have valid bytes truncated", ^{
                            NSUInteger expectedBytesTruncated =
                                event.bytesTruncated - 2 * largeCartItem().bytesTruncated;
                            [[theValue(results[0].bytesTruncated) should] equal:theValue(expectedBytesTruncated)];
                        });
                        it(@"Should have type", ^{
                            [[theValue(eventMessage->has_type) should] beYes];
                        });
                        it(@"Should have valid type", ^{
                            [[theValue(eventMessage->type) should] equal:theValue(protoType)];
                        });
                        it(@"Should have info", ^{
                            [[thePointerValue(eventMessage->order_info) shouldNot] equal:thePointerValue(NULL)];
                        });
                        context(@"Info", ^{
                            it(@"Should have order", ^{
                                [[thePointerValue(eventMessage->order_info->order) shouldNot] equal:thePointerValue(NULL)];
                            });
                            context(@"Order", ^{
                                __auto_type orderMessage = ^{
                                    return eventMessage->order_info->order;
                                };
                                it(@"Should have valid order id", ^{
                                    NSString *value = [AMAProtobufUtilities stringForBinaryData:&orderMessage()->order_id
                                                                                            has:orderMessage()->has_order_id];
                                    [[value should] equal:order.identifier];
                                });
                                it(@"Should have valid payload", ^{
                                    [[payloadDictionary(orderMessage()->payload) should] equal:order.payload];
                                });
                                it(@"Should have valid items count", ^{
                                    [[theValue(orderMessage()->n_items) should] equal:theValue(3)];
                                });
                                context(@"Items", ^{
                                    NSUInteger __block index = 0;
                                    __auto_type orderCartItemMessage = ^{
                                        return orderMessage()->items[index];
                                    };
                                    context(@"First", ^{
                                        beforeEach(^{
                                            index = 0;
                                        });
                                        it(@"Should have number in cart", ^{
                                            [[theValue(orderCartItemMessage()->has_number_in_cart) should] beYes];
                                        });
                                        it(@"Should have valid number in cart", ^{
                                            [[theValue(orderCartItemMessage()->number_in_cart) should] equal:theValue(index)];
                                        });
                                        it(@"Should have cart item", ^{
                                            [[thePointerValue(orderCartItemMessage()->item) shouldNot] equal:thePointerValue(NULL)];
                                        });
                                    });
                                    context(@"Last", ^{
                                        beforeEach(^{
                                            index = 2;
                                        });
                                        it(@"Should have number in cart", ^{
                                            [[theValue(orderCartItemMessage()->has_number_in_cart) should] beYes];
                                        });
                                        it(@"Should have valid number in cart", ^{
                                            [[theValue(orderCartItemMessage()->number_in_cart) should] equal:theValue(index)];
                                        });
                                        it(@"Should have cart item", ^{
                                            [[thePointerValue(orderCartItemMessage()->item) shouldNot] equal:thePointerValue(NULL)];
                                        });
                                    });
                                });
                                it(@"Should have total items count", ^{
                                    [[theValue(orderMessage()->has_total_items_count) should] beYes];
                                });
                                it(@"Should have valid total items count", ^{
                                    [[theValue(orderMessage()->total_items_count) should] equal:theValue(order.cartItems.count)];
                                });
                            });
                        });
                    });
                    context(@"Second", ^{
                        beforeEach(^{
                            eventMessage = eventMessageFor(1);
                        });

                        it(@"Should have valid bytes truncated", ^{
                            NSUInteger expectedBytesTruncated =
                                event.bytesTruncated - 3 * largeCartItem().bytesTruncated;
                            [[theValue(results[1].bytesTruncated) should] equal:theValue(expectedBytesTruncated)];
                        });
                        it(@"Should have type", ^{
                            [[theValue(eventMessage->has_type) should] beYes];
                        });
                        it(@"Should have valid type", ^{
                            [[theValue(eventMessage->type) should] equal:theValue(protoType)];
                        });
                        it(@"Should have info", ^{
                            [[thePointerValue(eventMessage->order_info) shouldNot] equal:thePointerValue(NULL)];
                        });
                        context(@"Info", ^{
                            it(@"Should have order", ^{
                                [[thePointerValue(eventMessage->order_info->order) shouldNot] equal:thePointerValue(NULL)];
                            });
                            context(@"Order", ^{
                                __auto_type orderMessage = ^{
                                    return eventMessage->order_info->order;
                                };
                                it(@"Should have valid order id", ^{
                                    NSString *value = [AMAProtobufUtilities stringForBinaryData:&orderMessage()->order_id
                                                                                            has:orderMessage()->has_order_id];
                                    [[value should] equal:order.identifier];
                                });
                                it(@"Should have valid payload", ^{
                                    [[payloadDictionary(orderMessage()->payload) should] equal:order.payload];
                                });
                                it(@"Should have valid items count", ^{
                                    [[theValue(orderMessage()->n_items) should] equal:theValue(2)];
                                });
                                context(@"Items", ^{
                                    NSUInteger __block index = 0;
                                    __auto_type orderCartItemMessage = ^{
                                        return orderMessage()->items[index];
                                    };
                                    context(@"First", ^{
                                        beforeEach(^{
                                            index = 0;
                                        });
                                        it(@"Should have number in cart", ^{
                                            [[theValue(orderCartItemMessage()->has_number_in_cart) should] beYes];
                                        });
                                        it(@"Should have valid number in cart", ^{
                                            [[theValue(orderCartItemMessage()->number_in_cart) should] equal:theValue(3)];
                                        });
                                        it(@"Should have cart item", ^{
                                            [[thePointerValue(orderCartItemMessage()->item) shouldNot] equal:thePointerValue(NULL)];
                                        });
                                    });
                                    context(@"Last", ^{
                                        beforeEach(^{
                                            index = 1;
                                        });
                                        it(@"Should have number in cart", ^{
                                            [[theValue(orderCartItemMessage()->has_number_in_cart) should] beYes];
                                        });
                                        it(@"Should have valid number in cart", ^{
                                            [[theValue(orderCartItemMessage()->number_in_cart) should] equal:theValue(4)];
                                        });
                                        it(@"Should have cart item", ^{
                                            [[thePointerValue(orderCartItemMessage()->item) shouldNot] equal:thePointerValue(NULL)];
                                        });
                                    });
                                });
                                it(@"Should have total items count", ^{
                                    [[theValue(orderMessage()->has_total_items_count) should] beYes];
                                });
                                it(@"Should have valid total items count", ^{
                                    [[theValue(orderMessage()->total_items_count) should] equal:theValue(order.cartItems.count)];
                                });
                            });
                        });
                    });
                });
            };
        };

        context(@"BeginCheckout",
                createOrderContextBlock(
                    AMAECommerceEventTypeBeginCheckout,
                    AMA__ECOMMERCE_EVENT__ECOMMERCE_EVENT_TYPE__ECOMMERCE_EVENT_TYPE_BEGIN_CHECKOUT
                )
        );
        context(@"Purchase",
                createOrderContextBlock(
                    AMAECommerceEventTypePurchase,
                    AMA__ECOMMERCE_EVENT__ECOMMERCE_EVENT_TYPE__ECOMMERCE_EVENT_TYPE_PURCHASE
                )
        );
    });
    context(@"Deserialize", ^{
        it(@"Value is nil", ^{
            Ama__ECommerceEvent *result = [serializer deserializeECommerceEvent:nil allocator:allocator];
            [[theValue(result == NULL) should] beYes];
        });
        it(@"Value is not binary", ^{
            id value = [[AMAStringEventValue alloc] initWithValue:@"value"];
            Ama__ECommerceEvent *result = [serializer deserializeECommerceEvent:value allocator:allocator];
            [[theValue(result == NULL) should] beYes];
        });
        it(@"Invalid binary value", ^{
            AMARevenueInfoModel *model = [[AMARevenueInfoModel alloc] initWithPriceDecimal:[NSDecimalNumber zero]
                                                                                  currency:@"USD"
                                                                                  quantity:1
                                                                                 productID:@"pid"
                                                                             transactionID:@"tid"
                                                                               receiptData:[NSData data]
                                                                             payloadString:@"payload"
                                                                            bytesTruncated:0
                                                                           isAutoCollected:NO
                                                                                 inAppType:AMAInAppTypePurchase
                                                                          subscriptionInfo:nil
                                                                           transactionInfo:nil];
            NSData *data = [[[AMARevenueInfoModelSerializer alloc] init] dataWithRevenueInfoModel:model];
            id value = [[AMABinaryEventValue alloc] initWithData:data gZipped:NO];
            Ama__ECommerceEvent *result = [serializer deserializeECommerceEvent:value allocator:allocator];
            [[theValue(result == NULL) should] beYes];
        });
        it(@"Valid binary value", ^{
            AMAECommerce *event = [AMAECommerce showScreenEventWithScreen:[[AMAECommerceScreen alloc] initWithName:@"name"]];
            NSData *data = [serializer serializeECommerce:event][0].data;
            id value = [[AMABinaryEventValue alloc] initWithData:data gZipped:NO];
            Ama__ECommerceEvent *result = [serializer deserializeECommerceEvent:value allocator:allocator];
            [[theValue(result == NULL) should] beNo];
        });
    });
});

SPEC_END
