
#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@protocol AMAExecuting;
@class AMAStartupPermissionController;
@class AMALocationCollectingController;
@class AMALocationCollectingConfiguration;

@interface AMALocationManager : NSObject

@property (nonatomic, assign) BOOL trackLocationEnabled;

+ (instancetype)sharedManager;

- (instancetype)initWithExecutor:(id<AMAExecuting>)executor
               mainQueueExecutor:(id<AMAExecuting>)mainQueueExecutor
     startupPermissionController:(AMAStartupPermissionController *)startupPermissionController
                   configuration:(AMALocationCollectingConfiguration *)configuration
    locationCollectingController:(AMALocationCollectingController *)locationCollectingController;

- (CLLocation *)currentLocation;
#if TARGET_OS_IOS
- (void)sendMockVisit:(CLVisit *)visit;
# endif
- (void)setLocation:(CLLocation *)location;
- (void)setAccurateLocationEnabled:(BOOL)accurateLocationEnabled;
- (void)setAllowsBackgroundLocationUpdates:(BOOL)allowsBackgroundLocationUpdates;

- (void)start;
- (void)updateAuthorizationStatus;
- (void)updateLocationManagerForCurrentStatus;

@end
