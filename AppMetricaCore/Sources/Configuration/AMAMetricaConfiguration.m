
#import <AppMetricaStorageUtils/AppMetricaStorageUtils.h>
#import <AppMetricaKeychain/AppMetricaKeychain.h>
#import <AppMetricaPlatform/AppMetricaPlatform.h>
#import "AMAMetricaConfiguration.h"
#import "AMAMetricaInMemoryConfiguration.h"
#import "AMAInstantFeaturesConfiguration.h"
#import "AMAMetricaPersistentConfiguration.h"
#import "AMAStartupParametersConfiguration.h"
#import "AMAReporterConfiguration+Internal.h"
#import "AMADatabaseFactory.h"
#import "AMADatabaseProtocol.h"
#import "AMAKeyValueStorageProvidersFactory.h"
#import "AMAAppMetricaUUIDMigrator.h"
#import "AMAAppGroupIdentifierProvider.h"
@import AppMetricaIdentifiers;

// Keychain identifiers
// Declared without `static` keywords (e.g. extern by default) in order to be used in Sample Application
NSString *const kAMAMetricaKeychainAccessGroup = @"io.appmetrica";
NSString *const kAMAMetricaKeychainAppServiceIdentifier = @"io.appmetrica.service.application";
NSString *const kAMAMetricaKeychainGroupServiceIdentifier = @"io.appmetrica.service.group";
NSString *const kAMAMetricaKeychainVendorServiceIdentifier = @"io.appmetrica.service.vendor";
//-----

static NSString *const kAMAMetricaIdentifierLockFileName = @"identifiers.lock";
static NSString *const kAMAMetricaFallbackPrefix = @"fallback-keychain";

@interface AMAMetricaConfiguration ()

@property (nonatomic, strong, readonly) AMAKeychainBridge *keychainBridge;
@property (nonatomic, strong, readonly) id<AMADatabaseProtocol> database;
@property (nonatomic, strong, readonly) id<AMAFileStorage> privateIdentifiersFileStorage;
@property (nonatomic, strong, readonly) id<AMAFileStorage> groupIdentifiersFileStorage;
@property (nonatomic, strong, readonly) NSMutableDictionary *apiConfigs;

@property (nonatomic, strong, readonly) NSObject *reporterConfigurationLock;
@property (nonatomic, strong, readonly) NSObject *startupConfigurationLock;
@property (nonatomic, strong, readonly) NSObject *persistentConfigurationLock;
@property (nonatomic, strong, readonly) NSObject *privateIdentifiersFileStorageLock;
@property (nonatomic, strong, readonly) NSObject *groupIdentifiersFileStorageLock;
@property (nonatomic, strong, readonly) NSObject *identifierProviderLock;

@property (nonatomic, strong, readwrite) AMAStartupParametersConfiguration *startup;
@property (nonatomic, strong, readonly) AMAAppGroupIdentifierProvider *appGroupIdentifierProvider;

@end

@implementation AMAMetricaConfiguration

@synthesize startup = _startup;
@synthesize persistent = _persistent;
@synthesize appConfiguration = _appConfiguration;
@synthesize identifierProvider = _identifierProvider;
@synthesize privateIdentifiersFileStorage = _privateIdentifiersFileStorage;
@synthesize groupIdentifiersFileStorage = _groupIdentifiersFileStorage;

+ (instancetype)sharedInstance
{
    static dispatch_once_t pred;
    static AMAMetricaConfiguration *shared = nil;
    dispatch_once(&pred, ^{
        shared = [[self alloc] init];
    });
    return shared;
}

- (instancetype)init
{
    return [self initWithKeychainBridge:[[AMAKeychainBridge alloc] init]
                               database:AMADatabaseFactory.configurationDatabase
             appGroupIdentifierProvider:[AMAAppGroupIdentifierProvider new]];
}

- (instancetype)initWithKeychainBridge:(AMAKeychainBridge *)keychainBridge
                              database:(id<AMADatabaseProtocol>)database
            appGroupIdentifierProvider:(AMAAppGroupIdentifierProvider*)appGroupIdentifierProvider
{
    self = [super init];
    if (self != nil) {
        _keychainBridge = keychainBridge;
        
        _database = database;
        [_database.storageProvider addBackingKeys:@[
            [NSString stringWithFormat:@"%@-%@", kAMAMetricaFallbackPrefix, [AMAAppMetricaIdentifiersKeys deviceID]],
            [NSString stringWithFormat:@"%@-%@", kAMAMetricaFallbackPrefix, [AMAAppMetricaIdentifiersKeys deviceIDHash]],
        ]];
        
        _inMemory = [[AMAMetricaInMemoryConfiguration alloc] init];
        _apiConfigs = [[NSMutableDictionary alloc] init];
        _appGroupIdentifierProvider = appGroupIdentifierProvider;

        _reporterConfigurationLock = [[NSObject alloc] init];
        _startupConfigurationLock = [[NSObject alloc] init];
        _persistentConfigurationLock = [[NSObject alloc] init];
        _privateIdentifiersFileStorageLock = [[NSObject alloc] init];
        _groupIdentifiersFileStorageLock = [[NSObject alloc] init];
        _identifierProviderLock = [[NSObject alloc] init];
    }
    return self;
}

#pragma mark - Public -

- (id<AMAIdentifierProviding>)identifierProvider
{
    if (_identifierProvider == nil) {
        @synchronized (self.identifierProviderLock) {
            if (_identifierProvider == nil) {
                _identifierProvider = [self createIdentifierProvider];
            }
        }
    }
    return _identifierProvider;
}

- (AMAMetricaPersistentConfiguration *)persistent
{
    if (_persistent == nil) {
        @synchronized (self.persistentConfigurationLock) {
            if (_persistent == nil) {
                id<AMAKeyValueStoring> appDatabase = self.database.storageProvider.cachingStorage;
                
                _persistent = [[AMAMetricaPersistentConfiguration alloc] initWithStorage:appDatabase
                                                                       identifierManager:self.identifierProvider
                                                                   inMemoryConfiguration:self.inMemory];
            }
        }

    }
    return _persistent;
}

- (AMAInstantFeaturesConfiguration *)instant
{
    return [AMAInstantFeaturesConfiguration sharedInstance];
}

- (AMAStartupParametersConfiguration *)startup
{
    if (_startup == nil) {
        @synchronized (self.startupConfigurationLock) {
            if (_startup == nil) {
                NSError *__block error = nil;
                id<AMAKeyValueStoring> storage =
                    [self.database.storageProvider nonPersistentStorageForKeys:[AMAStartupParametersConfiguration allKeys]
                                                                         error:&error];
                if (error != nil) {
                    AMALogError(@"Failed to load startup parameters");
                    storage = self.database.storageProvider.emptyNonPersistentStorage;
                }
                _startup = [[AMAStartupParametersConfiguration alloc] initWithStorage:storage];
            }
        }
    }
    return _startup;
}

- (AMAStartupParametersConfiguration *)startupCopy
{
    NSError *error = nil;
    id<AMAKeyValueStoring> storage = [self.database.storageProvider nonPersistentStorageForStorage:self.startup.storage
                                                                                             error:&error];
    if (error != nil) {
        AMALogAssert(@"Failed to copy startup configuration: %@", error);
        storage = self.database.storageProvider.emptyNonPersistentStorage;
    }
    return [[AMAStartupParametersConfiguration alloc] initWithStorage:storage];
}

- (void)updateStartupConfiguration:(AMAStartupParametersConfiguration *)startup
{
    @synchronized (self.startupConfigurationLock) {
        self.startup = startup;
    }
}

- (void)synchronizeStartup
{
    @synchronized (self.startupConfigurationLock) {
        NSError *__block error = nil;
        [self.database.storageProvider saveStorage:self.startup.storage error:&error];
        if (error != nil) {
            AMALogError(@"Failed to save startup parameters");
        }
    }
}

- (BOOL)persistentConfigurationCreated
{
    return _persistent != nil;
}

- (NSString *)detectedInconsistencyDescription
{
    return self.database.detectedInconsistencyDescription;
}

- (void)resetDetectedInconsistencyDescription
{
    [self.database resetDetectedInconsistencyDescription];
}

- (void)setAppConfiguration:(AMAReporterConfiguration *)appConfiguration
{
    @synchronized (self.reporterConfigurationLock) {
        AMAReporterConfiguration *validConfiguration = [self validConfigurationForConfiguration:appConfiguration];
        AMALogBacktrace(@"Update app config '%@': old: %@, new: %@, validated: %@",
                                appConfiguration.APIKey, _appConfiguration, appConfiguration, validConfiguration);
        _appConfiguration = [validConfiguration copy];
    }
}

- (AMAReporterConfiguration *)configurationForApiKey:(NSString *)apiKey
{
    AMAReporterConfiguration *configuration = nil;
    @synchronized (self.reporterConfigurationLock) {
        if ([self.appConfiguration.APIKey isEqual:apiKey]) {
            configuration = self.appConfiguration;
        }
        else {
            configuration = [self manualConfigurationForApiKey:apiKey];
        }
    }
    return configuration;
}

- (void)setConfiguration:(AMAReporterConfiguration *)configuration
{
    if (configuration == nil) {
        return;
    }
    @synchronized (self.reporterConfigurationLock) {
        AMAReporterConfiguration *validConfiguration = [self validConfigurationForConfiguration:configuration];
        if ([self.appConfiguration.APIKey isEqual:configuration.APIKey]) {
            self.appConfiguration = [validConfiguration copy];
        }
        else {
            AMALogInfo(@"Update reporter config: old: %@, new: %@, validated: %@",
                               _apiConfigs[configuration.APIKey], configuration, validConfiguration);
            _apiConfigs[configuration.APIKey] = [validConfiguration copy];
        }
    }
}

- (AMAReporterConfiguration *)appConfiguration
{
    @synchronized (self.reporterConfigurationLock) {
        if (_appConfiguration == nil) {
            AMAMutableReporterConfiguration *newConfiguration =
                [[AMAMutableReporterConfiguration alloc] initWithoutAPIKey];
            newConfiguration.maxReportsCount = kAMAAutomaticReporterDefaultMaxReportsCount;
            newConfiguration.dispatchPeriod = kAMADefaultDispatchPeriodSeconds;
            newConfiguration.sessionTimeout = kAMASessionValidIntervalInSecondsDefault;
            AMALogInfo(@"Create new empty app config: %@", newConfiguration);
            _appConfiguration = [newConfiguration copy];
        }
        return _appConfiguration;
    }
}

- (void)handleMainApiKey:(NSString *)apiKey
{
    [self.database migrateToMainApiKey:apiKey];
}

- (void)ensureMigrated
{
    [self.database ensureMigrated];
}

- (id<AMAKeyValueStoring>)UUIDOldStorage
{
    [self ensureMigrated];
    return self.database.storageProvider.cachingStorage;
}

#pragma mark - Private -

- (AMAIdentifierProviderConfiguration*)createIdentifierProviderConfiguration
{
    id<AMAKeyValueStoring> appDatabase = self.database.storageProvider.cachingStorage;
    
    AMAIdentifierProviderConfiguration *config =
        [[AMAIdentifierProviderConfiguration alloc] initWithPrivateKeychain:[self privateKeychain]
                                                         privateFileStorage:self.privateIdentifiersFileStorage
        ];
    AMAAppMetricaUUIDMigrator *migrator = [AMAAppMetricaUUIDMigrator new];
    
    if ([AMAPlatformDescription isExtension] == NO) {
        config.appDatabase = appDatabase;
    }
    config.uuidMigration = migrator;
    config.vendorKeychain = [self vendorKeychain];
    config.groupKeychain = [self groupKeychain];
    config.groupFileStorage = self.groupIdentifiersFileStorage;
    config.groupLockFilePath = [self groupLockPath];
    
    return config;
}

- (id<AMAIdentifierProviding>)createIdentifierProvider
{
    AMAIdentifierProviderConfiguration *config = [self createIdentifierProviderConfiguration];
    
    id<AMAIdentifierProviding> provider =
        [[AMAIdentifierProvider alloc] initWithConfig:config
                                                  env:[AMAPlatformDescription runEnvronment]
        ];
    return provider;
}

- (AMAKeychain *)privateKeychain
{
    return [[AMAKeychain alloc] initWithService:kAMAMetricaKeychainAppServiceIdentifier
                                    accessGroup:@""
                                         bridge:self.keychainBridge];;
}

- (AMAKeychain *)vendorKeychain
{
    // Apps that are built for the simulator aren't signed, so there's no keychain access group
    // for the simulator to check. This means that all apps can see all keychain items when run
    // on the simulator.
#if !TARGET_IPHONE_SIMULATOR
    NSString *appIdentifier = [AMAPlatformDescription appIdentifierPrefix];
    if (appIdentifier.length == 0) {
        return nil;
    }
    NSString *accessGroup = [appIdentifier stringByAppendingString:kAMAMetricaKeychainAccessGroup];
#else
    NSString *accessGroup = @"";
#endif
    AMAKeychain *vendorKeychain = [[AMAKeychain alloc] initWithService:kAMAMetricaKeychainVendorServiceIdentifier
                                                           accessGroup:accessGroup
                                                                bridge:self.keychainBridge];
    if (vendorKeychain.isAvailable == NO) {
        return nil;
    }

    return vendorKeychain;
}

- (id<AMAFileStorage>)privateIdentifiersFileStorage
{
    if (_privateIdentifiersFileStorage == nil) {
        @synchronized (self.privateIdentifiersFileStorageLock) {
            if (_privateIdentifiersFileStorage == nil) {
                NSString *appDir = [AMAFileUtility persistentPath];
                NSString *identifiersPath = [appDir stringByAppendingPathComponent:@"identifiers.json"];
                _privateIdentifiersFileStorage = 
                    [[AMADiskFileStorage alloc] initWithPath:identifiersPath
                                                     options:AMADiskFileStorageOptionNoBackup|AMADiskFileStorageOptionCreateDirectory];
            }
        }
    }

    return _privateIdentifiersFileStorage;
}

- (NSString *)groupLockPath
{
    NSString *appGroupId = self.appGroupIdentifierProvider.appGroupIdentifier;
    if (appGroupId.length == 0) {
        return nil;
    }

    NSString *sharedDir = [AMAFileUtility persistentPathForApplicationGroup:appGroupId];
    [AMAFileUtility createPathIfNeeded:sharedDir];
    NSString *lockPath = [sharedDir stringByAppendingPathComponent:kAMAMetricaIdentifierLockFileName];
    return lockPath;
}

- (id<AMAFileStorage>)groupIdentifiersFileStorage
{
    NSString *appGroupId = self.appGroupIdentifierProvider.appGroupIdentifier;
    if (appGroupId.length == 0) {
        return nil;
    }

    if (_groupIdentifiersFileStorage == nil) {
        @synchronized (self.groupIdentifiersFileStorageLock) {
            if (_groupIdentifiersFileStorage == nil) {
                NSString *sharedDir = [AMAFileUtility persistentPathForApplicationGroup:appGroupId];
                [AMAFileUtility createPathIfNeeded:sharedDir];
                NSString *identifiersPath = [sharedDir stringByAppendingPathComponent:@"identifiers.json"];
                _groupIdentifiersFileStorage = [[AMADiskFileStorage alloc] initWithPath:identifiersPath
                                                                        options:AMADiskFileStorageOptionNoBackup|AMADiskFileStorageOptionCreateDirectory];
            }
        }
    }
    
    return _groupIdentifiersFileStorage;
}

- (AMAKeychain *)groupKeychain
{
    NSString *appGroupId = self.appGroupIdentifierProvider.appGroupIdentifier;
    if (appGroupId.length == 0) {
        return nil;
    }
#if !TARGET_IPHONE_SIMULATOR
    NSString *appIdentifier = [AMAPlatformDescription appIdentifierPrefix];
    if (appIdentifier.length == 0) {
        return nil;
    }
    NSString *accessGroup = [appIdentifier stringByAppendingString:appGroupId];
#else
    NSString *accessGroup = appGroupId;
#endif

    AMAKeychain *groupKeychain = [[AMAKeychain alloc] initWithService:kAMAMetricaKeychainGroupServiceIdentifier
                                                          accessGroup:accessGroup
                                                               bridge:self.keychainBridge];
    if (groupKeychain.isAvailable == NO) {
        return nil;
    }
    
    return groupKeychain;
}

- (AMAReporterConfiguration *)manualConfigurationForApiKey:(NSString *)apiKey
{
    if (apiKey == nil) {
        return nil;
    }

    if (_apiConfigs[apiKey] == nil) {
        _apiConfigs[apiKey] = [[AMAReporterConfiguration alloc] initWithAPIKey:apiKey];
        AMALogInfo(@"Create new empty reporter config: %@", _apiConfigs[apiKey]);
    }
    return [_apiConfigs[apiKey] copy];
}

- (AMAReporterConfiguration *)validConfigurationForConfiguration:(AMAReporterConfiguration *)configuration
{
    if (configuration == nil) {
        return nil;
    }
    AMAReporterConfiguration *validConfiguration = configuration;

    if (configuration.sessionTimeout < kAMAMinSessionTimeoutInSeconds) {
        AMALogWarn(@"Can't set session timeout to %lu seconds; Minimum session timeout %lu",
                           (unsigned long)configuration.sessionTimeout, (unsigned long)kAMAMinSessionTimeoutInSeconds);
        AMAMutableReporterConfiguration *mutableConfiguration = [configuration mutableCopy];
        mutableConfiguration.sessionTimeout = kAMAMinSessionTimeoutInSeconds;
        validConfiguration = [mutableConfiguration copy];
    }

    if (configuration.maxReportsInDatabaseCount < kAMAMinValueOfMaxReportsInDatabaseCount) {
        AMALogWarn(@"Can't set max reports in database count to %lu; Minimum allowed value is %lu",
                           (unsigned long)configuration.maxReportsInDatabaseCount,
                           (unsigned long)kAMAMinValueOfMaxReportsInDatabaseCount);
        AMAMutableReporterConfiguration *mutableConfiguration = [configuration mutableCopy];
        mutableConfiguration.maxReportsInDatabaseCount = kAMAMinValueOfMaxReportsInDatabaseCount;
        validConfiguration = [mutableConfiguration copy];
    }
    else if (configuration.maxReportsInDatabaseCount > kAMAMaxValueOfMaxReportsInDatabaseCount) {
        AMALogWarn(@"Can't set max reports in database count to %lu; Maximum allowed value is %lu",
                           (unsigned long)configuration.maxReportsInDatabaseCount,
                           (unsigned long)kAMAMaxValueOfMaxReportsInDatabaseCount);
        AMAMutableReporterConfiguration *mutableConfiguration = [configuration mutableCopy];
        mutableConfiguration.maxReportsInDatabaseCount = kAMAMaxValueOfMaxReportsInDatabaseCount;
        validConfiguration = [mutableConfiguration copy];
    }

    return validConfiguration;
}

@end
