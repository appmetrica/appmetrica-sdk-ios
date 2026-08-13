
#import <Foundation/Foundation.h>
#import "AMAModuleRegistrar.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(ModuleEntryPoint)
@protocol AMAModuleEntryPoint <NSObject>

- (void)registerComponentsWithRegistrar:(id<AMAModuleRegistrar>)registrar
    NS_SWIFT_NAME(registerComponents(with:));

/// Module name reported in the `modules_status` event.
@property (nonatomic, copy, readonly) NSString *moduleName;

@end

NS_ASSUME_NONNULL_END
