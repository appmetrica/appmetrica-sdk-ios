
#import "AMAAdRevenueInfoMutableModel.h"

@implementation AMAAdRevenueInfoMutableModel

@dynamic amount;
@dynamic currency;
@dynamic adType;
@dynamic adNetwork;
@dynamic adUnitID;
@dynamic adUnitName;
@dynamic adPlacementID;
@dynamic adPlacementName;
@dynamic precision;
@dynamic payloadString;
@dynamic bytesTruncated;

- (instancetype)initWithAmount:(NSDecimalNumber *)amount currency:(NSString *)currency
{
    return [super initWithAmount:amount
                        currency:currency
                          adType:AMAAdTypeNative
                       adNetwork:nil
                        adUnitID:nil
                      adUnitName:nil
                   adPlacementID:nil
                 adPlacementName:nil
                       precision:nil
                   payloadString:nil
                  bytesTruncated:0
                 isAutocollected:NO];
}

@end
