
#import <Foundation/Foundation.h>
#import "AMACrashLogging.h"
#import "AMACrashReporting.h"

@interface AMACrashReportingStateNotifier : NSObject

- (void)addObserverWithCompletionQueue:(dispatch_queue_t)completionQueue
                       completionBlock:(AMACrashReportingStateCompletionBlock)completionBlock;

- (void)notifyWithEnabled:(BOOL)enabled crashedLastLaunch:(NSNumber *)crashedLastLaunch;

@end
