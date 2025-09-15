#import <Foundation/Foundation.h>

#import <AppMetricaCore/AppMetricaCore.h>

@protocol AMAKeyValueStoring;
@protocol AMAKeychainStoring;
@protocol AMAIdentifierProviding;

@class AMAPersistentTimeoutConfiguration;
@class AMAMetricaInMemoryConfiguration;
@class AMAAttributionModelConfiguration;
@class AMAExternalAttributionConfiguration;
@class AMAAppMetricaConfiguration;

typedef NSDictionary<AMAAttributionSource, AMAExternalAttributionConfiguration *> AMAExternalAttributionConfigurationMap;

@interface AMAMetricaPersistentConfiguration : NSObject

@property (nonatomic, assign) BOOL hadFirstStartup;
@property (nonatomic, strong) NSDate *startupUpdatedAt;
@property (nonatomic, strong) NSDate *firstStartupUpdateDate;
@property (nonatomic, copy) NSArray *userStartupHosts;

@property (nonatomic, copy, readonly) NSString *deviceID;
@property (nonatomic, copy, readonly) NSString *deviceIDHash;
@property (nonatomic, strong) AMAAttributionModelConfiguration *attributionModelConfiguration;
@property (nonatomic, strong) AMAExternalAttributionConfigurationMap *externalAttributionConfigurations;

@property (nonatomic, strong) NSDate *extensionsLastReportDate;

@property (nonatomic, strong, readonly) AMAPersistentTimeoutConfiguration *timeoutConfiguration;

@property (nonatomic, strong) NSDate *lastPermissionsUpdateDate;

@property (nonatomic, strong) NSDate *registerForAttributionTime;
@property (nonatomic, assign) NSNumber *conversionValue;
@property (nonatomic, assign) BOOL checkedInitialAttribution;
@property (nonatomic, strong) NSDictionary<NSString *, NSNumber *> *eventCountsByKey;
@property (nonatomic, strong) NSDecimalNumber *eventSum;
@property (nonatomic, copy) NSArray<NSString *> *revenueTransactionIds;
@property (nonatomic, copy) NSString *recentMainApiKey;

@property (nonatomic, strong) AMAAppMetricaConfiguration *appMetricaClientConfiguration;

@property (nonatomic, copy) NSDictionary<NSString *, NSNumber *> *autocollectedData;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithStorage:(id<AMAKeyValueStoring>)storage
              identifierManager:(id<AMAIdentifierProviding>)identifierManager
          inMemoryConfiguration:(AMAMetricaInMemoryConfiguration *)inMemoryConfiguration;

@end
