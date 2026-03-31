#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class AMAAppMetricaConfiguration;

@protocol AMAAppMetricaConfigurationStoring <NSObject>

- (nullable AMAAppMetricaConfiguration *)loadConfiguration;
- (void)saveConfiguration:(nonnull AMAAppMetricaConfiguration *)configuration;

@end

NS_ASSUME_NONNULL_END
