
#import <Foundation/Foundation.h>
#import "AMACrashLoading.h"
#import "AMACrashProviderDelegate.h"

@protocol AMACrashProviding;
@protocol AMAAsyncExecuting;
@class AMACrashSafeTransactor;
@class AMACrashEventConverter;

NS_ASSUME_NONNULL_BEGIN

/// Loads crash reports from external crash providers.
/// Handles both pull-model (pendingCrashReports) and push-model (delegate) providers.
/// Reports loaded crashes via AMACrashLoaderDelegate.
@interface AMAExternalCrashLoader : NSObject <AMACrashProviderDelegate, AMACrashLoading>

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithExecutor:(id<AMAAsyncExecuting>)executor
                      transactor:(AMACrashSafeTransactor *)transactor
                       converter:(AMACrashEventConverter *)converter NS_DESIGNATED_INITIALIZER;

/// Register an external crash provider. Sets self as delegate if provider supports push model.
- (void)registerProvider:(nullable id<AMACrashProviding>)provider;

@end

NS_ASSUME_NONNULL_END
