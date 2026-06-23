
#import "AMAInfoPlistPolicy.h"

NS_ASSUME_NONNULL_BEGIN

@interface AMAAppLovinAdRevenuePolicy : AMAInfoPlistPolicy

- (instancetype)initWithBundle:(NSBundle *)bundle NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithBundle:(NSBundle *)bundle
                           key:(NSString *)key
                  defaultValue:(BOOL)defaultValue NS_UNAVAILABLE;

+ (instancetype)sharedInstance;

@end

NS_ASSUME_NONNULL_END
