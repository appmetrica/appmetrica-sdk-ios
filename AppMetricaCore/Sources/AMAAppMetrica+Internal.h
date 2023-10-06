
#import "AMAAppMetrica.h"

NS_ASSUME_NONNULL_BEGIN

@class AMAInternalEventsReporter;
@class AMAAppMetricaImpl;
@protocol AMAHostStateProviding;

@interface AMAAppMetrica ()

+ (AMAAppMetricaImpl *)sharedImpl;
+ (id<AMAHostStateProviding>)sharedHostStateProvider;

@end

NS_ASSUME_NONNULL_END
