
#import <Kiwi/Kiwi.h>
#import "AMARevenueInfo.h"

SPEC_BEGIN(AMARevenueInfoTests)

describe(@"AMARevenueInfo", ^{

    double const price = 23.55;
    NSDecimalNumber *const priceDecimal = [NSDecimalNumber decimalNumberWithString:@"23.55"];
    NSString *const currency = @"CURRENCY";
    NSUInteger const quantity = 42.0;
    NSString *const productID = @"PRODUCT_ID";
    NSString *const transactionID = @"TRANSACTION_ID";
    NSData *const receiptData = [@"RECEIPT_DATA" dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *const payload = @{ @"foo": @"bar" };

    context(@"Immutable", ^{
        AMARevenueInfo *__block revenueInfo = nil;
        beforeEach(^{
            revenueInfo = [[AMARevenueInfo alloc] initWithPriceDecimal:priceDecimal currency:currency];
        });
        context(@"Initialization", ^{
            it(@"Should store price", ^{
                [[revenueInfo.priceDecimal should] equal:priceDecimal];
            });
            it(@"Should store currency", ^{
                [[revenueInfo.currency should] equal:currency];
            });
        });
        context(@"Immutable copy", ^{
            it(@"Should return self", ^{
                [[[revenueInfo copy] should] equal:revenueInfo];
            });
        });
        context(@"Mutable copy", ^{
            AMAMutableRevenueInfo *__block revenueInfoCopy = nil;
            beforeEach(^{
                revenueInfoCopy = [revenueInfo mutableCopy];
            });
            it(@"Should copy price", ^{
                [[revenueInfoCopy.priceDecimal should] equal:priceDecimal];
            });
            it(@"Should copy currency", ^{
                [[revenueInfoCopy.currency should] equal:currency];
            });
        });
    });
    context(@"Mutable", ^{
        AMAMutableRevenueInfo *__block revenueInfo = nil;
        beforeEach(^{
            revenueInfo = [[AMAMutableRevenueInfo alloc] initWithPriceDecimal:priceDecimal currency:currency];
        });
        context(@"Initialization", ^{
            it(@"Should store price", ^{
                [[revenueInfo.priceDecimal should] equal:priceDecimal];
            });
            it(@"Should store currency", ^{
                [[revenueInfo.currency should] equal:currency];
            });
        });
        it(@"Should store quantity", ^{
            revenueInfo.quantity = quantity;
            [[theValue(revenueInfo.quantity) should] equal:theValue(quantity)];
        });
        it(@"Should store productID", ^{
            revenueInfo.productID = productID;
            [[revenueInfo.productID should] equal:productID];
        });
        it(@"Should store transactionID", ^{
            revenueInfo.transactionID = transactionID;
            [[revenueInfo.transactionID should] equal:transactionID];
        });
        it(@"Should store receiptData", ^{
            revenueInfo.receiptData = receiptData;
            [[revenueInfo.receiptData should] equal:receiptData];
        });
        it(@"Should store payload", ^{
            revenueInfo.payload = payload;
            [[revenueInfo.payload should] equal:payload];
        });
        context(@"Immutable copy", ^{
            AMARevenueInfo *__block revenueInfoCopy = nil;
            beforeEach(^{
                revenueInfo.quantity = quantity;
                revenueInfo.productID = productID;
                revenueInfo.transactionID = transactionID;
                revenueInfo.receiptData = receiptData;
                revenueInfo.payload = payload;
                revenueInfoCopy = [revenueInfo copy];
            });
            it(@"Should copy price", ^{
                [[revenueInfoCopy.priceDecimal should] equal:priceDecimal];
            });
            it(@"Should copy currency", ^{
                [[revenueInfoCopy.currency should] equal:currency];
            });
            it(@"Should copy quantity", ^{
                [[theValue(revenueInfoCopy.quantity) should] equal:theValue(quantity)];
            });
            it(@"Should copy productID", ^{
                [[revenueInfoCopy.productID should] equal:productID];
            });
            it(@"Should copy transactionID", ^{
                [[revenueInfoCopy.transactionID should] equal:transactionID];
            });
            it(@"Should copy receiptData", ^{
                [[revenueInfoCopy.receiptData should] equal:receiptData];
            });
            it(@"Should copy payload", ^{
                [[revenueInfoCopy.payload should] equal:payload];
            });
            context(@"Change mutable source", ^{
                it(@"Should not change quantity", ^{
                    revenueInfo.quantity = 32;
                    [[theValue(revenueInfoCopy.quantity) should] equal:theValue(quantity)];
                });
                it(@"Should not change productID", ^{
                    revenueInfo.productID = @"OTHER";
                    [[revenueInfoCopy.productID should] equal:productID];
                });
                it(@"Should not change transactionID", ^{
                    revenueInfo.transactionID = @"OTHER";
                    [[revenueInfoCopy.transactionID should] equal:transactionID];
                });
                it(@"Should not change receiptData", ^{
                    revenueInfo.receiptData = [@"OTHER" dataUsingEncoding:NSUTF8StringEncoding];
                    [[revenueInfoCopy.receiptData should] equal:receiptData];
                });
                it(@"Should not change payload", ^{
                    revenueInfo.payload = @{ @"bar": @"foo" };
                    [[revenueInfoCopy.payload should] equal:payload];
                });
            });
        });
    });

});

SPEC_END
