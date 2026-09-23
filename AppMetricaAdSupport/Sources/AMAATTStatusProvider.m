
#import "AMAATTStatusProvider.h"
#import <AppTrackingTransparency/AppTrackingTransparency.h>

@implementation AMAATTStatusProvider

#pragma mark - Public -

- (BOOL)isAdvertisingTrackingEnabled
{
    return [self ATTStatus] == AMATrackingManagerAuthorizationStatusAuthorized;
}

- (AMATrackingManagerAuthorizationStatus)ATTStatus
{
    return (AMATrackingManagerAuthorizationStatus)[ATTrackingManager trackingAuthorizationStatus];
}

@end
