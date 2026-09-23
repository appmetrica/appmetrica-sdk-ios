
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, AMATrackingManagerAuthorizationStatus) {
    AMATrackingManagerAuthorizationStatusNotDetermined = 0,
    AMATrackingManagerAuthorizationStatusRestricted,
    AMATrackingManagerAuthorizationStatusDenied,
    AMATrackingManagerAuthorizationStatusAuthorized
} NS_SWIFT_NAME(TrackingManagerAuthorizationStatus);

NS_SWIFT_NAME(AdProviding)
@protocol AMAAdProviding <NSObject>

- (BOOL)isAdvertisingTrackingEnabled;
- (nullable NSUUID *)advertisingIdentifier;
- (AMATrackingManagerAuthorizationStatus)ATTStatus;

@end

NS_ASSUME_NONNULL_END
