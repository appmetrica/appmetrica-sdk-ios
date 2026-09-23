
#import <AppMetricaCoreExtension/AppMetricaCoreExtension.h>

@interface AMAATTStatusProvider : NSObject

- (BOOL)isAdvertisingTrackingEnabled;
- (AMATrackingManagerAuthorizationStatus)ATTStatus;

@end
