
#import "AMAIronSourceAdRevenuePolicy.h"

static NSString *const kKey = @"io.appmetrica.ironsource_auto_ad_revenue_enabled";

@implementation AMAIronSourceAdRevenuePolicy

- (instancetype)initWithBundle:(NSBundle *)bundle
{
    return [super initWithBundle:bundle key:kKey defaultValue:YES];
}

+ (instancetype)sharedInstance
{
    static AMAIronSourceAdRevenuePolicy *instance = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        instance = [[self alloc] initWithBundle:[NSBundle mainBundle]];
    });
    return instance;
}

@end
