
#import "AMAAppMetricaCrashes+Private.h"

@implementation AMAAppMetricaCrashes (Test)

- (NSDictionary *)crashContext
{
    return [AMACrashLoader crashContext];
}

@end
