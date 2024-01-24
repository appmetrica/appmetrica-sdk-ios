
#import <Foundation/Foundation.h>

@protocol AMAAsyncExecuting;
@protocol AMAResettableIterable;
@class AMAHTTPRequestsFactory;
@class AMAReportRequest;
@class AMAReportsController;
@class AMAReportResponseParser;
@class AMAReportRequestModel;
@class AMAIncrementableValueStorage;
@class AMAReportPayloadProvider;
@class AMATimeoutRequestsController;
@class AMAReportHostProvider;

extern NSErrorDomain const kAMAReportsControllerErrorDomain;

typedef NS_ERROR_ENUM(kAMAReportsControllerErrorDomain, AMAReportsControllerErrorCode) {
    AMAReportsControllerErrorOther,
    AMAReportsControllerErrorJsonStatusUnknown,
    AMAReportsControllerErrorBadRequest,
    AMAReportsControllerErrorRequestEntityTooLarge,
    AMAReportsControllerErrorTimeout,
};

@protocol AMAReportsControllerDelegate <NSObject>

@required
- (NSString *)reportsControllerNextRequestIdentifier;

- (void)reportsControllerDidFinishWithSuccess:(AMAReportsController *)controller;

- (void)reportsController:(AMAReportsController *)controller didReportRequest:(AMAReportRequestModel *)requestModel;
- (void)reportsController:(AMAReportsController *)controller
           didFailRequest:(AMAReportRequestModel *)requestModel
                withError:(NSError *)error;

@end

@interface AMAReportsController : NSObject

@property (nonatomic, weak) id<AMAReportsControllerDelegate> delegate;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithExecutor:(id<AMAAsyncExecuting>)executor
       timeoutRequestsController:(AMATimeoutRequestsController *)timeoutRequestsController;
- (instancetype)initWithExecutor:(id<AMAAsyncExecuting>)executor
                    hostProvider:(id<AMAResettableIterable>)hostProvider
             httpRequestsFactory:(AMAHTTPRequestsFactory *)httpRequestsFactory
                  responseParser:(AMAReportResponseParser *)responseParser
                 payloadProvider:(AMAReportPayloadProvider *)payloadProvider
       timeoutRequestsController:(AMATimeoutRequestsController *)timeoutRequestsController;

- (void)reportRequestModelsFromArray:(NSArray<AMAReportRequestModel *> *)requestModels;
- (void)cancelPendingRequests;

@end
