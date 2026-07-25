
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Types

typedef void (^AMAExecutingBlock)(void) NS_SWIFT_SENDABLE;

#pragma mark - Protocols

NS_SWIFT_NAME(AsyncExecuting)
NS_SWIFT_SENDABLE
@protocol AMAAsyncExecuting <NSObject>

- (void)execute:(AMAExecutingBlock)block;

@end

NS_SWIFT_NAME(SyncExecuting)
NS_SWIFT_SENDABLE
@protocol AMASyncExecuting <NSObject>
- (nullable id)syncExecute:(id _Nullable (^)(void))block;
@end


NS_SWIFT_NAME(DelayedExecuting)
NS_SWIFT_SENDABLE
@protocol AMADelayedExecuting <AMAAsyncExecuting>

- (void)executeAfterDelay:(NSTimeInterval)delay block:(AMAExecutingBlock)block;

@end

NS_SWIFT_NAME(CancelableExecuting)
NS_SWIFT_SENDABLE
@protocol AMACancelableExecuting <AMADelayedExecuting>

- (void)cancelDelayed;

@end

NS_SWIFT_NAME(ThreadProviding)
@protocol AMAThreadProviding<NSObject>

@property (nonatomic, strong, readonly) NSThread *thread;

@end


#pragma mark - AMAExecutor

NS_SWIFT_NAME(AsyncExecutor)
@interface AMAExecutor : NSObject <AMAAsyncExecuting, AMASyncExecuting>

- (instancetype)initWithQueue:(dispatch_queue_t)queue NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithIdentifier:(nullable NSObject *)identifier;

@end

#pragma mark - AMADelayedExecutor

NS_SWIFT_NAME(DelayedExecutor)
@interface AMADelayedExecutor : AMAExecutor <AMADelayedExecuting>

@end

NS_SWIFT_NAME(CancelableDelayedExecutor)
@interface AMACancelableDelayedExecutor : AMAExecutor <AMACancelableExecuting>

@end

NS_ASSUME_NONNULL_END
