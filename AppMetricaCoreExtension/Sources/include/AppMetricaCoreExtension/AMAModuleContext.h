
#import <Foundation/Foundation.h>
#import "AMAModuleActivationDelegate.h"
#import "AMAEventPollingDelegate.h"
#import "AMAEventFlushableDelegate.h"
#import "AMAAdProviding.h"
#import "AMAServiceConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(ModuleContext)
@protocol AMAModuleContext <NSObject>

- (void)addActivationDelegate:(Class<AMAModuleActivationDelegate>)delegate;
- (void)addEventPollingDelegate:(Class<AMAEventPollingDelegate>)delegate;
- (void)addEventFlushableDelegate:(Class<AMAEventFlushableDelegate>)delegate;
- (void)registerAdProvider:(id<AMAAdProviding>)provider;
- (void)registerExternalService:(AMAServiceConfiguration *)configuration;

@end

NS_ASSUME_NONNULL_END
