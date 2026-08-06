
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

- (void)registerPreActivationHandler:(id<AMAModulePreActivationHandler>)handler
    NS_SWIFT_NAME(register(preActivationHandler:));
- (void)registerActivationDelegate:(Class<AMAModuleActivationDelegate>)delegate
    NS_SWIFT_NAME(register(activationDelegate:));
- (void)registerEventPollingDelegate:(Class<AMAEventPollingDelegate>)delegate
    NS_SWIFT_NAME(register(eventPollingDelegate:));
- (void)registerEventFlushableDelegate:(Class<AMAEventFlushableDelegate>)delegate
    NS_SWIFT_NAME(register(eventFlushableDelegate:));
- (void)registerAdProvider:(id<AMAAdProviding>)provider
    NS_SWIFT_NAME(register(adProvider:));
- (void)registerServiceConfiguration:(AMAServiceConfiguration *)configuration
    NS_SWIFT_NAME(register(serviceConfiguration:));

@end

NS_ASSUME_NONNULL_END
