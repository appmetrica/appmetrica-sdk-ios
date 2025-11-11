
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMAReachability+TestUtilities.h"

@implementation AMAReachability (TestUtilities)

+ (void)amatest_stubSharedInstance
{
    AMAReachability *reachability = [[AMAReachability alloc] init];
    [AMAReachability stub:@selector(sharedInstance) andReturn:reachability];
}

@end
