
#import "AMALocationManager.h"

@class CLLocation;

@interface AMALocationManager (TestUtilities)

+ (void)stubCurrentLocation:(CLLocation *)location;

@end
