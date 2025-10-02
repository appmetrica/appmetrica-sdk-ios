
#import <Foundation/Foundation.h>
#import "AMADatabaseMigrationProvider.h"

@protocol AMADatabaseProtocol;
@protocol AMADatabaseKeyValueStorageProviding;
@class AMADatabaseMigrationManager;
@class AMATableSchemeController;
@protocol AMADatabaseDataMigration;

@interface AMADatabaseMigrationTestsUtils : NSObject

+ (id<AMADatabaseProtocol>)databaseForName:(NSString *)databaseName
                          migrationManager:(AMADatabaseMigrationManager *)migrationManager;

+ (id<AMADatabaseProtocol>)databaseWithPath:(NSString *)path
                           migrationManager:(AMADatabaseMigrationManager *)migrationManager;

+ (id<AMADatabaseProtocol>)databaseForBackupName:(NSString *)backupName
                                migrationManager:(AMADatabaseMigrationManager *)migrationManager;

+ (id<AMADatabaseProtocol>)databaseWithPath:(NSString *)databasePath
                           migrationManager:(AMADatabaseMigrationManager *)migrationManager
                            storageProvider:(id<AMADatabaseKeyValueStorageProviding>)storageProvider
                           schemeController:(AMATableSchemeController *)schemeController;

+ (NSString *)pathForDatabase:(NSString *)databaseName;

+ (id<AMADatabaseProtocol>)configurationDatabase:(NSString *)basePath;
+ (id<AMADatabaseProtocol>)reporterDatabase:(NSString *)basePath
                                     apiKey:(NSString *)apiKey;
+ (id<AMADatabaseProtocol>)reporterDatabase:(NSString *)basePath
                                     apiKey:(NSString *)apiKey
                                       main:(BOOL)main;
+ (id<AMADatabaseProtocol>)locationDatabase:(NSString *)basePath;

+ (void)cleanDatabase;

+ (void)includeDataMigration:(id<AMADatabaseDataMigration>)migration
                 contentType:(AMADatabaseContentType)contentType
                  inDatabase:(id<AMADatabaseProtocol>)database;

@end
