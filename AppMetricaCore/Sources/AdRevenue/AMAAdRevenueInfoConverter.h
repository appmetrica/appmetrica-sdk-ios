
#import <Foundation/Foundation.h>

@class AMAAdRevenueInfoModel;
@class AMAAdRevenueInfo;

@interface AMAAdRevenueInfoConverter : NSObject

+ (AMAAdRevenueInfoModel *)convertAdRevenueInfo:(AMAAdRevenueInfo *)adRevenueInfo
                                isAutocollected:(BOOL)isAutocollected
                                          error:(NSError **)error;

@end
