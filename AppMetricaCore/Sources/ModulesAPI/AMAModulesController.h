
#import <Foundation/Foundation.h>
#import "AMACore.h"

@class AMAModuleActivationConfiguration;
@class AMAModuleContextImpl;
@class AMAReporter;
@class AMAEnvironmentContainer;
@protocol AMAAsyncExecuting;
@protocol AMASyncExecuting;
@protocol AMAKeyValueStorageProviding;

NS_ASSUME_NONNULL_BEGIN

typedef void (^AMAStartupParametersHandler)(NSDictionary *parameters);

@interface AMAModulesController : NSObject

- (instancetype)initWithExecutor:(id<AMAAsyncExecuting, AMASyncExecuting>)executor NS_DESIGNATED_INITIALIZER;

/// The module context. Available immediately after init.
@property (nonatomic, strong, readonly) AMAModuleContextImpl *context;

/// Ad provider registered by a module via context.
@property (nonatomic, strong, readonly, nullable) id<AMAAdProviding> adProvider;

/// Triggers async module discovery and initialization on the first call (idempotent).
- (void)ensureLoaded;

- (void)registerModule:(id<AMAModuleEntryPoint>)module;

/// Called once per observer after modules are loaded, with that observer's startup parameters.
/// Set by AMAAppMetricaImpl to forward to addAdditionalStartupParameters:.
@property (nonatomic, copy, nullable) AMAStartupParametersHandler startupParametersHandler;

// MARK: - Activation lifecycle

- (void)notifyWillActivateWithConfiguration:(AMAModuleActivationConfiguration *)configuration;
- (void)notifyDidActivateWithConfiguration:(AMAModuleActivationConfiguration *)configuration;

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
