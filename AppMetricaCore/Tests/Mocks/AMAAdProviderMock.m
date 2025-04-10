#import "AMAAdProviderMock.h"

@implementation AMAAdProviderMock

- (void)setupAdProvider:(id<AMAAdProviding>)adProvider
{
    [super setupAdProvider:adProvider];
    
    self.setupAdProviderValue = adProvider;
    [self.setupAdProviderExpectation fulfill];
}

@end
