
#import <SystemConfiguration/SystemConfiguration.h>
#import "AMAReachability.h"

@interface AMAReachability ()

@property (nonatomic, assign) SCNetworkReachabilityRef reachabilityRef;
@property (nonatomic, assign) SCNetworkReachabilityFlags flags;

- (BOOL)isStarted;

@end

@interface AMAReachability (TestUtilities)

+ (void)amatest_stubSharedInstance;

@end
