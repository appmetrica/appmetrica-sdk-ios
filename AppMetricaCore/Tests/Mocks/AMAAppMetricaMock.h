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

@end

NS_ASSUME_NONNULL_END
