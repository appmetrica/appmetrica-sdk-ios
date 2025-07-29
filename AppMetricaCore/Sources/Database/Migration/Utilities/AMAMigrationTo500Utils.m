
#import <AppMetricaKeychain/AppMetricaKeychain.h>
#import "AMAMigrationTo500Utils.h"
#import "AMATableDescriptionProvider.h"
#import "AMAStorageKeys.h"
#import "AMADatabaseProtocol.h"
#import "AMADatabaseConstants.h"
#import <AppMetricaFMDB/AppMetricaFMDB.h>
#import "AMADatabaseHelper.h"
#import "AMAReporterStoragesContainer.h"
#import "AMAReporterStorage.h"
#import "AMAEvent.h"
#import "AMALegacyEventExtrasProvider.h"
#import "AMAMetricaConfiguration.h"
#import "AMAMetricaPersistentConfiguration.h"
#import "AMAEventNameHashesStorage.h"
#import "AMAEventStorage+Migration.h"
#import "AMAEventSerializer+Migration.h"
#import "AMAInstantFeaturesConfiguration+Migration.h"
#import "AMAEventNameHashesStorageFactory+Migration.h"
#import "AMAReporterDatabaseEncodersFactory.h"
#import "AMAReporterDatabaseMigrationTo5100EncodersFactory.h"
#import "AMAReporterDatabaseMigrationTo500EncodersFactory.h"
#import "AMAMetricaPersistentConfiguration.h"
#import <AppMetricaPlatform/AppMetricaPlatform.h>
#import "AMAKeyValueStorageProvidersFactory.h"
#import "AMADatabaseObjectProvider.h"
#import "AMAStringDatabaseKeyValueStorageConverter.h"
#import "AMAJSONFileKVSDataProvider.h"
#import "AMALocationMigrationTo500EncoderFactory.h"
#import "AMALocationMigrationTo5100EncoderFactory.h"
#import "AMADatabaseFactory.h"

@import AppMetricaIdentifiers;

NSString *const kAMAMigrationBundle = @"ru.yandex.mobile.YandexMobileMetrica";

NSString *const kAMAMigrationKeychainAccessGroup = @"com.yandex.mobile.appmetrica";
NSString *const kAMAMigrationKeychainAppServiceIdentifier = @"com.yandex.mobile.appmetrica.service.application";
NSString *const kAMAMigrationKeychainVendorServiceIdentifier = @"com.yandex.mobile.appmetrica.service.vendor";

NSString *const kAMAMigrationDeviceIDStorageKey = @"YMMMetricaPersistentConfigurationDeviceIDStorageKey";
NSString *const kAMAMigrationDeviceIDHashStorageKey = @"YMMMetricaPersistentConfigurationDeviceIDHashStorageKey";

@implementation AMAMigrationTo500Utils

+ (NSString *)migrationPath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *basePath = [paths firstObject];
    NSString *path = [basePath stringByAppendingPathComponent:kAMAMigrationBundle];
    return path;
}

+ (void)migrateTable:(NSString *)tableName
         tableScheme:(NSArray *)tableScheme
            sourceDB:(AMAFMDatabase *)sourceDB
       destinationDB:(AMAFMDatabase *)destinationDB
{
    NSMutableArray *columns = [NSMutableArray array];
    NSMutableArray *valueQuestions = [NSMutableArray array];
    for (NSDictionary *field in tableScheme) {
        [columns addObject:field[kAMASQLName]];
        [valueQuestions addObject:@"?"];
    }
    NSString *joined = [columns componentsJoinedByString:@", "];
    NSString *selectQuery = [NSString stringWithFormat:@"SELECT %@ FROM %@;", joined, tableName];
    AMAFMResultSet *resultSet = [sourceDB executeQuery:selectQuery];
    
    NSString *insertQuery = [NSString stringWithFormat:@"INSERT INTO %@ (%@) VALUES (%@);",
                             tableName, joined, [valueQuestions componentsJoinedByString:@", "]];
    
    while ([resultSet next]) {
        NSNumber *encryptionValue = nil;
        
        NSMutableArray *columnValues = [NSMutableArray array];
        for (NSString *columnName in columns) {
            id columnValue = [resultSet objectForColumn:columnName];
            
            if ([columnName isEqual:kAMACommonTableFieldDataEncryptionType]) {
                encryptionValue = columnValue;
            }
            else if ([columnName isEqual:kAMACommonTableFieldData]) {
                columnValue = [self migrationDataForTable:tableName data:columnValue encryptionValue:encryptionValue];
            }
            
            columnValue = [self fallbackKeychainMapping][columnValue] ?: columnValue;
            
            [columnValues addObject:(columnValue ?: [NSNull null])];
        }
        
        BOOL insertSuccess = [destinationDB executeUpdate:insertQuery withArgumentsInArray:columnValues];
        if (insertSuccess == NO) {
            AMALogWarn(@"Failed to insert values into table at path: %@ error: %@",
                       destinationDB.databasePath, [destinationDB lastErrorMessage]);
        }
    }
    [resultSet close];
}

+ (void)migrateReporterEvents:(AMAFMDatabase *)sourceDB
                destinationDB:(AMAFMDatabase *)destinationDB
                       apiKey:(NSString *)apiKey
{
    AMAEventSerializer *migrationSerializer = [[AMAEventSerializer alloc] migrationTo500Init];
    
    NSArray<AMAEvent*> *reporterEvents = [self getEventsInDB:sourceDB eventSerializer:migrationSerializer];
    
    NSString *legacyExtrasKey = @"ai";
    NSData *legacyExtras = [AMALegacyEventExtrasProvider legacyExtrasData:sourceDB];

    if (legacyExtras != nil) {
        [self addExtrasToEvents:reporterEvents extras:@{ legacyExtrasKey : legacyExtras }];

        id<AMAAppMetricaExtendedReporting> reporter = [AMAAppMetrica extendedReporterForApiKey:apiKey];
        [reporter setSessionExtras:legacyExtras forKey:legacyExtrasKey];
    }
    
    [self saveReporterEvents:reporterEvents db:destinationDB];
}

+ (void)migrateReporterEventHashes:(NSString *)migrationPath apiKey:(NSString *)apiKey
{
    AMAEventNameHashesStorage *migrationStorage = [AMAEventNameHashesStorageFactory migrationStorageForPath:migrationPath];
    AMAEventNameHashesStorage *currentStorage = [AMAEventNameHashesStorageFactory storageForApiKey:apiKey main:NO];
    AMAEventNameHashesCollection *oldCollection = [migrationStorage loadCollection];
    BOOL result = [currentStorage saveCollection:oldCollection];
    if (result == NO) {
        AMALogError(@"Failed to save event hashes collection for apiKey: %@", apiKey);
    }
}

+ (void)migrateDeviceIDFromDB:(AMAFMDatabase *)db
{
    id<AMADatabaseKeyValueStorageProviding> storageProvider = [self dataStorageProviderForPath:[self migrationPath]];
    id<AMAKeyValueStoring> migrationStorage = [storageProvider storageForDB:db];
    AMAFallbackKeychain *keychain = [self migrationKeychainStorageWithKVStorage:migrationStorage];
    
    NSString *storageDeviceID = [keychain stringValueForKey:kAMAMigrationDeviceIDStorageKey error:nil];
    NSString *deviceIDHash = [keychain stringValueForKey:kAMAMigrationDeviceIDHashStorageKey error:nil];
    
    id<AMAIdentifierProviding> idProvider = [AMAMetricaConfiguration sharedInstance].identifierProvider;
    
    [idProvider updateIfMissingWithDeviceID:storageDeviceID deviceIDHash:deviceIDHash];
}

+ (void)migrateUUID
{
    AMAInstantFeaturesConfiguration *migrationConfiguration = [AMAInstantFeaturesConfiguration migrationInstance];
    id<AMAIdentifierProviding> idProvider = [AMAMetricaConfiguration sharedInstance].identifierProvider;
    
    NSString *uuid = [migrationConfiguration UUID];
    
    if (uuid != nil) {
        [idProvider updateIfMissingWithUuid:uuid];
    }
}

#pragma mark - Private -

+ (NSData *)migrationDataForTable:(NSString *)tableName
                             data:(NSData *)data
                  encryptionValue:(NSNumber *)encryptionValue
{
    NSData *encryptedData = nil;
    if ([tableName isEqual:kAMALocationsTableName] || [tableName isEqual:kAMALocationsVisitsTableName]) {
        encryptedData = [self locationMigrationData:data];
    }
    else {
        encryptedData = [self reporterMigrationData:data encryptionValue:encryptionValue];
    }
    return encryptedData;
}

+ (NSData *)reporterMigrationData:(NSData *)data encryptionValue:(NSNumber *)encryptionValue
{
    AMAReporterDatabaseEncryptionType encryptionType = (AMAReporterDatabaseEncryptionType)[encryptionValue unsignedIntegerValue];
    
    id<AMAReporterDatabaseEncoderProviding> migrationEncoderFactory = [[AMAReporterDatabaseMigrationTo500EncodersFactory alloc] init];
    id<AMADataEncoding> migrationEncoder = [migrationEncoderFactory encoderForEncryptionType:encryptionType];
    NSData *decodedWithOldEncrypterData = [migrationEncoder decodeData:data error:nil];
    
    id<AMAReporterDatabaseEncoderProviding> encoderFactory = [[AMAReporterDatabaseMigrationTo5100EncodersFactory alloc] init];
    id<AMADataEncoding> encoder = [encoderFactory encoderForEncryptionType:encryptionType];
    NSData *encodedWithNewEncrypterData = [encoder encodeData:decodedWithOldEncrypterData error:nil];
    
    return encodedWithNewEncrypterData;
}

+ (NSData *)locationMigrationData:(NSData *)data
{
    id<AMALocationEncoderProviding> migrationEncoderFactory = [[AMALocationMigrationTo500EncoderFactory alloc] init];
    id<AMADataEncoding> migrationEncoder = [migrationEncoderFactory encoder];
    NSData *decodedWithOldEncrypterData = [migrationEncoder decodeData:data error:nil];
    
    id<AMALocationEncoderProviding> encoderFactory = [[AMALocationMigrationTo5100EncoderFactory alloc] init];
    id<AMADataEncoding> encoder = [encoderFactory encoder];
    NSData *encodedWithNewEncrypterData = [encoder encodeData:decodedWithOldEncrypterData error:nil];
    
    return encodedWithNewEncrypterData;
}

#pragma mark - Events Migration -

+ (NSArray<AMAEvent*> *)getEventsInDB:(AMAFMDatabase *)db
                      eventSerializer:(AMAEventSerializer *)eventSerializer
{
    NSMutableArray *result = [NSMutableArray array];
    NSError *error = nil;
    [AMADatabaseHelper enumerateRowsWithFilter:nil
                                         order:nil
                                   valuesArray:@[]
                                     tableName:kAMAEventTableName
                                         limit:INT_MAX
                                            db:db
                                         error:&error
                                         block:^(NSDictionary *dictionary) {
        NSError *deserializationError = nil;
        AMAEvent *event = [eventSerializer eventForDictionary:dictionary error:&deserializationError];
        if (deserializationError != nil) {
            AMALogInfo(@"Deserialization error: %@", deserializationError);
        }
        else if (event != nil) {
            [result addObject:event];
        }
    }];
    if (error != nil) {
        AMALogInfo(@"Error: %@", error);
    }
    return [result copy];
}

+ (void)saveReporterEvents:(NSArray<AMAEvent*> *)events
                        db:(AMAFMDatabase *)db
{
    AMAEventSerializer *eventSerializer = [[AMAEventSerializer alloc] migrationTo5100Init];
    
    for (AMAEvent *event in events) {
        NSDictionary *eventDictionary = [eventSerializer dictionaryForEvent:event error:nil];
        if (eventDictionary != nil) {
            [AMADatabaseHelper insertRowWithDictionary:eventDictionary
                                             tableName:kAMAEventTableName
                                                    db:db
                                                 error:nil];
        }
    }
}

+ (void)addExtrasToEvents:(NSArray<AMAEvent*> *)events
                   extras:(NSDictionary *)extras
{
    if (extras == nil) {
        return;
    }
    for (AMAEvent *event in events) {
        NSMutableDictionary *eventExtras = [NSMutableDictionary dictionary];
        if (event.extras != nil) {
            [eventExtras addEntriesFromDictionary:event.extras];
        }
        [eventExtras addEntriesFromDictionary:extras];
        event.extras = eventExtras;
    }
}

#pragma mark - Keychain Migration -

+ (id<AMAKeychainStoring>)migrationKeychainStorageWithKVStorage:(id<AMAKeyValueStoring>)storage
{
    AMAKeychainBridge *keychainBridge = [[AMAKeychainBridge alloc] init];
    AMAKeychain *appKeychain = [[AMAKeychain alloc] initWithService:kAMAMigrationKeychainAppServiceIdentifier
                                                        accessGroup:@""
                                                             bridge:keychainBridge];
    AMAKeychain *vendorKeychain = [self vendorMigrationKeychainWithBridge:keychainBridge];
    
    id<AMAKeychainStoring> keychain = [[AMAFallbackKeychain alloc] initWithStorage:storage
                                                                      mainKeychain:appKeychain
                                                                  fallbackKeychain:vendorKeychain];
    return keychain;
}

+ (AMAKeychain *)vendorMigrationKeychainWithBridge:(AMAKeychainBridge *)keychainBridge
{
#if !TARGET_IPHONE_SIMULATOR
    NSString *appIdentifier = [AMAPlatformDescription appIdentifierPrefix];
    if (appIdentifier.length == 0) {
        return nil;
    }
    NSString *accessGroup = [appIdentifier stringByAppendingString:kAMAMigrationKeychainAccessGroup];
#else
    NSString *accessGroup = @"";
#endif
    AMAKeychain *migrationVendorKeychain = [[AMAKeychain alloc] initWithService:kAMAMigrationKeychainVendorServiceIdentifier
                                                                    accessGroup:accessGroup
                                                                         bridge:keychainBridge];
    if (migrationVendorKeychain.isAvailable == NO) {
        return nil;
    }

    return migrationVendorKeychain;
}

+ (id<AMADatabaseKeyValueStorageProviding>)dataStorageProviderForPath:(NSString *)path
{
    NSString *backupTag = @"storage.bak";
    id<AMAKeyValueStorageDataProviding> backingDataProvider =
#if TARGET_OS_TV
    [self backingDataProviderWithSuiteNamePostfix:backupTag];
#else
    [self backingDataProviderWithPath:[path stringByAppendingPathComponent:backupTag]];
#endif
    
    id<AMAKeyValueStorageConverting> keyValueStorageConverter =
        [[AMAStringDatabaseKeyValueStorageConverter alloc] init];
    
    id<AMADatabaseKeyValueStorageProviding> storageProvider =
        [AMAKeyValueStorageProvidersFactory databaseProviderForTableName:kAMAKeyValueTableName
                                                               converter:keyValueStorageConverter
                                                          objectProvider:[AMADatabaseObjectProvider blockForStrings]
                                                  backingKVSDataProvider:backingDataProvider];
    
    NSArray *const kCriticalKVKeys = @[ AMAStorageStringKeyUUID ];
    
    [storageProvider addBackingKeys:kCriticalKVKeys];
    
    return storageProvider;
}

#if TARGET_OS_TV

+ (id<AMAKeyValueStorageDataProviding>)backingDataProviderWithSuiteNamePostfix:(NSString *)suiteNamePostfix
{
    NSString *suiteName = [@"ru.yandex.mobile.YandexMobileMetrica." stringByAppendingString:suiteNamePostfix];
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:suiteName];
    return [[AMAUserDefaultsKVSDataProvider alloc] initWithUserDefaults:defaults];
}

#else

+ (id<AMAKeyValueStorageDataProviding>)backingDataProviderWithPath:(NSString *)path
{
    AMADiskFileStorageOptions options = AMADiskFileStorageOptionCreateDirectory | AMADiskFileStorageOptionNoBackup;
    AMADiskFileStorage *fileStorage = [[AMADiskFileStorage alloc] initWithPath:path options:options];
    AMAJSONFileKVSDataProvider *jsonDataProvider = [[AMAJSONFileKVSDataProvider alloc] initWithFileStorage:fileStorage];
    return jsonDataProvider;
}

#endif

+ (NSDictionary *)fallbackKeychainMapping
{
    NSString *format = @"fallback-keychain-%@";
    return @{
        [NSString stringWithFormat:format, kAMAMigrationDeviceIDStorageKey]: [NSString stringWithFormat:format, [AMAAppMetricaIdentifiersKeys deviceID]],
        [NSString stringWithFormat:format, kAMAMigrationDeviceIDHashStorageKey]: [NSString stringWithFormat:format, [AMAAppMetricaIdentifiersKeys deviceIDHash]]
    };
}

#pragma mark - Crash reports

+ (NSString *)crashReportsWithBundleName:(NSString *)bundleName
{
    NSArray *cachePaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachePath = [cachePaths firstObject];
    NSString *directoryName = [bundleName stringByAppendingString:@".CrashReports"];
    return [cachePath stringByAppendingPathComponent:directoryName];
}

+ (void)migrateCrashReportsIfNeeded
{
    NSString *oldDirectoryPath = [self crashReportsWithBundleName:kAMAMigrationBundle];
    NSString *newDirectoryPath = [self crashReportsWithBundleName:[AMAPlatformDescription SDKBundleName]];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];

    if (![fileManager fileExistsAtPath:oldDirectoryPath]) {
        AMALogWarn(@"There are no migration crash reports found");
        return;
    }

    if ([fileManager fileExistsAtPath:newDirectoryPath]) {
        AMALogWarn(@"New crash reports directory already exists");
        return;
    }

    NSError *error;
    if (![fileManager moveItemAtPath:oldDirectoryPath toPath:newDirectoryPath error:&error]) {
        AMALogWarn(@"Failed to move crash reports from %@ to %@: %@", oldDirectoryPath, newDirectoryPath, error);
    } else {
        AMALogWarn(@"Successfully moved crash reports from %@ to %@", oldDirectoryPath, newDirectoryPath);
        [AMAFileUtility deleteFileAtPath:oldDirectoryPath];
    }
}

@end
