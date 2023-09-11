
#import <Foundation/Foundation.h>
#import "AMACompletionBlocks.h"
#import "AMAStartupController.h"

@class CLLocation;
@class AMAAppMetricaPreloadInfo;
@class AMACrash;
@class AMAUserProfile;
@class AMARevenueInfo;
@class AMAAdRevenueInfo;
@class AMAErrorModel;
@class AMAECommerce;
@class AMAAppMetricaConfiguration;
@class AMACustomEventParameters;

@protocol AMAExecuting;
@protocol AMAStartupCompletionObserving;
@protocol AMAAppMetricaReporting;
@protocol AMACrashReporting;
@protocol AMAHostStateProviding;
@class AMAReporterConfiguration;
@class AMAPluginErrorDetails;
#if !TARGET_OS_TV
@protocol AMAJSControlling;
#endif
@protocol AMAExtendedStartupObserving;
@protocol AMAReporterStorageControlling;

NS_ASSUME_NONNULL_BEGIN

@interface AMAAppMetricaImpl : NSObject <AMAStartupControllerDelegate>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithHostStateProvider:(nullable id<AMAHostStateProviding>)hostStateProvider
                                 executor:(id<AMAExecuting>)executor;

@property (nonatomic, copy, readonly) NSString *apiKey;
@property (nonatomic, strong, readonly) id<AMAExecuting> executor;

- (void)activateWithConfiguration:(AMAAppMetricaConfiguration *)configuration;

- (void)addStartupCompletionObserver:(id<AMAStartupCompletionObserving>)observer;
- (void)removeStartupCompletionObserver:(id<AMAStartupCompletionObserving>)observer;

- (void)reportEvent:(NSString *)eventName
         parameters:(NSDictionary *)params
          onFailure:(nullable void (^)(NSError *error))onFailure;
- (void)reportEventWithType:(NSUInteger)eventType
                       name:(NSString *)name
                      value:(NSString *)value
                environment:(nullable NSDictionary *)environment
                     extras:(nullable NSDictionary<NSString *, NSData *> *)extras
                  onFailure:(nullable void (^)(NSError *))onFailure;
- (void)reportEventWithParameters:(AMACustomEventParameters * )parameters
                        onFailure:(nullable void (^)(NSError *error))onFailure;

- (void)reportUserProfile:(AMAUserProfile *)userProfile onFailure:(nullable void (^)(NSError *error))onFailure;
- (void)reportRevenue:(AMARevenueInfo *)revenueInfo onFailure:(nullable void (^)(NSError *error))onFailure;
- (void)reportAdRevenue:(AMAAdRevenueInfo *)adRevenueInfo onFailure:(nullable void (^)(NSError *error))onFailure;
- (void)reportECommerce:(AMAECommerce *)eCommerce onFailure:(nullable void (^)(NSError *))onFailure;

- (void)sendEventsBuffer;
- (void)pauseSession;
- (void)resumeSession;

- (void)handleConfigurationUpdate;

- (void)startDispatcher;

- (id<AMAAppMetricaReporting >)manualReporterForConfiguration:(AMAReporterConfiguration *)configuration;
- (BOOL)isReporterCreatedForAPIKey:(NSString *)apiKey;

- (void)setUserProfileID:(NSString *)userProfileID;
- (void)setPreloadInfo:(nullable AMAAppMetricaPreloadInfo *)preloadInfo;

+ (void)syncSetErrorEnvironmentValue:(NSString *)value forKey:(NSString *)key;
- (void)setAppEnvironmentValue:(NSString *)value forKey:(NSString *)key;
- (void)clearAppEnvironment;

- (void)setSessionExtras:(nullable NSData *)data forKey:(NSString *)key;
- (void)clearSessionExtra;

- (void)setErrorEnvironmentValue:(NSString *)value forKey:(NSString *)key;
- (void)requestStartupIdentifiersWithCompletionQueue:(dispatch_queue_t)queue
                                     completionBlock:(AMAIdentifiersCompletionBlock)block
                                       notifyOnError:(BOOL)notifyOnError;
- (void)requestStartupIdentifiersWithKeys:(NSArray<NSString *> *)keys
                          completionQueue:(dispatch_queue_t)queue
                          completionBlock:(AMAIdentifiersCompletionBlock)block
                            notifyOnError:(BOOL)notifyOnError;
#if !TARGET_OS_TV
- (void)setupWebViewReporting:(id<AMAJSControlling>)controller;
#endif
- (void)reportUrl:(NSURL *)url ofType:(NSString *)type isAuto:(BOOL)isAuto;

- (void)setExtendedStartupObservers:(NSMutableSet<id<AMAExtendedStartupObserving>> *)observers;
- (void)setExtendedReporterStorageControllers:(NSMutableSet<id<AMAReporterStorageControlling>> *)controllers;

@end

NS_ASSUME_NONNULL_END
