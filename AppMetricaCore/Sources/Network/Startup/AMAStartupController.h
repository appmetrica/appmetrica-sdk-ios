
#import <Foundation/Foundation.h>

@class AMAStartupController;
@class AMATimeoutRequestsController;
@protocol AMAResettableIterable;
@protocol AMACancelableExecuting;
@class AMAStartupResponseParser;
@class AMAMetricaConfiguration;
@class AMAAttributionController;
@protocol AMAStartupStateProviding;

extern NSErrorDomain const AMAStartupRequestsErrorDomain;
typedef NS_ERROR_ENUM(AMAStartupRequestsErrorDomain, AMAStartupRequestsErrorCode) {
    AMAStartupRequestsErrorTimeout = 1,
};

@protocol AMAStartupControllerDelegate <NSObject>

@required
- (void)startupControllerDidFinishWithSuccess:(AMAStartupController *)controller;
- (void)startupController:(AMAStartupController *)controller didFailWithError:(NSError *)error;

@end

@protocol AMAExtendedStartupObservingDelegate <NSObject>

@required
- (void)startupUpdatedWithResponse:(NSDictionary *)response;
- (void)startupUpdateFailedWithError:(NSError *)error;

@end

@interface AMAStartupController : NSObject

@property (nonatomic, assign, readonly) BOOL startupUpdateRequired;
// Freshness of the received configuration, independent of pending request parameter updates.
@property (nonatomic, assign, readonly) BOOL startupConfigurationUpToDate;
@property (nonatomic, weak) id<AMAStartupControllerDelegate> delegate;
@property (nonatomic, weak) id<AMAExtendedStartupObservingDelegate> extendedDelegate;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithTimeoutRequestsController:(AMATimeoutRequestsController *)timeoutRequestsController
                             attributionController:(AMAAttributionController *)attributionController
                                     stateProvider:(id<AMAStartupStateProviding>)stateProvider;

- (instancetype)initWithExecutor:(id<AMACancelableExecuting>)executor
                    hostProvider:(id<AMAResettableIterable>)hostProvider
       timeoutRequestsController:(AMATimeoutRequestsController *)timeoutRequestsController
           startupResponseParser:(AMAStartupResponseParser *)startupResponseParser
           attributionController:(AMAAttributionController *)attributionController
           metricaConfiguration:(AMAMetricaConfiguration *)metricaConfiguration;

- (void)addAdditionalStartupParameters:(NSDictionary *)parameters;

- (instancetype)initWithExecutor:(id<AMACancelableExecuting>)executor
                    hostProvider:(id<AMAResettableIterable>)hostProvider
       timeoutRequestsController:(AMATimeoutRequestsController *)timeoutRequestsController
           startupResponseParser:(AMAStartupResponseParser *)startupResponseParser
           attributionController:(AMAAttributionController *)attributionController
            metricaConfiguration:(AMAMetricaConfiguration *)metricaConfiguration
                   stateProvider:(id<AMAStartupStateProviding>)stateProvider;

- (void)update;
- (void)cancel;

@end
