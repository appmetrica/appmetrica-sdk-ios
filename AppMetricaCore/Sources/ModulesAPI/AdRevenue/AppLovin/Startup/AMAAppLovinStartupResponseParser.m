
#import "AMAAppLovinStartupResponseParser.h"
#import "AMAAppLovinStartupConfiguration.h"

static NSString *const kFeaturesKey = @"features";
static NSString *const kFeaturesListKey = @"list";
static NSString *const kAramFeatureKey = @"ad_revenue_applovin_max";
static NSString *const kEnabledKey = @"enabled";

@implementation AMAAppLovinStartupResponseParser

- (void)parseResponse:(NSDictionary *)parameters
    intoConfiguration:(AMAAppLovinStartupConfiguration *)configuration
{
    id featuresList = parameters[kFeaturesKey][kFeaturesListKey];
    if ([featuresList isKindOfClass:[NSDictionary class]] == NO) {
        return;
    }
    id aramFeature = ((NSDictionary *)featuresList)[kAramFeatureKey];
    if ([aramFeature isKindOfClass:[NSDictionary class]] == NO) {
        return;
    }
    id enabled = ((NSDictionary *)aramFeature)[kEnabledKey];
    if ([enabled isKindOfClass:[NSNumber class]]) {
        configuration.aramEnabled = [enabled boolValue];
    }
}

@end
