
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - protocols

@protocol AMAExecuting <NSObject>

- (void)execute:(nullable dispatch_block_t)block;

@end

@protocol AMADelayedExecuting <AMAExecuting>

- (void)executeAfterDelay:(NSTimeInterval)delay block:(nullable dispatch_block_t)block;

@end

@protocol AMACancelableExecuting <AMADelayedExecuting>

- (void)cancelDelayed;

@end

#pragma mark - AMAExecutor

@interface AMAAsyncExecutor : NSObject <AMAExecuting>

- (instancetype)initWithQueue:(dispatch_queue_t)queue NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithIdentifier:(nullable NSObject *)identifier;

@end

#pragma mark - AMADelayedExecutor

@interface AMADelayedExecutor : AMAAsyncExecutor <AMADelayedExecuting>

@end

@interface AMACancelableDelayedExecutor : AMAAsyncExecutor <AMACancelableExecuting>

@end

NS_ASSUME_NONNULL_END
