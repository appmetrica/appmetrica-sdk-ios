
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol AMAPrivacyTimerRetryPolicy <NSObject>

@property (readonly, nonatomic) NSArray<NSNumber *> *retryPeriod;
@property (readonly) BOOL isResendPeriodOutdated;
- (void) privacyEventSent;

@end

NS_ASSUME_NONNULL_END
