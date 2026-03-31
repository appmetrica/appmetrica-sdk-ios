
#import "AMAAppMetricaConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

@interface AMAAppMetricaConfiguration (Internal)<NSCopying>

@property (nonatomic, nullable, copy, readonly) NSNumber *locationTrackingState;
@property (nonatomic, nullable, copy, readonly) NSNumber *dataSendingEnabledState;
@property (nonatomic, nullable, copy, readonly) NSNumber *advertisingIdentifierTrackingEnabledState;

- (BOOL)isEqualToConfiguration:(nonnull AMAAppMetricaConfiguration *)configuration;

@end

NS_ASSUME_NONNULL_END
