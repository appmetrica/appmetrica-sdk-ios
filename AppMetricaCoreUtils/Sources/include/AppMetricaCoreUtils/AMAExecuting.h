
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - protocols

NS_SWIFT_NAME(Executing)
@protocol AMAExecuting <NSObject>

- (void)execute:(nullable dispatch_block_t)block;

@end

NS_SWIFT_NAME(DelayedExecuting)
@protocol AMADelayedExecuting <AMAExecuting>

- (void)executeAfterDelay:(NSTimeInterval)delay block:(nullable dispatch_block_t)block;

@end

NS_SWIFT_NAME(CancelableExecuting)
@protocol AMACancelableExecuting <AMADelayedExecuting>

- (void)cancelDelayed;

@end

#pragma mark - AMAExecutor

NS_SWIFT_NAME(AsyncExecutor)
@interface AMAAsyncExecutor : NSObject <AMAExecuting>

- (instancetype)initWithQueue:(dispatch_queue_t)queue NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithIdentifier:(nullable NSObject *)identifier;

@end

#pragma mark - AMADelayedExecutor

NS_SWIFT_NAME(DelayedExecutor)
@interface AMADelayedExecutor : AMAAsyncExecutor <AMADelayedExecuting>

@end

NS_SWIFT_NAME(CancelableDelayedExecutor)
@interface AMACancelableDelayedExecutor : AMAAsyncExecutor <AMACancelableExecuting>

@end

NS_ASSUME_NONNULL_END
