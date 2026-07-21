
#import <Foundation/Foundation.h>
#import "AMAModuleActivationDelegate.h"
#import "AMAModulePreActivationHandler.h"
#import "AMAEventPollingDelegate.h"
#import "AMAEventFlushableDelegate.h"
#import "AMAAdProviding.h"
#import "AMAServiceConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(ModuleRegistrar)
@protocol AMAModuleRegistrar <NSObject>

- (void)registerPreActivationHandler:(id<AMAModulePreActivationHandler>)handler;
- (void)registerActivationDelegate:(Class<AMAModuleActivationDelegate>)delegate;
- (void)registerEventPollingDelegate:(Class<AMAEventPollingDelegate>)delegate;
- (void)registerEventFlushableDelegate:(Class<AMAEventFlushableDelegate>)delegate;
- (void)registerAdProvider:(id<AMAAdProviding>)provider;
- (void)registerServiceConfiguration:(AMAServiceConfiguration *)configuration;

@end

NS_ASSUME_NONNULL_END
