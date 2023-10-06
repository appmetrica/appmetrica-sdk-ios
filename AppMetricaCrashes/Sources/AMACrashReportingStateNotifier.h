
#import <Foundation/Foundation.h>
#import <dispatch/dispatch.h>

#import "AMACrashLogging.h"
#import "AMACrashes.h"

extern NSString *const kAMACrashReportingStateEnabledKey;
extern NSString *const kAMACrashReportingStateCrashedLastLaunchKey;

@interface AMACrashReportingStateNotifier : NSObject

- (void)addObserverWithCompletionQueue:(dispatch_queue_t)completionQueue
                       completionBlock:(AMACrashReportingStateCompletionBlock)completionBlock;

- (void)notifyWithEnabled:(BOOL)enabled crashedLastLaunch:(NSNumber *)crashedLastLaunch;

@end
