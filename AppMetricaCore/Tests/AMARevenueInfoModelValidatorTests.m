
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMACore.h"
#import "AMARevenueInfoModelValidator.h"
#import "AMARevenueInfoProcessingLogger.h"
#import "AMARevenueInfoModel.h"
#import "AMAAppMetrica.h"
#import "AMASubscriptionInfoModel.h"
#import "AMATransactionInfoModel.h"

SPEC_BEGIN(AMARevenueInfoModelValidatorTests)

describe(@"AMARevenueInfoModelValidator", ^{

    double const price = 23.5;
    NSDecimalNumber *const priceDecimal = [NSDecimalNumber decimalNumberWithString:@"23.5"];
    NSString *const currency = @"USD";
    NSUInteger const quantity = 42;
    NSString *const productID = @"PRODUCT_ID";
    NSString *const transactionID = @"TRANSACTION_ID";
    NSData *const receiptData = [@"RECEIPT_DATA" dataUsingEncoding:NSUTF8StringEncoding];
    NSString *const payloadString = @"PAYLOAD_STRING";
    NSUInteger const bytesTruncated = 0;

    AMARevenueInfoModel *__block model = nil;
    AMARevenueInfoProcessingLogger *__block logger = nil;
    AMARevenueInfoModelValidator *__block validator = nil;
    AMASubscriptionInfoModel *__block subscriptionInfoModel = nil;
    AMATransactionInfoModel *__block transactionInfoModel = nil;

    beforeEach(^{
        subscriptionInfoModel = [AMASubscriptionInfoModel nullMock];
        transactionInfoModel = [AMATransactionInfoModel nullMock];
        logger = [AMARevenueInfoProcessingLogger nullMock];
        validator = [[AMARevenueInfoModelValidator alloc] initWithLogger:logger];
    });

    context(@"Full", ^{
        beforeEach(^{
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
                                                     subscriptionInfo:subscriptionInfoModel
                                                      transactionInfo:transactionInfoModel];
        });
        it(@"Should return YES", ^{
            [[theValue([validator validateRevenueInfoModel:model error:nil]) should] beYes];
        });
        it(@"Should not fill error", ^{
            NSError *error = nil;
            [validator validateRevenueInfoModel:model error:&error];
            [[error should] beNil];
        });
    });
    context(@"Minimal", ^{
        beforeEach(^{
            model = [[AMARevenueInfoModel alloc] initWithPriceDecimal:priceDecimal
                                                             currency:currency
                                                             quantity:quantity
                                                            productID:nil
                                                        transactionID:nil
                                                          receiptData:nil
                                                        payloadString:nil
                                                       bytesTruncated:bytesTruncated
                                                      isAutoCollected:NO
                                                            inAppType:AMAInAppTypePurchase
                                                     subscriptionInfo:nil
                                                      transactionInfo:nil];
        });
        it(@"Should return YES", ^{
            [[theValue([validator validateRevenueInfoModel:model error:nil]) should] beYes];
        });
        it(@"Should not fill error", ^{
            NSError *error = nil;
            [validator validateRevenueInfoModel:model error:&error];
            [[error should] beNil];
        });
    });
    context(@"With decimal price", ^{
        beforeEach(^{
            model = [[AMARevenueInfoModel alloc] initWithPriceDecimal:priceDecimal
                                                             currency:currency
                                                             quantity:quantity
                                                            productID:nil
                                                        transactionID:nil
                                                          receiptData:nil
                                                        payloadString:nil
                                                       bytesTruncated:bytesTruncated
                                                      isAutoCollected:YES
                                                            inAppType:AMAInAppTypePurchase
                                                     subscriptionInfo:subscriptionInfoModel
                                                      transactionInfo:transactionInfoModel];
        });
        it(@"Should return YES", ^{
            [[theValue([validator validateRevenueInfoModel:model error:nil]) should] beYes];
        });
        it(@"Should not fill error", ^{
            NSError *error = nil;
            [validator validateRevenueInfoModel:model error:&error];
            [[error should] beNil];
        });
    });
    context(@"Zero quantity", ^{
        beforeEach(^{
            model = [[AMARevenueInfoModel alloc] initWithPriceDecimal:priceDecimal
                                                             currency:currency
                                                             quantity:0
                                                            productID:productID
                                                        transactionID:transactionID
                                                          receiptData:receiptData
                                                        payloadString:payloadString
                                                       bytesTruncated:bytesTruncated
                                                      isAutoCollected:YES
                                                            inAppType:AMAInAppTypePurchase
                                                     subscriptionInfo:subscriptionInfoModel
                                                      transactionInfo:transactionInfoModel];
        });
        it(@"Should return NO", ^{
            [[theValue([validator validateRevenueInfoModel:model error:nil]) should] beNo];
        });
        it(@"Should fill error", ^{
            NSString *description = @"Quantity can't be zero.";
            NSError *expectedError = [NSError errorWithDomain:kAMAAppMetricaErrorDomain
                                                         code:AMAAppMetricaEventErrorCodeInvalidRevenueInfo
                                                     userInfo:@{ NSLocalizedDescriptionKey: description}];
            NSError *error = nil;
            [validator validateRevenueInfoModel:model error:&error];
            [[error should] equal:expectedError];
        });
        it(@"Should log", ^{
            [[logger should] receive:@selector(logZeroQuantity)];
            [validator validateRevenueInfoModel:model error:nil];
        });
    });
    context(@"Wrong currency", ^{
        NSString *__block wrongCurrency = nil;
        AMARevenueInfoModel *(^modelWithWrongCurrency)(void) = ^{
            return [[AMARevenueInfoModel alloc] initWithPriceDecimal:priceDecimal
                                                            currency:wrongCurrency
                                                            quantity:quantity
                                                           productID:productID
                                                       transactionID:transactionID
                                                         receiptData:receiptData
                                                       payloadString:payloadString
                                                      bytesTruncated:bytesTruncated
                                                     isAutoCollected:YES
                                                           inAppType:AMAInAppTypePurchase
                                                    subscriptionInfo:subscriptionInfoModel
                                                     transactionInfo:transactionInfoModel];
        };
        NSString *(^expectedErrorDescription)(void) = ^{
            return [NSString stringWithFormat:@"Invalid currency code '%@'. Expected ISO 4217 format.", wrongCurrency];
        };
        context(@"Wrong size", ^{
            beforeEach(^{
                wrongCurrency = @"USDD";
                model = modelWithWrongCurrency();
            });
            it(@"Should return NO", ^{
                [[theValue([validator validateRevenueInfoModel:model error:nil]) should] beNo];
            });
            it(@"Should fill error", ^{
                NSString *description = expectedErrorDescription();
                NSError *expectedError = [NSError errorWithDomain:kAMAAppMetricaErrorDomain
                                                             code:AMAAppMetricaEventErrorCodeInvalidRevenueInfo
                                                         userInfo:@{ NSLocalizedDescriptionKey: description}];
                NSError *error = nil;
                [validator validateRevenueInfoModel:model error:&error];
                [[error should] equal:expectedError];
            });
            it(@"Should log", ^{
                [[logger should] receive:@selector(logInvalidCurrency:) withArguments:wrongCurrency];
                [validator validateRevenueInfoModel:model error:nil];
            });
        });
        context(@"Wrong symbols case", ^{
            beforeEach(^{
                wrongCurrency = @"byn";
                model = modelWithWrongCurrency();
            });
            it(@"Should return NO", ^{
                [[theValue([validator validateRevenueInfoModel:model error:nil]) should] beNo];
            });
            it(@"Should fill error", ^{
                NSString *description = expectedErrorDescription();
                NSError *expectedError = [NSError errorWithDomain:kAMAAppMetricaErrorDomain
                                                             code:AMAAppMetricaEventErrorCodeInvalidRevenueInfo
                                                         userInfo:@{ NSLocalizedDescriptionKey: description}];
                NSError *error = nil;
                [validator validateRevenueInfoModel:model error:&error];
                [[error should] equal:expectedError];
            });
            it(@"Should log", ^{
                [[logger should] receive:@selector(logInvalidCurrency:) withArguments:wrongCurrency];
                [validator validateRevenueInfoModel:model error:nil];
            });
        });
        context(@"Wrong symbols", ^{
            beforeEach(^{
                wrongCurrency = @"US1";
                model = modelWithWrongCurrency();
            });
            it(@"Should return NO", ^{
                [[theValue([validator validateRevenueInfoModel:model error:nil]) should] beNo];
            });
            it(@"Should fill error", ^{
                NSString *description = expectedErrorDescription();
                NSError *expectedError = [NSError errorWithDomain:kAMAAppMetricaErrorDomain
                                                             code:AMAAppMetricaEventErrorCodeInvalidRevenueInfo
                                                         userInfo:@{ NSLocalizedDescriptionKey: description}];
                NSError *error = nil;
                [validator validateRevenueInfoModel:model error:&error];
                [[error should] equal:expectedError];
            });
            it(@"Should log", ^{
                [[logger should] receive:@selector(logInvalidCurrency:) withArguments:wrongCurrency];
                [validator validateRevenueInfoModel:model error:nil];
            });
        });
    });
    context(@"Transaction ID without receipt data", ^{
        beforeEach(^{
            model = [[AMARevenueInfoModel alloc] initWithPriceDecimal:priceDecimal
                                                             currency:currency
                                                             quantity:quantity
                                                            productID:productID
                                                        transactionID:transactionID
                                                          receiptData:nil
                                                        payloadString:payloadString
                                                       bytesTruncated:bytesTruncated
                                                      isAutoCollected:YES
                                                            inAppType:AMAInAppTypePurchase
                                                     subscriptionInfo:subscriptionInfoModel
                                                      transactionInfo:transactionInfoModel];
        });
        it(@"Should return YES", ^{
            [[theValue([validator validateRevenueInfoModel:model error:nil]) should] beYes];
        });
        it(@"Should not fill error", ^{
            NSError *error = nil;
            [validator validateRevenueInfoModel:model error:&error];
            [[error should] beNil];
        });
        it(@"Should log", ^{
            [[logger should] receive:@selector(logReceiptDataIsMissing)];
            [validator validateRevenueInfoModel:model error:nil];
        });
    });
    context(@"Receipt data without transaction ID", ^{
        beforeEach(^{
            model = [[AMARevenueInfoModel alloc] initWithPriceDecimal:priceDecimal
                                                             currency:currency
                                                             quantity:quantity
                                                            productID:productID
                                                        transactionID:nil
                                                          receiptData:receiptData
                                                        payloadString:payloadString
                                                       bytesTruncated:bytesTruncated
                                                      isAutoCollected:YES
                                                            inAppType:AMAInAppTypePurchase
                                                     subscriptionInfo:subscriptionInfoModel
                                                      transactionInfo:transactionInfoModel];
        });
        it(@"Should return YES", ^{
            [[theValue([validator validateRevenueInfoModel:model error:nil]) should] beYes];
        });
        it(@"Should not fill error", ^{
            NSError *error = nil;
            [validator validateRevenueInfoModel:model error:&error];
            [[error should] beNil];
        });
        it(@"Should log", ^{
            [[logger should] receive:@selector(logTransactionIDIsMissing)];
            [validator validateRevenueInfoModel:model error:nil];
        });
    });

});

SPEC_END
