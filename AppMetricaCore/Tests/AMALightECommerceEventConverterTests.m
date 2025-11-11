
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMAECommerceSerializer.h"
#import "AMALightECommerceEventConverter.h"
#import "AMAECommerce+Internal.h"
#import "AMALightECommerceEvent.h"
#import "AMAECommerceUtils.h"
#import "AMALightECommerceEvent.h"
#import "AMABinaryEventValue.h"

SPEC_BEGIN(AMALightECommerceEventConverterTests)

describe(@"AMALightECommerceEventConverter", ^{

    AMALightECommerceEventConverter *converter = [[AMALightECommerceEventConverter alloc] init];

    context(@"Event from model", ^{
        AMAECommerce *__block eCommerce = nil;
        beforeEach(^{
            eCommerce = [AMAECommerce nullMock];
        });
        it(@"Should be first", ^{
            AMALightECommerceEvent *converted = [converter eventFromModel:eCommerce];
            [[theValue(converted.isFirst) should] beYes];
        });
        it(@"Should convert type", ^{
            [eCommerce stub:@selector(eventType) andReturn:theValue(AMAECommerceEventTypePurchase)];
            AMALightECommerceEvent *converted = [converter eventFromModel:eCommerce];
            [[theValue(converted.type) should] equal:theValue(AMAECommerceEventTypePurchase)];
        });
        context(@"Amounts", ^{
            AMAECommerceOrder *__block order = nil;
            beforeEach(^{
                order = [AMAECommerceOrder nullMock];
            });
            it(@"No order", ^{
                [eCommerce stub:@selector(order) andReturn:nil];
                AMALightECommerceEvent *converted = [converter eventFromModel:eCommerce];
                [[converted.amounts should] equal:@[]];
            });
            it(@"Nil cart items", ^{
                [eCommerce stub:@selector(order) andReturn:order];
                [order stub:@selector(cartItems) andReturn:nil];
                AMALightECommerceEvent *converted = [converter eventFromModel:eCommerce];
                [[converted.amounts should] equal:@[]];
            });
            it(@"Empty cart items", ^{
                [eCommerce stub:@selector(order) andReturn:order];
                [order stub:@selector(cartItems) andReturn:@[]];
                AMALightECommerceEvent *converted = [converter eventFromModel:eCommerce];
                [[converted.amounts should] equal:@[]];
            });
            it(@"Has null revenue", ^{
                AMAECommerceCartItem *firstCartItem = [AMAECommerceCartItem nullMock];
                AMAECommerceCartItem *secondCartItem = [AMAECommerceCartItem nullMock];
                AMAECommerceCartItem *thirdCartItem = [AMAECommerceCartItem nullMock];
                AMAECommerceAmount *firstAmount = [AMAECommerceAmount nullMock];
                AMAECommerceAmount *thirdAmount = [AMAECommerceAmount nullMock];
                [firstCartItem stub:@selector(revenue) andReturn:[[AMAECommercePrice alloc] initWithFiat:firstAmount]];
                [secondCartItem stub:@selector(revenue) andReturn:nil];
                [thirdCartItem stub:@selector(revenue) andReturn:[[AMAECommercePrice alloc] initWithFiat:thirdAmount]];
                [eCommerce stub:@selector(order) andReturn:order];
                [order stub:@selector(cartItems) andReturn:@[ firstCartItem, secondCartItem, thirdCartItem ]];
                AMALightECommerceEvent *converted = [converter eventFromModel:eCommerce];
                [[converted.amounts should] equal:@[ firstAmount, thirdAmount ]];
            });
            it(@"Should convert everything", ^{
                AMAECommerceCartItem *firstCartItem = [AMAECommerceCartItem nullMock];
                AMAECommerceCartItem *secondCartItem = [AMAECommerceCartItem nullMock];
                AMAECommerceAmount *firstAmount = [AMAECommerceAmount nullMock];
                AMAECommerceAmount *secondAmount = [AMAECommerceAmount nullMock];
                [firstCartItem stub:@selector(revenue) andReturn:[[AMAECommercePrice alloc] initWithFiat:firstAmount]];
                [secondCartItem stub:@selector(revenue) andReturn:[[AMAECommercePrice alloc] initWithFiat:secondAmount]];
                [eCommerce stub:@selector(order) andReturn:order];
                [order stub:@selector(cartItems) andReturn:@[ firstCartItem, secondCartItem ]];
                AMALightECommerceEvent *converted = [converter eventFromModel:eCommerce];
                [[converted.amounts should] equal:@[ firstAmount, secondAmount ]];
            });
        });
    });

    context(@"Event from serialized value", ^{
        AMAECommerceSerializer *serializer = [[AMAECommerceSerializer alloc] init];

        id __block value;
        __auto_type valueWithECommerce = ^id(AMAECommerce *eCommerce) {
            NSData *data = [serializer serializeECommerce:eCommerce][0].data;
            return [[AMABinaryEventValue alloc] initWithData:data gZipped:NO];
        };
        AMAECommerceProduct *product = [[AMAECommerceProduct alloc] initWithSKU:@"sku"];
        AMAECommercePrice *price = [[AMAECommercePrice alloc] initWithFiat:[[AMAECommerceAmount alloc] initWithUnit:@"USD"
                                                                                                              value:[NSDecimalNumber zero]]];
        AMAECommerceCartItem *cartItem = [[AMAECommerceCartItem alloc] initWithProduct:product
                                                                              quantity:[NSDecimalNumber zero]
                                                                               revenue:price
                                                                              referrer:nil];
        AMAECommerceOrder *order = [[AMAECommerceOrder alloc] initWithIdentifier:@"id"
                                                                       cartItems:@[ cartItem ]];
        context(@"Type", ^{
            beforeEach(^{
                [AMAECommerceUtils stub:@selector(convertECommerceEventProtoType:error:)
                              andReturn:theValue(AMAECommerceEventTypeBeginCheckout)];
            });
            it(@"Should fill type", ^{
                value = valueWithECommerce([AMAECommerce beginCheckoutEventWithOrder:order]);
                AMALightECommerceEvent * result = [converter eventFromSerializedValue:value];
                [[theValue(result.type) should] equal:theValue(AMAECommerceEventTypeBeginCheckout)];

            });
            it(@"Should convert type", ^{
                [[AMAECommerceUtils should] receive:@selector(convertECommerceEventProtoType:error:)
                                      withArguments:theValue(AMA__ECOMMERCE_EVENT__ECOMMERCE_EVENT_TYPE__ECOMMERCE_EVENT_TYPE_BEGIN_CHECKOUT), kw_any()];
                value = valueWithECommerce([AMAECommerce beginCheckoutEventWithOrder:order]);
                [converter eventFromSerializedValue:value];
            });
        });
        context(@"Is first", ^{
            beforeEach(^{
                [AMAECommerceUtils stub:@selector(isFirstECommerceEvent:) andReturn:theValue(YES)];
            });
            it(@"Should fill isFirst", ^{
                value = valueWithECommerce([AMAECommerce beginCheckoutEventWithOrder:order]);
                AMALightECommerceEvent * result = [converter eventFromSerializedValue:value];
                [[theValue(result.isFirst) should] beYes];

            });
            it(@"Should convert isFirst", ^{
                [[AMAECommerceUtils should] receive:@selector(isFirstECommerceEvent:)];
                value = valueWithECommerce([AMAECommerce beginCheckoutEventWithOrder:order]);
                [converter eventFromSerializedValue:value];
            });
        });
        context(@"Amounts", ^{
            NSArray *__block amounts = nil;
            beforeEach(^{
                amounts = @[ [AMAECommerceAmount nullMock], [AMAECommerceAmount nullMock] ];
                [AMAECommerceUtils stub:@selector(getECommerceMoneyFromOrder:) andReturn:amounts];
            });
            it(@"Should fill amounts", ^{
                value = valueWithECommerce([AMAECommerce beginCheckoutEventWithOrder:order]);
                AMALightECommerceEvent * result = [converter eventFromSerializedValue:value];
                [[result.amounts should] equal:amounts];

            });
            it(@"Should convert isFirst", ^{
                [[AMAECommerceUtils should] receive:@selector(getECommerceMoneyFromOrder:)];
                value = valueWithECommerce([AMAECommerce beginCheckoutEventWithOrder:order]);
                [converter eventFromSerializedValue:value];
            });
        });
    });
});

SPEC_END
