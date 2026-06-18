
#import "AMAAdSupportModuleEntryPoint.h"
#import "AMAAdController.h"

@implementation AMAAdSupportModuleEntryPoint


- (void)initModuleWithContext:(id<AMAModuleContext>)context
{
    [context registerAdProvider:[[AMAAdController alloc] init]];
}


@end
