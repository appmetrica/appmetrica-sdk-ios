
#import <Foundation/Foundation.h>

@protocol AMAAsyncExecuting;

NS_ASSUME_NONNULL_BEGIN

/// Subscribes to ALCCommunicator "max_revenue_events" topic and reports ILRD as autocollected ad revenue.
@interface AMAAppLovinMaxIlrdObserver : NSObject

- (instancetype)initWithExecutor:(id<AMAAsyncExecuting>)executor NS_DESIGNATED_INITIALIZER;

/// Subscribe or unsubscribe based on the aram enabled flag.
/// Called by AMAAppLovinManager on activation and on startup updates.
- (void)activateAndSubscribe:(BOOL)enabled;

@end

NS_ASSUME_NONNULL_END
