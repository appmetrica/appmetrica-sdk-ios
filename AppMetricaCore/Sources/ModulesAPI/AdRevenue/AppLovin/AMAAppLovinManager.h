
#import <Foundation/Foundation.h>
#import "AMACore.h"

@class AMAAppLovinStartupResponseParser;

NS_ASSUME_NONNULL_BEGIN

/// Manages the AppLovin ILRD observer lifecycle.
@interface AMAAppLovinManager : NSObject <AMAModuleActivationDelegate, AMAExtendedStartupObserving>

+ (instancetype)sharedInstance;

- (instancetype)initWithExecutor:(id<AMAAsyncExecuting>)executor
                  responseParser:(AMAAppLovinStartupResponseParser *)responseParser NS_DESIGNATED_INITIALIZER;

/// Creates the ILRD observer. Must be called before activation.
- (void)setup;

@end

NS_ASSUME_NONNULL_END
