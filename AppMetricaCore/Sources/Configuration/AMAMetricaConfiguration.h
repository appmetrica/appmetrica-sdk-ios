
#import <Foundation/Foundation.h>

@class AMAReporterConfiguration;
@class AMAInstantFeaturesConfiguration;
@class AMAStartupParametersConfiguration;
@class AMAMetricaPersistentConfiguration;
@class AMAMetricaInMemoryConfiguration;
@class AMAKeychainBridge;
@class AMAAppGroupIdentifierProvider;
@protocol AMADatabaseProtocol;
@protocol AMAKeyValueStoring;
@protocol AMAIdentifierProviding;
@protocol AMAKeyValueStorageProviding;
@protocol AMAAppMetricaConfigurationStoring;

@interface AMAMetricaConfiguration : NSObject

@property (atomic, copy) AMAReporterConfiguration *appConfiguration;

@property (nonatomic, strong, readonly) AMAMetricaInMemoryConfiguration *inMemory;
@property (nonatomic, strong, readonly) AMAStartupParametersConfiguration *startup;
@property (nonatomic, strong, readonly) AMAMetricaPersistentConfiguration *persistent;
@property (nonatomic, strong, readonly) AMAInstantFeaturesConfiguration *instant;
@property (nonatomic, strong, readonly) id<AMAKeyValueStoring> UUIDOldStorage;
@property (nonatomic, strong, readonly) id<AMAIdentifierProviding> identifierProvider;
@property (nonatomic, strong, readonly) AMAAppGroupIdentifierProvider *appGroupIdentifierProvider;

@property (atomic, assign, readonly) BOOL persistentConfigurationCreated;

- (instancetype)initWithKeychainBridge:(AMAKeychainBridge *)keychainBridge
                              database:(id<AMADatabaseProtocol>)database
            appGroupIdentifierProvider:(AMAAppGroupIdentifierProvider*)appGroupIdentifierProvider
        appMetricaConfigurationStorage:(id<AMAAppMetricaConfigurationStoring>)appMetricaConfigurationStorage;

- (AMAStartupParametersConfiguration *)startupCopy;
- (void)updateStartupConfiguration:(AMAStartupParametersConfiguration *)startup;
- (void)synchronizeStartup;

- (AMAReporterConfiguration *)configurationForApiKey:(NSString *)apiKey;
- (void)setConfiguration:(AMAReporterConfiguration *)configuration;

- (void)handleMainApiKey:(NSString *)apiKey;
- (void)ensureMigrated;
- (NSString *)detectedInconsistencyDescription;
- (void)resetDetectedInconsistencyDescription;
- (id<AMAKeyValueStorageProviding>)storageProvider;

+ (instancetype)sharedInstance;

@end
