
#import <Foundation/Foundation.h>

@protocol AMAKeyValueStoring;
@protocol AMAKeychainStoring;

@class AMAPersistentTimeoutConfiguration;
@class AMAMetricaInMemoryConfiguration;
@class AMAAttributionModelConfiguration;

extern NSString *const kAMADeviceIDStorageKey;
extern NSString *const kAMADeviceIDHashStorageKey;

@interface AMAMetricaPersistentConfiguration : NSObject

@property (nonatomic, assign) BOOL hadFirstStartup;
@property (nonatomic, strong) NSDate *startupUpdatedAt;
@property (nonatomic, strong) NSDate *firstStartupUpdateDate;
@property (nonatomic, copy) NSArray *userStartupHosts;

@property (nonatomic, copy) NSString *deviceID;
@property (nonatomic, copy) NSString *deviceIDHash;
@property (nonatomic, strong) AMAAttributionModelConfiguration *attributionModelConfiguration;

@property (nonatomic, strong) NSDate *extensionsLastReportDate;

@property (nonatomic, strong, readonly) AMAPersistentTimeoutConfiguration *timeoutConfiguration;

@property (nonatomic, strong) NSDate *lastPermissionsUpdateDate;

@property (nonatomic, strong) NSDate *registerForAttributionTime;
@property (nonatomic, assign) NSNumber *conversionValue;
@property (nonatomic, assign) BOOL checkedInitialAttribution;
@property (nonatomic, strong) NSDictionary<NSString *, NSNumber *> *eventCountsByKey;
@property (nonatomic, strong) NSDecimalNumber *eventSum;
@property (nonatomic, copy) NSArray<NSString *> *revenueTransactionIds;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithStorage:(id<AMAKeyValueStoring>)storage
                       keychain:(id<AMAKeychainStoring>)keychain
          inMemoryConfiguration:(AMAMetricaInMemoryConfiguration *)inMemoryConfiguration;

@end
