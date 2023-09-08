
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>

NS_ASSUME_NONNULL_BEGIN

@interface AMAFullDataTruncator : NSObject<AMADataTruncating>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithMaxLength:(NSUInteger)maxLength;

@end

NS_ASSUME_NONNULL_END
