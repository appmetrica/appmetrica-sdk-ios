
#import <Foundation/Foundation.h>

@class AMAPrivacyTimer;
@class AMAAdProviderProxy;
@protocol AMACancelableExecuting;
@protocol AMAAsyncExecuting;
@protocol AMAPrivacyTimerRetryPolicy;

NS_ASSUME_NONNULL_BEGIN

@protocol AMAPrivacyTimerDelegate<NSObject>
- (void)privacyTimerDidFire:(AMAPrivacyTimer*)privacyTimer;
@end

@interface AMAPrivacyTimer : NSObject

@property (nullable, nonatomic, weak) id<AMAPrivacyTimerDelegate> delegate;
@property (nonatomic, strong) id<AMAPrivacyTimerRetryPolicy> timerStorage;

- (instancetype)initWithTimerRetryPolicy:(id<AMAPrivacyTimerRetryPolicy>)retryPolicy
                        delegateExecutor:(id<AMAAsyncExecuting>)executor
                          adProviderProxy:(AMAAdProviderProxy *)adProviderProxy;

- (instancetype)initWithTimerRetryPolicy:(id<AMAPrivacyTimerRetryPolicy>)retryPolicy
                                executor:(id<AMACancelableExecuting>)executor
                        delegateExecutor:(id<AMAAsyncExecuting>)executor
                          adProviderProxy:(AMAAdProviderProxy *)adProviderProxy;

- (void)start;
- (void)stop;

@end

NS_ASSUME_NONNULL_END
