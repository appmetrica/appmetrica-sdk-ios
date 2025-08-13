#import "AMAAdProviderResolver.h"
#import "AMAAdProvider.h"

@implementation AMAAdProviderResolver

- (instancetype)initWithAdProvider:(AMAAdProvider *)adProvider
{
    self = [super init];
    if (self) {
        _adProvider = adProvider;
    }
    return self;
}

- (void)updateWithValue:(BOOL)value
{
    self.adProvider.isEnabled = value;
}

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    static AMAAdProviderResolver *resolver;
    dispatch_once(&onceToken, ^{
        resolver = [[AMAAdProviderResolver alloc] initWithAdProvider:[AMAAdProvider sharedInstance]];
    });
    return resolver;
}

@end
