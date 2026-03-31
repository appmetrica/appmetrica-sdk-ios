#import <Foundation/Foundation.h>
#import <AppMetricaPlatform/AppMetricaPlatform.h>
#import "AMAAppMetricaConfigurationStoring.h"

NS_ASSUME_NONNULL_BEGIN

@interface AMAAppMetricaConfigurationStorageCoordinator : NSObject <AMAAppMetricaConfigurationStoring>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithPrivateStorage:(nonnull id<AMAAppMetricaConfigurationStoring>)privateStorage
                          groupStorage:(nullable id<AMAAppMetricaConfigurationStoring>)groupStorage;

@end

NS_ASSUME_NONNULL_END
