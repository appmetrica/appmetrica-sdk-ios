
#import <Kiwi/Kiwi.h>
#import <AppMetricaProtobufUtils/AppMetricaProtobufUtils.h>

#import "AMARevenueInfoModelSerializer.h"
#import "Revenue.pb-c.h"
#import "AMARevenueInfoModel.h"
#import "AMASubscriptionInfoModel.h"
#import "AMATransactionInfoModel.h"
#import "AMASubscriptionPeriod.h"
#import "AMAStringEventValue.h"
#import "AMABinaryEventValue.h"
#import "AMAECommerce.h"
#import "AMAECommerceSerializer.h"

SPEC_BEGIN(AMARevenueInfoModelSerializerTests)

describe(@"AMARevenueInfoModelSerializer", ^{

    AMAProtobufAllocator *__block allocator = nil;
    Ama__Revenue *__block revenue = NULL;
    AMARevenueInfoModel *__block model = nil;
    AMARevenueInfoModelSerializer *__block serializer = nil;

    beforeEach(^{
        serializer = [[AMARevenueInfoModelSerializer alloc] init];
    });

    beforeAll(^{
        allocator = [[AMAProtobufAllocator alloc] init];
    });

    Ama__Revenue *(^serializeAndDeserializeModel)(AMARevenueInfoModel *) = ^(AMARevenueInfoModel *model) {
        NSData *data = [serializer dataWithRevenueInfoModel:model];
        return ama__revenue__unpack([allocator protobufCAllocator], data.length, data.bytes);
    };

    NSString *(^stringForBinary)(ProtobufCBinaryData *) = ^(ProtobufCBinaryData *binaryData) {
        NSData *data = [NSData dataWithBytes:binaryData->data length:binaryData->len];
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    };

    context(@"Empty model", ^{
        beforeAll(^{
            model = [[AMARevenueInfoModel alloc] initWithPriceDecimal:nil
                                                             currency:nil
                                                             quantity:0
                                                            productID:nil
                                                        transactionID:nil
                                                          receiptData:nil
                                                        payloadString:nil
                                                       bytesTruncated:0
                                                      isAutoCollected:NO
                                                            inAppType:AMAInAppTypePurchase
                                                     subscriptionInfo:nil
                                                      transactionInfo:nil];
            revenue = serializeAndDeserializeModel(model);
        });
        it(@"Should fill price", ^{
            [[theValue(revenue->price) should] equal:0 withDelta:DBL_EPSILON];
        });
        it(@"Should fill has_price", ^{
            [[theValue(revenue->has_price) should] beYes];
        });
        it(@"Should not fill has_price_micros", ^{
            [[theValue(revenue->has_price_micros) should] beNo];
        });
        it(@"Should not fill currency", ^{
            [[stringForBinary(&(revenue->currency)) should] beEmpty];
        });
        it(@"Should fill has_quantity", ^{
            [[theValue(revenue->has_quantity) should] beYes];
        });
        it(@"Should fill quantity", ^{
            [[theValue(revenue->quantity) should] beZero];
        });
        it(@"Should not fill has_product_id", ^{
            [[theValue(revenue->has_product_id) should] beNo];
        });
        it(@"Should not fill receipt", ^{
            [[thePointerValue(revenue->receipt) should] equal:thePointerValue(NULL)];
        });
        it(@"Should not fill has_payload", ^{
            [[theValue(revenue->has_payload) should] beNo];
        });
        it(@"Should fill has_auto_collected", ^{
            [[theValue(revenue->has_auto_collected) should] beYes];
        });
        it(@"Should fill auto_collected", ^{
            [[theValue(revenue->auto_collected) should] beNo];
        });
        it(@"Should fill has_in_app_type", ^{
            [[theValue(revenue->has_in_app_type) should] beYes];
        });
        it(@"Should fill in_app_type", ^{
            [[theValue(revenue->in_app_type) should] equal:theValue(AMA__REVENUE__IN_APP_TYPE__PURCHASE)];
        });
        it(@"Should not fill transaction_info", ^{
            [[thePointerValue(revenue->transaction_info) should] equal:thePointerValue(NULL)];
        });
        it(@"Should not fill subscription_info", ^{
            [[thePointerValue(revenue->subscription_info) should] equal:thePointerValue(NULL)];
        });
    });
    context(@"Complete model", ^{
        NSString *const currency = @"USD";
        NSUInteger const quantity = 42;
        NSString *const productID = @"PRODUCT_ID";
        NSString *const transactionID = @"TRANSACTION_ID";
        NSString *const secondaryID = @"ORIGINAL_ID";
        NSData *const receiptData = [@"RECEIPT_DATA" dataUsingEncoding:NSUTF8StringEncoding];
        NSString *const payloadString = @"PAYLOAD_STRING";
        NSUInteger const bytesTruncated = 108;
        NSString *const introductaryID = @"INTRODUCTARY_ID";
        NSDecimalNumber *const introductoryPrice = [NSDecimalNumber decimalNumberWithString:@"14.28"];
        NSDate *const transactionDate = [NSDate date];
        NSDate *const secondaryDate = [NSDate dateWithTimeIntervalSinceNow:-1000];
        AMASubscriptionPeriod *const subscriptionPeriod = [[AMASubscriptionPeriod alloc] initWithCount:1 timeUnit:AMATimeUnitYear];
        AMASubscriptionPeriod *const introductoryPeriod = [[AMASubscriptionPeriod alloc] initWithCount:7 timeUnit:AMATimeUnitDay];
        
        AMASubscriptionInfoModel *const subscription = [[AMASubscriptionInfoModel alloc] initWithIsAutoRenewing:YES
                                                                                             subscriptionPeriod:subscriptionPeriod
                                                                                                 introductoryID:introductaryID
                                                                                              introductoryPrice:introductoryPrice
                                                                                             introductoryPeriod:introductoryPeriod
                                                                                        introductoryPeriodCount:12];
        AMATransactionInfoModel *const transaction = [[AMATransactionInfoModel alloc]
                                                      initWithTransactionID:transactionID
                                                      transactionTime:transactionDate
                                                      transactionState:AMATransactionStatePurchased
                                                      secondaryID:secondaryID
                                                      secondaryTime:secondaryDate];
        
        context(@"Decimal price", ^{
            NSDecimalNumber *const priceDecimal = [NSDecimalNumber decimalNumberWithString:@"23.55"];
            beforeAll(^{
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
                                                         subscriptionInfo:subscription
                                                          transactionInfo:transaction];
                revenue = serializeAndDeserializeModel(model);
            });
            it(@"Should not fill price", ^{
                [[theValue(revenue->price) should] equal:0.0 withDelta:DBL_EPSILON];
            });
            it(@"Should fill has_price", ^{
                [[theValue(revenue->has_price) should] beNo];
            });
            it(@"Should fill price_micros", ^{
                [[theValue(revenue->price_micros) should] equal:theValue(23550000)];
            });
            it(@"Should fill has_price_micros", ^{
                [[theValue(revenue->has_price_micros) should] beYes];
            });
            it(@"Should fill currency", ^{
                [[stringForBinary(&(revenue->currency)) should] equal:currency];
            });
            it(@"Should fill has_quantity", ^{
                [[theValue(revenue->has_quantity) should] beYes];
            });
            it(@"Should fill quantity", ^{
                [[theValue(revenue->quantity) should] equal:theValue(quantity)];
            });
            it(@"Should fill has_product_id", ^{
                [[theValue(revenue->has_product_id) should] beYes];
            });
            it(@"Should fill product_id", ^{
                [[stringForBinary(&(revenue->product_id)) should] equal:productID];
            });
            it(@"Should fill receipt has_transaction_id", ^{
                [[theValue(revenue->receipt->has_transaction_id) should] beYes];
            });
            it(@"Should fill receipt transaction_id", ^{
                [[stringForBinary(&(revenue->receipt->transaction_id)) should] equal:transactionID];
            });
            it(@"Should fill receipt has_data", ^{
                [[theValue(revenue->receipt->has_data) should] beYes];
            });
            it(@"Should fill receipt data", ^{
                ProtobufCBinaryData *binaryData = &(revenue->receipt->data);
                NSData *data = [NSData dataWithBytes:binaryData->data length:binaryData->len];
                [[data should] equal:receiptData];
            });
            it(@"Should fill has_payload", ^{
                [[theValue(revenue->has_payload) should] beYes];
            });
            it(@"Should fill payload", ^{
                [[stringForBinary(&(revenue->payload)) should] equal:payloadString];
            });
            it(@"Should fill has_auto_collected", ^{
                [[theValue(revenue->has_auto_collected) should] beYes];
            });
            it(@"Should fill auto_collected", ^{
                [[theValue(revenue->auto_collected) should] beYes];
            });
            it(@"Should fill in_app_type", ^{
                [[theValue(revenue->in_app_type) should] equal:theValue(AMA__REVENUE__IN_APP_TYPE__PURCHASE)];
            });
            
            context(@"Transaction", ^{
                it(@"Should fill has_id", ^{
                    [[theValue(revenue->transaction_info->has_id) should] beYes];
                });
                it(@"Should fill id", ^{
                    [[stringForBinary(&(revenue->transaction_info->id)) should] equal:transactionID];
                });
                it(@"Should fill has_time", ^{
                    [[theValue(revenue->transaction_info->has_time) should] beYes];
                });
                it(@"Should fill time", ^{
                    [[theValue(revenue->transaction_info->time) should] equal:transactionDate.timeIntervalSince1970 withDelta:0.1];
                });
                it(@"Should fill has_state", ^{
                    [[theValue(revenue->transaction_info->has_state) should] beYes];
                });
                it(@"Should fill state", ^{
                    [[theValue(revenue->transaction_info->state) should] equal:theValue(AMA__REVENUE__TRANSACTION__STATE__PURCHASED)];
                });
                it(@"Should fill has_secondary_id", ^{
                    [[theValue(revenue->transaction_info->has_secondary_id) should] beYes];
                });
                it(@"Should fill secondary_id", ^{
                    [[stringForBinary(&(revenue->transaction_info->secondary_id)) should] equal:secondaryID];
                });
                it(@"Should fill has_secondary_time", ^{
                    [[theValue(revenue->transaction_info->has_secondary_time) should] beYes];
                });
                it(@"Should fill secondary_time", ^{
                    [[theValue(revenue->transaction_info->secondary_time) should] equal:secondaryDate.timeIntervalSince1970 withDelta:0.1];
                });
            });
            
            context(@"Subscription info", ^{
                it(@"Should fill has_auto_renewing", ^{
                    [[theValue(revenue->subscription_info->has_auto_renewing) should] beYes];
                });
                it(@"Should fill auto_renewing", ^{
                    [[theValue(revenue->subscription_info->auto_renewing) should] beYes];
                });
                context(@"subscription_period", ^{
                    it(@"Should fill has_number", ^{
                        [[theValue(revenue->subscription_info->subscription_period->has_number) should] beYes];
                    });
                    it(@"Should fill number", ^{
                        [[theValue(revenue->subscription_info->subscription_period->number) should] equal:theValue(subscriptionPeriod.count)];
                    });
                    it(@"Should fill has_time_unit", ^{
                        [[theValue(revenue->subscription_info->subscription_period->has_time_unit) should] beYes];
                    });
                    it(@"Should fill time_unit", ^{
                        [[theValue(revenue->subscription_info->subscription_period->time_unit) should]
                         equal:theValue(AMA__REVENUE__SUBSCRIPTION_INFO__PERIOD__TIME_UNIT__YEAR)];
                    });
                });
                context(@"introductory_info", ^{
                    it(@"Should fill has_price_micros", ^{
                        [[theValue(revenue->subscription_info->introductory_info->has_price_micros) should] beYes];
                    });
                    it(@"Should fill price_micros", ^{
                        [[theValue(revenue->subscription_info->introductory_info->price_micros) should]
                         equal:theValue(14280000)];
                    });
                    it(@"Should fill has_number_of_periods", ^{
                        [[theValue(revenue->subscription_info->introductory_info->has_number_of_periods) should] beYes];
                    });
                    it(@"Should fill number_of_periods", ^{
                        [[theValue(revenue->subscription_info->introductory_info->number_of_periods) should] equal:theValue(subscription.introductoryPeriodCount)];
                    });
                    context(@"period", ^{
                        it(@"Should fill has_number", ^{
                            [[theValue(revenue->subscription_info->introductory_info->period->has_number) should] beYes];
                        });
                        it(@"Should fill number", ^{
                            [[theValue(revenue->subscription_info->introductory_info->period->number) should] equal:theValue(introductoryPeriod.count)];
                        });
                        it(@"Should fill has_time_unit", ^{
                            [[theValue(revenue->subscription_info->introductory_info->period->has_time_unit) should] beYes];
                        });
                        it(@"Should fill time_unit", ^{
                            [[theValue(revenue->subscription_info->introductory_info->period->time_unit) should]
                             equal:theValue(AMA__REVENUE__SUBSCRIPTION_INFO__PERIOD__TIME_UNIT__DAY)];
                        });
                    });
                });
            });
        });
        
        context(@"Decimal corner cases", ^{
            int64_t (^microsForDecimal)(NSDecimalNumber *) = ^(NSDecimalNumber *value) {
                model = [[AMARevenueInfoModel alloc] initWithPriceDecimal:value
                                                                 currency:currency
                                                                 quantity:quantity
                                                                productID:productID
                                                            transactionID:transactionID
                                                              receiptData:receiptData
                                                            payloadString:payloadString
                                                           bytesTruncated:bytesTruncated
                                                          isAutoCollected:NO
                                                                inAppType:AMAInAppTypePurchase
                                                         subscriptionInfo:nil
                                                          transactionInfo:nil];
                revenue = serializeAndDeserializeModel(model);
                return revenue->price_micros;
            };
            context(@"From doubles", ^{
                it(@"Should have valid value for 0", ^{
                    NSDecimalNumber *number = [[NSDecimalNumber alloc] initWithDouble:0.0];
                    [[theValue(microsForDecimal(number)) should] equal:theValue(0)];
                });
                it(@"Should have valid value for 1127.6999988555908", ^{
                    NSDecimalNumber *number = [[NSDecimalNumber alloc] initWithDouble:1127.6999988555908];
                    [[theValue(microsForDecimal(number)) should] equal:theValue(1127699998)];
                });
                it(@"Should have valid value for -37.919998168945312", ^{
                    NSDecimalNumber *number = [[NSDecimalNumber alloc] initWithDouble:-37.919998168945312];
                    [[theValue(microsForDecimal(number)) should] equal:theValue(-37919998)];
                });
                it(@"Should have valid value for 9223372036854.775807", ^{
                    NSDecimalNumber *number = [[NSDecimalNumber alloc] initWithDouble:9223372036854.775807];
                    [[theValue(microsForDecimal(number)) should] equal:theValue(9223372036854775807)];
                });
                it(@"Should have valid value for 9223372036855 (overflow)", ^{
                    NSDecimalNumber *number = [[NSDecimalNumber alloc] initWithDouble:9223372036855.0];
                    [[theValue(microsForDecimal(number)) should] equal:theValue(9223372036854775807)];
                });
            });
            context(@"From strings", ^{
                it(@"Should have valid value for 0", ^{
                    NSDecimalNumber *number = [NSDecimalNumber decimalNumberWithString:@"0"];
                    [[theValue(microsForDecimal(number)) should] equal:theValue(0)];
                });
                it(@"Should have valid value for 1127.6999988555908", ^{
                    NSDecimalNumber *number = [NSDecimalNumber decimalNumberWithString:@"1127.6999988555908"];
                    [[theValue(microsForDecimal(number)) should] equal:theValue(1127699998)];
                });
                it(@"Should have valid value for -37.919998168945312", ^{
                    NSDecimalNumber *number = [NSDecimalNumber decimalNumberWithString:@"-37.919998168945312"];
                    [[theValue(microsForDecimal(number)) should] equal:theValue(-37919998)];
                });
                it(@"Should have valid value for 9223372036854.775807", ^{
                    NSDecimalNumber *number = [NSDecimalNumber decimalNumberWithString:@"9223372036854.775807"];
                    [[theValue(microsForDecimal(number)) should] equal:theValue(9223372036854775807)];
                });
                it(@"Should have valid value for 9223372036855 (overflow)", ^{
                    NSDecimalNumber *number = [NSDecimalNumber decimalNumberWithString:@"9223372036855"];
                    [[theValue(microsForDecimal(number)) should] equal:theValue(9223372036854775807)];
                });
            });
        });
    });

    context(@"Deserialize revenue", ^{
        it(@"Value is nil", ^{
            Ama__Revenue *result = [serializer deserializeRevenue:nil allocator:allocator];
            [[theValue(result == NULL) should] beYes];
        });
        it(@"Value is not binary", ^{
            id value = [[AMAStringEventValue alloc] initWithValue:@"value"];
            Ama__Revenue *result = [serializer deserializeRevenue:value allocator:allocator];
            [[theValue(result == NULL) should] beYes];
        });
        it(@"Invalid binary value", ^{
            AMAECommerce *eCommerce = [AMAECommerce showScreenEventWithScreen:[[AMAECommerceScreen alloc] initWithName:@"name"]];
            NSData *data = [[[AMAECommerceSerializer alloc] init] serializeECommerce:eCommerce][0].data;
            id value = [[AMABinaryEventValue alloc] initWithData:data gZipped:NO];
            Ama__Revenue *result = [serializer deserializeRevenue:value allocator:allocator];
            [[theValue(result == NULL) should] beYes];
        });
        it(@"Valid binary value", ^{
            model = [[AMARevenueInfoModel alloc] initWithPriceDecimal:[NSDecimalNumber zero]
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
            NSData *data = [serializer dataWithRevenueInfoModel:model];
            id value = [[AMABinaryEventValue alloc] initWithData:data gZipped:NO];
            Ama__Revenue *result = [serializer deserializeRevenue:value allocator:allocator];
            [[theValue(result == NULL) should] beNo];
        });
    });

});

SPEC_END
