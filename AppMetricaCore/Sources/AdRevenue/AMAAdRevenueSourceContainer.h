#import <Foundation/Foundation.h>
#import "AMAAdRevenueSourceStorable.h"

NS_ASSUME_NONNULL_BEGIN

@interface AMAAdRevenueSourceContainer : NSObject<AMAAdRevenueSourceStorable>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

+ (instancetype)sharedInstance;

@end

NS_ASSUME_NONNULL_END
