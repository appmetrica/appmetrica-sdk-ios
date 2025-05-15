#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSMutableDictionary (AdRevenueHelper)

- (void)updatePluginSupportedSources:(nullable NSArray<NSString *> *)pluginSupportedSources
              nativeSupportedSources:(nullable NSArray<NSString *> *)nativeSupportedSources;


@end

NS_ASSUME_NONNULL_END
