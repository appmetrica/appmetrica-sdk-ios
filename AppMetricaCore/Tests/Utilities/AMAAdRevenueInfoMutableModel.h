
#import "AMAAdRevenueInfoModel.h"

@interface AMAAdRevenueInfoMutableModel : AMAAdRevenueInfoModel

@property (nonatomic, strong) NSDecimalNumber *amount;
@property (nonatomic, copy) NSString *currency;
@property (nonatomic, assign) AMAAdType adType;
@property (nonatomic, copy) NSString *adNetwork;
@property (nonatomic, copy) NSString *adUnitID;
@property (nonatomic, copy) NSString *adUnitName;
@property (nonatomic, copy) NSString *adPlacementID;
@property (nonatomic, copy) NSString *adPlacementName;
@property (nonatomic, copy) NSString *precision;
@property (nonatomic, copy) NSString *payloadString;
@property (nonatomic, assign) NSUInteger bytesTruncated;

- (instancetype)initWithAmount:(NSDecimalNumber *)amount currency:(NSString *)currency;

@end
