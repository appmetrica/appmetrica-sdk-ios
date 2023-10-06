
#import "AMADecodedCrashSerializer.h"
#import "AMACrashEventType.h"

NS_ASSUME_NONNULL_BEGIN

@class AMADecodedCrash;
@class AMACustomEventParameters;

@interface AMADecodedCrashSerializer (CustomEventParameters)

- (AMACustomEventParameters *)eventParametersFromDecodedData:(AMADecodedCrash *)decodedCrash;

- (AMACustomEventParameters *)eventParametersFromDecodedData:(AMADecodedCrash *)decodedCrash
                                                forEventType:(AMACrashEventType)eventType;

@end

NS_ASSUME_NONNULL_END
