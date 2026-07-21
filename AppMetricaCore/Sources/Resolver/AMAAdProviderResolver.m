#import "AMAAdProviderResolver.h"
#import "AMAAdProviderProxy.h"

@implementation AMAAdProviderResolver

- (instancetype)initWithAdProviderProxy:(AMAAdProviderProxy *)adProviderProxy
{
    self = [super init];
    if (self) {
        _adProviderProxy = adProviderProxy;
    }
    return self;
}

- (void)updateWithValue:(BOOL)value
{
    self.adProviderProxy.enabled = value;
}

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    static AMAAdProviderResolver *resolver;
    dispatch_once(&onceToken, ^{
        resolver = [[AMAAdProviderResolver alloc] initWithAdProviderProxy:[AMAAdProviderProxy sharedInstance]];
    });
    return resolver;
}

@end
