#import <Kiwi/Kiwi.h>
#import "AMACore.h"
#import "AMAAppMetrica.h"
#import "AMARevenueInfoModelFormatter.h"
#import "AMARevenueInfoMutableModel.h"
#import "AMARevenueInfoProcessingLogger.h"
#import "AMASubscriptionInfoMutableModel.h"
#import "AMASubscriptionPeriod.h"
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMATransactionInfoMutableModel.h"

SPEC_BEGIN(AMARevenueInfoModelFormatterTests)

describe(@"AMARevenueInfoModelFormatter", ^{

    double const price = 23.55;
    NSDecimalNumber *const priceDecimal = [NSDecimalNumber decimalNumberWithString:@"23.55"];
    NSString *const currency = @"USD";

    AMARevenueInfoMutableModel *__block revenueInfoModel = nil;
    AMATestTruncator *__block productIDTruncator = nil;
    AMATestTruncator *__block transactionIDTruncator = nil;
    AMATestTruncator *__block payloadStringTruncator = nil;
    AMARevenueInfoProcessingLogger *__block logger = nil;
    AMARevenueInfoModelFormatter *__block formatter = nil;

    beforeEach(^{
        revenueInfoModel = [[AMARevenueInfoMutableModel alloc] initWithPriceDecimal:priceDecimal currency:currency];
        productIDTruncator = [[AMATestTruncator alloc] init];
        transactionIDTruncator = [[AMATestTruncator alloc] init];
        payloadStringTruncator = [[AMATestTruncator alloc] init];
        logger = [AMARevenueInfoProcessingLogger nullMock];
        formatter = [[AMARevenueInfoModelFormatter alloc] initWithProductIDTruncator:productIDTruncator
                                                              transactionIDTruncator:transactionIDTruncator
                                                              payloadStringTruncator:payloadStringTruncator
                                                                              logger:logger];
    });
    
    context(@"Decimal price", ^{
        it(@"Should return model with valid value", ^{
            [[[formatter formattedRevenueModel:revenueInfoModel error:nil].priceDecimal should] equal:priceDecimal];
        });
        it(@"Should not fill error", ^{
            NSError *error = nil;
            [formatter formattedRevenueModel:revenueInfoModel error:&error];
            [[error should] beNil];
        });
        it(@"Should return model with zero bytesTruncated", ^{
            [[theValue([formatter formattedRevenueModel:revenueInfoModel error:nil].bytesTruncated) should] beZero];
        });
    });
    context(@"Currency", ^{
        it(@"Should return model with valid value", ^{
            [[[formatter formattedRevenueModel:revenueInfoModel error:nil].currency should] equal:currency];
        });
        it(@"Should not fill error", ^{
            NSError *error = nil;
            [formatter formattedRevenueModel:revenueInfoModel error:&error];
            [[error should] beNil];
        });
        it(@"Should return model with zero bytesTruncated", ^{
            [[theValue([formatter formattedRevenueModel:revenueInfoModel error:nil].bytesTruncated) should] beZero];
        });
    });
    context(@"Quantity", ^{
        NSUInteger const quantity = 23;
        beforeEach(^{
            revenueInfoModel.quantity = quantity;
        });

        it(@"Should return model with valid value", ^{
            [[theValue([formatter formattedRevenueModel:revenueInfoModel error:nil].quantity) should]
                equal:theValue(revenueInfoModel.quantity)];
        });
        it(@"Should not fill error", ^{
            NSError *error = nil;
            [formatter formattedRevenueModel:revenueInfoModel error:&error];
            [[error should] beNil];
        });
        it(@"Should return model with zero bytesTruncated", ^{
            [[theValue([formatter formattedRevenueModel:revenueInfoModel error:nil].bytesTruncated) should] beZero];
        });
    });
    context(@"Product ID", ^{
        NSUInteger const maxLength = 200;
        NSString *const productID = @"PRODUCT_ID";
        beforeEach(^{
            revenueInfoModel.productID = productID;
        });
        context(@"Normal", ^{
            it(@"Should return model with valid value", ^{
                [[[formatter formattedRevenueModel:revenueInfoModel error:nil].productID should]
                    equal:revenueInfoModel.productID];
            });
            it(@"Should not fill error", ^{
                NSError *error = nil;
                [formatter formattedRevenueModel:revenueInfoModel error:&error];
                [[error should] beNil];
            });
            it(@"Should return model with zero bytesTruncated", ^{
                [[theValue([formatter formattedRevenueModel:revenueInfoModel error:nil].bytesTruncated) should] beZero];
            });
        });
        context(@"Large", ^{
            NSString *const truncatedProductID = @"PRODUCT";
            NSUInteger const bytesTruncated = 42;
            beforeEach(^{
                [productIDTruncator enableTruncationWithResult:truncatedProductID bytesTruncated:bytesTruncated];
            });
            it(@"Should call truncator", ^{
                [[productIDTruncator should] receive:@selector(truncatedString:onTruncation:)
                                       withArguments:productID, kw_any()];
                [formatter formattedRevenueModel:revenueInfoModel error:nil];
            });
            it(@"Should return model with truncated value", ^{
                [[[formatter formattedRevenueModel:revenueInfoModel error:nil].productID should] equal:truncatedProductID];
            });
            it(@"Should not fill error", ^{
                NSError *error = nil;
                [formatter formattedRevenueModel:revenueInfoModel error:&error];
                [[error should] beNil];
            });
            it(@"Should log truncation", ^{
                [[logger should] receive:@selector(logTruncationOfType:value:maxLength:)
                           withArguments:@"productID", productID, theValue(maxLength)];
                [formatter formattedRevenueModel:revenueInfoModel error:nil];
            });
            it(@"Should return model with valid bytesTruncated", ^{
                [[theValue([formatter formattedRevenueModel:revenueInfoModel error:nil].bytesTruncated) should]
                 equal:theValue(bytesTruncated)];
            });
        });
    });
    context(@"Transaction ID", ^{
        NSUInteger const maxLength = 200;
        NSString *const transactionID = @"TRANSACTION_ID";
        beforeEach(^{
            revenueInfoModel.transactionID = transactionID;
        });
        context(@"Normal", ^{
            it(@"Should return model with valid value", ^{
                NSString *modelTransactionID = [formatter formattedRevenueModel:revenueInfoModel error:nil].transactionID;
                [[modelTransactionID should] equal:transactionID];
            });
            it(@"Should not fill error", ^{
                NSError *error = nil;
                [formatter formattedRevenueModel:revenueInfoModel error:&error];
                [[error should] beNil];
            });
            it(@"Should return model with zero bytesTruncated", ^{
                [[theValue([formatter formattedRevenueModel:revenueInfoModel error:nil].bytesTruncated) should] beZero];
            });
        });
        context(@"Large", ^{
            NSString *const truncatedTransactionID = @"TRANSACTION";
            NSUInteger const bytesTruncated = 42;
            beforeEach(^{
                [transactionIDTruncator enableTruncationWithResult:truncatedTransactionID
                                                    bytesTruncated:bytesTruncated];
            });
            it(@"Should call truncator", ^{
                [[transactionIDTruncator should] receive:@selector(truncatedString:onTruncation:)
                                           withArguments:transactionID, kw_any()];
                [formatter formattedRevenueModel:revenueInfoModel error:nil];
            });
            it(@"Should return model with truncated value", ^{
                NSString *modelTransactionID = [formatter formattedRevenueModel:revenueInfoModel error:nil].transactionID;
                [[modelTransactionID should] equal:truncatedTransactionID];
            });
            it(@"Should not fill error", ^{
                NSError *error = nil;
                [formatter formattedRevenueModel:revenueInfoModel error:&error];
                [[error should] beNil];
            });
            it(@"Should log truncation", ^{
                [[logger should] receive:@selector(logTruncationOfType:value:maxLength:)
                           withArguments:@"transactionID", transactionID, theValue(maxLength)];
                [formatter formattedRevenueModel:revenueInfoModel error:nil];
            });
            it(@"Should return model with valid bytesTruncated", ^{
                [[theValue([formatter formattedRevenueModel:revenueInfoModel error:nil].bytesTruncated) should]
                 equal:theValue(bytesTruncated)];
            });
        });
    });
    context(@"Receipt Data", ^{
        context(@"Normal", ^{
            NSData *const receiptData = [@"DATA" dataUsingEncoding:NSUTF8StringEncoding];
            beforeEach(^{
                revenueInfoModel.receiptData = receiptData;
            });
            it(@"Should return model with valid value", ^{
                [[[formatter formattedRevenueModel:revenueInfoModel error:nil].receiptData should] equal:receiptData];
            });
            it(@"Should not fill error", ^{
                NSError *error = nil;
                [formatter formattedRevenueModel:revenueInfoModel error:&error];
                [[error should] beNil];
            });
            it(@"Should return model with zero bytesTruncated", ^{
                [[theValue([formatter formattedRevenueModel:revenueInfoModel error:nil].bytesTruncated) should] beZero];
            });
        });
        context(@"Large", ^{
            NSUInteger const maxSize = 180 * 1024;
            NSUInteger const extraSize = 3;
            NSData *const receiptData = [AMATestUtilities dataOfSize:maxSize + extraSize
                                                    filledWithSample:[@"DATA" dataUsingEncoding:NSUTF8StringEncoding]];
            beforeEach(^{
                revenueInfoModel.receiptData = receiptData;
            });
            it(@"Should return model with truncated value", ^{
                NSData *expectedReceiptData =
                    [@"<truncated data was not sent, see https://nda.ya.ru/t/40z6Prmt6fHZXq>" dataUsingEncoding:NSUTF8StringEncoding];
                [[[formatter formattedRevenueModel:revenueInfoModel error:nil].receiptData should] equal:expectedReceiptData];
            });
            it(@"Should not fill error", ^{
                NSError *error = nil;
                [formatter formattedRevenueModel:revenueInfoModel error:&error];
                [[error should] beNil];
            });
            it(@"Should log truncation", ^{
                [[logger should] receive:@selector(logTruncationOfReceiptDataWithLength:maxSize:)
                           withArguments:theValue(receiptData.length), theValue(maxSize)];
                [formatter formattedRevenueModel:revenueInfoModel error:nil];
            });
            it(@"Should increment bytesTruncated", ^{
                NSUInteger bytesTruncated = [formatter formattedRevenueModel:revenueInfoModel error:nil].bytesTruncated;
                [[theValue(bytesTruncated) should] equal:theValue(receiptData.length)];
            });
        });
    });
    context(@"Payload", ^{
        NSUInteger const maxLength = 30 * 1024;
        NSString *const payloadString = @"{\"foo\":\"bar\"}";
        beforeEach(^{
            revenueInfoModel.payloadString = payloadString;
        });
        context(@"Normal", ^{
            it(@"Should return model with valid value", ^{
                [[[formatter formattedRevenueModel:revenueInfoModel error:nil].payloadString should] equal:payloadString];
            });
            it(@"Should not fill error", ^{
                NSError *error = nil;
                [formatter formattedRevenueModel:revenueInfoModel error:&error];
                [[error should] beNil];
            });
            it(@"Should return model with zero bytesTruncated", ^{
                [[theValue([formatter formattedRevenueModel:revenueInfoModel error:nil].bytesTruncated) should] beZero];
            });
        });
        context(@"Large", ^{
            NSString *const truncatedPayloadString = @"{\"foo\":\"ba";
            NSUInteger const bytesTruncated = 42;
            beforeEach(^{
                [payloadStringTruncator enableTruncationWithResult:truncatedPayloadString
                                                    bytesTruncated:bytesTruncated];
            });
            it(@"Should call truncator", ^{
                [[payloadStringTruncator should] receive:@selector(truncatedString:onTruncation:)
                                           withArguments:payloadString, kw_any()];
                [formatter formattedRevenueModel:revenueInfoModel error:nil];
            });
            it(@"Should return model with truncated value", ^{
                [[[formatter formattedRevenueModel:revenueInfoModel error:nil].payloadString should] equal:truncatedPayloadString];
            });
            it(@"Should not fill error", ^{
                NSError *error = nil;
                [formatter formattedRevenueModel:revenueInfoModel error:&error];
                [[error should] beNil];
            });
            it(@"Should log truncation", ^{
                [[logger should] receive:@selector(logTruncationOfPayloadString:maxLength:)
                           withArguments:payloadString, theValue(maxLength)];
                [formatter formattedRevenueModel:revenueInfoModel error:nil];
            });
            it(@"Should return model with valid bytesTruncated", ^{
                [[theValue([formatter formattedRevenueModel:revenueInfoModel error:nil].bytesTruncated) should]
                 equal:theValue(bytesTruncated)];
            });
        });
    });
    context(@"Auto Collected", ^{
        beforeEach(^{
            revenueInfoModel.isAutoCollected = YES;
        });

        it(@"Should return model with YES", ^{
            revenueInfoModel.isAutoCollected = YES;
            [[theValue([formatter formattedRevenueModel:revenueInfoModel error:nil].isAutoCollected) should] equal:theValue(YES)];
        });
        it(@"Should return model with NO", ^{
            revenueInfoModel.isAutoCollected = NO;
            [[theValue([formatter formattedRevenueModel:revenueInfoModel error:nil].isAutoCollected) should] equal:theValue(NO)];
        });
        it(@"Should not fill error", ^{
            NSError *error = nil;
            [formatter formattedRevenueModel:revenueInfoModel error:&error];
            [[error should] beNil];
        });
        it(@"Should return model with zero bytesTruncated", ^{
            [[theValue([formatter formattedRevenueModel:revenueInfoModel error:nil].bytesTruncated) should] beZero];
        });
    });
    context(@"In-app type", ^{
        beforeEach(^{
            revenueInfoModel.inAppType = AMAInAppTypePurchase;
        });

        it(@"Should return model with AMAInAppTypePurchase value", ^{
            revenueInfoModel.inAppType = AMAInAppTypePurchase;
            [[theValue([formatter formattedRevenueModel:revenueInfoModel error:nil].inAppType) should]
                equal:theValue(AMAInAppTypePurchase)];
        });
        it(@"Should return model with AMAInAppTypeSubscription value", ^{
            revenueInfoModel.inAppType = AMAInAppTypeSubscription;
            [[theValue([formatter formattedRevenueModel:revenueInfoModel error:nil].inAppType) should]
                equal:theValue(AMAInAppTypeSubscription)];
        });
        it(@"Should not fill error", ^{
            NSError *error = nil;
            [formatter formattedRevenueModel:revenueInfoModel error:&error];
            [[error should] beNil];
        });
        it(@"Should return model with zero bytesTruncated", ^{
            [[theValue([formatter formattedRevenueModel:revenueInfoModel error:nil].bytesTruncated) should] beZero];
        });
    });
    context(@"Subscription Info", ^{

        AMASubscriptionInfoMutableModel *__block subscriptionInfo = nil;
        beforeEach(^{
            subscriptionInfo = [[AMASubscriptionInfoMutableModel alloc] init];
            revenueInfoModel.subscriptionInfo = subscriptionInfo;
        });

        it(@"Should not fill error", ^{
            NSError *error = nil;
            [formatter formattedRevenueModel:revenueInfoModel error:&error];
            [[error should] beNil];
        });

        it(@"Should not fill error if there is no subscription info", ^{
            revenueInfoModel.subscriptionInfo = nil;
            NSError *error = nil;
            [formatter formattedRevenueModel:revenueInfoModel error:&error];
            [[error should] beNil];
        });

        context(@"Autorenewing", ^{
            it(@"Should return model with YES", ^{
                subscriptionInfo.isAutoRenewing = YES;
                BOOL result = [formatter formattedRevenueModel:revenueInfoModel error:nil].subscriptionInfo.isAutoRenewing;
                [[theValue(result) should] equal:theValue(YES)];
            });
            it(@"Should return model with NO", ^{
                subscriptionInfo.isAutoRenewing = NO;
                BOOL result = [formatter formattedRevenueModel:revenueInfoModel error:nil].subscriptionInfo.isAutoRenewing;
                [[theValue(result) should] equal:theValue(NO)];
            });
            it(@"Should not fill error", ^{
                NSError *error = nil;
                [formatter formattedRevenueModel:revenueInfoModel error:&error];
                [[error should] beNil];
            });
            it(@"Should return model with zero bytesTruncated", ^{
                [[theValue([formatter formattedRevenueModel:revenueInfoModel error:nil].bytesTruncated) should] beZero];
            });
        });
        context(@"Subscription period", ^{
            AMASubscriptionPeriod *const period = [[AMASubscriptionPeriod alloc] initWithCount:123 timeUnit:AMATimeUnitWeek];
            beforeEach(^{
                subscriptionInfo.subscriptionPeriod = period;
            });

            it(@"Should return model with valid value", ^{
                AMARevenueInfoModel *result = [formatter formattedRevenueModel:revenueInfoModel error:nil];
                [[theValue(result.subscriptionInfo.subscriptionPeriod) should] equal:theValue(period)];
            });
            it(@"Should not fill error", ^{
                NSError *error = nil;
                [formatter formattedRevenueModel:revenueInfoModel error:&error];
                [[error should] beNil];
            });
            it(@"Should return model with zero bytesTruncated", ^{
                [[theValue([formatter formattedRevenueModel:revenueInfoModel error:nil].bytesTruncated) should] beZero];
            });
        });
        context(@"Introductary ID", ^{
            NSUInteger const maxLength = 200;
            NSString *const introductaryID = @"INTRODUCTARY_ID";
            beforeEach(^{
                subscriptionInfo.introductoryID = introductaryID;
            });
            context(@"Normal", ^{
                it(@"Should return model with valid value", ^{
                    [[[formatter formattedRevenueModel:revenueInfoModel error:nil].subscriptionInfo.introductoryID should]
                        equal:subscriptionInfo.introductoryID];
                });
                it(@"Should not fill error", ^{
                    NSError *error = nil;
                    [formatter formattedRevenueModel:revenueInfoModel error:&error];
                    [[error should] beNil];
                });
                it(@"Should return model with zero bytesTruncated", ^{
                    [[theValue([formatter formattedRevenueModel:revenueInfoModel error:nil].bytesTruncated) should] beZero];
                });
            });
            context(@"Large", ^{
                NSString *const truncatedIntroductaryID = @"INTRODUCTARY";
                NSUInteger const bytesTruncated = 42;
                beforeEach(^{
                    [productIDTruncator enableTruncationWithResult:truncatedIntroductaryID bytesTruncated:bytesTruncated];
                });
                it(@"Should call truncator", ^{
                    [[productIDTruncator should] receive:@selector(truncatedString:onTruncation:)
                                           withArguments:introductaryID, kw_any()];
                    [formatter formattedRevenueModel:revenueInfoModel error:nil];
                });
                it(@"Should return model with truncated value", ^{
                    [[[formatter formattedRevenueModel:revenueInfoModel error:nil].subscriptionInfo.introductoryID should]
                        equal:truncatedIntroductaryID];
                });
                it(@"Should not fill error", ^{
                    NSError *error = nil;
                    [formatter formattedRevenueModel:revenueInfoModel error:&error];
                    [[error should] beNil];
                });
                it(@"Should log truncation", ^{
                    [[logger should] receive:@selector(logTruncationOfType:value:maxLength:)
                               withArguments:@"productID", introductaryID, theValue(maxLength)];
                    [formatter formattedRevenueModel:revenueInfoModel error:nil];
                });
                it(@"Should return model with valid bytesTruncated", ^{
                    [[theValue([formatter formattedRevenueModel:revenueInfoModel error:nil].bytesTruncated) should]
                     equal:theValue(bytesTruncated)];
                });
            });
        });
        context(@"Introductory price", ^{
            beforeEach(^{
                subscriptionInfo.introductoryPrice = priceDecimal;
            });
            it(@"Should return model with valid value", ^{
                [[[formatter formattedRevenueModel:revenueInfoModel error:nil].subscriptionInfo.introductoryPrice should] equal:priceDecimal];
            });
            it(@"Should not fill error", ^{
                NSError *error = nil;
                [formatter formattedRevenueModel:revenueInfoModel error:&error];
                [[error should] beNil];
            });
            it(@"Should return model with zero bytesTruncated", ^{
                [[theValue([formatter formattedRevenueModel:revenueInfoModel error:nil].bytesTruncated) should] beZero];
            });
        });
        context(@"Introductory period", ^{
            AMASubscriptionPeriod *const period = [[AMASubscriptionPeriod alloc] initWithCount:123 timeUnit:AMATimeUnitWeek];
            beforeEach(^{
                subscriptionInfo.introductoryPeriod = period;
            });

            it(@"Should return model with valid value", ^{
                AMARevenueInfoModel *result = [formatter formattedRevenueModel:revenueInfoModel error:nil];
                [[theValue(result.subscriptionInfo.introductoryPeriod) should] equal:theValue(period)];
            });
            it(@"Should not fill error", ^{
                NSError *error = nil;
                [formatter formattedRevenueModel:revenueInfoModel error:&error];
                [[error should] beNil];
            });
            it(@"Should return model with zero bytesTruncated", ^{
                [[theValue([formatter formattedRevenueModel:revenueInfoModel error:nil].bytesTruncated) should] beZero];
            });
        });
    });
    context(@"Transaction info", ^{

        AMATransactionInfoMutableModel *__block transactionInfo = nil;
        beforeEach(^{
            transactionInfo = [[AMATransactionInfoMutableModel alloc] init];
            revenueInfoModel.transactionInfo = transactionInfo;
        });

        it(@"Should not fill error", ^{
            NSError *error = nil;
            [formatter formattedRevenueModel:revenueInfoModel error:&error];
            [[error should] beNil];
        });

        it(@"Should not fill error if there is no transaction info", ^{
            revenueInfoModel.transactionInfo = nil;
            NSError *error = nil;
            [formatter formattedRevenueModel:revenueInfoModel error:&error];
            [[error should] beNil];
        });

        context(@"Transaction ID", ^{
            NSUInteger const maxLength = 200;
            NSString *const transactionID = @"TRANSACTION_ID";
            beforeEach(^{
                transactionInfo.transactionID = transactionID;
            });
            context(@"Normal", ^{
                it(@"Should return model with valid value", ^{
                    AMARevenueInfoModel *model = [formatter formattedRevenueModel:revenueInfoModel error:nil];
                    [[model.transactionInfo.transactionID should] equal:transactionID];
                });
                it(@"Should not fill error", ^{
                    NSError *error = nil;
                    [formatter formattedRevenueModel:revenueInfoModel error:&error];
                    [[error should] beNil];
                });
                it(@"Should return model with zero bytesTruncated", ^{
                    [[theValue([formatter formattedRevenueModel:revenueInfoModel error:nil].bytesTruncated) should] beZero];
                });
            });
            context(@"Large", ^{
                NSString *const truncatedTransactionID = @"TRANSACTION";
                NSUInteger const bytesTruncated = 42;
                beforeEach(^{
                    [transactionIDTruncator enableTruncationWithResult:truncatedTransactionID
                                                        bytesTruncated:bytesTruncated];
                });
                it(@"Should call truncator", ^{
                    [[transactionIDTruncator should] receive:@selector(truncatedString:onTruncation:)
                                               withArguments:transactionID, kw_any()];
                    [formatter formattedRevenueModel:revenueInfoModel error:nil];
                });
                it(@"Should return model with truncated value", ^{
                    AMARevenueInfoModel *model = [formatter formattedRevenueModel:revenueInfoModel error:nil];
                    [[model.transactionInfo.transactionID should] equal:truncatedTransactionID];
                });
                it(@"Should not fill error", ^{
                    NSError *error = nil;
                    [formatter formattedRevenueModel:revenueInfoModel error:&error];
                    [[error should] beNil];
                });
                it(@"Should log truncation", ^{
                    [[logger should] receive:@selector(logTruncationOfType:value:maxLength:)
                               withArguments:@"transactionID", transactionID, theValue(maxLength)];
                    [formatter formattedRevenueModel:revenueInfoModel error:nil];
                });
                it(@"Should return model with valid bytesTruncated", ^{
                    [[theValue([formatter formattedRevenueModel:revenueInfoModel error:nil].bytesTruncated) should]
                     equal:theValue(bytesTruncated)];
                });
            });
        });
        context(@"Transaction time", ^{
            NSDate *const transactionTime = [NSDate date];
            beforeEach(^{
                transactionInfo.transactionTime = transactionTime;
            });
            it(@"Should return model with valid value", ^{
                AMARevenueInfoModel *result = [formatter formattedRevenueModel:revenueInfoModel error:nil];
                [[result.transactionInfo.transactionTime should] equal:transactionTime];
            });
            it(@"Should not fill error", ^{
                NSError *error = nil;
                [formatter formattedRevenueModel:revenueInfoModel error:&error];
                [[error should] beNil];
            });
            it(@"Should return model with zero bytesTruncated", ^{
                [[theValue([formatter formattedRevenueModel:revenueInfoModel error:nil].bytesTruncated) should] beZero];
            });
        });
        context(@"Transaction state", ^{
            beforeEach(^{
                transactionInfo.transactionState = AMATransactionStateUndefined;
            });
            it(@"Should return model with AMATransactionStateUndefined value", ^{
                transactionInfo.transactionState = AMATransactionStateUndefined;
                AMARevenueInfoModel *result = [formatter formattedRevenueModel:revenueInfoModel error:nil];
                [[theValue(result.transactionInfo.transactionState) should] equal:theValue(AMATransactionStateUndefined)];
            });
            it(@"Should return model with AMATransactionStateRestored value", ^{
                transactionInfo.transactionState = AMATransactionStateRestored;
                AMARevenueInfoModel *result = [formatter formattedRevenueModel:revenueInfoModel error:nil];
                [[theValue(result.transactionInfo.transactionState) should] equal:theValue(AMATransactionStateRestored)];
            });
            it(@"Should return model with AMATransactionStatePurchased value", ^{
                transactionInfo.transactionState = AMATransactionStatePurchased;
                AMARevenueInfoModel *result = [formatter formattedRevenueModel:revenueInfoModel error:nil];
                [[theValue(result.transactionInfo.transactionState) should] equal:theValue(AMATransactionStatePurchased)];
            });
            it(@"Should not fill error", ^{
                NSError *error = nil;
                [formatter formattedRevenueModel:revenueInfoModel error:&error];
                [[error should] beNil];
            });
            it(@"Should return model with zero bytesTruncated", ^{
                [[theValue([formatter formattedRevenueModel:revenueInfoModel error:nil].bytesTruncated) should] beZero];
            });
        });
        context(@"Secondary ID", ^{
            NSUInteger const maxLength = 200;
            NSString *const secondaryID = @"TRANSACTION_ID";
            beforeEach(^{
                transactionInfo.secondaryID = secondaryID;
            });
            context(@"Normal", ^{
                it(@"Should return model with valid value", ^{
                    AMARevenueInfoModel *model = [formatter formattedRevenueModel:revenueInfoModel error:nil];
                    [[model.transactionInfo.secondaryID should] equal:secondaryID];
                });
                it(@"Should not fill error", ^{
                    NSError *error = nil;
                    [formatter formattedRevenueModel:revenueInfoModel error:&error];
                    [[error should] beNil];
                });
                it(@"Should return model with zero bytesTruncated", ^{
                    [[theValue([formatter formattedRevenueModel:revenueInfoModel error:nil].bytesTruncated) should] beZero];
                });
            });
            context(@"Large", ^{
                NSString *const truncatedSecondaryID = @"TRANSACTION";
                NSUInteger const bytesTruncated = 42;
                beforeEach(^{
                    [transactionIDTruncator enableTruncationWithResult:truncatedSecondaryID
                                                        bytesTruncated:bytesTruncated];
                });
                it(@"Should call truncator", ^{
                    [[transactionIDTruncator should] receive:@selector(truncatedString:onTruncation:)
                                               withArguments:secondaryID, kw_any()];
                    [formatter formattedRevenueModel:revenueInfoModel error:nil];
                });
                it(@"Should return model with truncated value", ^{
                    AMARevenueInfoModel *model = [formatter formattedRevenueModel:revenueInfoModel error:nil];
                    [[model.transactionInfo.secondaryID should] equal:truncatedSecondaryID];
                });
                it(@"Should not fill error", ^{
                    NSError *error = nil;
                    [formatter formattedRevenueModel:revenueInfoModel error:&error];
                    [[error should] beNil];
                });
                it(@"Should log truncation", ^{
                    [[logger should] receive:@selector(logTruncationOfType:value:maxLength:)
                               withArguments:@"transactionID", secondaryID, theValue(maxLength)];
                    [formatter formattedRevenueModel:revenueInfoModel error:nil];
                });
                it(@"Should return model with valid bytesTruncated", ^{
                    [[theValue([formatter formattedRevenueModel:revenueInfoModel error:nil].bytesTruncated) should]
                     equal:theValue(bytesTruncated)];
                });
            });
        });
        context(@"Secondary time", ^{
            NSDate *const secondaryTime = [NSDate date];
            beforeEach(^{
                transactionInfo.secondaryTime = secondaryTime;
            });
            it(@"Should return model with valid value", ^{
                AMARevenueInfoModel *result = [formatter formattedRevenueModel:revenueInfoModel error:nil];
                [[result.transactionInfo.secondaryTime should] equal:secondaryTime];
            });
            it(@"Should not fill error", ^{
                NSError *error = nil;
                [formatter formattedRevenueModel:revenueInfoModel error:&error];
                [[error should] beNil];
            });
            it(@"Should return model with zero bytesTruncated", ^{
                [[theValue([formatter formattedRevenueModel:revenueInfoModel error:nil].bytesTruncated) should] beZero];
            });
        });
    });

    context(@"Bytes truncating", ^{
        NSUInteger const maxLength = 100;
        NSUInteger expectedBytesCount = 9 + 5;
        NSString *const maxSizeString = @"1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890";

        beforeEach(^{
            formatter = [[AMARevenueInfoModelFormatter alloc] initWithProductIDTruncator:[[AMABytesStringTruncator alloc]
                                                                                          initWithMaxBytesLength:maxLength]
                                                                  transactionIDTruncator:[[AMABytesStringTruncator alloc]
                                                                                          initWithMaxBytesLength:maxLength]
                                                                  payloadStringTruncator:payloadStringTruncator
                                                                                  logger:logger];
            revenueInfoModel.productID = [maxSizeString stringByAppendingString:@"XXXXXXXXX"];
            revenueInfoModel.transactionID = [maxSizeString stringByAppendingString:@"XXXXX"];
        });

        it(@"Should return model with zero bytesTruncated", ^{
            [[theValue([formatter formattedRevenueModel:revenueInfoModel error:nil].bytesTruncated) should]
             equal:theValue(expectedBytesCount)];
        });
    });
});

SPEC_END
