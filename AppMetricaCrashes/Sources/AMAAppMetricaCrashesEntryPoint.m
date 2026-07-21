
#import "AMAAppMetricaCrashesEntryPoint.h"
#import "AMAAppMetricaCrashes.h"

@implementation AMAAppMetricaCrashesEntryPoint


- (void)registerComponentsWithRegistrar:(id<AMAModuleRegistrar>)registrar
{
    [registrar registerActivationDelegate:[AMAAppMetricaCrashes class]];
    [registrar registerEventPollingDelegate:[AMAAppMetricaCrashes class]];
}


@end
