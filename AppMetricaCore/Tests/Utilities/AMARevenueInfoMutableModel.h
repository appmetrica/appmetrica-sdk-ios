
#import "AMARevenueInfoModel.h"

@interface AMARevenueInfoMutableModel : AMARevenueInfoModel

@property (nonatomic, assign) double price;
@property (nonatomic, strong) NSDecimalNumber *priceDecimal;
@property (nonatomic, copy) NSString *currency;
@property (nonatomic, assign) NSUInteger quantity;
@property (nonatomic, copy) NSString *productID;
@property (nonatomic, copy) NSString *transactionID;
@property (nonatomic, copy) NSData *receiptData;
@property (nonatomic, copy) NSString *payloadString;
@property (nonatomic, assign) NSUInteger bytesTruncated;
// Auto-in-app-purchases types
@property (nonatomic, assign) BOOL isAutoCollected;
@property (nonatomic, assign) AMAInAppType inAppType;
@property (nonatomic, strong) AMASubscriptionInfoModel *subscriptionInfo;
@property (nonatomic, strong) AMATransactionInfoModel *transactionInfo;

- (instancetype)initWithPriceDecimal:(NSDecimalNumber *)priceDecimal currency:(NSString *)currency;

@end
