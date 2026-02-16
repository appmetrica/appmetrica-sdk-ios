#import <Foundation/Foundation.h>
#import "AMACrashObserving.h"

NS_ASSUME_NONNULL_BEGIN

/// Configuration for crash observer registration
NS_SWIFT_NAME(CrashObserverConfiguration)
@interface AMACrashObserverConfiguration : NSObject <NSCopying>

/// Delegate for receiving crash callbacks
@property (nonatomic, weak, readonly, nullable) id<AMACrashObserving> delegate;

/// Queue on which to execute callbacks (defaults to main queue)
@property (nonatomic, strong, readonly) dispatch_queue_t callbackQueue;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithDelegate:(nullable id<AMACrashObserving>)delegate
                   callbackQueue:(nullable dispatch_queue_t)callbackQueue NS_DESIGNATED_INITIALIZER;

+ (instancetype)configurationWithDelegate:(id<AMACrashObserving>)delegate;

@end

NS_ASSUME_NONNULL_END
