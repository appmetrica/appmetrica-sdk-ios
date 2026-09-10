#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AMASavedAppMetricaConfigTtlChecker : NSObject

/// 30 × 24 hours, matching Android `TimeUnit.DAYS.toMillis(30)`.
@property (nonatomic, class, readonly) NSTimeInterval savedAppMetricaConfigTTL;

+ (BOOL)isExpiredForSavedAt:(NSDate *)savedAt now:(NSDate *)now;

@end

NS_ASSUME_NONNULL_END
