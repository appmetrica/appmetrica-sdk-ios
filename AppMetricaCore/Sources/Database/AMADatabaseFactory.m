
#import "AMADatabaseFactory.h"
#import "AMADatabase.h"
#import "AMADatabaseConstants.h"
#import "AMAStorageKeys.h"
#import "AMATableSchemeController.h"
#import "AMATableDescriptionProvider.h"
#import "AMADatabaseMigrationManager.h"
#import "AMAStorageTrimManager.h"
#import "AMAKeyValueStorageProvidersFactory.h"
#import "AMABinaryDatabaseKeyValueStorageConverter.h"
#import "AMAStringDatabaseKeyValueStorageConverter.h"
#import "AMADatabaseObjectProvider.h"
#import "AMAProxyDataToStringKVSDataProvider.h"
#import "AMAJSONFileKVSDataProvider.h"
#import "AMADatabaseMigrationProvider.h"

NSString *const kAMAMainReporterDBPath = @"main";

@implementation AMADatabaseFactory

+ (id<AMADatabaseProtocol>)configurationDatabase
{
    NSString *databasePath = [self configurationDatabasePath];
    AMATableSchemeController *tableSchemeController = [[AMATableSchemeController alloc] initWithTableSchemes:@{
        kAMAKeyValueTableName: [AMATableDescriptionProvider stringKVTableMetaInfo],
    }];
    AMADatabaseMigrationProvider *provider = [[AMADatabaseMigrationProvider alloc] init];
    AMADatabaseMigrationManager *migrationManager =
        [[AMADatabaseMigrationManager alloc] initWithCurrentSchemeVersion:kAMAConfigurationDatabaseSchemaVersion
                                                         schemeMigrations:[provider schemeMigrations]
                                                         apiKeyMigrations:[provider apiKeyMigrations]
                                                           dataMigrations:[provider dataMigrationsWithAPIKey:nil
                                                                                                        main:YES]
                                                        libraryMigrations:[provider libraryMigrations]];
   
    id<AMAKeyValueStorageConverting> keyValueStorageConverter =
        [[AMAStringDatabaseKeyValueStorageConverter alloc] init];

    NSString *backupTag = @"storage.bak";
    id<AMAKeyValueStorageDataProviding> backingDataProvider =
#if TARGET_OS_TV
        [self backingDataProviderWithSuiteNamePostfix:backupTag];
#else
        [self backingDataProviderWithPath:[AMAFileUtility.persistentPath stringByAppendingPathComponent:backupTag]];
#endif
    
    id<AMADatabaseKeyValueStorageProviding> storageProvider =
        [AMAKeyValueStorageProvidersFactory databaseProviderForTableName:kAMAKeyValueTableName
                                                               converter:keyValueStorageConverter
                                                          objectProvider:[AMADatabaseObjectProvider blockForStrings]
                                                  backingKVSDataProvider:backingDataProvider];
    
    NSArray *const kCriticalKVKeys = @[ AMAStorageStringKeyUUID ];
    
    [storageProvider addBackingKeys:kCriticalKVKeys];
    
    id<AMADatabaseProtocol> database = [[AMADatabase alloc] initWithTableSchemeController:tableSchemeController
                                                                             databasePath:databasePath
                                                                         migrationManager:migrationManager
                                                                              trimManager:nil
                                                                  keyValueStorageProvider:storageProvider
                                                                     criticalKeyValueKeys:kCriticalKVKeys];
    [storageProvider setDatabase:database];
    return database;
}

+ (NSString *)configurationDatabasePath
{
    NSString *basePath = AMAFileUtility.persistentPath;
    return [basePath stringByAppendingPathComponent:@"storage.sqlite"];
}

+ (id<AMADatabaseProtocol>)reporterDatabaseForApiKey:(NSString *)apiKey
                                                main:(BOOL)main
                                       eventsCleaner:(AMAEventsCleaner *)eventsCleaner
{
    NSString *dirPath = main ? kAMAMainReporterDBPath : apiKey;
    NSString *basePath = [AMAFileUtility persistentPathForApiKey:dirPath];
    NSString *databasePath = [basePath stringByAppendingPathComponent:@"data.sqlite"];
    AMATableSchemeController *tableSchemeController = [[AMATableSchemeController alloc] initWithTableSchemes:@{
        kAMAEventTableName: [AMATableDescriptionProvider eventsTableMetaInfo],
        kAMASessionTableName: [AMATableDescriptionProvider sessionsTableMetaInfo],
        kAMAKeyValueTableName: [AMATableDescriptionProvider binaryKVTableMetaInfo],
    }];
    __auto_type *provider = [[AMADatabaseMigrationProvider alloc] initWithContentType:AMADatabaseContentTypeReporter];
    AMADatabaseMigrationManager *migrationManager =
        [[AMADatabaseMigrationManager alloc] initWithCurrentSchemeVersion:kAMAReporterDatabaseSchemaVersion
                                                         schemeMigrations:[provider schemeMigrations]
                                                         apiKeyMigrations:[provider apiKeyMigrations]
                                                           dataMigrations:[provider dataMigrationsWithAPIKey:apiKey
                                                                                                        main:main]
                                                        libraryMigrations:[provider libraryMigrations]];
    AMAStorageTrimManager *trimManager = [[AMAStorageTrimManager alloc] initWithApiKey:apiKey
                                                                         eventsCleaner:eventsCleaner];
    id<AMAKeyValueStorageConverting> keyValueStorageConverter =
        [[AMABinaryDatabaseKeyValueStorageConverter alloc] init];

    id<AMAKeyValueStorageDataProviding> backingDataProvider =
#if TARGET_OS_TV
        [self backingDataProviderWithSuiteNamePostfix:[dirPath stringByAppendingString:@".bak"]];
#else
        [self backingDataProviderWithPath:[basePath stringByAppendingPathComponent:@"data.bak"]];
    backingDataProvider =
        [[AMAProxyDataToStringKVSDataProvider alloc] initWithUnderlyingDataProvider:backingDataProvider];
#endif

    id<AMADatabaseKeyValueStorageProviding> storageProvider =
        [AMAKeyValueStorageProvidersFactory databaseProviderForTableName:kAMAKeyValueTableName
                                                               converter:keyValueStorageConverter
                                                          objectProvider:[AMADatabaseObjectProvider blockForDataBlobs]
                                                  backingKVSDataProvider:backingDataProvider];
    id<AMADatabaseProtocol> database = [[AMADatabase alloc] initWithTableSchemeController:tableSchemeController
                                                                             databasePath:databasePath
                                                                         migrationManager:migrationManager
                                                                              trimManager:trimManager
                                                                  keyValueStorageProvider:storageProvider
                                                                     criticalKeyValueKeys:@[]];
    [storageProvider setDatabase:database];
    return database;
}

+ (id<AMADatabaseProtocol>)locationDatabase
{
    NSString *basePath = AMAFileUtility.persistentPath;
    NSString *databasePath = [basePath stringByAppendingPathComponent:@"l_data.sqlite"];
    AMATableSchemeController *tableSchemeController = [[AMATableSchemeController alloc] initWithTableSchemes:@{
        kAMALocationsTableName: [AMATableDescriptionProvider locationsTableMetaInfo],
        kAMALocationsVisitsTableName: [AMATableDescriptionProvider visitsTableMetaInfo],
        kAMAKeyValueTableName: [AMATableDescriptionProvider stringKVTableMetaInfo],
    }];
    __auto_type *provider = [[AMADatabaseMigrationProvider alloc] initWithContentType:AMADatabaseContentTypeLocation];
    AMADatabaseMigrationManager *migrationManager =
        [[AMADatabaseMigrationManager alloc] initWithCurrentSchemeVersion:kAMALocationDatabaseSchemaVersion
                                                         schemeMigrations:[provider schemeMigrations]
                                                         apiKeyMigrations:[provider apiKeyMigrations]
                                                           dataMigrations:[provider dataMigrationsWithAPIKey:nil
                                                                                                        main:YES]
                                                        libraryMigrations:[provider libraryMigrations]];
    id<AMAKeyValueStorageConverting> keyValueStorageConverter =
        [[AMAStringDatabaseKeyValueStorageConverter alloc] init];

    NSString *backupTag = @"l_data.bak";
    id<AMAKeyValueStorageDataProviding> backingDataProvider =
#if TARGET_OS_TV
        [self backingDataProviderWithSuiteNamePostfix:backupTag];
#else
        [self backingDataProviderWithPath:[basePath stringByAppendingPathComponent:backupTag]];
#endif
    
    id<AMADatabaseKeyValueStorageProviding> storageProvider =
        [AMAKeyValueStorageProvidersFactory databaseProviderForTableName:kAMAKeyValueTableName
                                                               converter:keyValueStorageConverter
                                                          objectProvider:[AMADatabaseObjectProvider blockForStrings]
                                                  backingKVSDataProvider:backingDataProvider];
    id<AMADatabaseProtocol> database = [[AMADatabase alloc] initWithTableSchemeController:tableSchemeController
                                                                             databasePath:databasePath
                                                                         migrationManager:migrationManager
                                                                              trimManager:nil
                                                                  keyValueStorageProvider:storageProvider
                                                                     criticalKeyValueKeys:@[]];
    [storageProvider setDatabase:database];
    return database;
}

#if TARGET_OS_TV

+ (id<AMAKeyValueStorageDataProviding>)backingDataProviderWithSuiteNamePostfix:(NSString *)suiteNamePostfix
{
    NSString *suiteName = [@"io.appmetrica." stringByAppendingString:suiteNamePostfix];
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

@end
