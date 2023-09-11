
#import "AMAReporterConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

@interface AMAReporterConfiguration (Internal)

@property (nonatomic, strong, nullable, readonly) NSNumber *dataSendingEnabledState;

- (instancetype)initWithoutApiKey;

@end

@interface AMAMutableReporterConfiguration (Internal)

/** Application key used to initialize the configuration.
 */
@property (nonatomic, copy, nullable) NSString *apiKey;

@end

NS_ASSUME_NONNULL_END
