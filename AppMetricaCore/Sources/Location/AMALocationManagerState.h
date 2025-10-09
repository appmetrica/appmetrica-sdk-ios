#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AMALocationManagerState : NSObject<NSCopying, NSMutableCopying>

- (instancetype)initWithAuthorizationStatus:(nullable NSNumber *)authorizationStatus
                           externalLocation:(nullable CLLocation *)externalLocation
                currentTrackLocationEnabled:(BOOL)currentTrackLocationEnabled
             currentAccurateLocationEnabled:(BOOL)currentAccurateLocationEnabled
     currentAllowsBackgroundLocationUpdates:(BOOL)currentAllowsBackgroundLocationUpdates;

@property (nonatomic, strong, readonly) NSNumber *authorizationStatus;
@property (nonatomic, strong, readonly) CLLocation *externalLocation;

@property (nonatomic, assign, readonly) BOOL currentTrackLocationEnabled;
@property (nonatomic, assign, readonly) BOOL currentAccurateLocationEnabled;
@property (nonatomic, assign, readonly) BOOL currentAllowsBackgroundLocationUpdates;

- (CLAuthorizationStatus)currentAuthorizationStatus;
- (BOOL)isLocationSystemPermissionGranted;
- (BOOL)isVisitsSystemPermissionGranted;
- (BOOL)isExternalLocationAvailable;

@end

@interface AMALocationManagerMutableState : AMALocationManagerState

@property (nonatomic, strong, readwrite) NSNumber *authorizationStatus;
@property (nonatomic, strong, readwrite) CLLocation *externalLocation;

@property (nonatomic, assign, readwrite) BOOL currentTrackLocationEnabled;
@property (nonatomic, assign, readwrite) BOOL currentAccurateLocationEnabled;
@property (nonatomic, assign, readwrite) BOOL currentAllowsBackgroundLocationUpdates;

@end

NS_ASSUME_NONNULL_END
