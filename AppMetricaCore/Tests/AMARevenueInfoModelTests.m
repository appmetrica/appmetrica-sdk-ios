
#import <Kiwi/Kiwi.h>
#import "AMARevenueInfoModel.h"
#import "AMASubscriptionInfoModel.h"
#import "AMATransactionInfoModel.h"

SPEC_BEGIN(AMARevenueInfoModelTests)

describe(@"AMARevenueInfoModel", ^{

    double const price = 23.55;
    NSDecimalNumber *const priceDecimal = [NSDecimalNumber decimalNumberWithString:@"23.55"];
    NSString *const currency = @"CURRENCY";
    NSUInteger const quantity = 42;
    NSString *const productID = @"PRODUCT_ID";
    NSString *const transactionID = @"TRANSACTION_ID";
    NSData *const receiptData = [@"RECEIPT_DATA" dataUsingEncoding:NSUTF8StringEncoding];
    NSString *const payloadString = @"PAYLOAD_STRING";
    NSUInteger const bytesTruncated = 108;
    AMASubscriptionInfoModel *__block subscriptionInfo = nil;
    AMATransactionInfoModel *__block transactionInfo = nil;

    AMARevenueInfoModel *__block model = nil;

    beforeEach(^{
        subscriptionInfo = [AMASubscriptionInfoModel nullMock];
        transactionInfo = [AMATransactionInfoModel nullMock];
        model = [[AMARevenueInfoModel alloc] initWithPriceDecimal:priceDecimal
                                                         currency:currency
                                                         quantity:quantity
                                                        productID:productID
                                                    transactionID:transactionID
                                                      receiptData:receiptData
                                                    payloadString:payloadString
                                                   bytesTruncated:bytesTruncated
                                                  isAutoCollected:YES
                                                        inAppType:AMAInAppTypePurchase
                                                 subscriptionInfo:subscriptionInfo
                                                  transactionInfo:transactionInfo];
    });
    it(@"Should store priceDecimal", ^{
        [[model.priceDecimal should] equal:model.priceDecimal];
    });
    it(@"Should store currency", ^{
        [[model.currency should] equal:currency];
    });
    it(@"Should store quantity", ^{
        [[theValue(model.quantity) should] equal:theValue(quantity)];
    });
    it(@"Should store productID", ^{
        [[model.productID should] equal:productID];
    });
    it(@"Should store transactionID", ^{
        [[model.transactionID should] equal:transactionID];
    });
    it(@"Should store receiptData", ^{
        [[model.receiptData should] equal:receiptData];
    });
    it(@"Should store payloadString", ^{
        [[model.payloadString should] equal:payloadString];
    });
    it(@"Should store bytesTruncated", ^{
        [[theValue(model.bytesTruncated) should] equal:theValue(bytesTruncated)];
    });
    it(@"Should store isAutoCollected", ^{
        [[theValue(model.isAutoCollected) should] beYes];
    });
    it(@"Should store inAppType", ^{
        [[theValue(model.inAppType) should] equal:theValue(AMAInAppTypePurchase)];
    });
    it(@"Should store subscriptionInfo", ^{
        [[model.subscriptionInfo should] equal:subscriptionInfo];
    });
    it(@"Should store transactionInfo", ^{
        [[model.transactionInfo should] equal:transactionInfo];
    });
});

SPEC_END
