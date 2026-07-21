#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class AMAModuleActivationConfiguration;

/// Handles module setup that must complete before activation delegates are notified.
NS_SWIFT_NAME(ModulePreActivationHandler)
@protocol AMAModulePreActivationHandler <NSObject>

- (void)handlePreActivationWithConfiguration:(AMAModuleActivationConfiguration *)configuration;

@end

NS_ASSUME_NONNULL_END
