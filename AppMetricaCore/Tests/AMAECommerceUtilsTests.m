
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMACore.h"
#import "AMAECommerce+Internal.h"
#import "AMAECommerceUtils.h"
#import "AMAECommerceSerializer.h"
#import "AMABinaryEventValue.h"
#import <AppMetricaProtobufUtils/AppMetricaProtobufUtils.h>

SPEC_BEGIN(AMAECommerceUtilsTests)

describe(@"AMAECommerceUtils", ^{
    context(@"convertECommerceEventProtoType", ^{
        NSError *__block error = nil;
        beforeEach(^{
            error = nil;
        });
        it(@"Type screen", ^{
            AMAECommerceEventType result = [AMAECommerceUtils
                convertECommerceEventProtoType:AMA__ECOMMERCE_EVENT__ECOMMERCE_EVENT_TYPE__ECOMMERCE_EVENT_TYPE_SHOW_SCREEN
                error:&error];
            [[theValue(result) should] equal:theValue(AMAECommerceEventTypeScreen)];
            [[error should] beNil];
        });
        it(@"Type product card", ^{
            AMAECommerceEventType result = [AMAECommerceUtils
                convertECommerceEventProtoType:AMA__ECOMMERCE_EVENT__ECOMMERCE_EVENT_TYPE__ECOMMERCE_EVENT_TYPE_SHOW_PRODUCT_CARD
                                         error:&error];
            [[theValue(result) should] equal:theValue(AMAECommerceEventTypeProductCard)];
            [[error should] beNil];
        });
        it(@"Type product details", ^{
            AMAECommerceEventType result = [AMAECommerceUtils
                convertECommerceEventProtoType:AMA__ECOMMERCE_EVENT__ECOMMERCE_EVENT_TYPE__ECOMMERCE_EVENT_TYPE_SHOW_PRODUCT_DETAILS
                                         error:&error];
            [[theValue(result) should] equal:theValue(AMAECommerceEventTypeProductDetails)];
            [[error should] beNil];
        });
        it(@"Type add to cart", ^{
            AMAECommerceEventType result = [AMAECommerceUtils
                convertECommerceEventProtoType:AMA__ECOMMERCE_EVENT__ECOMMERCE_EVENT_TYPE__ECOMMERCE_EVENT_TYPE_ADD_TO_CART
                                         error:&error];
            [[theValue(result) should] equal:theValue(AMAECommerceEventTypeAddToCart)];
            [[error should] beNil];
        });
        it(@"Type remove from cart", ^{
            AMAECommerceEventType result = [AMAECommerceUtils
                convertECommerceEventProtoType:AMA__ECOMMERCE_EVENT__ECOMMERCE_EVENT_TYPE__ECOMMERCE_EVENT_TYPE_REMOVE_FROM_CART
                                         error:&error];
            [[theValue(result) should] equal:theValue(AMAECommerceEventTypeRemoveFromCart)];
            [[error should] beNil];
        });
        it(@"Type begin checkout", ^{
            AMAECommerceEventType result = [AMAECommerceUtils
                convertECommerceEventProtoType:AMA__ECOMMERCE_EVENT__ECOMMERCE_EVENT_TYPE__ECOMMERCE_EVENT_TYPE_BEGIN_CHECKOUT
                                         error:&error];
            [[theValue(result) should] equal:theValue(AMAECommerceEventTypeBeginCheckout)];
            [[error should] beNil];
        });
        it(@"Type purchase", ^{
            AMAECommerceEventType result = [AMAECommerceUtils
                convertECommerceEventProtoType:AMA__ECOMMERCE_EVENT__ECOMMERCE_EVENT_TYPE__ECOMMERCE_EVENT_TYPE_PURCHASE
                                         error:&error];
            [[theValue(result) should] equal:theValue(AMAECommerceEventTypePurchase)];
            [[error should] beNil];
        });
        it(@"Unknown type", ^{
            AMAECommerceEventType result = [AMAECommerceUtils convertECommerceEventProtoType:99 error:&error];
            [[theValue(result) should] equal:theValue(AMAECommerceEventTypeScreen)];
            [[error shouldNot] beNil];
        });
    });
    context(@"isFirstECommerceEvent", ^{
        AMAProtobufAllocator *__block allocator = nil;

        beforeEach(^{
            allocator = [[AMAProtobufAllocator alloc] init];
        });

        afterEach(^{
            allocator = nil;
        });
        it(@"Should be YES for no order info", ^{
            [AMAAllocationsTrackerProvider track:^(id<AMAAllocationsTracking> tracker) {
                Ama__ECommerceEvent message = AMA__ECOMMERCE_EVENT__INIT;
                [[theValue([AMAECommerceUtils isFirstECommerceEvent:&message]) should] beYes];
            }];
        });
        it(@"Should be YES for no order", ^{
            [AMAAllocationsTrackerProvider track:^(id<AMAAllocationsTracking> tracker) {
                Ama__ECommerceEvent message = AMA__ECOMMERCE_EVENT__INIT;
                Ama__ECommerceEvent__OrderInfo *orderInfo = [tracker allocateSize:sizeof(Ama__ECommerceEvent__OrderInfo)];
                ama__ecommerce_event__order_info__init(orderInfo);
                message.order_info = orderInfo;
                [[theValue([AMAECommerceUtils isFirstECommerceEvent:&message]) should] beYes];
            }];
        });
        it(@"Should be YES for no order", ^{
            [AMAAllocationsTrackerProvider track:^(id<AMAAllocationsTracking> tracker) {
                Ama__ECommerceEvent message = AMA__ECOMMERCE_EVENT__INIT;
                Ama__ECommerceEvent__OrderInfo *orderInfo = [tracker allocateSize:sizeof(Ama__ECommerceEvent__OrderInfo)];
                ama__ecommerce_event__order_info__init(orderInfo);
                message.order_info = orderInfo;
                [[theValue([AMAECommerceUtils isFirstECommerceEvent:&message]) should] beYes];
            }];
        });
        it(@"Should be YES for no items", ^{
            [AMAAllocationsTrackerProvider track:^(id<AMAAllocationsTracking> tracker) {
                Ama__ECommerceEvent message = AMA__ECOMMERCE_EVENT__INIT;
                Ama__ECommerceEvent__Order *order = [tracker allocateSize:sizeof(Ama__ECommerceEvent__Order)];
                ama__ecommerce_event__order__init(order);
                order->items = NULL;
                order->n_items = 0;
                Ama__ECommerceEvent__OrderInfo *orderInfo = [tracker allocateSize:sizeof(Ama__ECommerceEvent__OrderInfo)];
                ama__ecommerce_event__order_info__init(orderInfo);
                orderInfo->order = order;
                message.order_info = orderInfo;
                [[theValue([AMAECommerceUtils isFirstECommerceEvent:&message]) should] beYes];
            }];
        });
        it(@"Should be YES for empty items", ^{
            [AMAAllocationsTrackerProvider track:^(id<AMAAllocationsTracking> tracker) {
                Ama__ECommerceEvent message = AMA__ECOMMERCE_EVENT__INIT;
                Ama__ECommerceEvent__Order *order = [tracker allocateSize:sizeof(Ama__ECommerceEvent__Order)];
                ama__ecommerce_event__order__init(order);
                order->n_items = 0;
                order->items = [tracker allocateSize:sizeof(Ama__ECommerceEvent__OrderCartItem) * 0];
                Ama__ECommerceEvent__OrderInfo *orderInfo = [tracker allocateSize:sizeof(Ama__ECommerceEvent__OrderInfo)];
                ama__ecommerce_event__order_info__init(orderInfo);
                orderInfo->order = order;
                message.order_info = orderInfo;
                [[theValue([AMAECommerceUtils isFirstECommerceEvent:&message]) should] beYes];
            }];
        });
        it(@"Should be YES for NULL cart item", ^{
            [AMAAllocationsTrackerProvider track:^(id<AMAAllocationsTracking> tracker) {
                Ama__ECommerceEvent message = AMA__ECOMMERCE_EVENT__INIT;
                Ama__ECommerceEvent__Order *order = [tracker allocateSize:sizeof(Ama__ECommerceEvent__Order)];
                ama__ecommerce_event__order__init(order);
                order->n_items = 1;
                order->items = [tracker allocateSize:sizeof(Ama__ECommerceEvent__OrderCartItem *) * 1];
                order->items[0] = NULL;
                Ama__ECommerceEvent__OrderInfo *orderInfo = [tracker allocateSize:sizeof(Ama__ECommerceEvent__OrderInfo)];
                ama__ecommerce_event__order_info__init(orderInfo);
                orderInfo->order = order;
                message.order_info = orderInfo;
                [[theValue([AMAECommerceUtils isFirstECommerceEvent:&message]) should] beYes];
            }];
        });
        it(@"Should be YES for cart item with first number_in_cart = 0", ^{
            [AMAAllocationsTrackerProvider track:^(id<AMAAllocationsTracking> tracker) {
                Ama__ECommerceEvent message = AMA__ECOMMERCE_EVENT__INIT;
                Ama__ECommerceEvent__Order *order = [tracker allocateSize:sizeof(Ama__ECommerceEvent__Order)];
                ama__ecommerce_event__order__init(order);
                order->n_items = 2;
                order->items = [tracker allocateSize:sizeof(Ama__ECommerceEvent__OrderCartItem) * 2];
                order->items[0] = [tracker allocateSize:sizeof(Ama__ECommerceEvent__OrderCartItem)];
                ama__ecommerce_event__order_cart_item__init(order->items[0]);
                order->items[0]->number_in_cart = 0;
                order->items[1] = [tracker allocateSize:sizeof(Ama__ECommerceEvent__OrderCartItem)];
                ama__ecommerce_event__order_cart_item__init(order->items[1]);
                order->items[1]->number_in_cart = 1;
                Ama__ECommerceEvent__OrderInfo *orderInfo = [tracker allocateSize:sizeof(Ama__ECommerceEvent__OrderInfo)];
                ama__ecommerce_event__order_info__init(orderInfo);
                orderInfo->order = order;
                message.order_info = orderInfo;
                [[theValue([AMAECommerceUtils isFirstECommerceEvent:&message]) should] beYes];
            }];
        });
        it(@"Should be NO for cart item with first number_in_cart != 0", ^{
            [AMAAllocationsTrackerProvider track:^(id<AMAAllocationsTracking> tracker) {
                Ama__ECommerceEvent message = AMA__ECOMMERCE_EVENT__INIT;
                Ama__ECommerceEvent__Order *order = [tracker allocateSize:sizeof(Ama__ECommerceEvent__Order)];
                ama__ecommerce_event__order__init(order);
                order->n_items = 2;
                order->items = [tracker allocateSize:sizeof(Ama__ECommerceEvent__OrderCartItem) * 2];
                order->items[0] = [tracker allocateSize:sizeof(Ama__ECommerceEvent__OrderCartItem)];
                ama__ecommerce_event__order_cart_item__init(order->items[0]);
                order->items[0]->number_in_cart = 1;
                order->items[1] = [tracker allocateSize:sizeof(Ama__ECommerceEvent__OrderCartItem)];
                ama__ecommerce_event__order_cart_item__init(order->items[1]);
                order->items[1]->number_in_cart = 0;
                Ama__ECommerceEvent__OrderInfo *orderInfo = [tracker allocateSize:sizeof(Ama__ECommerceEvent__OrderInfo)];
                ama__ecommerce_event__order_info__init(orderInfo);
                orderInfo->order = order;
                message.order_info = orderInfo;
                [[theValue([AMAECommerceUtils isFirstECommerceEvent:&message]) should] beNo];
            }];
        });
    });
    context(@"getECommerceMoneyFromOrder", ^{
        __auto_type createCartItem = ^Ama__ECommerceEvent__OrderCartItem *(NSString *currency, NSDecimalNumber *price, id<AMAAllocationsTracking> tracker) {
        Ama__ECommerceEvent__OrderCartItem *orderCartItem = [tracker allocateSize:sizeof(Ama__ECommerceEvent__OrderCartItem)];
        ama__ecommerce_event__order_cart_item__init(orderCartItem);
        Ama__ECommerceEvent__CartItem *cartItem = [tracker allocateSize:sizeof(Ama__ECommerceEvent__CartItem)];
        ama__ecommerce_event__cart_item__init(cartItem);
        Ama__ECommerceEvent__Price *revenue = [tracker allocateSize:sizeof(Ama__ECommerceEvent__Price)];
        ama__ecommerce_event__price__init(revenue);
        Ama__ECommerceEvent__Amount *fiat = [tracker allocateSize:sizeof(Ama__ECommerceEvent__Amount)];
        ama__ecommerce_event__amount__init(fiat);
        Ama__ECommerceEvent__Decimal *decimal = [tracker allocateSize:sizeof(Ama__ECommerceEvent__Decimal)];
        ama__ecommerce_event__decimal__init(decimal);
            [AMADecimalUtils fillMantissa:&decimal->mantissa
                                 exponent:&decimal->exponent
                              withDecimal:price];
        fiat->value = decimal;
        fiat->has_unit_type = true;
        [AMAProtobufUtilities fillBinaryData:&fiat->unit_type
                                  withString:currency
                                     tracker:tracker];
        revenue->fiat = fiat;
        cartItem->revenue = revenue;
        orderCartItem->item = cartItem;
        return orderCartItem;
    };
        NS_VALID_UNTIL_END_OF_SCOPE AMAProtobufAllocator *allocator = [[AMAProtobufAllocator alloc] init];
        it(@"Should be empty for NULL order info", ^{
            [AMAAllocationsTrackerProvider track:^(id<AMAAllocationsTracking> tracker) {
                NSArray<AMAECommerceAmount *> *result = [AMAECommerceUtils getECommerceMoneyFromOrder:NULL];
                [[result should] equal:@[]];
            }];
        });
        it(@"Should be empty for NULL order", ^{
            [AMAAllocationsTrackerProvider track:^(id<AMAAllocationsTracking> tracker) {
                Ama__ECommerceEvent__OrderInfo *orderInfo = [tracker allocateSize:sizeof(Ama__ECommerceEvent__OrderInfo)];
                ama__ecommerce_event__order_info__init(orderInfo);
                orderInfo->order = NULL;
                NSArray<AMAECommerceAmount *> *result = [AMAECommerceUtils getECommerceMoneyFromOrder:orderInfo];
                [[result should] equal:@[]];
            }];
        });
        it(@"Should be empty for NULL items", ^{
            [AMAAllocationsTrackerProvider track:^(id<AMAAllocationsTracking> tracker) {
                Ama__ECommerceEvent__Order *order = [tracker allocateSize:sizeof(Ama__ECommerceEvent__Order)];
                ama__ecommerce_event__order__init(order);
                order->items = NULL;
                Ama__ECommerceEvent__OrderInfo *orderInfo = [tracker allocateSize:sizeof(Ama__ECommerceEvent__OrderInfo)];
                ama__ecommerce_event__order_info__init(orderInfo);
                orderInfo->order = order;
                NSArray<AMAECommerceAmount *> *result = [AMAECommerceUtils getECommerceMoneyFromOrder:orderInfo];
                [[result should] equal:@[]];
            }];
        });
        it(@"Should be empty for empty items", ^{
            [AMAAllocationsTrackerProvider track:^(id<AMAAllocationsTracking> tracker) {
                Ama__ECommerceEvent__Order *order = [tracker allocateSize:sizeof(Ama__ECommerceEvent__Order)];
                ama__ecommerce_event__order__init(order);
                order->items = [tracker allocateSize:sizeof(Ama__ECommerceEvent__Order)];
                order->n_items = 0;
                Ama__ECommerceEvent__OrderInfo *orderInfo = [tracker allocateSize:sizeof(Ama__ECommerceEvent__OrderInfo)];
                ama__ecommerce_event__order_info__init(orderInfo);
                orderInfo->order = order;
                NSArray<AMAECommerceAmount *> *result = [AMAECommerceUtils getECommerceMoneyFromOrder:orderInfo];
                [[result should] equal:@[]];
            }];
        });
        it(@"Should ignore NULL order cart item", ^{
            [AMAAllocationsTrackerProvider track:^(id<AMAAllocationsTracking> tracker) {
                Ama__ECommerceEvent__Order *order = [tracker allocateSize:sizeof(Ama__ECommerceEvent__Order)];
                ama__ecommerce_event__order__init(order);
                order->items = [tracker allocateSize:sizeof(Ama__ECommerceEvent__Order) * 2];
                order->n_items = 2;
                order->items[0] = NULL;
                order->items[1] = createCartItem(@"USD", [NSDecimalNumber decimalNumberWithString:@"1.2"], tracker);
                Ama__ECommerceEvent__OrderInfo *orderInfo = [tracker allocateSize:sizeof(Ama__ECommerceEvent__OrderInfo)];
                ama__ecommerce_event__order_info__init(orderInfo);
                orderInfo->order = order;
                NSArray<AMAECommerceAmount *> *result = [AMAECommerceUtils getECommerceMoneyFromOrder:orderInfo];
                [[theValue(result.count) should] equal:theValue(1)];
                [[result[0].value should] equal:[NSDecimalNumber decimalNumberWithString:@"1.2"]];
                [[result[0].unit should] equal:@"USD"];
            }];
        });
        it(@"Should ignore NULL cart item", ^{
            [AMAAllocationsTrackerProvider track:^(id<AMAAllocationsTracking> tracker) {
                Ama__ECommerceEvent__Order *order = [tracker allocateSize:sizeof(Ama__ECommerceEvent__Order)];
                ama__ecommerce_event__order__init(order);
                order->items = [tracker allocateSize:sizeof(Ama__ECommerceEvent__Order) * 2];
                order->n_items = 2;
                Ama__ECommerceEvent__OrderCartItem *orderCartItem = [tracker allocateSize:sizeof(Ama__ECommerceEvent__OrderCartItem)];
                ama__ecommerce_event__order_cart_item__init(orderCartItem);
                orderCartItem->item = NULL;
                order->items[0] = orderCartItem;
                order->items[1] = createCartItem(@"USD", [NSDecimalNumber decimalNumberWithString:@"1.2"], tracker);
                Ama__ECommerceEvent__OrderInfo *orderInfo = [tracker allocateSize:sizeof(Ama__ECommerceEvent__OrderInfo)];
                ama__ecommerce_event__order_info__init(orderInfo);
                orderInfo->order = order;
                NSArray<AMAECommerceAmount *> *result = [AMAECommerceUtils getECommerceMoneyFromOrder:orderInfo];
                [[theValue(result.count) should] equal:theValue(1)];
                [[result[0].value should] equal:[NSDecimalNumber decimalNumberWithString:@"1.2"]];
                [[result[0].unit should] equal:@"USD"];
            }];
        });
        it(@"Should ignore NULL price", ^{
            [AMAAllocationsTrackerProvider track:^(id<AMAAllocationsTracking> tracker) {
                Ama__ECommerceEvent__Order *order = [tracker allocateSize:sizeof(Ama__ECommerceEvent__Order)];
                ama__ecommerce_event__order__init(order);
                order->items = [tracker allocateSize:sizeof(Ama__ECommerceEvent__Order) * 2];
                order->n_items = 2;
                Ama__ECommerceEvent__OrderCartItem *orderCartItem = [tracker allocateSize:sizeof(Ama__ECommerceEvent__OrderCartItem)];
                ama__ecommerce_event__order_cart_item__init(orderCartItem);
                Ama__ECommerceEvent__CartItem *cartItem = [tracker allocateSize:sizeof(Ama__ECommerceEvent__CartItem)];
                ama__ecommerce_event__cart_item__init(cartItem);
                cartItem->revenue = NULL;
                orderCartItem->item = cartItem;
                order->items[0] = orderCartItem;
                order->items[1] = createCartItem(@"USD", [NSDecimalNumber decimalNumberWithString:@"1.2"], tracker);
                Ama__ECommerceEvent__OrderInfo *orderInfo = [tracker allocateSize:sizeof(Ama__ECommerceEvent__OrderInfo)];
                ama__ecommerce_event__order_info__init(orderInfo);
                orderInfo->order = order;
                NSArray<AMAECommerceAmount *> *result = [AMAECommerceUtils getECommerceMoneyFromOrder:orderInfo];
                [[theValue(result.count) should] equal:theValue(1)];
                [[result[0].value should] equal:[NSDecimalNumber decimalNumberWithString:@"1.2"]];
                [[result[0].unit should] equal:@"USD"];
            }];
        });
        it(@"Should ignore NULL fiat", ^{
            [AMAAllocationsTrackerProvider track:^(id<AMAAllocationsTracking> tracker) {
                Ama__ECommerceEvent__Order *order = [tracker allocateSize:sizeof(Ama__ECommerceEvent__Order)];
                ama__ecommerce_event__order__init(order);
                order->items = [tracker allocateSize:sizeof(Ama__ECommerceEvent__Order) * 2];
                order->n_items = 2;
                Ama__ECommerceEvent__OrderCartItem *orderCartItem = [tracker allocateSize:sizeof(Ama__ECommerceEvent__OrderCartItem)];
                ama__ecommerce_event__order_cart_item__init(orderCartItem);
                Ama__ECommerceEvent__CartItem *cartItem = [tracker allocateSize:sizeof(Ama__ECommerceEvent__CartItem)];
                ama__ecommerce_event__cart_item__init(cartItem);
                Ama__ECommerceEvent__Price *price = [tracker allocateSize:sizeof(Ama__ECommerceEvent__Price)];
                ama__ecommerce_event__price__init(price);
                price->fiat = NULL;
                cartItem->revenue = price;
                orderCartItem->item = cartItem;
                order->items[0] = orderCartItem;
                order->items[1] = createCartItem(@"USD", [NSDecimalNumber decimalNumberWithString:@"1.2"], tracker);
                Ama__ECommerceEvent__OrderInfo *orderInfo = [tracker allocateSize:sizeof(Ama__ECommerceEvent__OrderInfo)];
                ama__ecommerce_event__order_info__init(orderInfo);
                orderInfo->order = order;
                NSArray<AMAECommerceAmount *> *result = [AMAECommerceUtils getECommerceMoneyFromOrder:orderInfo];
                [[theValue(result.count) should] equal:theValue(1)];
                [[result[0].value should] equal:[NSDecimalNumber decimalNumberWithString:@"1.2"]];
                [[result[0].unit should] equal:@"USD"];
            }];
        });
        it(@"Should ignore NULL value", ^{
            [AMAAllocationsTrackerProvider track:^(id<AMAAllocationsTracking> tracker) {
                Ama__ECommerceEvent__Order *order = [tracker allocateSize:sizeof(Ama__ECommerceEvent__Order)];
                ama__ecommerce_event__order__init(order);
                order->items = [tracker allocateSize:sizeof(Ama__ECommerceEvent__Order) * 2];
                order->n_items = 2;
                Ama__ECommerceEvent__OrderCartItem *orderCartItem = [tracker allocateSize:sizeof(Ama__ECommerceEvent__OrderCartItem)];
                ama__ecommerce_event__order_cart_item__init(orderCartItem);
                Ama__ECommerceEvent__CartItem *cartItem = [tracker allocateSize:sizeof(Ama__ECommerceEvent__CartItem)];
                ama__ecommerce_event__cart_item__init(cartItem);
                Ama__ECommerceEvent__Price *price = [tracker allocateSize:sizeof(Ama__ECommerceEvent__Price)];
                ama__ecommerce_event__price__init(price);
                Ama__ECommerceEvent__Amount *fiat = [tracker allocateSize:sizeof(Ama__ECommerceEvent__Amount)];
                ama__ecommerce_event__amount__init(fiat);
                fiat->value = NULL;
                fiat->has_unit_type = true;
                [AMAProtobufUtilities fillBinaryData:&fiat->unit_type
                                          withString:@"BYN"
                                             tracker:tracker];
                price->fiat = fiat;
                cartItem->revenue = price;
                orderCartItem->item = cartItem;
                order->items[0] = orderCartItem;
                order->items[1] = createCartItem(@"USD", [NSDecimalNumber decimalNumberWithString:@"1.2"], tracker);
                Ama__ECommerceEvent__OrderInfo *orderInfo = [tracker allocateSize:sizeof(Ama__ECommerceEvent__OrderInfo)];
                ama__ecommerce_event__order_info__init(orderInfo);
                orderInfo->order = order;
                NSArray<AMAECommerceAmount *> *result = [AMAECommerceUtils getECommerceMoneyFromOrder:orderInfo];
                [[theValue(result.count) should] equal:theValue(1)];
                [[result[0].value should] equal:[NSDecimalNumber decimalNumberWithString:@"1.2"]];
                [[result[0].unit should] equal:@"USD"];
            }];
        });
        it(@"Should convert several items", ^{
            [AMAAllocationsTrackerProvider track:^(id<AMAAllocationsTracking> tracker) {
                Ama__ECommerceEvent__Order *order = [tracker allocateSize:sizeof(Ama__ECommerceEvent__Order)];
                ama__ecommerce_event__order__init(order);
                order->items = [tracker allocateSize:sizeof(Ama__ECommerceEvent__Order) * 2];
                order->n_items = 2;
                order->items[0] = createCartItem(@"BYN", [NSDecimalNumber decimalNumberWithString:@"333"], tracker);
                order->items[1] = createCartItem(@"USD", [NSDecimalNumber decimalNumberWithString:@"1.2"], tracker);
                Ama__ECommerceEvent__OrderInfo *orderInfo = [tracker allocateSize:sizeof(Ama__ECommerceEvent__OrderInfo)];
                ama__ecommerce_event__order_info__init(orderInfo);
                orderInfo->order = order;
                NSArray<AMAECommerceAmount *> *result = [AMAECommerceUtils getECommerceMoneyFromOrder:orderInfo];
                [[theValue(result.count) should] equal:theValue(2)];
                [[result[0].value should] equal:[NSDecimalNumber decimalNumberWithString:@"333"]];
                [[result[0].unit should] equal:@"BYN"];
                [[result[1].value should] equal:[NSDecimalNumber decimalNumberWithString:@"1.2"]];
                [[result[1].unit should] equal:@"USD"];
            }];
        });
    });
});

SPEC_END
