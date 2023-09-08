
#import "AMASubscriptionInfoModel.h"

@interface AMASubscriptionInfoMutableModel : AMASubscriptionInfoModel

@property (nonatomic, assign) BOOL isAutoRenewing;
@property (nonatomic, strong) AMASubscriptionPeriod *subscriptionPeriod;

@property (nonatomic, strong) NSString *introductoryID;
@property (nonatomic, strong) NSDecimalNumber *introductoryPrice;
@property (nonatomic, strong) AMASubscriptionPeriod *introductoryPeriod;
@property (nonatomic, assign) NSUInteger introductoryPeriodCount;

@end
