
#import <Foundation/Foundation.h>
#import "AMAStartupCompletionObserving.h"
#import "AMATransactionObserver.h"
#import "AMAProductRequestor.h"

@class AMAReporter;
@class AMATransactionObserver;
@class AMARevenueInfoModelFactory;
@protocol AMAExecuting;

@interface AMAAutoPurchasesWatcher : NSObject<AMATransactionObserverDelegate, AMAProductRequestorDelegate>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithExecutor:(id<AMAExecuting>)executor
             transactionObserver:(AMATransactionObserver *)observer
                         factory:(AMARevenueInfoModelFactory *)factory;

- (instancetype)initWithExecutor:(id<AMAExecuting>)executor;

- (void)startWatchingWithReporter:(AMAReporter *)reporter;

@end
