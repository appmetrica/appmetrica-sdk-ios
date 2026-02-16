
#import <Foundation/Foundation.h>
#import <dispatch/dispatch.h>
#import <AppMetricaCoreExtension/AppMetricaCoreExtension.h>
#import "AMACrashLogging.h"
#import "AMAKSCrashLoader.h"
#import "AMAANRWatchdog.h"
#import "AMAAppMetricaCrashes.h"
#import "AMACrashObserverDispatcher.h"

@class AMAAppMetricaConfiguration;
@class AMAKSCrashLoader;
@class AMAExternalCrashLoader;
@class AMACrashReporter;
@class AMACrashReportingStateNotifier;
@class AMADecodedCrashSerializer;
@class AMAErrorEnvironment;
@class AMAErrorModelFactory;
@class AMACrashForwarder;

@protocol AMAAsyncExecuting;
@protocol AMASyncExecuting;
@protocol AMAHostStateProviding;

@interface AMAAppMetricaCrashes() <AMACrashLoaderDelegate,
                         AMAANRWatchdogDelegate,
                         AMAHostStateProviderDelegate,
                         AMAEventPollingDelegate,
                         AMAModuleActivationDelegate>

@property (nonatomic, strong, readonly) AMAKSCrashLoader *ksCrashLoader;
@property (nonatomic, strong, readonly) AMAExternalCrashLoader *externalCrashLoader;
@property (nonatomic, strong, readonly) AMAAppMetricaCrashesConfiguration *internalConfiguration;
@property (nonatomic, assign, getter=isActivated, readonly) BOOL activated;
@property (nonatomic, strong, readonly) AMACrashObserverDispatcher *crashObserverManager;
@property (nonatomic, strong, readonly) AMACrashForwarder *crashHandlerManager;

- (instancetype)initWithExecutor:(id<AMAAsyncExecuting, AMASyncExecuting>)executor
                   ksCrashLoader:(AMAKSCrashLoader *)ksCrashLoader
                   stateNotifier:(AMACrashReportingStateNotifier *)stateNotifier
               hostStateProvider:(id<AMAHostStateProviding>)hostStateProvider
                      serializer:(AMADecodedCrashSerializer *)serializer
                   configuration:(AMAAppMetricaCrashesConfiguration *)configuration
             externalCrashLoader:(AMAExternalCrashLoader *)externalCrashLoader NS_DESIGNATED_INITIALIZER;

- (void)activate;

- (void)requestCrashReportingStateWithCompletionQueue:(dispatch_queue_t)completionQueue
                                      completionBlock:(AMACrashReportingStateCompletionBlock)completionBlock;

- (void)enableANRWatchdogWithWatchdogInterval:(NSTimeInterval)watchdogInterval
                                 pingInterval:(NSTimeInterval)pingInterval;

- (void)handlePluginInitFinished;

@end
