
#import <Foundation/Foundation.h>

@class AMAAppMetricaConfiguration;
@class AMAReporterConfiguration;
@class AMAMetricaConfiguration;
@class AMADataSendingRestrictionController;
@class AMAAppMetricaPreloadInfo;
@class AMADispatchStrategiesContainer;
@protocol AMAAsyncExecuting;
@protocol AMASyncExecuting;
@class AMAConfigForAnonymousActivationProvider;
@class AMAFirstActivationDetector;
@class AMAAppMetricaLibraryAdapterConfiguration;
@protocol AMAPermissionResolvingInput;
@class AMALocationManager;
@protocol AMAAppMetricaConfigurationStoring;

NS_ASSUME_NONNULL_BEGIN

@interface AMAAppMetricaConfigurationManager : NSObject

@property (nonatomic, copy, nullable) AMAAppMetricaPreloadInfo *preloadInfo;
@property (nonatomic, readonly) AMAAppMetricaConfiguration *anonymousConfiguration;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithExecutor:(id<AMAAsyncExecuting, AMASyncExecuting>)executor
             strategiesContainer:(AMADispatchStrategiesContainer *)strategiesContainer
         firstActivationDetector:(AMAFirstActivationDetector *)firstActivationDetector;

- (instancetype)initWithExecutor:(id<AMAAsyncExecuting, AMASyncExecuting>)executor
             strategiesContainer:(AMADispatchStrategiesContainer *)strategiesContainer
            metricaConfiguration:(AMAMetricaConfiguration *)metricaConfiguration
           restrictionController:(AMADataSendingRestrictionController *)restrictionController
         anonymousConfigProvider:(AMAConfigForAnonymousActivationProvider *)anonymousConfigProvider
                 locationManager:(AMALocationManager *)locationManager
                locationResolver:(id<AMAPermissionResolvingInput>)locationResolver
              adProviderResolver:(id<AMAPermissionResolvingInput>)adProviderResolver;


- (void)updateMainConfiguration:(nullable AMAAppMetricaConfiguration *)configuration
               activatedAnonymously:(BOOL)calledFromActivateAnonymous;
- (void)updateReporterConfiguration:(AMAReporterConfiguration *)configuration;
- (void)updateAnonymousConfigurationWithLibraryAdapterConfiguration:(AMAAppMetricaLibraryAdapterConfiguration *)libraryAdapterConfiguration;

@end

NS_ASSUME_NONNULL_END
