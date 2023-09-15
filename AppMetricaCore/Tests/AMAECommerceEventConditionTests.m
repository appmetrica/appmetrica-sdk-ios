
#import <Foundation/Foundation.h>
#import <Kiwi/Kiwi.h>
#import "AMAECommerceEventCondition.h"

SPEC_BEGIN(AMAECommerceEventConditionTests)

describe(@"AMAECommerceEventCondition", ^{
    context(@"Init with JSON", ^{
        it(@"Should return nil for nil json", ^{
            [[[[AMAECommerceEventCondition alloc] initWithJSON:nil] should] beNil];
        });
        it(@"Type screen", ^{
            NSDictionary *json = @{ @"type" : @0 };
            AMAECommerceEventCondition *condition = [[AMAECommerceEventCondition alloc] initWithJSON:json];
            [[theValue([condition checkEvent:AMAECommerceEventTypeScreen]) should] beYes];
        });
        it(@"Type product card", ^{
            NSDictionary *json = @{ @"type" : @1 };
            AMAECommerceEventCondition *condition = [[AMAECommerceEventCondition alloc] initWithJSON:json];
            [[theValue([condition checkEvent:AMAECommerceEventTypeProductCard]) should] beYes];
        });
        it(@"Type product details", ^{
            NSDictionary *json = @{ @"type" : @2 };
            AMAECommerceEventCondition *condition = [[AMAECommerceEventCondition alloc] initWithJSON:json];
            [[theValue([condition checkEvent:AMAECommerceEventTypeProductDetails]) should] beYes];
        });
        it(@"Type add to cart", ^{
            NSDictionary *json = @{ @"type" : @3 };
            AMAECommerceEventCondition *condition = [[AMAECommerceEventCondition alloc] initWithJSON:json];
            [[theValue([condition checkEvent:AMAECommerceEventTypeAddToCart]) should] beYes];
        });
        it(@"Type remove from cart", ^{
            NSDictionary *json = @{ @"type" : @4 };
            AMAECommerceEventCondition *condition = [[AMAECommerceEventCondition alloc] initWithJSON:json];
            [[theValue([condition checkEvent:AMAECommerceEventTypeRemoveFromCart]) should] beYes];
        });
        it(@"Type begin checkout", ^{
            NSDictionary *json = @{ @"type" : @5 };
            AMAECommerceEventCondition *condition = [[AMAECommerceEventCondition alloc] initWithJSON:json];
            [[theValue([condition checkEvent:AMAECommerceEventTypeBeginCheckout]) should] beYes];
        });
        it(@"Type purchase", ^{
            NSDictionary *json = @{ @"type" : @6 };
            AMAECommerceEventCondition *condition = [[AMAECommerceEventCondition alloc] initWithJSON:json];
            [[theValue([condition checkEvent:AMAECommerceEventTypePurchase]) should] beYes];
        });
    });
    context(@"JSON", ^{
        it(@"Type screen", ^{
            AMAECommerceEventCondition *condition = [[AMAECommerceEventCondition alloc] initWithType:AMAECommerceEventTypeScreen];
            [[[condition JSON] should] equal:@{ @"type" : @0 }];
        });
        it(@"Type product card", ^{
            AMAECommerceEventCondition *condition = [[AMAECommerceEventCondition alloc] initWithType:AMAECommerceEventTypeProductCard];
            [[[condition JSON] should] equal:@{ @"type" : @1 }];
        });
        it(@"Type product details", ^{
            AMAECommerceEventCondition *condition = [[AMAECommerceEventCondition alloc] initWithType:AMAECommerceEventTypeProductDetails];
            [[[condition JSON] should] equal:@{ @"type" : @2 }];
        });
        it(@"Type add to cart", ^{
            AMAECommerceEventCondition *condition = [[AMAECommerceEventCondition alloc] initWithType:AMAECommerceEventTypeAddToCart];
            [[[condition JSON] should] equal:@{ @"type" : @3 }];
        });
        it(@"Type remove from cart", ^{
            AMAECommerceEventCondition *condition = [[AMAECommerceEventCondition alloc] initWithType:AMAECommerceEventTypeRemoveFromCart];
            [[[condition JSON] should] equal:@{ @"type" : @4 }];
        });
        it(@"Type begin checkout", ^{
            AMAECommerceEventCondition *condition = [[AMAECommerceEventCondition alloc] initWithType:AMAECommerceEventTypeBeginCheckout];
            [[[condition JSON] should] equal:@{ @"type" : @5 }];
        });
        it(@"Type purchase", ^{
            AMAECommerceEventCondition *condition = [[AMAECommerceEventCondition alloc] initWithType:AMAECommerceEventTypePurchase];
            [[[condition JSON] should] equal:@{ @"type" : @06 }];
        });
    });
    context(@"Convert", ^{
        context(@"Type screen", ^{
            AMAECommerceEventCondition *condition = [[AMAECommerceEventCondition alloc] initWithType:AMAECommerceEventTypeScreen];
            it(@"Should be YES for right type", ^{
                [[theValue([condition checkEvent:AMAECommerceEventTypeScreen]) should] beYes];
            });
            it(@"Should be NO for wrong name", ^{
                [[theValue([condition checkEvent:AMAECommerceEventTypeProductCard]) should] beNo];
            });
        });
        context(@"Type product card", ^{
            AMAECommerceEventCondition *condition = [[AMAECommerceEventCondition alloc] initWithType:AMAECommerceEventTypeProductCard];
            it(@"Should be YES for right type", ^{
                [[theValue([condition checkEvent:AMAECommerceEventTypeProductCard]) should] beYes];
            });
            it(@"Should be NO for wrong name", ^{
                [[theValue([condition checkEvent:AMAECommerceEventTypeProductDetails]) should] beNo];
            });
        });
        context(@"Type product details", ^{
            AMAECommerceEventCondition *condition = [[AMAECommerceEventCondition alloc] initWithType:AMAECommerceEventTypeProductDetails];
            it(@"Should be YES for right type", ^{
                [[theValue([condition checkEvent:AMAECommerceEventTypeProductDetails]) should] beYes];
            });
            it(@"Should be NO for wrong name", ^{
                [[theValue([condition checkEvent:AMAECommerceEventTypeAddToCart]) should] beNo];
            });
        });
        context(@"Type add to cart", ^{
            AMAECommerceEventCondition *condition = [[AMAECommerceEventCondition alloc] initWithType:AMAECommerceEventTypeAddToCart];
            it(@"Should be YES for right type", ^{
                [[theValue([condition checkEvent:AMAECommerceEventTypeAddToCart]) should] beYes];
            });
            it(@"Should be NO for wrong name", ^{
                [[theValue([condition checkEvent:AMAECommerceEventTypeRemoveFromCart]) should] beNo];
            });
        });
        context(@"Type remove from cart", ^{
            AMAECommerceEventCondition *condition = [[AMAECommerceEventCondition alloc] initWithType:AMAECommerceEventTypeRemoveFromCart];
            it(@"Should be YES for right type", ^{
                [[theValue([condition checkEvent:AMAECommerceEventTypeRemoveFromCart]) should] beYes];
            });
            it(@"Should be NO for wrong name", ^{
                [[theValue([condition checkEvent:AMAECommerceEventTypeBeginCheckout]) should] beNo];
            });
        });
        context(@"Type begin checkout", ^{
            AMAECommerceEventCondition *condition = [[AMAECommerceEventCondition alloc] initWithType:AMAECommerceEventTypeBeginCheckout];
            it(@"Should be YES for right type", ^{
                [[theValue([condition checkEvent:AMAECommerceEventTypeBeginCheckout]) should] beYes];
            });
            it(@"Should be NO for wrong name", ^{
                [[theValue([condition checkEvent:AMAECommerceEventTypePurchase]) should] beNo];
            });
        });
        context(@"Type purchase", ^{
            AMAECommerceEventCondition *condition = [[AMAECommerceEventCondition alloc] initWithType:AMAECommerceEventTypePurchase];
            it(@"Should be YES for right type", ^{
                [[theValue([condition checkEvent:AMAECommerceEventTypePurchase]) should] beYes];
            });
            it(@"Should be NO for wrong name", ^{
                [[theValue([condition checkEvent:AMAECommerceEventTypeScreen]) should] beNo];
            });
        });
    });
    
    it(@"Should conform to AMAJSONSerializable", ^{
        AMAECommerceEventCondition *condition = [[AMAECommerceEventCondition alloc] init];
        [[condition should] conformToProtocol:@protocol(AMAJSONSerializable)];
    });
});

SPEC_END
