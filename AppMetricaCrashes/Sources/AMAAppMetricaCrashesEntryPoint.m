
#import "AMAAppMetricaCrashesEntryPoint.h"
#import "AMAAppMetricaCrashes.h"

@implementation AMAAppMetricaCrashesEntryPoint


- (void)initModuleWithContext:(id<AMAModuleContext>)context
{
    [context addActivationDelegate:[AMAAppMetricaCrashes class]];
    [context addEventPollingDelegate:[AMAAppMetricaCrashes class]];
}


@end
