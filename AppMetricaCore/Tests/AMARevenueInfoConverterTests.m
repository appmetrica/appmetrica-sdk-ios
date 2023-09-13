#import <Kiwi/Kiwi.h>

#import "AMARevenueInfoConverter.h"
#import "AMARevenueInfoModel.h"
#import "AMARevenueInfo.h"
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMAAppMetrica.h"
#import "AMASubscriptionInfoModel.h"
#import "AMATransactionInfoModel.h"

SPEC_BEGIN(AMARevenueInfoConverterTests)

describe(@"AMARevenueInfoConverter", ^{

    double const price = 23.55;
    NSDecimalNumber *const priceDecimal = [NSDecimalNumber decimalNumberWithString:@"23.55"];
    NSString *const currency = @"USD";

    AMAMutableRevenueInfo *__block revenueInfo = nil;

    beforeEach(^{
        revenueInfo = [[AMAMutableRevenueInfo alloc] initWithPriceDecimal:priceDecimal currency:currency];
    });

    context(@"Payload", ^{
        NSDictionary *const payload = @{ @"foo": @"bar" };
        NSString *const expectedPayloadString = @"{\"foo\":\"bar\"}";
        beforeEach(^{
            revenueInfo.payload = payload;
        });
        context(@"Normal", ^{
            it(@"Should return model with valid value", ^{
                [[[AMARevenueInfoConverter convertRevenueInfo:revenueInfo error:nil].payloadString should] equal:expectedPayloadString];
            });
            it(@"Should not fill error", ^{
                NSError *error = nil;
                [AMARevenueInfoConverter convertRevenueInfo:revenueInfo error:&error];
                [[error should] beNil];
            });
            it(@"Should return model with zero bytesTruncated", ^{
                [[theValue([AMARevenueInfoConverter convertRevenueInfo:revenueInfo error:nil].bytesTruncated) should] beZero];
            });
        });
        context(@"Non-JSON", ^{
            NSDictionary *const payload = @{ @[ @"foo", @"bar" ]: @"bar" };
            beforeEach(^{
                [AMATestUtilities stubAssertions];
                revenueInfo.payload = payload;
            });
            it(@"Should fill error", ^{
                NSString *desription =
                @"Passed dictionary is not a valid serializable JSON object: {\n    \"Wrong JSON object\" ="
                "     {\n                (\n            foo,\n            bar\n        ) = bar;\n    };\n}";
                NSError *expectedError = [NSError errorWithDomain:kAMAAppMetricaErrorDomain
                                                             code:AMAAppMetricaInternalEventJsonSerializationError
                                                         userInfo:@{ NSLocalizedDescriptionKey: desription }];
                NSError *error = nil;
                [AMARevenueInfoConverter convertRevenueInfo:revenueInfo error:&error];
                [[error should] equal:expectedError];
            });
        });
    });
    context(@"All fields", ^{
        NSUInteger quantity = 10;
        NSString *productID = @"pid";
        NSString *transactionID = @"tid";
        NSData *receiptData = [@"aaa bbb" dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *const payload = @{ @"foo": @"bar" };
        NSString *const expectedPayloadString = @"{\"foo\":\"bar\"}";
        AMARevenueInfoModel *__block converted = nil;

        AMARevenueInfo *revenue =
            [[AMARevenueInfo alloc] initWithPriceDecimal:priceDecimal
                                                currency:currency
                                                quantity:quantity
                                               productID:productID
                                           transactionID:transactionID
                                             receiptData:receiptData
                                                 payload:payload];
        beforeEach(^{
            converted = [AMARevenueInfoConverter convertRevenueInfo:revenue error:nil];
        });
        it(@"Should convert price decimal", ^{
            [[converted.priceDecimal should] equal:priceDecimal];
        });
        it(@"Should convert currency", ^{
            [[converted.currency should] equal:currency];
        });
        it(@"Should convert quantity", ^{
            [[theValue(converted.quantity) should] equal:theValue(quantity)];
        });
        it(@"Should convert product ID", ^{
            [[converted.productID should] equal:productID];
        });
        it(@"Should convert transaction ID", ^{
            [[converted.transactionID should] equal:transactionID];
        });
        it(@"Should convert receipt data", ^{
            [[converted.receiptData should] equal:receiptData];
        });
        it(@"Should convert payload", ^{
            [[converted.payloadString should] equal:expectedPayloadString];
        });
        it(@"Should be NO for auto collecting", ^{
            [[theValue(converted.isAutoCollected) should] beNo];
        });
        it(@"Should be purchase for type", ^{
            [[theValue(converted.inAppType) should] equal:theValue(AMAInAppTypePurchase)];
        });
        it(@"Subscription info should be nil", ^{
            [[converted.subscriptionInfo should] beNil];
        });
        it(@"Transaction info should be nil", ^{
            [[converted.transactionInfo should] beNil];
        });
        it(@"Bytes truncated should be zero", ^{
            [[theValue(converted.bytesTruncated) should] beZero];
        });
    });
});

SPEC_END
