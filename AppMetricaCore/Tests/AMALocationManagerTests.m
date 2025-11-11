
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMALocationManager.h"
#import "AMAStartupPermissionController.h"
#import "AMALocationCollectingController.h"
#import "AMALocationCollectingConfiguration.h"
#import <AppMetricaPlatform/AppMetricaPlatform.h>

SPEC_BEGIN(AMALocationManagerTests)

describe(@"AMALocationManager", ^{
    context(@"Manages location manager and its updates", ^{
        CLLocationManager *__block stubLocationManager = nil;

        CLLocationManager *__block systemLocationManager = nil;
        NSObject<CLLocationManagerDelegate> *__block delegate = nil;
        BOOL __block systemAllowsBackgroundLocationUpdates = NO;
        SEL __block startUpdatingLocationSelector = @selector(startUpdatingLocation);

        __auto_type setAuthorizationStatus = ^(CLAuthorizationStatus status, BOOL notifyDelegate) {
            [CLLocationManager stub:@selector(authorizationStatus) andReturn:theValue(status)];
            [stubLocationManager stub:@selector(authorizationStatus) andReturn:theValue(status)];
            if (notifyDelegate) {
                [delegate locationManager:stubLocationManager didChangeAuthorizationStatus:status];
            }
        };
        __auto_type stubSystemLocationManagerWithBlock = ^(void(^block)(CLLocationManager *)){
            [CLLocationManager stub:@selector(alloc) withBlock:^id(NSArray *params) {
                systemLocationManager = stubLocationManager;
                [systemLocationManager stub:@selector(setDelegate:) withBlock:^id(NSArray *params) {
                    delegate = params[0];
                    return nil;
                }];
                systemAllowsBackgroundLocationUpdates = NO;
                [systemLocationManager stub:@selector(setAllowsBackgroundLocationUpdates:) withBlock:^id(NSArray *params) {
                    systemAllowsBackgroundLocationUpdates = [params[0] boolValue];
                    return nil;
                }];
                if (block != nil) {
                    block(systemLocationManager);
                }
                return systemLocationManager;
            }];
        };
        __auto_type stubSystemLocationManager = ^{
            stubSystemLocationManagerWithBlock(nil);
        };
    
        AMAStartupPermissionController *__block startupPermissionController = nil;
        AMALocationCollectingController *__block locationCollectingController = nil;
        AMALocationCollectingConfiguration *__block configurationMock = nil;
        AMACurrentQueueExecutor *__block executor = nil;
    
        beforeEach(^{
#if TARGET_OS_TV
            startUpdatingLocationSelector = @selector(requestLocation);
#endif
            stubLocationManager = [CLLocationManager nullMock];
            systemLocationManager = nil;
            delegate = nil;
            startupPermissionController = [AMAStartupPermissionController nullMock];
            [startupPermissionController stub:@selector(isLocationCollectingGranted) andReturn:theValue(YES)];
            locationCollectingController = [AMALocationCollectingController nullMock];
            configurationMock = [AMALocationCollectingConfiguration nullMock];
            [AMAPlatformDescription stub:@selector(isExtension) andReturn:theValue(NO)];
            
            executor = [[AMACurrentQueueExecutor alloc] init];
            
            AMALocationManager *locationManager =
                [[AMALocationManager alloc] initWithExecutor:executor
                                 startupPermissionController:startupPermissionController
                                               configuration:configurationMock
                                locationCollectingController:locationCollectingController];
            
            [AMALocationManager stub:@selector(sharedManager) andReturn:locationManager];
        });
        afterEach(^{
            [AMALocationManager clearStubs];
        });
        it(@"Should create location manager on start if location permission not granted", ^{
            stubSystemLocationManager();
            [[AMALocationManager sharedManager] start];
            setAuthorizationStatus(kCLAuthorizationStatusDenied, YES);
            [[systemLocationManager shouldNot] beNil];
        });
        it(@"Should create location manager on start if location permissions are granted", ^{
            stubSystemLocationManager();
            [[AMALocationManager sharedManager] start];
            setAuthorizationStatus(kCLAuthorizationStatusAuthorizedAlways, YES);
            [[systemLocationManager shouldNot] beNil];
        });
        it(@"Should not create location manager on start if location gathering is forbidden", ^{
            [startupPermissionController stub:@selector(isLocationCollectingGranted) andReturn:theValue(NO)];
            stubSystemLocationManager();
            [[AMALocationManager sharedManager] start];
            setAuthorizationStatus(kCLAuthorizationStatusAuthorizedAlways, YES);
            [[systemLocationManager should] beNil];
        });
        it(@"Should set location manager delegate on start if location permissions are granted", ^{
            stubSystemLocationManager();
            [[AMALocationManager sharedManager] start];
            setAuthorizationStatus(kCLAuthorizationStatusAuthorizedAlways, YES);
            [[delegate shouldNot] beNil];
        });
        it(@"Should start location updates if authorization status is changed after start without calling delegate", ^{
            stubSystemLocationManager();
            [[AMALocationManager sharedManager] start];
            setAuthorizationStatus(kCLAuthorizationStatusDenied, YES);
            [[systemLocationManager should] receive:startUpdatingLocationSelector];
            setAuthorizationStatus(kCLAuthorizationStatusAuthorizedWhenInUse, YES);
        });
        it(@"Should create location manager when location permission are granted", ^{
            stubSystemLocationManager();
            [[AMALocationManager sharedManager] start];
            setAuthorizationStatus(kCLAuthorizationStatusDenied, YES);
            setAuthorizationStatus(kCLAuthorizationStatusAuthorizedAlways, YES);
            [[systemLocationManager shouldNot] beNil];
        });
        it(@"Should set location manager delegate when location permission are granted", ^{
            stubSystemLocationManager();
            [[AMALocationManager sharedManager] start];
            setAuthorizationStatus(kCLAuthorizationStatusDenied, YES);
            setAuthorizationStatus(kCLAuthorizationStatusAuthorizedAlways, YES);
            [[delegate shouldNot] beNil];
        });
        it(@"Should start CLLocationManager on main thread if started from background thread", ^{
            stubSystemLocationManager();
            setAuthorizationStatus(kCLAuthorizationStatusAuthorizedAlways, YES);
            [[executor should] receive:@selector(execute:) withCount:1];
            [[AMALocationManager sharedManager] start];
        });
        it(@"Should receive correct block if started from background thread", ^{
            stubSystemLocationManagerWithBlock(^(CLLocationManager *manager) {
                [[manager should] receive:startUpdatingLocationSelector];
            });
            [[AMALocationManager sharedManager] start];
            setAuthorizationStatus(kCLAuthorizationStatusAuthorizedAlways, YES);
        });
        it(@"Should stop CLLocationManager on main thread if started from background thread", ^{
            stubSystemLocationManager();
            [[executor should] receive:@selector(execute:) withCount:1];
            [[AMALocationManager sharedManager] start];
        });
        it(@"Should receive correct block if stopped from background thread", ^{
            stubSystemLocationManagerWithBlock(^(CLLocationManager *manager) {
                [[manager should] receive:@selector(stopUpdatingLocation)];
            });
            [[AMALocationManager sharedManager] start];
        });
        it(@"Should dispatch locations update to collecting controller", ^{
            stubSystemLocationManager();
            [[AMALocationManager sharedManager] start];
            setAuthorizationStatus(kCLAuthorizationStatusAuthorizedAlways, YES);
            NSArray *locations = @[ [CLLocation nullMock], [CLLocation nullMock] ];
            [[locationCollectingController should] receive:@selector(addSystemLocations:) withArguments:locations];
            [delegate locationManager:systemLocationManager didUpdateLocations:locations];
        });
        it(@"Should not request status on location receiving", ^{
            stubSystemLocationManager();
            [[AMALocationManager sharedManager] start];
            setAuthorizationStatus(kCLAuthorizationStatusAuthorizedAlways, YES);
            [[CLLocationManager shouldNot] receive:@selector(authorizationStatus)];
            [[stubLocationManager shouldNot] receive:@selector(authorizationStatus)];
            [[AMALocationManager sharedManager] currentLocation];
        });
        it(@"Should start location updates after location restriction is changed from startup", ^{
            [startupPermissionController stub:@selector(isLocationCollectingGranted) andReturn:theValue(NO)];
            stubSystemLocationManagerWithBlock(^(CLLocationManager *locationManager) {
                [[locationManager should] receive:startUpdatingLocationSelector];
            });
            [[AMALocationManager sharedManager] start];
            [startupPermissionController stub:@selector(isLocationCollectingGranted) andReturn:theValue(YES)];
            [[AMALocationManager sharedManager] start]; // just need create CLLocationManager
            setAuthorizationStatus(kCLAuthorizationStatusAuthorizedAlways, YES); // notify via delegate
            [[AMALocationManager sharedManager] updateLocationManagerForCurrentStatus];
            [[systemLocationManager shouldNot] beNil];
        });
#if TARGET_OS_IOS
        context(@"Visits", ^{
            beforeEach(^{
                [configurationMock stub:@selector(visitsCollectingEnabled) andReturn:theValue(YES)];
            });
            
            it(@"Should not start visits monitoring if visits collecting disabled", ^{
                [configurationMock stub:@selector(visitsCollectingEnabled) andReturn:theValue(NO)];
                stubSystemLocationManager();
                [[systemLocationManager shouldNotEventually] receive:@selector(startMonitoringVisits)];
                [[AMALocationManager sharedManager] start];
                setAuthorizationStatus(kCLAuthorizationStatusAuthorizedAlways, YES);
            });
            it(@"Should start visits monitoring if authorization status is changed after enabling", ^{
                stubSystemLocationManager();
                [[AMALocationManager sharedManager] start];
                setAuthorizationStatus(kCLAuthorizationStatusDenied, YES);
                setAuthorizationStatus(kCLAuthorizationStatusAuthorizedAlways, YES);
                [[systemLocationManager should] receive:@selector(startMonitoringVisits)];
                [[AMALocationManager sharedManager] updateAuthorizationStatus];
            });
            it(@"Should not start visits monitoring if authorization status `When In Use`", ^{
                stubSystemLocationManager();
                [[AMALocationManager sharedManager] start];
                setAuthorizationStatus(kCLAuthorizationStatusAuthorizedWhenInUse, YES);
                [[systemLocationManager shouldNot] receive:@selector(startMonitoringVisits)];
                [[AMALocationManager sharedManager] start];
            });
            it(@"Should start visits monitoring if authorization status `Always`", ^{
                stubSystemLocationManager();
                [[AMALocationManager sharedManager] start];
                setAuthorizationStatus(kCLAuthorizationStatusAuthorizedAlways, YES);
                [[systemLocationManager should] receive:@selector(startMonitoringVisits)];
                [[AMALocationManager sharedManager] start];
            });
        });
#endif
        context(@"All permissions", ^{
            CLLocation *const customLocation = [[CLLocation alloc] initWithLatitude:23 longitude:42];
            beforeEach(^{
                setAuthorizationStatus(kCLAuthorizationStatusAuthorizedAlways, YES);
                stubSystemLocationManager();
            });
            it(@"Should have no custom location by default", ^{
                [[[AMALocationManager sharedManager].location should] beNil];
            });
            it(@"Should return set custom location", ^{
                [AMALocationManager sharedManager].location = customLocation;
                [[[AMALocationManager sharedManager].location should] equal:customLocation];
            });
            it(@"Should not start if custom location is set", ^{
                [[AMALocationManager sharedManager] setLocation:customLocation];
                stubSystemLocationManagerWithBlock(^(CLLocationManager *locationManager) {
                    [[locationManager shouldNot] receive:startUpdatingLocationSelector];
                });
                [[AMALocationManager sharedManager] start];
            });
            it(@"Should not start if location collecting disabled", ^{
                [[AMALocationManager sharedManager] setTrackLocationEnabled:NO];
                stubSystemLocationManagerWithBlock(^(CLLocationManager *locationManager) {
                    [[locationManager shouldNot] receive:startUpdatingLocationSelector];
                });
                [[AMALocationManager sharedManager] start];
            });
            it(@"Custom location should ignore location collecting disabled", ^{
                [[AMALocationManager sharedManager] setTrackLocationEnabled:NO];
                
                CLLocation *mockLocation = [CLLocation nullMock];
                [[AMALocationManager sharedManager] setLocation:mockLocation];
                
                [[[[AMALocationManager sharedManager] currentLocation] should] equal:mockLocation];
            });
            it(@"Should stop when custom location is set", ^{
                [[AMALocationManager sharedManager] start];
                [[systemLocationManager should] receive:@selector(stopUpdatingLocation)];
                [[AMALocationManager sharedManager] setLocation:customLocation];
            });
            it(@"Should stop when location collecting disabled", ^{
                [[AMALocationManager sharedManager] start];
                [[systemLocationManager should] receive:@selector(stopUpdatingLocation)];
                [[AMALocationManager sharedManager] setTrackLocationEnabled:NO];
            });
        });
#if !TARGET_OS_TV
        context(@"Allow background updates", ^{
            BOOL hasProperAPILevel = [CLLocationManager instancesRespondToSelector:@selector(setAllowsBackgroundLocationUpdates:)];
            beforeEach(^{
                stubSystemLocationManager();
                setAuthorizationStatus(kCLAuthorizationStatusAuthorizedAlways, YES);
            });
            it(@"Should set default desiredAccuracy from configuration", ^{
                const double expectedDesiredAccuracy = 1;
                const double expectedDistanceFilter = 2;
                
                [configurationMock stub:@selector(defaultDesiredAccuracy) andReturn:theValue(expectedDesiredAccuracy)];
                [configurationMock stub:@selector(defaultDistanceFilter) andReturn:theValue(expectedDistanceFilter)];
                
                stubSystemLocationManagerWithBlock(^(CLLocationManager *manager) {
                    [systemLocationManager stub:@selector(setDesiredAccuracy:) withBlock:^id(NSArray *params) {
                        [[params[0] should] equal:theValue(expectedDesiredAccuracy)];
                        return nil;
                    }];
                    [systemLocationManager stub:@selector(setDistanceFilter:) withBlock:^id(NSArray *params) {
                        [[params[0] should] equal:theValue(expectedDistanceFilter)];
                        return nil;
                    }];
                });

                [AMALocationManager sharedManager].allowsBackgroundLocationUpdates = YES;
                [[AMALocationManager sharedManager] start];
            });
            it(@"Should set accurate desiredAccuracy from configuration if accurate location enabled", ^{
                const double expectedDesiredAccuracy = 3;
                const double expectedDistanceFilter = 4;
                
                [configurationMock stub:@selector(accurateDesiredAccuracy) andReturn:theValue(expectedDesiredAccuracy)];
                [configurationMock stub:@selector(accurateDistanceFilter) andReturn:theValue(expectedDistanceFilter)];
                
                stubSystemLocationManagerWithBlock(^(CLLocationManager *manager) {
                    [systemLocationManager stub:@selector(setDesiredAccuracy:) withBlock:^id(NSArray *params) {
                        [[params[0] should] equal:theValue(expectedDesiredAccuracy)];
                        return nil;
                    }];
                    [systemLocationManager stub:@selector(setDistanceFilter:) withBlock:^id(NSArray *params) {
                        [[params[0] should] equal:theValue(expectedDistanceFilter)];
                        return nil;
                    }];
                });

                [AMALocationManager sharedManager].allowsBackgroundLocationUpdates = YES;
                [AMALocationManager sharedManager].accurateLocationEnabled = YES;
                [[AMALocationManager sharedManager] start];
            });
            it(@"Should pass flag value to the system before start", ^{
                if (hasProperAPILevel) {
                    [AMALocationManager sharedManager].allowsBackgroundLocationUpdates = YES;
                    [[AMALocationManager sharedManager] start];
                    setAuthorizationStatus(kCLAuthorizationStatusAuthorizedAlways, YES);
                    BOOL actual = [AMALocationManager sharedManager].allowsBackgroundLocationUpdates;
                    [[theValue(actual) should] beYes];
                }
            });
            it(@"Should return flag value before start", ^{
                if (hasProperAPILevel) {
                    [AMALocationManager sharedManager].allowsBackgroundLocationUpdates = YES;
                    [[AMALocationManager sharedManager] start];
                    setAuthorizationStatus(kCLAuthorizationStatusAuthorizedAlways, YES);
                    [[theValue(systemAllowsBackgroundLocationUpdates) should] beYes];
                }
            });
            it(@"Should pass flag value to the system after start", ^{
                if (hasProperAPILevel) {
                    [[AMALocationManager sharedManager] start];
                    [AMALocationManager sharedManager].allowsBackgroundLocationUpdates = YES;
                    [[theValue(systemAllowsBackgroundLocationUpdates) should] beYes];
                }
            });
            it(@"Should return flag value after start", ^{
                if (hasProperAPILevel) {
                    [[AMALocationManager sharedManager] start];
                    [AMALocationManager sharedManager].allowsBackgroundLocationUpdates = YES;
                    BOOL actual = [AMALocationManager sharedManager].allowsBackgroundLocationUpdates;
                    [[theValue(actual) should] beYes];
                }
            });
            it(@"Should indicate the system value is NO by default", ^{
                [[AMALocationManager sharedManager] start];
                [[theValue(systemAllowsBackgroundLocationUpdates) should] beNo];
            });
            it(@"Should be NO by default", ^{
                [[AMALocationManager sharedManager] start];
                [[theValue([AMALocationManager sharedManager].allowsBackgroundLocationUpdates) should] beNo];
            });
            context(@"pausesLocationUpdatesAutomatically", ^{
                BOOL __block pausesLocationUpdatesAutomatically = YES;
                beforeEach(^{
                    pausesLocationUpdatesAutomatically = YES;
                    [configurationMock stub:@selector(pausesLocationUpdatesAutomatically) andReturn:theValue(NO)];
                    stubSystemLocationManagerWithBlock(^(CLLocationManager *manager) {
                        [manager stub:@selector(setPausesLocationUpdatesAutomatically:) withBlock:^id(NSArray *params) {
                            pausesLocationUpdatesAutomatically = [params[0] boolValue];
                            return nil;
                        }];
                    });
                });
                it(@"Should set proper value", ^{
                    [[AMALocationManager sharedManager] start];
                    setAuthorizationStatus(kCLAuthorizationStatusAuthorizedAlways, YES);
                    [[theValue(pausesLocationUpdatesAutomatically) should] beNo];
                });
                it(@"Should not set value in extension", ^{
                    [AMAPlatformDescription stub:@selector(isExtension) andReturn:theValue(YES)];
                    [[AMALocationManager sharedManager] start];
                    [[theValue(pausesLocationUpdatesAutomatically) should] beYes];
                });
            });
        });
#endif
    });
    it(@"Should conform to CLLocationManagerDelegate", ^{
        [[[AMALocationManager sharedManager] should] conformToProtocol:@protocol(CLLocationManagerDelegate)];
    });
});

SPEC_END
