#import <Foundation/Foundation.h>

@protocol AMAAppMetricaConfigurationStoring;

NS_ASSUME_NONNULL_BEGIN

@interface AMAAppMetricaConfigurationStorageFactory : NSObject

+ (id<AMAAppMetricaConfigurationStoring>)configurationStorage;

@end

NS_ASSUME_NONNULL_END
