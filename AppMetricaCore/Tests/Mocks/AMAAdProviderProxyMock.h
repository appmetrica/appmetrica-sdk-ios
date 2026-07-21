#import "AMAAdProviderProxy.h"

NS_ASSUME_NONNULL_BEGIN

@interface AMAAdProviderProxyMock : AMAAdProviderProxy

@property (nonatomic, strong, nullable) id<AMAAdProviding> lastBackingProvider;
@property (nonatomic, assign) NSUInteger setBackingProviderCallCount;

@end

NS_ASSUME_NONNULL_END
