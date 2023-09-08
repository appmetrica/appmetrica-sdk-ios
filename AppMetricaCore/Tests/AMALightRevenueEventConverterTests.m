
#import <Kiwi/Kiwi.h>
#import "AMALightRevenueEventConverter.h"
#import "AMARevenueInfoModel.h"
#import "AMALightRevenueEvent.h"
#import "AMATransactionInfoModel.h"
#import "AMARevenueInfoModelSerializer.h"
#import "AMABinaryEventValue.h"

SPEC_BEGIN(AMALightRevenueEventConverterTests)

describe(@"AMALightRevenueEventConverter", ^{

    AMALightRevenueEventConverter *converter = [[AMALightRevenueEventConverter alloc] init];

    context(@"Event from model", ^{
        AMARevenueInfoModel *__block revenue = nil;
        AMALightRevenueEvent *__block result = nil;
        beforeEach(^{
            revenue = [AMARevenueInfoModel nullMock];
        });
        context(@"Price", ^{
            it(@"Has price decimal", ^{
                NSDecimalNumber *price = [NSDecimalNumber decimalNumberWithString:@"8989"];
                [revenue stub:@selector(priceDecimal) andReturn:price];
                result = [converter eventFromModel:revenue];
                [[result.priceMicros should] equal:[NSDecimalNumber decimalNumberWithString:@"8989000000"]];
            });
            it(@"Has zero price decimal", ^{
                [revenue stub:@selector(priceDecimal) andReturn:[NSDecimalNumber zero]];
                result = [converter eventFromModel:revenue];
                [[result.priceMicros should] equal:[NSDecimalNumber zero]];
            });
        });
        it(@"Should convert currency", ^{
            NSString *currency = @"USD";
            [revenue stub:@selector(currency) andReturn:currency];
            result = [converter eventFromModel:revenue];
            [[result.currency should] equal:currency];
        });
        it(@"Should convert quantity", ^{
            NSUInteger quantity = 15;
            [revenue stub:@selector(quantity) andReturn:theValue(quantity)];
            result = [converter eventFromModel:revenue];
            [[theValue(result.quantity) should] equal:theValue(quantity)];
        });
        it(@"Should convert transaction ID", ^{
            NSString *transactionID = @"some id";
            [revenue stub:@selector(transactionID) andReturn:transactionID];
            result = [converter eventFromModel:revenue];
            [[result.transactionID should] equal:transactionID];
        });
        it(@"Should convert autoCollected", ^{
            [revenue stub:@selector(isAutoCollected) andReturn:theValue(YES)];
            result = [converter eventFromModel:revenue];
            [[theValue(result.isAuto) should] beYes];
        });
        context(@"Restore", ^{
            AMATransactionInfoModel *__block transactionInfo = nil;
            beforeEach(^{
                transactionInfo = [AMATransactionInfoModel nullMock];
                [revenue stub:@selector(transactionInfo) andReturn:transactionInfo];
            });
            it(@"Should be NO for nil transaction info", ^{
                [revenue stub:@selector(transactionInfo) andReturn:nil];
                result = [converter eventFromModel:revenue];
                [[theValue(result.isRestore) should] beNo];
            });
            it(@"Should be NO for undefined transaction state", ^{
                [transactionInfo stub:@selector(transactionState) andReturn:theValue(AMATransactionStateUndefined)];
                result = [converter eventFromModel:revenue];
                [[theValue(result.isRestore) should] beNo];
            });
            it(@"Should be NO for purchased transaction state", ^{
                [transactionInfo stub:@selector(transactionState) andReturn:theValue(AMATransactionStatePurchased)];
                result = [converter eventFromModel:revenue];
                [[theValue(result.isRestore) should] beNo];
            });
            it(@"Should be YES for restored transaction state", ^{
                [transactionInfo stub:@selector(transactionState) andReturn:theValue(AMATransactionStateRestored)];
                result = [converter eventFromModel:revenue];
                [[theValue(result.isRestore) should] beYes];
            });
        });
    });
    context(@"Event from serialized value", ^{
        AMARevenueInfoModelSerializer *serializer = [[AMARevenueInfoModelSerializer alloc] init];
        AMARevenueInfoModel *__block revenue = nil;
        AMALightRevenueEvent *__block result = nil;
        __auto_type valueWithRevenue = ^id (AMARevenueInfoModel *revenue) {
            NSData *data = [serializer dataWithRevenueInfoModel:revenue];
            return [[AMABinaryEventValue alloc] initWithData:data gZipped:NO];
        };

        context(@"Price", ^{
            it(@"Has price decimal", ^{
                NSDecimalNumber *price = [NSDecimalNumber decimalNumberWithString:@"8989"];
                revenue = [[AMARevenueInfoModel alloc] initWithPriceDecimal:price
                                                                   currency:@"USD"
                                                                   quantity:1
                                                                  productID:nil
                                                              transactionID:nil
                                                                receiptData:nil
                                                              payloadString:nil
                                                             bytesTruncated:0
                                                            isAutoCollected:NO
                                                                  inAppType:AMAInAppTypePurchase
                                                           subscriptionInfo:nil
                                                            transactionInfo:nil];
                result = [converter eventFromSerializedValue:valueWithRevenue(revenue)];
                [[result.priceMicros should] equal:[NSDecimalNumber decimalNumberWithString:@"8989000000"]];
            });
            it(@"Has zero price", ^{
                revenue = [[AMARevenueInfoModel alloc] initWithPriceDecimal:nil
                                                                   currency:@"USD"
                                                                   quantity:1
                                                                  productID:nil
                                                              transactionID:nil
                                                                receiptData:nil
                                                              payloadString:nil
                                                             bytesTruncated:0
                                                            isAutoCollected:NO
                                                                  inAppType:AMAInAppTypePurchase
                                                           subscriptionInfo:nil
                                                            transactionInfo:nil];
                result = [converter eventFromSerializedValue:valueWithRevenue(revenue)];
                [[result.priceMicros should] equal:[NSDecimalNumber zero]];
            });
        });
        it(@"Should convert currency", ^{
            NSString *currency = @"USD";
            revenue = [[AMARevenueInfoModel alloc] initWithPriceDecimal:nil
                                                               currency:currency
                                                               quantity:1
                                                              productID:nil
                                                          transactionID:nil
                                                            receiptData:nil
                                                          payloadString:nil
                                                         bytesTruncated:0
                                                        isAutoCollected:NO
                                                              inAppType:AMAInAppTypePurchase
                                                       subscriptionInfo:nil
                                                        transactionInfo:nil];
            result = [converter eventFromSerializedValue:valueWithRevenue(revenue)];
            [[result.currency should] equal:currency];
        });
        it(@"Should convert quantity", ^{
            NSUInteger quantity = 15;
            revenue = [[AMARevenueInfoModel alloc] initWithPriceDecimal:nil
                                                               currency:@"USD"
                                                               quantity:quantity
                                                              productID:nil
                                                          transactionID:nil
                                                            receiptData:nil
                                                          payloadString:nil
                                                         bytesTruncated:0
                                                        isAutoCollected:NO
                                                              inAppType:AMAInAppTypePurchase
                                                       subscriptionInfo:nil
                                                        transactionInfo:nil];
            result = [converter eventFromSerializedValue:valueWithRevenue(revenue)];
            [[theValue(result.quantity) should] equal:theValue(quantity)];
        });
        it(@"Should convert transaction ID", ^{
            NSString *transactionID = @"some id";
            revenue = [[AMARevenueInfoModel alloc] initWithPriceDecimal:nil
                                                               currency:@"USD"
                                                               quantity:1
                                                              productID:nil
                                                          transactionID:transactionID
                                                            receiptData:nil
                                                          payloadString:nil
                                                         bytesTruncated:0
                                                        isAutoCollected:NO
                                                              inAppType:AMAInAppTypePurchase
                                                       subscriptionInfo:nil
                                                        transactionInfo:nil];
            result = [converter eventFromSerializedValue:valueWithRevenue(revenue)];
            [[result.transactionID should] equal:transactionID];
        });
        it(@"Should convert autoCollected", ^{
            revenue = [[AMARevenueInfoModel alloc] initWithPriceDecimal:nil
                                                               currency:@"USD"
                                                               quantity:1
                                                              productID:nil
                                                          transactionID:nil
                                                            receiptData:nil
                                                          payloadString:nil
                                                         bytesTruncated:0
                                                        isAutoCollected:YES
                                                              inAppType:AMAInAppTypePurchase
                                                       subscriptionInfo:nil
                                                        transactionInfo:nil];
            result = [converter eventFromSerializedValue:valueWithRevenue(revenue)];
            [[theValue(result.isAuto) should] beYes];
        });
        context(@"Restore", ^{
            AMATransactionInfoModel *__block transactionInfo = nil;
            it(@"Should be NO for nil transaction info", ^{
                revenue = [[AMARevenueInfoModel alloc] initWithPriceDecimal:nil
                                                                   currency:@"USD"
                                                                   quantity:1
                                                                  productID:nil
                                                              transactionID:nil
                                                                receiptData:nil
                                                              payloadString:nil
                                                             bytesTruncated:0
                                                            isAutoCollected:NO
                                                                  inAppType:AMAInAppTypePurchase
                                                           subscriptionInfo:nil
                                                            transactionInfo:nil];
                result = [converter eventFromSerializedValue:valueWithRevenue(revenue)];
                [[theValue(result.isRestore) should] beNo];
            });
            it(@"Should be NO for undefined transaction state", ^{
                transactionInfo =
                    [[AMATransactionInfoModel alloc] initWithTransactionID:nil
                                                           transactionTime:[NSDate date]
                                                          transactionState:AMATransactionStateUndefined
                                                               secondaryID:nil
                                                             secondaryTime:nil];
                revenue = [[AMARevenueInfoModel alloc] initWithPriceDecimal:nil
                                                                   currency:@"USD"
                                                                   quantity:1
                                                                  productID:nil
                                                              transactionID:nil
                                                                receiptData:nil
                                                              payloadString:nil
                                                             bytesTruncated:0
                                                            isAutoCollected:NO
                                                                  inAppType:AMAInAppTypePurchase
                                                           subscriptionInfo:nil
                                                            transactionInfo:transactionInfo];
                result = [converter eventFromSerializedValue:valueWithRevenue(revenue)];
                [[theValue(result.isRestore) should] beNo];
            });
            it(@"Should be NO for purchased transaction state", ^{
                transactionInfo =
                    [[AMATransactionInfoModel alloc] initWithTransactionID:nil
                                                           transactionTime:[NSDate date]
                                                          transactionState:AMATransactionStatePurchased
                                                               secondaryID:nil
                                                             secondaryTime:nil];
                revenue = [[AMARevenueInfoModel alloc] initWithPriceDecimal:nil
                                                                   currency:@"USD"
                                                                   quantity:1
                                                                  productID:nil
                                                              transactionID:nil
                                                                receiptData:nil
                                                              payloadString:nil
                                                             bytesTruncated:0
                                                            isAutoCollected:NO
                                                                  inAppType:AMAInAppTypePurchase
                                                           subscriptionInfo:nil
                                                            transactionInfo:transactionInfo];
                result = [converter eventFromSerializedValue:valueWithRevenue(revenue)];
                [[theValue(result.isRestore) should] beNo];
            });
            it(@"Should be YES for restored transaction state", ^{
                transactionInfo =
                    [[AMATransactionInfoModel alloc] initWithTransactionID:nil
                                                           transactionTime:[NSDate date]
                                                          transactionState:AMATransactionStateRestored
                                                               secondaryID:nil
                                                             secondaryTime:nil];
                revenue = [[AMARevenueInfoModel alloc] initWithPriceDecimal:nil
                                                                   currency:@"USD"
                                                                   quantity:1
                                                                  productID:nil
                                                              transactionID:nil
                                                                receiptData:nil
                                                              payloadString:nil
                                                             bytesTruncated:0
                                                            isAutoCollected:NO
                                                                  inAppType:AMAInAppTypePurchase
                                                           subscriptionInfo:nil
                                                            transactionInfo:transactionInfo];
                result = [converter eventFromSerializedValue:valueWithRevenue(revenue)];
                [[theValue(result.isRestore) should] beYes];
            });
        });
    });
});

SPEC_END
