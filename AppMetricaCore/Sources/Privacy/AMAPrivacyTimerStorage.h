
#import <Foundation/Foundation.h>
#import "AMAPrivacyTimerRetryPolicy.h"

@class AMAReporterStateStorage;
@class AMAMetricaConfiguration;

NS_ASSUME_NONNULL_BEGIN

@interface AMAPrivacyTimerStorage : NSObject<AMAPrivacyTimerRetryPolicy>

- (instancetype)initWithReporterMetricaConfiguration:(AMAMetricaConfiguration*)metricaConfiguration
                                        stateStorage:(AMAReporterStateStorage*)stateStorage;

@property (nonnull, atomic, strong, readwrite) AMAMetricaConfiguration *metricaConfiguration;

@end

NS_ASSUME_NONNULL_END
