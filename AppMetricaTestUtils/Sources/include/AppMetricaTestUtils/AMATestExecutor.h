
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(TestDelayedManualExecutor)
@interface AMATestDelayedManualExecutor : NSObject <AMACancelableExecuting, AMASyncExecuting>

- (NSTimeInterval)delayInterval;

@end

NS_SWIFT_NAME(CurrentQueueExecutor)
@interface AMACurrentQueueExecutor : NSObject <AMACancelableExecuting, AMASyncExecuting, AMAThreadProviding>

@end

NS_SWIFT_NAME(ManualCurrentQueueExecutor)
@interface AMAManualCurrentQueueExecutor : NSObject <AMACancelableExecuting, AMASyncExecuting>

@property (nonatomic, assign) BOOL executeNonDelayedBlocksImmediately;

- (void)execute;

@end

NS_ASSUME_NONNULL_END
