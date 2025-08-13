
#import "AMAAppMetricaConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

@interface AMAAppMetricaConfiguration (Internal)

@property (nonatomic, nullable, copy, readonly) NSNumber *locationTrackingState;
@property (nonatomic, nullable, copy, readonly) NSNumber *dataSendingEnabledState;
@property (nonatomic, nullable, copy, readonly) NSNumber *advertisingIdentifierTrackingEnabledState;

@end

NS_ASSUME_NONNULL_END
