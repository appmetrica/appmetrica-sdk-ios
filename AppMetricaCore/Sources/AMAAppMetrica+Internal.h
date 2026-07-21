#import "AMAAppMetrica.h"

NS_ASSUME_NONNULL_BEGIN

@class AMAInternalEventsReporter;
@class AMAAppMetricaImpl;
@class AMAMetricaConfiguration;
@class AMALegacyModuleRegistrationCoordinator;
@protocol AMAHostStateProviding;

@interface AMAAppMetrica ()

+ (AMAMetricaConfiguration *)metricaConfiguration;

+ (AMAAppMetricaImpl *)sharedImpl;
+ (id<AMAHostStateProviding>)sharedHostStateProvider;
+ (AMAInternalEventsReporter *)sharedInternalEventsReporter;
+ (void)setLogs:(BOOL)enabled;
+ (BOOL)isActivatedAsMain;

+ (AMALegacyModuleRegistrationCoordinator *)legacyModuleRegistrationCoordinator;

@end

NS_ASSUME_NONNULL_END
