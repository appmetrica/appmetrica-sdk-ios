
#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@protocol AMAAsyncExecuting;
@protocol AMASyncExecuting;
@protocol AMAThreadProviding;
@class AMAStartupPermissionController;
@class AMALocationCollectingController;
@class AMALocationCollectingConfiguration;
@class AMARunLoopExecutor;

NS_ASSUME_NONNULL_BEGIN

@interface AMALocationManager : NSObject

@property (nonatomic, assign) BOOL trackLocationEnabled;
@property (nonatomic, assign) BOOL accurateLocationEnabled;
@property (nonatomic, assign) BOOL allowsBackgroundLocationUpdates;
@property (nonatomic, strong) CLLocation *location;

+ (instancetype)sharedManager;

- (instancetype)initWithExecutor:(id<AMASyncExecuting, AMAAsyncExecuting, AMAThreadProviding>)executor
     startupPermissionController:(AMAStartupPermissionController *)startupPermissionController
                   configuration:(AMALocationCollectingConfiguration *)configuration
    locationCollectingController:(AMALocationCollectingController *)locationCollectingController;

- (CLLocation *)currentLocation;
#if TARGET_OS_IOS
- (void)sendMockVisit:(CLVisit *)visit;
# endif

- (void)start;
- (void)updateAuthorizationStatus;
- (void)updateLocationManagerForCurrentStatus;

@end

NS_ASSUME_NONNULL_END
