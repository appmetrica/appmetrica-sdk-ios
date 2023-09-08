
#import <Foundation/Foundation.h>
#import <Kiwi/Kiwi.h>
#import "AMAAttributionConvertingUtils.h"

SPEC_BEGIN(AMAAttributionConvertingUtilsTests)

describe(@"AMAAttributionConvertingUtils", ^{

    context(@"stringForECommerceType", ^{
        it(@"Should convert show_screen", ^{
            NSString *result = [AMAAttributionConvertingUtils stringForECommerceType:AMAECommerceEventTypeScreen];
            [[result should] equal:@"show_screen"];
        });
        it(@"Should convert product_card", ^{
            NSString *result = [AMAAttributionConvertingUtils stringForECommerceType:AMAECommerceEventTypeProductCard];
            [[result should] equal:@"show_product_card"];
        });
        it(@"Should convert product_details", ^{
            NSString *result = [AMAAttributionConvertingUtils stringForECommerceType:AMAECommerceEventTypeProductDetails];
            [[result should] equal:@"show_product_details"];
        });
        it(@"Should convert add_to_cart", ^{
            NSString *result = [AMAAttributionConvertingUtils stringForECommerceType:AMAECommerceEventTypeAddToCart];
            [[result should] equal:@"add_cart_item"];
        });
        it(@"Should convert remove_from_cart", ^{
            NSString *result = [AMAAttributionConvertingUtils stringForECommerceType:AMAECommerceEventTypeRemoveFromCart];
            [[result should] equal:@"remove_cart_item"];
        });
        it(@"Should convert begin_checkout", ^{
            NSString *result = [AMAAttributionConvertingUtils stringForECommerceType:AMAECommerceEventTypeBeginCheckout];
            [[result should] equal:@"begin_checkout"];
        });
        it(@"Should convert purchase", ^{
            NSString *result = [AMAAttributionConvertingUtils stringForECommerceType:AMAECommerceEventTypePurchase];
            [[result should] equal:@"purchase"];
        });
    });
    context(@"eCommerceTypeForString", ^{
        NSError *__block error = nil;
        beforeEach(^{
            error = nil;
        });
        it(@"Should convert show_screen", ^{
            AMAECommerceEventType result = [AMAAttributionConvertingUtils eCommerceTypeForString:@"show_screen"
                                                                                           error:&error];
            [[theValue(result) should] equal:theValue(AMAECommerceEventTypeScreen)];
            [[error should] beNil];
        });
        it(@"Should convert product_card", ^{
            AMAECommerceEventType result = [AMAAttributionConvertingUtils eCommerceTypeForString:@"show_product_card"
                                                                                           error:&error];
            [[theValue(result) should] equal:theValue(AMAECommerceEventTypeProductCard)];
            [[error should] beNil];
        });
        it(@"Should convert product_details", ^{
            AMAECommerceEventType result = [AMAAttributionConvertingUtils eCommerceTypeForString:@"show_product_details"
                                                                                           error:&error];
            [[theValue(result) should] equal:theValue(AMAECommerceEventTypeProductDetails)];
            [[error should] beNil];
        });
        it(@"Should convert add_cart_item", ^{
            AMAECommerceEventType result = [AMAAttributionConvertingUtils eCommerceTypeForString:@"add_cart_item"
                                                                                           error:&error];
            [[theValue(result) should] equal:theValue(AMAECommerceEventTypeAddToCart)];
            [[error should] beNil];
        });
        it(@"Should convert remove_cart_item", ^{
            AMAECommerceEventType result = [AMAAttributionConvertingUtils eCommerceTypeForString:@"remove_cart_item"
                                                                                           error:&error];
            [[theValue(result) should] equal:theValue(AMAECommerceEventTypeRemoveFromCart)];
            [[error should] beNil];
        });
        it(@"Should convert begin_checkout", ^{
            AMAECommerceEventType result = [AMAAttributionConvertingUtils eCommerceTypeForString:@"begin_checkout"
                                                                                           error:&error];
            [[theValue(result) should] equal:theValue(AMAECommerceEventTypeBeginCheckout)];
            [[error should] beNil];
        });
        it(@"Should convert purchase", ^{
            AMAECommerceEventType result = [AMAAttributionConvertingUtils eCommerceTypeForString:@"purchase"
                                                                                           error:&error];
            [[theValue(result) should] equal:theValue(AMAECommerceEventTypePurchase)];
            [[error should] beNil];
        });
        it(@"Should not convert bad string", ^{
            AMAECommerceEventType result = [AMAAttributionConvertingUtils eCommerceTypeForString:@"bad string"
                                                                                           error:&error];
            [[theValue(result) should] equal:theValue(AMAECommerceEventTypeScreen)];
            [[error shouldNot] beNil];
        });
    });
    context(@"modelTypeForString", ^{
        it(@"Should convert conversion", ^{
            AMAAttributionModelType result = [AMAAttributionConvertingUtils modelTypeForString:@"conversion"];
            [[theValue(result) should] equal:theValue(AMAAttributionModelTypeConversion)];
        });
        it(@"Should convert engagement", ^{
            AMAAttributionModelType result = [AMAAttributionConvertingUtils modelTypeForString:@"engagement"];
            [[theValue(result) should] equal:theValue(AMAAttributionModelTypeEngagement)];
        });
        it(@"Should convert revenue", ^{
            AMAAttributionModelType result = [AMAAttributionConvertingUtils modelTypeForString:@"revenue"];
            [[theValue(result) should] equal:theValue(AMAAttributionModelTypeRevenue)];
        });
        it(@"Should convert bad string", ^{
            AMAAttributionModelType result = [AMAAttributionConvertingUtils modelTypeForString:@"bad string"];
            [[theValue(result) should] equal:theValue(AMAAttributionModelTypeUnknown)];
        });
    });
    context(@"eventTypeForString", ^{
        NSError *__block error = nil;
        beforeEach(^{
            error = nil;
        });
        it(@"Should convert client", ^{
            AMAEventType eventType = [AMAAttributionConvertingUtils eventTypeForString:@"client" error:&error];
            [[theValue(eventType) should] equal:theValue(AMAEventTypeClient)];
            [[error should] beNil];
        });
        it(@"Should convert revenue", ^{
            AMAEventType eventType = [AMAAttributionConvertingUtils eventTypeForString:@"revenue" error:&error];
            [[theValue(eventType) should] equal:theValue(AMAEventTypeRevenue)];
            [[error should] beNil];
        });
        it(@"Should convert e-commerce", ^{
            AMAEventType eventType = [AMAAttributionConvertingUtils eventTypeForString:@"ecom" error:&error];
            [[theValue(eventType) should] equal:theValue(AMAEventTypeECommerce)];
            [[error should] beNil];
        });
        it(@"Should not convert bad string", ^{
            AMAEventType eventType = [AMAAttributionConvertingUtils eventTypeForString:@"bad string" error:&error];
            [[theValue(eventType) should] equal:theValue(AMAEventTypeClient)];
            [[error shouldNot] beNil];
        });
    });
    context(@"revenueSourceForString", ^{
        NSError *__block error = nil;
        beforeEach(^{
            error = nil;
        });
        it(@"Should convert auto", ^{
            AMARevenueSource result = [AMAAttributionConvertingUtils revenueSourceForString:@"automatic" error:&error];
            [[theValue(result) should] equal:theValue(AMARevenueSourceAuto)];
            [[error should] beNil];
        });

        it(@"Should convert api", ^{
            AMARevenueSource result = [AMAAttributionConvertingUtils revenueSourceForString:@"api" error:&error];
            [[theValue(result) should] equal:theValue(AMARevenueSourceAPI)];
            [[error should] beNil];
        });
        it(@"Should not convert bad string", ^{
            AMARevenueSource result = [AMAAttributionConvertingUtils revenueSourceForString:@"bad string" error:&error];
            [[theValue(result) should] equal:theValue(AMARevenueSourceAPI)];
            [[error shouldNot] beNil];
        });
    });
});

SPEC_END
