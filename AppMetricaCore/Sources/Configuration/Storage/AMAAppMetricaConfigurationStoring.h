#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class AMAAppMetricaConfigurationSnapshot;

@protocol AMAAppMetricaConfigurationStoring <NSObject>

- (nullable AMAAppMetricaConfigurationSnapshot *)loadSnapshot;
- (void)saveSnapshot:(nonnull AMAAppMetricaConfigurationSnapshot *)snapshot;
- (void)clearSnapshot:(nonnull AMAAppMetricaConfigurationSnapshot *)snapshot;

@end

NS_ASSUME_NONNULL_END
