#import <Foundation/Foundation.h>
#import "AMAModuleEntryPointDiscovering.h"

NS_ASSUME_NONNULL_BEGIN

typedef NSArray<id<AMAModuleEntryPoint>> * _Nonnull (^AMAModuleEntryPointDiscoveryBlock)(void);

@interface AMAModuleEntryPointDiscovererMock : NSObject <AMAModuleEntryPointDiscovering>

@property (nonatomic, copy) NSArray<id<AMAModuleEntryPoint>> *entryPoints;
@property (nonatomic, copy, nullable) AMAModuleEntryPointDiscoveryBlock discoveryBlock;
@property (atomic, readonly) NSUInteger discoverCallCount;

@end

NS_ASSUME_NONNULL_END
