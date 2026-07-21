#import <Foundation/Foundation.h>
#import "AMACore.h"

NS_ASSUME_NONNULL_BEGIN

@protocol AMAModuleEntryPointDiscovering <NSObject>

- (NSArray<id<AMAModuleEntryPoint>> *)discoverEntryPoints;

@end

NS_ASSUME_NONNULL_END
