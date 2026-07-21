#import "AMAAdProviderProxyMock.h"

@implementation AMAAdProviderProxyMock

- (instancetype)init
{
    self = [super init];
    if (self != nil) {
        _lastBackingProvider = nil;
        _setBackingProviderCallCount = 0;
    }
    return self;
}

- (void)setBackingProvider:(id<AMAAdProviding>)backingProvider
{
    self.lastBackingProvider = backingProvider;
    self.setBackingProviderCallCount += 1;
}

@end
