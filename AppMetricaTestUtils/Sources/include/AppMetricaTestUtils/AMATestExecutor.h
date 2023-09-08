
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>

NS_ASSUME_NONNULL_BEGIN

@interface AMATestDelayedManualExecutor : NSObject <AMACancelableExecuting>

- (NSTimeInterval)delayInterval;

@end

@interface AMACurrentQueueExecutor : NSObject <AMACancelableExecuting>

@end

@interface AMAManualCurrentQueueExecutor : NSObject <AMACancelableExecuting>

@property (nonatomic, assign) BOOL executeNonDelayedBlocksImmediately;

- (void)execute;

@end

NS_ASSUME_NONNULL_END
