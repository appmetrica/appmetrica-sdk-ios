
#import <CoreLocation/CoreLocation.h>
#import <AppMetricaPlatform/AppMetricaPlatform.h>

#import "AMACore.h"
#import "AMALocationManager.h"
#import "AMAStartupPermissionController.h"
#import "AMALocationCollectingController.h"
#import "AMALocationCollectingConfiguration.h"
#import "AMAMetricaConfiguration.h"
#import "AMAMetricaPersistentConfiguration.h"
#import "AMALocationManagerState.h"

@interface AMALocationManager () <CLLocationManagerDelegate>

@property (atomic, strong) CLLocationManager *locationManager;
@property (nonatomic, assign) BOOL locationUpdateInProgress;

@property (atomic, copy) AMALocationManagerState *state;

@property (nonatomic, strong, readonly) id<AMASyncExecuting, AMAAsyncExecuting, AMAThreadProviding> executor;
@property (nonatomic, strong, readonly) AMAStartupPermissionController *startupPermissionController;
@property (nonatomic, strong, readonly) AMALocationCollectingController *locationCollectingController;
@property (nonatomic, strong, readonly) AMALocationCollectingConfiguration *configuration;

@end

@implementation AMALocationManager

- (instancetype)init
{
    AMARunLoopExecutor *executor = [[AMARunLoopExecutor alloc] initWithName:@"AMALocationManager"];
    AMAStartupPermissionController *startupPermissionController = [[AMAStartupPermissionController alloc] init];
    AMALocationCollectingConfiguration *configuration = [[AMALocationCollectingConfiguration alloc] init];
    AMAPersistentTimeoutConfiguration *timeoutConfiguration =
        [AMAMetricaConfiguration sharedInstance].persistent.timeoutConfiguration;
    AMALocationCollectingController *locationController =
        [[AMALocationCollectingController alloc] initWithConfiguration:configuration
                                                  timeoutConfiguration:timeoutConfiguration];

    return [self initWithExecutor:executor
      startupPermissionController:startupPermissionController
                    configuration:configuration
     locationCollectingController:locationController];
}

- (instancetype)initWithExecutor:(id<AMASyncExecuting, AMAAsyncExecuting, AMAThreadProviding>)executor
     startupPermissionController:(AMAStartupPermissionController *)startupPermissionController
                   configuration:(AMALocationCollectingConfiguration *)configuration
    locationCollectingController:(AMALocationCollectingController *)locationCollectingController
{
    self = [super init];
    if (self != nil) {
        _executor = executor;
        _startupPermissionController = startupPermissionController;
        _configuration = configuration;
        _locationCollectingController = locationCollectingController;
        
        AMALocationManagerMutableState *initialState = [AMALocationManagerMutableState new];
        initialState.currentTrackLocationEnabled = YES;
        _state = [[AMALocationManagerState alloc] initWithAuthorizationStatus:nil
                                                             externalLocation:nil
                                                  currentTrackLocationEnabled:YES
                                               currentAccurateLocationEnabled:NO
                                       currentAllowsBackgroundLocationUpdates:NO];
    }

    return self;
}

#pragma mark - Public -

+ (instancetype)sharedManager
{
    static AMALocationManager *sharedLocationManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedLocationManager = [[AMALocationManager alloc] init];
    });
    return sharedLocationManager;
}

- (CLLocation *)currentLocation
{
    AMALocationManagerState *state = self.state;
    CLLocation *currentLocation = nil;
    
    if ([state isExternalLocationAvailable]) {
        currentLocation = state.externalLocation;
    } else if (state.currentTrackLocationEnabled && state.isLocationSystemPermissionGranted) {
        currentLocation = [self.executor syncExecute:^id _Nullable {
            return self.locationManager.location;
        }];
    }
    
    AMALogInfo(@"Current location is: %@", currentLocation);
    return currentLocation;
}

#if TARGET_OS_IOS
- (void)sendMockVisit:(CLVisit *)visit
{
    [self locationManager:(CLLocationManager *)[NSObject new] didVisit:visit];
}
#endif

- (void)setLocation:(CLLocation *)location
{
    @synchronized (self) {
        AMALocationManagerMutableState *newState = [self.state mutableCopy];
        newState.externalLocation = location;
        self.state = newState;
    }
    
    [self.executor execute:^{
        AMALogInfo(@"External location is set: %@", location);
        [self syncUpdateLocationUpdatesForCurrentStatus];
    }];
}

- (CLLocation *)location
{
    return self.state.externalLocation;
}

- (void)setAccurateLocationEnabled:(BOOL)preciseLocationNeeded
{
    @synchronized (self) {
        AMALocationManagerMutableState *newState = [self.state mutableCopy];
        newState.currentAccurateLocationEnabled = preciseLocationNeeded;
        self.state = newState;
    }
    
    [self.executor execute:^{
        [self configureLocationManager];
    }];
}

- (BOOL)accurateLocationEnabled
{
    return self.state.currentAccurateLocationEnabled;
}

- (void)setAllowsBackgroundLocationUpdates:(BOOL)allowsBackgroundLocationUpdates
{
    @synchronized (self) {
        AMALocationManagerMutableState *newState = [self.state mutableCopy];
        newState.currentAllowsBackgroundLocationUpdates = allowsBackgroundLocationUpdates;
        self.state = newState;
    }
    
    [self.executor execute:^{
        [self configureLocationManager];
    }];
}

- (BOOL)allowsBackgroundLocationUpdates
{
    return self.state.currentAllowsBackgroundLocationUpdates;
}

- (void)start
{
    [self.executor execute:^{
        [self syncUpdateLocationManagerForCurrentStatus];
    }];
}

- (void)updateAuthorizationStatus
{
    [self.executor execute:^{
        [self updateAuthorizationStatusFromLocationManager];
        [self syncUpdateLocationManagerForCurrentStatus];
    }];
}

- (void)updateLocationManagerForCurrentStatus
{
    [self.executor execute:^{
        [self syncUpdateLocationManagerForCurrentStatus];
    }];
}

- (BOOL)trackLocationEnabled
{
    return self.state.currentTrackLocationEnabled;
}

- (void)setTrackLocationEnabled:(BOOL)locationTrackingEnabled
{
    @synchronized (self) {
        AMALocationManagerMutableState *newState = [self.state mutableCopy];
        newState.currentTrackLocationEnabled = locationTrackingEnabled;
        self.state = newState;
    }
    [self.executor execute:^{
        AMALogInfo(@"Location tracking flag is changed to: %@", locationTrackingEnabled ? @"YES" : @"NO");
        [self syncUpdateLocationManagerForCurrentStatus];
    }];
}

#pragma mark - Private -

- (BOOL)isLocationCollectingGranted
{
    BOOL result = [self.startupPermissionController isLocationCollectingGranted];
    AMALogInfo(@"isLocationCollectingGranted: %d", result);
    return result;
}

- (void)logPreventionOfAction:(NSString *)action reason:(NSString *)reason
{
    AMALogInfo(@"Location %@ prevented: %@", action, reason);
}

- (BOOL)shouldUseLocationManagerForAction:(NSString *)action
{
    BOOL result = NO;
    if (self.state.isExternalLocationAvailable) {
        [self logPreventionOfAction:action reason:@"external location is available"];
    }
    else if (self.state.currentTrackLocationEnabled == NO) {
        [self logPreventionOfAction:action reason:@"location tracking is disabled"];
    }
    else if ([self isLocationCollectingGranted] == NO) {
        [self logPreventionOfAction:action reason:@"location collecting is forbidden"];
    }
    else {
        result = YES;
    }
    return result;
}

- (BOOL)shouldInitializeLocationManager
{
    BOOL result = NO;
    NSString *action = @"initialization";
    if (self.locationManager != nil) {
        [self logPreventionOfAction:action reason:@"already initialized"];
    }
    else if ([self shouldUseLocationManagerForAction:action] == NO) {
        // Already logged
    }
    else {
        result = YES;
    }
    return result;
}

- (BOOL)shouldStartLocationUpdates
{
    BOOL result = NO;
    NSString *action = @"start";
    if ([self isLocationManagerAvailableForAction:action] == NO) {
        // Already logged
    }
    else if (self.state.isLocationSystemPermissionGranted == NO) {
        [self logPreventionOfAction:action reason:@"location permission is not granted"];
    }
    else {
        result = YES;
    }
    return result;
}

- (BOOL)shouldStartVisitsMonitoring
{
    BOOL result = NO;
    NSString *action = @"visits";
    if ([self isLocationManagerAvailableForAction:action] == NO) {
        // Already logged
    }
    else if (self.state.isVisitsSystemPermissionGranted == NO) {
        [self logPreventionOfAction:action reason:@"always system permission for visits is not granted"];
    }
    else if (self.configuration.visitsCollectingEnabled == NO) {
        [self logPreventionOfAction:action reason:@"visit monitoring is not granted in startup"];
    }
    else {
        result = YES;
    }
    return result;
}

- (BOOL)isLocationManagerAvailableForAction:(NSString *)action
{
    BOOL result = NO;
    if (self.locationManager == nil) {
        [self logPreventionOfAction:action reason:@"location manager is not initialized"];
    }
    else if ([self shouldUseLocationManagerForAction:action] == NO) {
        // Already logged
    }
    else {
        result = YES;
    }
    return result;
}

- (void)syncUpdateLocationManagerForCurrentStatus
{
    [self syncUpdateLocationUpdatesForCurrentStatus];
    [self syncUpdateVisitsMonitoringForCurrentStatus];
}

- (void)syncUpdateLocationUpdatesForCurrentStatus
{
    [self initLocationManagerIfNeeded];
    if ([self shouldStartLocationUpdates]) {
        [self startLocationUpdates];
    }
    else {
        [self stopLocationUpdates];
    }
}

- (void)syncUpdateVisitsMonitoringForCurrentStatus
{
    [self initLocationManagerIfNeeded];
    if ([self shouldStartVisitsMonitoring]) {
        [self startVisitsMonitoring];
    }
    else {
        [self stopVisitsMonitoring];
    }
}

- (void)initLocationManagerIfNeeded
{
    if ([self shouldInitializeLocationManager]) {
        [self initializeLocationManager];
    }
}

- (void)initializeLocationManager
{
    if (self.locationManager == nil) {
        CLLocationManager *manager = [[CLLocationManager alloc] init];
        AMALogInfo(@"location manager is created: %@", manager);
        self.locationManager = manager;
        
        manager.delegate = self;
    }
}

- (void)updateAuthorizationStatusFromLocationManager
{
    CLAuthorizationStatus status = kCLAuthorizationStatusNotDetermined;
    if (@available(iOS 14.0, tvOS 14.0, *)) {
        if (self.locationManager != nil) {
            status = self.locationManager.authorizationStatus;
        }
    }
    else {
        status = [CLLocationManager authorizationStatus];
    }
    
    @synchronized (self) {
        AMALocationManagerMutableState *newState = [self.state mutableCopy];
        newState.authorizationStatus = @(status);
        self.state = newState;
    }
}

- (void)startLocationUpdates
{
    if (self.locationUpdateInProgress) {
        return;
    }

    self.locationUpdateInProgress = YES;
    AMALogInfo(@"Start location manager");
    
    [self configureLocationManager];
#if TARGET_OS_TV
    [self.locationManager requestLocation];
#else
    [self.locationManager startUpdatingLocation];
#endif
}

- (void)stopLocationUpdates
{
    self.locationUpdateInProgress = NO;
    
    AMALogInfo(@"Stop location manager");
    [self.locationManager stopUpdatingLocation];
}

- (void)startVisitsMonitoring
{
#if TARGET_OS_IOS
    AMALogInfo(@"Start monitoring visits");
    [self.locationManager startMonitoringVisits];
#endif
}

- (void)stopVisitsMonitoring
{
#if TARGET_OS_IOS
    AMALogInfo(@"Stop monitoring visits");
    [self.locationManager stopMonitoringVisits];
#endif
}

- (void)configureLocationManager
{
    AMALocationManagerState *state = self.state;
    if (state.currentAccurateLocationEnabled) {
        AMALogInfo(@"Use accurate location");
        self.locationManager.desiredAccuracy = self.configuration.accurateDesiredAccuracy;
        self.locationManager.distanceFilter = self.configuration.accurateDistanceFilter;
    }
    else {
        self.locationManager.desiredAccuracy = self.configuration.defaultDesiredAccuracy;
        self.locationManager.distanceFilter = self.configuration.defaultDistanceFilter;
    }

#if !TARGET_OS_TV
    if ([AMAPlatformDescription isExtension] == NO) {
        self.locationManager.pausesLocationUpdatesAutomatically = self.configuration.pausesLocationUpdatesAutomatically;
    }
    AMALogInfo(@"Allow background location updates");
    self.locationManager.allowsBackgroundLocationUpdates = state.currentAllowsBackgroundLocationUpdates;
#endif
}

#pragma mark - CLLocationManagerDelegate -

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    AMALogInfo(@"Authorization status changed to %d", status);
    [self updateAuthorizationStatusFromLocationManager];
    [self updateLocationManagerForCurrentStatus];
}

- (void)locationManagerDidChangeAuthorization:(CLLocationManager *)manager API_AVAILABLE(ios(14.0), macos(11.0), watchos(7.0), tvos(14.0))
{
    AMALogInfo(@"Authorization status changed to %d", manager.authorizationStatus);
    [self updateAuthorizationStatusFromLocationManager];
    [self updateLocationManagerForCurrentStatus];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    if (self.trackLocationEnabled == NO) {
        return;
    }
    
    AMALogInfo(@"Location updated with %@", locations.lastObject);
    [self.locationCollectingController addSystemLocations:locations];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    AMALogInfo(@"Failed to retrieve location with error: %@", error);
}
#if TARGET_OS_IOS
- (void)locationManager:(CLLocationManager *)manager didVisit:(CLVisit *)visit
{
    AMALogInfo(@"Visit captured: %@", visit);
    [self.locationCollectingController addVisit:visit];
}
#endif
@end
