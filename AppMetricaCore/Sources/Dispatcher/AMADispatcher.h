
#import <Foundation/Foundation.h>

@protocol AMADispatcherDelegate;
@protocol AMAAsyncExecuting;
@protocol AMAReportsControlling;
@class AMAReporterStorage;
@class AMATimeoutRequestsController;
@class AMAMetricaConfiguration;

@interface AMADispatcher : NSObject

@property (nonatomic, weak) id<AMADispatcherDelegate> delegate;
@property (nonatomic, copy, readonly) NSString *apiKey;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithReporterStorage:(AMAReporterStorage *)reporterStorage
                                   main:(BOOL)main
                reportTimeoutController:(AMATimeoutRequestsController *)reportTimeoutController
              trackingTimeoutController:(AMATimeoutRequestsController *)trackingTimeoutController;

- (instancetype)initWithReporterStorage:(AMAReporterStorage *)reporterStorage
                                   main:(BOOL)main
                                executor:(id<AMAAsyncExecuting>)executor
                      reportsController:(id<AMAReportsControlling>)reportsController;

- (instancetype)initWithReporterStorage:(AMAReporterStorage *)reporterStorage
                                   main:(BOOL)main
                reportTimeoutController:(AMATimeoutRequestsController *)reportTimeoutController
              trackingTimeoutController:(AMATimeoutRequestsController *)trackingTimeoutController
                   metricaConfiguration:(AMAMetricaConfiguration *)metricaConfiguration;

- (instancetype)initWithReporterStorage:(AMAReporterStorage *)reporterStorage
                                   main:(BOOL)main
                               executor:(id<AMAAsyncExecuting>)executor
                      reportsController:(id<AMAReportsControlling>)reportsController
                   metricaConfiguration:(AMAMetricaConfiguration *)metricaConfiguration;

- (void)cancelPending;
- (void)performReport;

@end
