#import "AMALocationManagerState.h"

@interface AMALocationManagerState  () {
@protected
    NSNumber *_authorizationStatus;
    CLLocation *_externalLocation;
    BOOL _currentTrackLocationEnabled;
    BOOL _currentAccurateLocationEnabled;
    BOOL _currentAllowsBackgroundLocationUpdates;
}

@end

@implementation AMALocationManagerState

- (instancetype)initWithAuthorizationStatus:(NSNumber *)authorizationStatus
                           externalLocation:(CLLocation *)externalLocation
                currentTrackLocationEnabled:(BOOL)currentTrackLocationEnabled
             currentAccurateLocationEnabled:(BOOL)currentAccurateLocationEnabled
     currentAllowsBackgroundLocationUpdates:(BOOL)currentAllowsBackgroundLocationUpdates
{
    self = [super init];
    if (self) {
        _authorizationStatus = [authorizationStatus copy];
        _externalLocation = externalLocation;
        _currentTrackLocationEnabled = currentTrackLocationEnabled;
        _currentAccurateLocationEnabled = currentAccurateLocationEnabled;
        _currentAllowsBackgroundLocationUpdates = currentAllowsBackgroundLocationUpdates;
    }
    return self;
}

- (NSNumber *)authorizationStatus
{
    return _authorizationStatus;
}

- (CLLocation *)externalLocation
{
    return _externalLocation;
}

- (BOOL)currentTrackLocationEnabled
{
    return _currentTrackLocationEnabled;
}

- (BOOL)currentAccurateLocationEnabled
{
    return _currentAccurateLocationEnabled;
}

- (BOOL)currentAllowsBackgroundLocationUpdates
{
    return _currentAllowsBackgroundLocationUpdates;
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
    AMALocationManagerMutableState *newState = [[AMALocationManagerMutableState alloc] init];
    [newState copyValuesFrom:self];
    return newState;
}

- (CLAuthorizationStatus)currentAuthorizationStatus
{
    CLAuthorizationStatus authorizationStatus = kCLAuthorizationStatusNotDetermined;
    if (self.authorizationStatus != nil) {
        authorizationStatus = (CLAuthorizationStatus)[self.authorizationStatus intValue];
    }
    return authorizationStatus;
}

- (BOOL)isLocationSystemPermissionGranted
{
    CLAuthorizationStatus authorizationStatus = [self currentAuthorizationStatus];
    BOOL result = authorizationStatus == kCLAuthorizationStatusAuthorizedWhenInUse ||
                  authorizationStatus == kCLAuthorizationStatusAuthorizedAlways;
    return result;
}

- (BOOL)isVisitsSystemPermissionGranted
{
    return [self currentAuthorizationStatus] == kCLAuthorizationStatusAuthorizedAlways;
}

- (BOOL)isExternalLocationAvailable
{
    return self.externalLocation != nil;
}

- (void)copyValuesFrom:(AMALocationManagerState*)state
{
    _authorizationStatus = [state.authorizationStatus copy];
    _externalLocation = state.externalLocation;
    _currentTrackLocationEnabled = state.currentTrackLocationEnabled;
    _currentAccurateLocationEnabled = state.currentAccurateLocationEnabled;
    _currentAllowsBackgroundLocationUpdates = state.currentAllowsBackgroundLocationUpdates;
}

@end

@implementation AMALocationManagerMutableState

@dynamic authorizationStatus;
@dynamic externalLocation;
@dynamic currentTrackLocationEnabled;
@dynamic currentAccurateLocationEnabled;
@dynamic currentAllowsBackgroundLocationUpdates;

- (id)copyWithZone:(NSZone *)zone
{
    AMALocationManagerState *newState = [[AMALocationManagerState alloc] init];
    [newState copyValuesFrom:self];
    return newState;
}

- (void)setAuthorizationStatus:(NSNumber *)authorizationStatus
{
    _authorizationStatus = [authorizationStatus copy];
}

- (void)setExternalLocation:(CLLocation *)externalLocation
{
    _externalLocation = externalLocation;
}

- (void)setCurrentTrackLocationEnabled:(BOOL)currentTrackLocationEnabled
{
    _currentTrackLocationEnabled = currentTrackLocationEnabled;
}

- (void)setCurrentAccurateLocationEnabled:(BOOL)currentAccurateLocationEnabled
{
    _currentAccurateLocationEnabled = currentAccurateLocationEnabled;
}

- (void)setCurrentAllowsBackgroundLocationUpdates:(BOOL)currentAllowsBackgroundLocationUpdates
{
    _currentAllowsBackgroundLocationUpdates = currentAllowsBackgroundLocationUpdates;
}

@end
