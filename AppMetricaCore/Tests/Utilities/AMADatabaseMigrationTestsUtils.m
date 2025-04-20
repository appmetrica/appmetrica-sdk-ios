
#import "AMADatabaseMigrationTestsUtils.h"
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>
#import <AppMetricaFMDB/AppMetricaFMDB.h>
#import <sqlite3.h>
#import "AMATableSchemeController.h"
#import <Kiwi/Kiwi.h>
#import <AppMetricaStorageUtils/AppMetricaStorageUtils.h>
#import "AMAStringDatabaseKeyValueStorageConverter.h"
#import "AMADatabaseKeyValueStorageProvider.h"
#import "AMADatabaseObjectProvider.h"
#import "AMAStorageKeys.h"
#import "AMADatabase.h"
#import "AMAMigrationTo500Utils.h"
#import "AMATableDescriptionProvider.h"
#import "AMADatabaseConstants.h"
#import "AMAKeyValueStorageProvidersFactory.h"
#import "AMABinaryDatabaseKeyValueStorageConverter.h"
#import "AMADatabaseMigrationManager.h"
#import "AMADatabaseDataMigration.h"
#import "AMADatabaseMigrationProvider.h"
#import "AMASharedReporterProvider.h"
#import "AMAEventsCleaner.h"
#import "AMAEventSerializer.h"
#import "AMAEvent.h"
#import "AMASessionSerializer.h"
#import "AMADatabaseHelper.h"
#import "AMADatabaseFactory.h"
#import "AMAJSONFileKVSDataProvider.h"
#import "AMAProxyDataToStringKVSDataProvider.h"

@implementation AMADatabaseMigrationTestsUtils

+ (id<AMADatabaseProtocol>)databaseForName:(NSString *)databaseName
                          migrationManager:(AMADatabaseMigrationManager *)migrationManager
{
    NSString *targetPath = [self tempDatabasePath];
    NSString *sourcePath = [self pathForDatabase:databaseName];
    [[NSFileManager defaultManager] copyItemAtPath:sourcePath toPath:targetPath error:nil];

    return [self databaseWithPath:targetPath migrationManager:migrationManager];
}

+ (id<AMADatabaseProtocol>)databaseForBackupName:(NSString *)backupName
                                migrationManager:(AMADatabaseMigrationManager *)migrationManager
{
    NSString *targetPath = [self tempDatabasePath];
    NSString *backupPath = [AMAModuleBundleProvider.moduleBundle pathForResource:backupName ofType:@"sql"];

    AMAFMDatabaseQueue *dbQueue = [[AMAFMDatabaseQueue alloc] initWithPath:targetPath
                                                               flags:(SQLITE_OPEN_READWRITE |
                                                                      SQLITE_OPEN_CREATE |
                                                                      SQLITE_OPEN_FILEPROTECTION_NONE)];
    [dbQueue inDatabase:^(AMAFMDatabase * _Nonnull db) {
        [db executeStatements:[NSString stringWithContentsOfFile:backupPath encoding:NSUTF8StringEncoding error:nil]];
    }];
    [dbQueue close];

    return [self databaseWithPath:targetPath migrationManager:migrationManager];
}

+ (NSString *)tempDatabasePath
{
    NSString *fileName = [NSString stringWithFormat:@"%@.sqlite", [NSUUID UUID].UUIDString];
    NSURL *targetPath = [[NSFileManager defaultManager].temporaryDirectory URLByAppendingPathComponent:fileName];
    return targetPath.path;
}

+ (id<AMADatabaseProtocol>)databaseWithPath:(NSString *)path
                           migrationManager:(AMADatabaseMigrationManager *)migrationManager
{
    AMATableSchemeController *schemeController = [AMATableSchemeController nullMock];
    id<AMAKeyValueStorageConverting> converter = [[AMAStringDatabaseKeyValueStorageConverter alloc] init];
    AMADatabaseKeyValueStorageProvider *keyValueStorageProvider =
        [[AMADatabaseKeyValueStorageProvider alloc] initWithTableName:kAMAKeyValueTableName
                                                            converter:converter
                                                       objectProvider:[AMADatabaseObjectProvider blockForStrings]
                                               backingKVSDataProvider:nil];
    return [self databaseWithPath:path
                 migrationManager:migrationManager
                  storageProvider:keyValueStorageProvider
                 schemeController:schemeController];
}

+ (NSString *)pathForDatabase:(NSString *)databaseName
{
    return [AMAModuleBundleProvider.moduleBundle pathForResource:databaseName ofType:@"sqlite"];
}

+ (id<AMADatabaseProtocol>)databaseWithPath:(NSString *)databasePath
                           migrationManager:(AMADatabaseMigrationManager *)migrationManager
                            storageProvider:(id<AMADatabaseKeyValueStorageProviding>)storageProvider
                           schemeController:(AMATableSchemeController *)schemeController
{
    NSArray *const kCriticalKVKeys = @[ AMAStorageStringKeyUUID ];
    [storageProvider addBackingKeys:kCriticalKVKeys];

    id<AMADatabaseProtocol> database = [[AMADatabase alloc] initWithTableSchemeController:schemeController
                                                                             databasePath:databasePath
                                                                         migrationManager:migrationManager
                                                                              trimManager:nil
                                                                  keyValueStorageProvider:storageProvider
                                                                     criticalKeyValueKeys:kCriticalKVKeys];
    [storageProvider setDatabase:database];
    return database;
}

+ (id<AMADatabaseProtocol>)configurationDatabase:(NSString *)basePath
{
    AMADatabaseMigrationManager *migrationManager =
        [[AMADatabaseMigrationManager alloc] initWithCurrentSchemeVersion:kAMAConfigurationDatabaseSchemaVersion
                                                         schemeMigrations:@[]
                                                         apiKeyMigrations:@[]
                                                           dataMigrations:@[]
                                                        libraryMigrations:@[]];
    AMATableSchemeController *tableSchemeController = [[AMATableSchemeController alloc] initWithTableSchemes:@{
        kAMAKeyValueTableName: [AMATableDescriptionProvider stringKVTableMetaInfo],
    }];
    
    id<AMADatabaseKeyValueStorageProviding> storageProvider =
        [AMAKeyValueStorageProvidersFactory databaseProviderForTableName:kAMAKeyValueTableName
                                                               converter:[[AMAStringDatabaseKeyValueStorageConverter alloc] init]
                                                          objectProvider:[AMADatabaseObjectProvider blockForStrings]
                                                  backingKVSDataProvider:nil];
    
    return [self databaseWithPath:[basePath stringByAppendingPathComponent:@"storage.sqlite"]
                 migrationManager:migrationManager
                  storageProvider:storageProvider
                 schemeController:tableSchemeController];
}

+ (id<AMADatabaseProtocol>)reporterDatabase:(NSString *)basePath
                                     apiKey:(NSString *)apiKey
{
    return [self reporterDatabase:basePath apiKey:apiKey main:NO];
}

+ (id<AMADatabaseProtocol>)reporterDatabase:(NSString *)basePath
                                     apiKey:(NSString *)apiKey
                                       main:(BOOL)main
{
    AMASharedReporterProvider *reporterProvider = [[AMASharedReporterProvider alloc] initWithApiKey:apiKey];
    AMAEventsCleaner *eventsCleaner = [[AMAEventsCleaner alloc] initWithReporterProvider:reporterProvider];

    AMADatabaseMigrationManager *migrationManager =
    [[AMADatabaseMigrationManager alloc] initWithCurrentSchemeVersion:kAMAReporterDatabaseSchemaVersion
                                                         schemeMigrations:@[]
                                                         apiKeyMigrations:@[]
                                                           dataMigrations:@[]
                                                        libraryMigrations:@[]];
    AMATableSchemeController *tableSchemeController = [[AMATableSchemeController alloc] initWithTableSchemes:@{
        kAMAEventTableName: [AMATableDescriptionProvider eventsTableMetaInfo],
        kAMASessionTableName: [AMATableDescriptionProvider sessionsTableMetaInfo],
        kAMAKeyValueTableName: [AMATableDescriptionProvider binaryKVTableMetaInfo],
    }];
    
    NSString *dirPath = main ? kAMAMainReporterDBPath : apiKey;
    NSString *backingDataPath = [[basePath stringByAppendingPathComponent:dirPath] stringByAppendingPathComponent:@"data.bak"];
    AMADiskFileStorageOptions options = AMADiskFileStorageOptionCreateDirectory | AMADiskFileStorageOptionNoBackup;
    AMADiskFileStorage *fileStorage = [[AMADiskFileStorage alloc] initWithPath:backingDataPath options:options];
    AMAJSONFileKVSDataProvider *jsonDataProvider = [[AMAJSONFileKVSDataProvider alloc] initWithFileStorage:fileStorage];
    id<AMAKeyValueStorageDataProviding> backingDataProvider = [[AMAProxyDataToStringKVSDataProvider alloc]
                                                               initWithUnderlyingDataProvider:jsonDataProvider];
    
    id<AMADatabaseKeyValueStorageProviding> storageProvider =
        [AMAKeyValueStorageProvidersFactory databaseProviderForTableName:kAMAKeyValueTableName
                                                               converter:[[AMABinaryDatabaseKeyValueStorageConverter alloc] init]
                                                          objectProvider:[AMADatabaseObjectProvider blockForDataBlobs]
                                                  backingKVSDataProvider:backingDataProvider];
    
    return [self databaseWithPath:[[basePath
                                    stringByAppendingPathComponent:dirPath]
                                   stringByAppendingPathComponent:@"data.sqlite"]
                 migrationManager:migrationManager
                  storageProvider:storageProvider
                 schemeController:tableSchemeController];
}

+ (id<AMADatabaseProtocol>)locationDatabase:(NSString *)basePath
{
    AMADatabaseMigrationManager *migrationManager =
        [[AMADatabaseMigrationManager alloc] initWithCurrentSchemeVersion:kAMALocationDatabaseSchemaVersion
                                                         schemeMigrations:@[]
                                                         apiKeyMigrations:@[]
                                                           dataMigrations:@[]
                                                        libraryMigrations:@[]];
    AMATableSchemeController *tableSchemeController = [[AMATableSchemeController alloc] initWithTableSchemes:@{
        kAMALocationsTableName: [AMATableDescriptionProvider locationsTableMetaInfo],
        kAMALocationsVisitsTableName: [AMATableDescriptionProvider visitsTableMetaInfo],
        kAMAKeyValueTableName: [AMATableDescriptionProvider stringKVTableMetaInfo],
    }];
    
    id<AMADatabaseKeyValueStorageProviding> storageProvider =
        [AMAKeyValueStorageProvidersFactory databaseProviderForTableName:kAMAKeyValueTableName
                                                               converter:[[AMAStringDatabaseKeyValueStorageConverter alloc] init]
                                                          objectProvider:[AMADatabaseObjectProvider blockForStrings]
                                                  backingKVSDataProvider:nil];
    
    return [self databaseWithPath:[basePath stringByAppendingPathComponent:@"l_data.sqlite"]
                 migrationManager:migrationManager
                  storageProvider:storageProvider
                 schemeController:tableSchemeController];
}

+ (void)cleanDatabase
{
    [[NSFileManager defaultManager] removeItemAtPath:[AMAMigrationTo500Utils migrationPath] error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:AMAFileUtility.persistentPath error:nil];
}

+ (void)includeDataMigration:(id<AMADatabaseDataMigration>)migration
                 contentType:(AMADatabaseContentType)contentType
                  inDatabase:(id<AMADatabaseProtocol>)database
{
    [database inDatabase:^(AMAFMDatabase *db) {
        id<AMAKeyValueStoring> storage = [database.storageProvider storageForDB:db];
        
        __auto_type *migrationProvider = [[AMADatabaseMigrationProvider alloc] initWithContentType:contentType];
        NSArray *migrations = [migrationProvider dataMigrationsWithAPIKey:nil main:YES];
        
        for (id<AMADatabaseDataMigration> migration in migrations) {
            [storage saveBoolNumber:@YES forKey:migration.migrationKey error:nil];
        }
        
        [storage saveBoolNumber:@NO forKey:migration.migrationKey error:nil];
    }];
}

@end
