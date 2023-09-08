
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>

@implementation CLLocation (TestUtilities)

- (BOOL)test_isEqualToLocation:(CLLocation *)location
{
    return (fabs(self.coordinate.latitude - location.coordinate.latitude) < DBL_EPSILON &&
            fabs(self.coordinate.longitude - location.coordinate.longitude) < DBL_EPSILON);
}

@end
