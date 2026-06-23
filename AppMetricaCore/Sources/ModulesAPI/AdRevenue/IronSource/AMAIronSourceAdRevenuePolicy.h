
#import "AMAInfoPlistPolicy.h"

NS_ASSUME_NONNULL_BEGIN

/// Controls IronSource ad revenue autocollection.
/// Key: io.appmetrica.ironsource_auto_ad_revenue_enabled (BOOL, default YES)
@interface AMAIronSourceAdRevenuePolicy : AMAInfoPlistPolicy

- (instancetype)initWithBundle:(NSBundle *)bundle NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithBundle:(NSBundle *)bundle
                           key:(NSString *)key
                  defaultValue:(BOOL)defaultValue NS_UNAVAILABLE;

+ (instancetype)sharedInstance;

@end

NS_ASSUME_NONNULL_END
