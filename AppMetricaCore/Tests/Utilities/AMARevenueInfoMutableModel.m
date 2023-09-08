
#import "AMARevenueInfoMutableModel.h"

@implementation AMARevenueInfoMutableModel

@dynamic priceDecimal;
@dynamic currency;
@dynamic quantity;
@dynamic productID;
@dynamic transactionID;
@dynamic receiptData;
@dynamic payloadString;
@dynamic bytesTruncated;
@dynamic isAutoCollected;
@dynamic inAppType;
@dynamic subscriptionInfo;
@dynamic transactionInfo;

- (instancetype)initWithPriceDecimal:(NSDecimalNumber *)priceDecimal currency:(NSString *)currency
{
    return [super initWithPriceDecimal:priceDecimal
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
}

@end
