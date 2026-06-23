
#import "AMAAppLovinAdRevenuePolicy.h"

static NSString *const kKey = @"io.appmetrica.applovin_auto_ad_revenue_enabled";

@implementation AMAAppLovinAdRevenuePolicy

- (instancetype)initWithBundle:(NSBundle *)bundle
{
    return [super initWithBundle:bundle key:kKey defaultValue:YES];
}

+ (instancetype)sharedInstance
{
    static AMAAppLovinAdRevenuePolicy *instance = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        instance = [[self alloc] initWithBundle:[NSBundle mainBundle]];
    });
    return instance;
}

@end
