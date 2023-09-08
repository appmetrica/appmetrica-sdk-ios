
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>

@protocol AMADateProviding;

@interface AMAIntervalExecutionCondition : NSObject <AMAExecutionCondition>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithLastExecuted:(NSDate *)lastExecuted
                            interval:(NSTimeInterval)interval
                 underlyingCondition:(id<AMAExecutionCondition>)underlyingCondition;

- (instancetype)initWithLastExecuted:(NSDate *)lastExecuted
                            interval:(NSTimeInterval)interval
                 underlyingCondition:(id<AMAExecutionCondition>)underlyingCondition
                        dateProvider:(id<AMADateProviding>)dateProvider;

@end
