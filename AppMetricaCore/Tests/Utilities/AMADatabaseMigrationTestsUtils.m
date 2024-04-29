
#import "AMADatabaseMigrationTestsUtils.h"
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
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
        [[AMADatabaseKeyValueStorageProvider alloc] initWithTableName:@"kv"
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

@end
