#import <Foundation/Foundation.h>
#import "AMAAppMetricaConfigurationStoring.h"

NS_ASSUME_NONNULL_BEGIN

@protocol AMAExclusiveLocking;
@protocol AMAAppMetricaConfigurationFileStoring;

@interface AMAAppMetricaConfigurationStorageCoordinator : NSObject <AMAAppMetricaConfigurationStoring>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithPrivateStorage:(id<AMAAppMetricaConfigurationFileStoring>)privateStorage
                          groupStorage:(nullable id<AMAAppMetricaConfigurationFileStoring>)groupStorage
                                  lock:(id<AMAExclusiveLocking>)lock;

@end

NS_ASSUME_NONNULL_END
