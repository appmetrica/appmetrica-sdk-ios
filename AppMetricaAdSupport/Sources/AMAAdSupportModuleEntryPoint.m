
#import "AMAAdSupportModuleEntryPoint.h"
#import "AMAAdController.h"

@implementation AMAAdSupportModuleEntryPoint


- (void)registerComponentsWithRegistrar:(id<AMAModuleRegistrar>)registrar
{
    [registrar registerAdProvider:[[AMAAdController alloc] init]];
}


@end
