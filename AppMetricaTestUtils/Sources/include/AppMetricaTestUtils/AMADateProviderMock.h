
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>

NS_ASSUME_NONNULL_BEGIN

@interface AMADateProviderMock : NSObject <AMADateProviding>

- (NSDate *)freeze;

- (void)freezeWithDate:(NSDate *)date;

@end

NS_ASSUME_NONNULL_END
