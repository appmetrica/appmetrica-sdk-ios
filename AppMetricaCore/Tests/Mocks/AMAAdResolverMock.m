#import "AMAAdResolverMock.h"

@interface AMAAdResolver (Unprivate)
- (void)updateAdProvider:(BOOL)isEnabled;
@end

@implementation AMAAdResolverMock

- (void)updateAdProvider:(BOOL)isEnabled
{
    [super updateAdProvider:isEnabled];
    
    [self.updateAdProviderExpectation fulfill];
    self.updateAdProviderValue = isEnabled;
}

@end
