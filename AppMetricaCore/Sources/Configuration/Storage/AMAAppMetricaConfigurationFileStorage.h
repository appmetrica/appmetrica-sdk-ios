#import <Foundation/Foundation.h>
#import "AMAAppMetricaConfigurationStoring.h"

NS_ASSUME_NONNULL_BEGIN

@protocol AMAFileStorage;

@interface AMAAppMetricaConfigurationFileStorage : NSObject <AMAAppMetricaConfigurationFileStoring>

@property (nonatomic, readonly, nonnull) id<AMAFileStorage> fileStorage;

- (instancetype)initWithFileStorage:(id<AMAFileStorage>)fileStorage;

+ (instancetype)appMetricaConfigurationFileStorageWithFileStorage:(id<AMAFileStorage>)fileStorage;

@end

NS_ASSUME_NONNULL_END
