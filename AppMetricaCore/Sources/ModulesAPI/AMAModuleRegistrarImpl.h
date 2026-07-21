
#import <Foundation/Foundation.h>
#import "AMACore.h"

@class AMAModuleRegistry;

NS_ASSUME_NONNULL_BEGIN

@interface AMAModuleRegistrarImpl : NSObject <AMAModuleRegistrar>

- (AMAModuleRegistry *)publishRegistryWithEntryPoints:(NSArray<id<AMAModuleEntryPoint>> *)entryPoints;

@end

NS_ASSUME_NONNULL_END
