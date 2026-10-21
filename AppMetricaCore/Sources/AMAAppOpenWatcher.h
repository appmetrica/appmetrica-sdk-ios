
#import <Foundation/Foundation.h>
#import "AMAStartupCompletionObserving.h"

@class AMAStartupParametersConfiguration;
@class AMAReporter;
@protocol AMAAsyncExecuting;

@interface AMAAppOpenWatcher : NSObject

- (instancetype)initWithNotificationCenter:(NSNotificationCenter *)center;
- (void)startWatchingWithReporter:(AMAReporter *)reporter;

@end
