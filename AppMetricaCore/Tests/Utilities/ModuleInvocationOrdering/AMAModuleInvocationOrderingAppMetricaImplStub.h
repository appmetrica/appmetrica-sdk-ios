#import "AMAAppMetricaImpl.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const kAMAModuleCoreActivationInvocation;
FOUNDATION_EXPORT NSString *const kAMAModuleInvocationOrderingTestAPIKey;

@interface AMAModuleInvocationOrderingAppMetricaImplStub : AMAAppMetricaImpl

@property (nonatomic, copy, nullable) dispatch_block_t scheduledAnonymousActivationBlock;

- (instancetype)initWithHostStateProvider:(nullable id<AMAHostStateProviding>)hostStateProvider
                                 executor:(id<AMAAsyncExecuting, AMASyncExecuting>)executor;
- (void)scheduleAnonymousActivationWithDelay:(NSTimeInterval)delay;

// Runs the real AMAAppMetricaImpl implementation so tests can guard its synchronous controller publication
// without giving up the deterministic fake discoverer used by the existing ordering scenarios.
- (void)initializeModulesControllerUsingProductionImplementation;

@end

NS_ASSUME_NONNULL_END
