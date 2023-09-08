
#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CLLocation (TestUtilities)

- (BOOL)test_isEqualToLocation:(CLLocation *)location;

@end

NS_ASSUME_NONNULL_END
