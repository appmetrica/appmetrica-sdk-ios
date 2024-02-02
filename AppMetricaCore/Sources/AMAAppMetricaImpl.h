#import <Foundation/Foundation.h>
#import "AMACompletionBlocks.h"
#import "AMAStartupController.h"

@class AMAAdRevenueInfo;
@class AMAAppMetricaConfiguration;
@class AMAECommerce;
@class AMARevenueInfo;
@class AMAUserProfile;
@protocol AMAAppMetricaExtendedReporting;
@protocol AMAEventPollingDelegate;
@protocol AMAAsyncExecuting;
@protocol AMAExtendedStartupObserving;
@protocol AMAHostStateProviding;
@protocol AMAModuleActivationDelegate;
@protocol AMAReporterStorageControlling;
@protocol AMAStartupCompletionObserving;
#if !TARGET_OS_TV
@protocol AMAJSControlling;
#endif

NS_ASSUME_NONNULL_BEGIN

@interface AMAAppMetricaImpl : NSObject <AMAStartupControllerDelegate>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithHostStateProvider:(nullable id<AMAHostStateProviding>)hostStateProvider
                                 executor:(id<AMAAsyncExecuting>)executor
                    eventPollingDelegates:(nullable NSArray<Class<AMAEventPollingDelegate>> *)eventPollingDelegates;

@property (nonatomic, copy, readonly) NSString *apiKey;
@property (nonatomic, strong, readonly) id<AMAAsyncExecuting> executor;

- (void)activateWithConfiguration:(AMAAppMetricaConfiguration *)configuration;

- (void)addStartupCompletionObserver:(id<AMAStartupCompletionObserving>)observer;
- (void)removeStartupCompletionObserver:(id<AMAStartupCompletionObserving>)observer;

- (void)reportEvent:(NSString *)eventName
         parameters:(NSDictionary *)params
          onFailure:(nullable void (^)(NSError *error))onFailure;

- (void)reportEventWithType:(NSUInteger)eventType
                       name:(NSString *)name
                      value:(NSString *)value
           eventEnvironment:(nullable NSDictionary *)eventEnvironment
             appEnvironment:(nullable NSDictionary *)appEnvironment
                     extras:(nullable NSDictionary<NSString *, NSData *> *)extras
                  onFailure:(nullable void (^)(NSError *))onFailure;

- (void)reportBinaryEventWithType:(NSUInteger)eventType
                             data:(NSData *)data
                             name:(nullable NSString *)name
                          gZipped:(BOOL)gZipped
                 eventEnvironment:(nullable NSDictionary *)eventEnvironment
                   appEnvironment:(nullable NSDictionary *)appEnvironment
                           extras:(nullable NSDictionary<NSString *, NSData *> *)extras
                   bytesTruncated:(NSUInteger)bytesTruncated
                        onFailure:(nullable void (^)(NSError *error))onFailure;

- (void)reportFileEventWithType:(NSUInteger)eventType
                           data:(NSData *)data
                       fileName:(NSString *)fileName
                        gZipped:(BOOL)gZipped
                      encrypted:(BOOL)encrypted
                      truncated:(BOOL)truncated
               eventEnvironment:(nullable NSDictionary *)eventEnvironment
                 appEnvironment:(nullable NSDictionary *)appEnvironment
                         extras:(nullable NSDictionary<NSString *, NSData *> *)extras
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

- (id<AMAAppMetricaExtendedReporting>)manualReporterForConfiguration:(AMAReporterConfiguration *)configuration;
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

- (void)setExtendedStartupObservers:(NSSet<id<AMAExtendedStartupObserving>> *)observers;
- (void)setExtendedReporterStorageControllers:(NSSet<id<AMAReporterStorageControlling>> *)controllers;

@end

NS_ASSUME_NONNULL_END
