
#import <Foundation/Foundation.h>

@class AMAStartupController;
@class AMATimeoutRequestsController;
@protocol AMAResettableIterable;
@protocol AMACancelableExecuting;
@class AMAStartupResponseParser;
@class AMAMetricaConfiguration;
@class AMAAttributionController;

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

@property (nonatomic, assign, readonly) BOOL upToDate;
@property (nonatomic, weak) id<AMAStartupControllerDelegate> delegate;
@property (nonatomic, weak) id<AMAExtendedStartupObservingDelegate> extendedDelegate;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithTimeoutRequestsController:(AMATimeoutRequestsController *)timeoutRequestsController
                             attributionController:(AMAAttributionController *)attributionController;

- (instancetype)initWithExecutor:(id<AMACancelableExecuting>)executor
                    hostProvider:(id<AMAResettableIterable>)hostProvider
       timeoutRequestsController:(AMATimeoutRequestsController *)timeoutRequestsController
           startupResponseParser:(AMAStartupResponseParser *)startupResponseParser
           attributionController:(AMAAttributionController *)attributionController
           metricaConfiguration:(AMAMetricaConfiguration *)metricaConfiguration;

- (void)addAdditionalStartupParameters:(NSDictionary *)parameters;

- (void)update;
- (void)cancel;

@end
