#import "NSMutableDictionary+AdRevenueHelper.h"
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>
#import "AMAAdRevenueKeys.h"

@implementation NSMutableDictionary (AdRevenueHelper)

- (void)updatePluginSupportedSources:(nullable NSArray<NSString *> *)pluginSupportedSources
              nativeSupportedSources:(nullable NSArray<NSString *> *)nativeSupportedSources
{
    if (pluginSupportedSources != nil) {
        self[kAdRevenuePayloadPluginSourcesKey] = [AMAJSONSerialization stringWithJSONObject:pluginSupportedSources error:nil];
    }
    if (nativeSupportedSources != nil) {
        self[kAdRevenuePayloadNativeSourcesKey] = [AMAJSONSerialization stringWithJSONObject:nativeSupportedSources error:nil];
    }
}

@end
