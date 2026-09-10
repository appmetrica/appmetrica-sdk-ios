#import <Foundation/Foundation.h>

#import <AppMetricaCore/AppMetricaCore.h>

@protocol AMAKeyValueStoring;
@protocol AMAKeychainStoring;
@protocol AMAAppMetricaConfigurationStoring;

@class AMAPersistentTimeoutConfiguration;
@class AMAMetricaInMemoryConfiguration;
@class AMAAttributionModelConfiguration;
@class AMAExternalAttributionConfiguration;
@class AMAAppMetricaConfigurationSnapshot;
@class AMAModulesStatusReportState;

typedef NSDictionary<AMAAttributionSource, AMAExternalAttributionConfiguration *> AMAExternalAttributionConfigurationMap;

NS_ASSUME_NONNULL_BEGIN

@interface AMAMetricaPersistentConfiguration : NSObject

@property (nonatomic, assign) BOOL hadFirstStartup;
@property (nonatomic, strong, nullable) NSDate *startupUpdatedAt;
@property (nonatomic, strong, nullable) NSDate *firstStartupUpdateDate;
@property (nonatomic, copy, nullable) NSArray *userStartupHosts;
@property (nonatomic, copy, nullable) NSArray *libraryAdapterCustomHosts;

@property (nonatomic, strong, nullable) AMAAttributionModelConfiguration *attributionModelConfiguration;
@property (nonatomic, strong, nullable) AMAExternalAttributionConfigurationMap *externalAttributionConfigurations;

@property (nonatomic, strong, nullable) NSDate *extensionsLastReportDate;

@property (nonatomic, strong, readonly) AMAPersistentTimeoutConfiguration *timeoutConfiguration;

@property (nonatomic, strong, nullable) NSDate *lastPermissionsUpdateDate;

@property (nonatomic, strong, nullable) NSDate *registerForAttributionTime;
@property (nonatomic, assign, nullable) NSNumber *conversionValue;
@property (nonatomic, assign) BOOL checkedInitialAttribution;
@property (nonatomic, strong, nullable) NSDictionary<NSString *, NSNumber *> *eventCountsByKey;
@property (nonatomic, strong, nullable) NSDecimalNumber *eventSum;
@property (nonatomic, copy, nullable) NSArray<NSString *> *revenueTransactionIds;
@property (nonatomic, copy, nullable) NSString *recentMainApiKey;

@property (nonatomic, copy, nullable) NSDictionary<NSString *, NSNumber *> *autocollectedData;

@property (nonatomic, copy, nullable) AMAModulesStatusReportState *modulesStatusReportState;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithStorage:(id<AMAKeyValueStoring>)storage
          inMemoryConfiguration:(AMAMetricaInMemoryConfiguration *)inMemoryConfiguration
 appMetricaConfigurationStorage:(id<AMAAppMetricaConfigurationStoring>)appMetricaConfigurationStoring;

- (nullable AMAAppMetricaConfigurationSnapshot *)appMetricaClientConfigurationSnapshot;
- (void)saveAppMetricaClientConfigurationSnapshot:(AMAAppMetricaConfigurationSnapshot *)snapshot;
- (void)clearAppMetricaClientConfigurationSnapshot:(AMAAppMetricaConfigurationSnapshot *)snapshot;

@end

NS_ASSUME_NONNULL_END
