
#import <Foundation/Foundation.h>
#import <AppMetricaCore/AppMetricaCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface AMAMutableAdRevenueInfo (AdRevenueHelper)

- (void)updatePluginSupportedSources:(nullable NSArray<NSString *> *)pluginSupportedSources
              nativeSupportedSources:(nullable NSArray<NSString *> *)nativeSupportedSources;

@end



NS_ASSUME_NONNULL_END
