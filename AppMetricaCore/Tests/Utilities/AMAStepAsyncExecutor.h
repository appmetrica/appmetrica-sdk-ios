#import <Foundation/Foundation.h>
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>

NS_ASSUME_NONNULL_BEGIN

@interface AMAStepAsyncExecutor : NSObject <AMAAsyncExecuting>

@property (nonatomic, readonly) NSUInteger pendingBlockCount;

- (BOOL)runNext;
- (void)runUntilIdle;
- (BOOL)waitForPendingBlockCount:(NSUInteger)pendingBlockCount timeout:(NSTimeInterval)timeout;

@end

NS_ASSUME_NONNULL_END
