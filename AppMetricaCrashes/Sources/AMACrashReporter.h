
#import <Foundation/Foundation.h>
#import "AMACrashLogging.h"
#import "AMACrashReporting.h"
#import "AMACrashLoader.h"
#import "AMAANRWatchdog.h"

@class AMACrashLoader;
@class AMACrashReportingStateNotifier;

@interface AMACrashReporter : NSObject <AMACrashReporting,
                                        AMACrashLoaderDelegate,
                                        AMAANRWatchdogDelegate,
                                        AMAHostStateProviderDelegate>

@property (nonatomic, strong, readonly) AMACrashLoader *crashLoader;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithExecutor:(id<AMAExecuting>)executor
                     crashLoader:(AMACrashLoader *)crashLoader
                   stateNotifier:(AMACrashReportingStateNotifier *)stateNotifier NS_DESIGNATED_INITIALIZER;

@end
