#import "AMACore.h"

#import <UIKit/UIKit.h>

#import <AppMetricaStorageUtils/AppMetricaStorageUtils.h>
#import <AppMetricaKeychain/AppMetricaKeychain.h>

#import "AMAMetricaPersistentConfiguration.h"
#import "AMAStorageKeys.h"
#import "AMAPersistentTimeoutConfiguration.h"
#import "AMAAttributionModelConfiguration.h"
#import "AMAExternalAttributionConfiguration.h"
#import "AMAAppMetricaConfiguration+JSONSerializable.h"

@import AppMetricaIdentifiers;

static NSString *const kAMADeviceIDDefaultValue = @"";

@interface AMAMetricaPersistentConfiguration ()

@property (nonatomic, strong, readonly) id<AMAKeyValueStoring> storage;
@property (nonatomic, strong, readonly) id<AMAIdentifierProviding> identifierManager;
@property (nonatomic, strong, readonly) AMAMetricaInMemoryConfiguration *inMemoryConfiguration;

@end

@implementation AMAMetricaPersistentConfiguration

- (instancetype)initWithStorage:(id<AMAKeyValueStoring>)storage
              identifierManager:(id<AMAIdentifierProviding>)identifierManager
          inMemoryConfiguration:(AMAMetricaInMemoryConfiguration *)inMemoryConfiguration
{
    self = [super init];
    if (self != nil) {
        _storage = storage;
        _identifierManager = identifierManager;
        _inMemoryConfiguration = inMemoryConfiguration;

        _timeoutConfiguration = [[AMAPersistentTimeoutConfiguration alloc] initWithStorage:_storage];
    }
    return self;
}

- (NSString *)deviceID
{
    return self.identifierManager.deviceID;
}

- (NSString *)deviceIDHash
{
    return self.identifierManager.deviceIDHash;
}

- (NSArray *)userStartupHosts
{
    // If this logic is needed here more than once, unify it with
    // `- [AMAStartupParametersConfiguration jsonArrayForKey:valueClass:onError]`
    NSArray *hosts = [self.storage jsonArrayForKey:AMAStorageStringKeyUserStartupHosts error:nil];
    for (NSString *host in hosts) {
        if ([host isKindOfClass:[NSString class]] == NO) {
            return nil;
        }
    }
    return hosts;
}

- (void)setUserStartupHosts:(NSArray *)value
{
    [self.storage saveJSONArray:value forKey:AMAStorageStringKeyUserStartupHosts error:nil];
}

#define PROPERTY_FOR_TYPE(returnType, getter, setter, key, storageGetter, storageSetter, setOnce) \
- (returnType *)getter { \
    return [self.storage storageGetter:key error:NULL]; \
} \
- (void)setter:(returnType *)value { \
    if (setOnce && self.getter != nil) return; \
    [self.storage storageSetter:value forKey:key error:NULL]; \
}

#define BOOL_PROPERTY(getter, setter, key) \
- (BOOL)getter { \
    return [self.storage boolNumberForKey:key error:NULL].boolValue; \
} \
- (void)setter:(BOOL)value { \
    [self.storage saveBoolNumber:@(value) forKey:key error:nil]; \
}

#define DATE_PROPERTY(getter, setter, key) PROPERTY_FOR_TYPE(NSDate, getter, setter, key, dateForKey, saveDate, NO)
#define LONG_PROPERTY(getter, setter, key) PROPERTY_FOR_TYPE(NSNumber, getter, setter, key, longLongNumberForKey, saveLongLongNumber, NO)

#define DATE_SET_ONCE_PROPERTY(getter, setter, key) PROPERTY_FOR_TYPE(NSDate, getter, setter, key, dateForKey, saveDate, YES)

BOOL_PROPERTY(hadFirstStartup, setHadFirstStartup, AMAStorageStringKeyHadFirstStartup);
BOOL_PROPERTY(checkedInitialAttribution, setCheckedInitialAttribution, AMAStorageStringKeyCheckedInitialAttribution);

DATE_SET_ONCE_PROPERTY(firstStartupUpdateDate, setFirstStartupUpdateDate, AMAStorageStringKeyFirstStartupUpdateDate);
DATE_PROPERTY(startupUpdatedAt, setStartupUpdatedAt, AMAStorageStringKeyStartupUpdatedAt);
DATE_PROPERTY(extensionsLastReportDate, setExtensionsLastReportDate, AMAStorageStringKeyExtensionsLastReportDate);
DATE_PROPERTY(lastPermissionsUpdateDate, setLastPermissionsUpdateDate, AMAStorageStringKeyPermissionsLastUpdateDate);
DATE_PROPERTY(registerForAttributionTime, setRegisterForAttributionTime, AMAStorageStringKeyRegisterForAttributionTime);

LONG_PROPERTY(conversionValue, setConversionValue, AMAStorageStringKeyConversionValue);

- (NSDictionary<NSString *, NSNumber *> *)eventCountsByKey
{
    return [self.storage jsonDictionaryForKey:AMAStorageStringKeyEventCountsByKey error:nil];
}

- (void)setEventCountsByKey:(NSDictionary<NSString *, NSNumber *> *)value
{
    [self.storage saveJSONDictionary:value forKey:AMAStorageStringKeyEventCountsByKey error:nil];
}

- (NSDecimalNumber *)eventSum
{
    return [AMADecimalUtils decimalNumberWithString:[self.storage stringForKey:AMAStorageStringKeyEventsSum error:nil]
                                                 or:[NSDecimalNumber zero]];
}

- (void)setEventSum:(NSDecimalNumber *)value
{
    [self.storage saveString:value.stringValue forKey:AMAStorageStringKeyEventsSum error:nil];
}

- (NSArray<NSString *> *)revenueTransactionIds
{
    NSArray *ids = [self.storage jsonArrayForKey:AMAStorageStringKeyRevenueTransactionIds error:nil];
    for (id transactionID in ids) {
        if ([transactionID isKindOfClass:NSString.class] == NO) {
            return nil;
        }
    }
    return ids;
}

- (void)setRevenueTransactionIds:(NSArray<NSString *> *)revenueTransactionIds
{
    [self.storage saveJSONArray:revenueTransactionIds forKey:AMAStorageStringKeyRevenueTransactionIds error:nil];
}

- (AMAAttributionModelConfiguration *)attributionModelConfiguration
{
    NSDictionary *json = [self.storage jsonDictionaryForKey:AMAStorageStringKeyAttributionModel error:NULL];
    return [[AMAAttributionModelConfiguration alloc] initWithJSON:json];
}

- (void)setAttributionModelConfiguration:(AMAAttributionModelConfiguration *)attributionModel
{
    [self.storage saveJSONDictionary:[attributionModel JSON] forKey:AMAStorageStringKeyAttributionModel error:NULL];
}

- (AMAExternalAttributionConfigurationMap *)externalAttributionConfigurations
{
    NSDictionary *allConfigurationsJSON =
        [self.storage jsonDictionaryForKey:AMAStorageStringKeyExternalAttributionConfiguration error:NULL];
    
    if (allConfigurationsJSON.count == 0) {
        return nil;
    }

    NSDictionary *configurations =
        [AMACollectionUtilities compactMapValuesOfDictionary:allConfigurationsJSON
                                                   withBlock:^id(AMAAttributionSource key, NSDictionary *json) {
        AMAExternalAttributionConfiguration *attribution = [[AMAExternalAttributionConfiguration alloc] initWithJSON:json];
        return attribution;
    }];
    
    return configurations;
}

- (void)setExternalAttributionConfigurations:(AMAExternalAttributionConfigurationMap *)configurations
{
    NSDictionary *allConfigurationsJSON =
        [AMACollectionUtilities compactMapValuesOfDictionary:configurations
                                                   withBlock:^id(AMAAttributionSource key, AMAExternalAttributionConfiguration *attribution) {
        return [attribution JSON];
    }];

    allConfigurationsJSON = allConfigurationsJSON.count == 0 ? nil : allConfigurationsJSON;

    [self.storage saveJSONDictionary:allConfigurationsJSON
                              forKey:AMAStorageStringKeyExternalAttributionConfiguration
                               error:NULL];
}

- (AMAAppMetricaConfiguration *)appMetricaClientConfiguration
{
    NSDictionary *json = [self.storage jsonDictionaryForKey:AMAStorageStringKeyAppMetricaClientConfiguration error:NULL];
    return [[AMAAppMetricaConfiguration alloc] initWithJSON:json];
}

- (void)setAppMetricaClientConfiguration:(AMAAppMetricaConfiguration *)appMetricaClientConfiguration
{
    [self.storage saveJSONDictionary:[appMetricaClientConfiguration JSON]
                              forKey:AMAStorageStringKeyAppMetricaClientConfiguration
                               error:NULL];
}

- (NSString *)recentMainApiKey
{
    return [self.storage stringForKey:AMAStorageStringKeyRecentMainApiKey error:NULL];
}

- (void)setRecentMainApiKey:(NSString *)recentMainApiKey
{
    [self.storage saveString:recentMainApiKey
                      forKey:AMAStorageStringKeyRecentMainApiKey
                       error:NULL];
}

- (NSDictionary<NSString *, NSNumber *> *)autocollectedData
{
    return [self.storage jsonDictionaryForKey:AMAStorageStringKeyAutocollectedData error:nil];
}

- (void)setAutocollectedData:(NSDictionary<NSString *, NSNumber *> *)value
{
    [self.storage saveJSONDictionary:value forKey:AMAStorageStringKeyAutocollectedData error:nil];
}

@end
