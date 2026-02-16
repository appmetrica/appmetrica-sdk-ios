
#import "AMAAppMetricaCrashes+Private.h"

@implementation AMAAppMetricaCrashes (Test)

- (NSDictionary *)crashContext
{
    return [AMAKSCrashLoader crashContext];
}

@end
