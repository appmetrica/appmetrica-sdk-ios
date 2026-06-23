#import <Foundation/Foundation.h>
#import "AMAAppMetrica.h"
#import "AMAAppMetricaImpl.h"
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>
#import "AMAMetricaConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

@interface AMAAppMetricaMock : AMAAppMetrica

@property (class, nonatomic) id<AMAAsyncExecuting, AMASyncExecuting> sharedExecutor;
@property (class, nonatomic) AMAAppMetricaImpl *sharedImpl;
@property (class, nonatomic) AMAMetricaConfiguration *metricaConfiguration;

// MARK: - Ad revenue capture

@property (class, nonatomic, strong, readonly) NSMutableArray<AMAAdRevenueInfo *> *capturedAdRevenues;
@property (class, nonatomic, strong, readonly) NSMutableArray<NSNumber *> *capturedIsAutocollected;
@property (class, nonatomic, strong, readonly) NSMutableArray<NSString *> *capturedNativeSources;

+ (void)resetCaptures;

@end

NS_ASSUME_NONNULL_END
