
#import <Foundation/Foundation.h>

@protocol AMAExecuting;
@protocol AMACrashProcessingReporting;
@class AMACrashMatchingRule;
@class AMAAppMetricaConfiguration;
@class AMAReporterStateStorage;
@class AMAEnvironmentContainer;

//TODO: Fix nullability
#import "AMACrashes.h" //FIXME: For `AMACrashReportingStateCompletionBlock`
NS_ASSUME_NONNULL_BEGIN

extern NSString *const kAMACrashReportingStateEnabledKey;
extern NSString *const kAMACrashReportingStateCrashedLastLaunchKey;

@protocol AMACrashReporting

+ (void)registerSymbolsForApiKey:(NSString *)apiKey rule:(AMACrashMatchingRule *)rule;

- (instancetype)initWithExecutor:(id<AMAExecuting>)executor;

- (void)setConfiguration:(AMAAppMetricaConfiguration *)configuration;
- (void)setupEnvironmentWithReporterStateStorage:(AMAReporterStateStorage *)reporterStateStorage;
- (void)quickSetupEnvironment;

- (void)requestCrashReportingStateWithCompletionQueue:(dispatch_queue_t)completionQueue
                                      completionBlock:(AMACrashReportingStateCompletionBlock)completionBlock;

- (void)handleConfigurationUpdate;

- (void)enableANRWatchdogWithWatchdogInterval:(NSTimeInterval)watchdogInterval
                                 pingInterval:(NSTimeInterval)pingInterval;

- (void)addCrashProcessingReporter:(id<AMACrashProcessingReporting>)crashReporter;

NS_ASSUME_NONNULL_END

@end
