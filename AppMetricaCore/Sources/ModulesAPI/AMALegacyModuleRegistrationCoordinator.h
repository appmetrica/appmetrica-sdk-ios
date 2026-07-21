#import <Foundation/Foundation.h>
#import "AMACore.h"

@class AMAModuleRegistrarImpl;

NS_ASSUME_NONNULL_BEGIN

@interface AMALegacyModuleRegistrationCoordinator : NSObject

- (void)registerActivationDelegate:(Class<AMAModuleActivationDelegate>)delegate;
- (void)registerServiceConfiguration:(AMAServiceConfiguration *)configuration;

- (void)beginRegistrationWithRegistrar:(AMAModuleRegistrarImpl *)registrar;
- (void)completeRegistrationWithRegistrar:(AMAModuleRegistrarImpl *)registrar;

@end

NS_ASSUME_NONNULL_END
