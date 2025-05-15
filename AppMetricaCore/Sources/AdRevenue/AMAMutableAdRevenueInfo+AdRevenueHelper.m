
#import "AMAMutableAdRevenueInfo+AdRevenueHelper.h"
#import "NSMutableDictionary+AdRevenueHelper.h"
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>

@implementation AMAMutableAdRevenueInfo (AdRevenueHelper)

- (void)updatePluginSupportedSources:(nullable NSArray<NSString *> *)pluginSupportedSources
              nativeSupportedSources:(nullable NSArray<NSString *> *)nativeSupportedSources
{
    NSMutableDictionary *newDict = [self.payload mutableCopy] ?: [NSMutableDictionary dictionary];
    
    [newDict updatePluginSupportedSources:pluginSupportedSources
                   nativeSupportedSources:nativeSupportedSources];
    
    self.payload = newDict;
}

@end
