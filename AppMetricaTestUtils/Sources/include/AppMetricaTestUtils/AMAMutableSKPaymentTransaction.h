
#import <StoreKit/StoreKit.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(MutableSKPaymentTransaction)
@interface AMAMutableSKPaymentTransaction : SKPaymentTransaction

@property(nonatomic, nullable, strong) NSError *error;
@property(nonatomic, nullable, strong) SKPaymentTransaction *originalTransaction;
@property(nonatomic, nullable, strong) SKPayment *payment;
@property(nonatomic, nullable, strong) NSArray<SKDownload *> *downloads;
@property(nonatomic, nullable, strong) NSDate *transactionDate;
@property(nonatomic, nullable, strong) NSString *transactionIdentifier;
@property(nonatomic, assign) SKPaymentTransactionState transactionState;

@end

NS_ASSUME_NONNULL_END
