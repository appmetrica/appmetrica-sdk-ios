
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(TestDelayedManualExecutor)
@interface AMATestDelayedManualExecutor : NSObject <AMACancelableExecuting>

- (NSTimeInterval)delayInterval;

@end

NS_SWIFT_NAME(CurrentQueueExecutor)
@interface AMACurrentQueueExecutor : NSObject <AMACancelableExecuting>

@end

NS_SWIFT_NAME(ManualCurrentQueueExecutor)
@interface AMAManualCurrentQueueExecutor : NSObject <AMACancelableExecuting>

@property (nonatomic, assign) BOOL executeNonDelayedBlocksImmediately;

- (void)execute;

@end

NS_ASSUME_NONNULL_END
