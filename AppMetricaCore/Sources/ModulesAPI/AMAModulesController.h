
#import <Foundation/Foundation.h>
#import "AMACore.h"

@class AMAAppMetricaConfiguration;
@class AMALegacyModuleRegistrationCoordinator;
@class AMAReporter;
@class AMAEnvironmentContainer;
@protocol AMAAsyncExecuting;
@protocol AMAKeyValueStorageProviding;
@protocol AMAModuleEntryPointDiscovering;

NS_ASSUME_NONNULL_BEGIN

typedef void (^AMAStartupParametersHandler)(NSDictionary *parameters);
typedef void (^AMAModuleAdProviderHandler)(id<AMAAdProviding> _Nullable moduleAdProvider);

@interface AMAModulesController : NSObject

/// `executor` must execute submitted blocks serially in FIFO order.
- (instancetype)initWithExecutor:(id<AMAAsyncExecuting>)executor
        registrationCoordinator:
            (nullable AMALegacyModuleRegistrationCoordinator *)registrationCoordinator
        startupParametersHandler:(nullable AMAStartupParametersHandler)startupParametersHandler;

/// `executor` must execute submitted blocks serially in FIFO order.
- (instancetype)initWithExecutor:(id<AMAAsyncExecuting>)executor
                       discoverer:(id<AMAModuleEntryPointDiscovering>)discoverer
           registrationCoordinator:
               (nullable AMALegacyModuleRegistrationCoordinator *)registrationCoordinator
         startupParametersHandler:(nullable AMAStartupParametersHandler)startupParametersHandler
    NS_DESIGNATED_INITIALIZER;

/// Schedules the handler on the modules executor after discovery.
- (void)resolveModuleAdProviderWithHandler:(AMAModuleAdProviderHandler)handler;

/// Starts idempotent asynchronous discovery and registry publication on the modules executor.
/// AMAAppMetricaImpl calls this once immediately after publishing the controller.
- (void)startLoading;

/// Called once per observer after modules are loaded, with that observer's startup parameters.
/// Set by AMAAppMetricaImpl to forward to addAdditionalStartupParameters:.
@property (nonatomic, copy, nullable) AMAStartupParametersHandler startupParametersHandler;

/// Takes an immutable module configuration snapshot, enqueues pre-activation/will after
/// asynchronous module loading, executes core activation synchronously on the caller,
/// then enqueues did after the core block returns.
- (void)performActivationWithAppMetricaConfiguration:(AMAAppMetricaConfiguration *)configuration
                                     activationBlock:(nullable dispatch_block_t)activationBlock;

// MARK: - Startup observers

/// Calls startupUpdatedWithParameters: on all registered startup observers (async, on executor).
- (void)notifyStartupUpdatedWithParameters:(NSDictionary *)parameters;

/// Calls startupUpdateFailedWithError: on all registered startup observers (async, on executor).
- (void)notifyStartupFailedWithError:(NSError *)error;

// MARK: - Reporter storage

/// Calls setupWithReporterStorage:main:forAPIKey: on all registered storage controllers (async).
- (void)setupReporterStorageWithProvider:(id<AMAKeyValueStorageProviding>)provider
                                    main:(BOOL)main
                                  apiKey:(NSString *)apiKey;

// MARK: - Event polling

/// Reports polling events from all registered polling delegates to the given reporter.
- (void)addPollingEventsToReporter:(AMAReporter *)reporter;

/// Calls setupAppEnvironment: on all registered polling delegates.
- (void)setupAppEnvironmentWithContainer:(AMAEnvironmentContainer *)appEnvironment;

// MARK: - Event flushing

/// Calls sendEventsBuffer on all registered flushable delegates.
- (void)notifySendEventsBuffer;

@end

NS_ASSUME_NONNULL_END
