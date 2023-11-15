#import <Foundation/Foundation.h>

#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(DateProviderMock)
@interface AMADateProviderMock : NSObject <AMADateProviding>

- (NSDate *)freeze;

- (void)freezeWithDate:(NSDate *)date;

@end

NS_ASSUME_NONNULL_END
