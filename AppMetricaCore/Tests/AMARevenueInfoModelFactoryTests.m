
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMARevenueInfoModelFactory.h"
#import "AMARevenueInfoModel.h"
#import "AMATransactionInfoModel.h"
#import "AMASubscriptionInfoModel.h"
#import "AMASubscriptionPeriod.h"

SPEC_BEGIN(AMARevenueInfoModelFactoryTests)

describe(@"AMARevenueInfoModelFactory", ^{
    
    AMAMutableSKProduct *__block product = nil;
    SKMutablePayment *__block payment = nil;
    AMAMutableSKPaymentTransaction *__block transaction = nil;
    
    NSData *__block receiptData = nil;
    
    AMARevenueInfoModelFactory *__block revenueFactory = nil;
    AMARevenueInfoModel *__block model = nil;
    
    __auto_type createModel = ^(AMATransactionState state){
        model = [revenueFactory revenueInfoModelWithTransaction:transaction state:state product:product];
    };
    
    beforeEach(^{
        product = [[AMAMutableSKProduct alloc] init];
        product.localizedDescription = @"1 super coin";
        product.localizedTitle = @"1 Coint";
        product.price = [NSDecimalNumber decimalNumberWithString:@"0.99"];
        product.priceLocale = [NSLocale localeWithLocaleIdentifier:@"en_US"]; // for USD currency
        product.productIdentifier = @"io.appmetrica.coin.super";
        product.isDownloadable = NO;
        product.isFamilyShareable = NO;
        product.downloadContentLengths = @[];
        product.downloadContentVersion = @"1.0.0";
        product.subscriptionPeriod = nil;
        product.introductoryPrice = nil;
        product.discounts = @[];
        product.subscriptionGroupIdentifier = nil;
        
        payment = [[SKMutablePayment alloc] init];
        payment.productIdentifier = product.productIdentifier;
        payment.requestData = nil;
        payment.quantity = 1;
        payment.applicationUsername = nil;
        payment.paymentDiscount = nil;
        
        AMAMutableSKPaymentTransaction *originalTransaction = [[AMAMutableSKPaymentTransaction alloc] init];
        originalTransaction.transactionIdentifier = @"123456789";
        originalTransaction.transactionDate = [NSDate dateWithTimeIntervalSinceNow:-1000];
        
        transaction = [[AMAMutableSKPaymentTransaction alloc] init];
        transaction.error = nil;
        transaction.originalTransaction = originalTransaction;
        transaction.payment = payment;
        transaction.downloads = nil;
        transaction.transactionDate = [NSDate date];
        transaction.transactionIdentifier = @"987654321";
        transaction.transactionState = SKPaymentTransactionStatePurchased;
        
        NSURL *tmpDir = [NSFileManager.defaultManager.temporaryDirectory URLByAppendingPathComponent:@"receiptData"];
        [[NSBundle mainBundle] stub:@selector(appStoreReceiptURL) andReturn:tmpDir];
        
        receiptData = [@"receipt_data" dataUsingEncoding:NSUTF8StringEncoding];
        [receiptData writeToURL:tmpDir atomically:YES];
        
        revenueFactory = [[AMARevenueInfoModelFactory alloc] init];
    });
    
    context(@"Purchase", ^{
        
        beforeEach(^{
            product.subscriptionPeriod = nil;
            transaction.transactionState = SKPaymentTransactionStatePurchased;
            createModel(AMATransactionStatePurchased);
        });
        
        it(@"Should fill price", ^{
            [[model.priceDecimal should] equal:product.price];
        });
        
        it(@"Should fill USD currency", ^{
            [[model.currency should] equal:@"USD"];
        });
        
        it(@"Should fill quantity", ^{
            [[theValue(model.quantity) should] equal:theValue(payment.quantity)];
        });
        
        it(@"Should fill product ID", ^{
            [[model.productID should] equal:product.productIdentifier];
        });
        
        it(@"Should fill receipt data", ^{
            [[model.receiptData should] equal:receiptData];
        });
        
        it(@"Should not truncate data", ^{
            [[theValue(model.bytesTruncated) should] beZero];
        });

        it(@"Should not fill payload", ^{
            [[model.payloadString should] beNil];
        });

        it(@"Should be auto-collected", ^{
            [[theValue(model.isAutoCollected) should] beYes];
        });
        
        it(@"Should fill in-app type with Purchase", ^{
            [[theValue(model.inAppType) should] equal:theValue(AMAInAppTypePurchase)];
        });
        
        it(@"Should not fill subscription info", ^{
            [[model.subscriptionInfo should] beNil];
        });
        
        context(@"Purchased/Renewed", ^{
            
            it(@"Should set transaction state to purchased", ^{
                [[theValue(model.transactionInfo.transactionState) should] equal:theValue(AMATransactionStatePurchased)];
            });
            
            it(@"Should fill current transaction ID to receipt", ^{
                [[model.transactionID should] equal:transaction.transactionIdentifier];
            });
            
            it(@"Should fill current transaction ID to transaction info ID", ^{
                [[model.transactionInfo.transactionID should] equal:transaction.transactionIdentifier];
            });
            
            it(@"Should fill current transaction date to transaction info time", ^{
                [[model.transactionInfo.transactionTime should] equal:transaction.transactionDate];
            });
            
            it(@"Should fill original transaction ID to transaction info Secondary ID", ^{
                [[model.transactionInfo.secondaryID should] equal:transaction.originalTransaction.transactionIdentifier];
            });
            
            it(@"Should fill original transaction date to transaction info Secondary time", ^{
                [[model.transactionInfo.secondaryTime should] equal:transaction.originalTransaction.transactionDate];
            });
        });
        
        context(@"Restored", ^{
            
            beforeEach(^{
                revenueFactory = [[AMARevenueInfoModelFactory alloc] init];
                
                transaction.transactionState = SKPaymentTransactionStateRestored;
                createModel(AMATransactionStateRestored);
            });
            
            it(@"Should set transaction state to restored", ^{
                [[theValue(model.transactionInfo.transactionState) should] equal:theValue(AMATransactionStateRestored)];
            });
            
            it(@"Should fill original transaction ID to receipt", ^{
                [[model.transactionID should] equal:transaction.originalTransaction.transactionIdentifier];
            });
            
            it(@"Should fill original transaction ID to transaction info ID", ^{
                [[model.transactionInfo.transactionID should] equal:transaction.originalTransaction.transactionIdentifier];
            });
            
            it(@"Should fill original transaction date to transaction info time", ^{
                [[model.transactionInfo.transactionTime should] equal:transaction.originalTransaction.transactionDate];
            });
            
            it(@"Should fill current transaction ID to transaction info Secondary ID", ^{
                [[model.transactionInfo.secondaryID should] equal:transaction.transactionIdentifier];
            });
            
            it(@"Should fill current transaction date to transaction info Secondary time", ^{
                [[model.transactionInfo.secondaryTime should] equal:transaction.transactionDate];
            });
        });
        
        context(@"Undefined", ^{
            
            context(@"Production", ^{
               
                beforeEach(^{
                    [AMATestUtilities stubAssertions];
                    createModel(AMATransactionStateUndefined);
                });
                
                it(@"Should set transaction state to undefined", ^{
                    [[theValue(model.transactionInfo.transactionState) should] equal:theValue(AMATransactionStateUndefined)];
                });
                
                it(@"Should fill price", ^{
                    [[model.priceDecimal should] equal:product.price];
                });
                
                it(@"Should fill USD currency", ^{
                    [[model.currency should] equal:@"USD"];
                });
                
                it(@"Should fill quantity", ^{
                    [[theValue(model.quantity) should] equal:theValue(payment.quantity)];
                });
                
                it(@"Should fill product ID", ^{
                    [[model.productID should] equal:product.productIdentifier];
                });
                
                it(@"Should fill receipt data", ^{
                    [[model.receiptData should] equal:receiptData];
                });

                it(@"Should not fill payload", ^{
                    [[model.payloadString should] beNil];
                });
                
                it(@"Should not truncate data", ^{
                    [[theValue(model.bytesTruncated) should] beZero];
                });
                
                it(@"Should be auto-collected", ^{
                    [[theValue(model.isAutoCollected) should] beYes];
                });
                
                it(@"Should fill in-app type with Purchase", ^{
                    [[theValue(model.inAppType) should] equal:theValue(AMAInAppTypePurchase)];
                });
                
                it(@"Should not fill subscription info", ^{
                    [[model.subscriptionInfo should] beNil];
                });
            });
        });
    });
    
    context(@"Subscription", ^{
        
        beforeEach(^{
            SKProductSubscriptionMutablePeriod *period = [[SKProductSubscriptionMutablePeriod alloc] init];
            period.unit = SKProductPeriodUnitMonth;
            period.numberOfUnits = 6;
            
            SKProductSubscriptionMutablePeriod *discountPeriod = [[SKProductSubscriptionMutablePeriod alloc] init];
            discountPeriod.unit = SKProductPeriodUnitWeek;
            discountPeriod.numberOfUnits = 1;
            
            SKProductMutableDiscount *discount = [[SKProductMutableDiscount alloc] init];
            discount.price = [NSDecimalNumber decimalNumberWithString:@"19.99"];
            discount.priceLocale = [NSLocale localeWithLocaleIdentifier:@"en_US"]; // for USD currency
            discount.subscriptionPeriod = discountPeriod;
            discount.numberOfPeriods = 2;
            discount.paymentMode = SKProductDiscountPaymentModePayUpFront;
            discount.identifier = @"76543456789";
            discount.type = SKProductDiscountTypeIntroductory;
            
            product.subscriptionPeriod = period;
            product.introductoryPrice = discount;
            product.price = [NSDecimalNumber decimalNumberWithString:@"29.99"];
            product.subscriptionGroupIdentifier = @"Subscriptions";
            product.productIdentifier = @"io.appmetrica.subscription.halfyear";
            payment.productIdentifier = product.productIdentifier;
            
            transaction.transactionState = SKPaymentTransactionStatePurchased;
            createModel(AMATransactionStatePurchased);
        });
        
        it(@"Should fill price", ^{
            [[model.priceDecimal should] equal:product.price];
        });
        
        it(@"Should fill USD currency", ^{
            [[model.currency should] equal:@"USD"];
        });
        
        it(@"Should fill product ID", ^{
            [[model.productID should] equal:product.productIdentifier];
        });

        it(@"Should not truncate data", ^{
            [[theValue(model.bytesTruncated) should] beZero];
        });

        it(@"Should not fill payload", ^{
            [[model.payloadString should] beNil];
        });

        it(@"Should be auto-collected", ^{
            [[theValue(model.isAutoCollected) should] beYes];
        });
        
        it(@"Should fill in-app type with Subscription", ^{
            [[theValue(model.inAppType) should] equal:theValue(AMAInAppTypeSubscription)];
        });
        
        it(@"Should set auto-renewing always to YES", ^{
            [[theValue(model.subscriptionInfo.isAutoRenewing) should] beYes];
        });
        
        context(@"Subscription period", ^{
            it(@"Should fill subscription duration", ^{
                [[theValue(model.subscriptionInfo.subscriptionPeriod.count) should] equal:theValue(6)];
            });
            
            it(@"It should set Day period", ^{
                ((SKProductSubscriptionMutablePeriod *)product.subscriptionPeriod).unit = SKProductPeriodUnitDay;
                createModel(AMATransactionStatePurchased);
                [[theValue(model.subscriptionInfo.subscriptionPeriod.timeUnit) should] equal:theValue(AMATimeUnitDay)];
            });
            
            it(@"It should set Week period", ^{
                ((SKProductSubscriptionMutablePeriod *)product.subscriptionPeriod).unit = SKProductPeriodUnitWeek;
                createModel(AMATransactionStatePurchased);
                [[theValue(model.subscriptionInfo.subscriptionPeriod.timeUnit) should] equal:theValue(AMATimeUnitWeek)];
            });
            
            it(@"It should set Month period", ^{
                ((SKProductSubscriptionMutablePeriod *)product.subscriptionPeriod).unit = SKProductPeriodUnitMonth;
                createModel(AMATransactionStatePurchased);
                [[theValue(model.subscriptionInfo.subscriptionPeriod.timeUnit) should] equal:theValue(AMATimeUnitMonth)];
            });
            
            it(@"It should set Year period", ^{
                ((SKProductSubscriptionMutablePeriod *)product.subscriptionPeriod).unit = SKProductPeriodUnitYear;
                createModel(AMATransactionStatePurchased);
                [[theValue(model.subscriptionInfo.subscriptionPeriod.timeUnit) should] equal:theValue(AMATimeUnitYear)];
            });
        });
        context(@"Intoductary", ^{
            it(@"Should set Indroductary ID", ^{
                [[model.subscriptionInfo.introductoryID should] equal:product.introductoryPrice.identifier];
            });
            
            it(@"Should set intoructary price", ^{
                [[model.subscriptionInfo.introductoryPrice should] equal:product.introductoryPrice.price];
            });
            
            context(@"Intoductary period", ^{
                
                it(@"Should fill Intoductary duration", ^{
                    [[theValue(model.subscriptionInfo.introductoryPeriod.count) should] equal:theValue(1)];
                });
                
                it(@"Should fill Intoductary unit", ^{
                    [[theValue(model.subscriptionInfo.introductoryPeriod.timeUnit) should] equal:theValue(AMATimeUnitWeek)];
                });
                
                it(@"Should fill Intoductary durations count", ^{
                    [[theValue(model.subscriptionInfo.introductoryPeriodCount) should] equal:theValue(2)];
                });
            });
        });
    });
});

SPEC_END
