
#import <Foundation/Foundation.h>
#import <dispatch/dispatch.h>
#import <AppMetricaCoreExtension/AppMetricaCoreExtension.h>
#import "AMACrashLogging.h"
#import "AMACrashLoader.h"
#import "AMAANRWatchdog.h"
#import "AMACrashes.h"

@class AMAAppMetricaConfiguration;
@class AMACrashLoader;
@class AMACrashMatchingRule;
@class AMACrashReporter;
@class AMACrashReportingStateNotifier;
@class AMADecodedCrashSerializer;
@class AMAErrorEnvironment;
@class AMAErrorModelFactory;
@class AMAReporterStateStorage;

@protocol AMACrashProcessingReporting;
@protocol AMAExecuting;

@interface AMACrashes() <AMACrashLoaderDelegate,
                         AMAANRWatchdogDelegate,
                         AMAHostStateProviderDelegate,
                         AMAEventPollingDelegate,
                         AMAModuleActivationDelegate>

@property (nonatomic, strong, readonly) AMACrashLoader *crashLoader;
@property (nonatomic, strong, readonly) AMACrashesConfiguration *internalConfiguration;
@property (nonatomic, assign, getter=isActivated, readonly) BOOL activated;

- (instancetype)initWithExecutor:(id<AMAExecuting>)executor
                     crashLoader:(AMACrashLoader *)crashLoader
                   stateNotifier:(AMACrashReportingStateNotifier *)stateNotifier
               hostStateProvider:(AMAHostStateProvider *)hostStateProvider
                      serializer:(AMADecodedCrashSerializer *)serializer
                   configuration:(AMACrashesConfiguration *)configuration
                errorEnvironment:(AMAErrorEnvironment *)errorEnvironment
               errorModelFactory:(AMAErrorModelFactory *)errorModelFactory
                   crashReporter:(AMACrashReporter *)crashReporter NS_DESIGNATED_INITIALIZER;

- (void)activate;

- (void)requestCrashReportingStateWithCompletionQueue:(dispatch_queue_t)completionQueue
                                      completionBlock:(AMACrashReportingStateCompletionBlock)completionBlock;

- (void)enableANRWatchdogWithWatchdogInterval:(NSTimeInterval)watchdogInterval
                                 pingInterval:(NSTimeInterval)pingInterval;

- (void)addCrashProcessingReporter:(id<AMACrashProcessingReporting>)crashReporter;

@end
