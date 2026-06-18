
#import <Foundation/Foundation.h>
#import "AMAModuleContext.h"
#import "AMAModuleActivationConfiguration.h"
#import "AMAEventPollingDelegate.h"
#import "AMAEnvironmentContainer.h"
#import <AppMetricaStorageUtils/AppMetricaStorageUtils.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(ModuleEntryPoint)
@protocol AMAModuleEntryPoint <NSObject>

- (void)initModuleWithContext:(id<AMAModuleContext>)context;

@end

NS_ASSUME_NONNULL_END
