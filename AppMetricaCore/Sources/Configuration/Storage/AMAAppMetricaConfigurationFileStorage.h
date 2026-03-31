#import <Foundation/Foundation.h>
#import "AMAAppMetricaConfigurationStoring.h"

NS_ASSUME_NONNULL_BEGIN

@protocol AMAFileStorage;
@protocol AMAAsyncExecuting;

@interface AMAAppMetricaConfigurationFileStorage : NSObject <AMAAppMetricaConfigurationStoring>

@property (nonatomic, readonly, nonnull) id<AMAFileStorage> fileStorage;
@property (nonatomic, readonly, nonnull) id<AMAAsyncExecuting> executor;

- (instancetype)initWithFileStorage:(id<AMAFileStorage>)fileStorage;

- (instancetype)initWithFileStorage:(id<AMAFileStorage>)fileStorage
                           executor:(id<AMAAsyncExecuting>)executor;

+ (instancetype)appMetricaConfigurationFileStorageWithFileStorage:(id<AMAFileStorage>)fileStorage;

@end

NS_ASSUME_NONNULL_END
