
#import <Foundation/Foundation.h>

@protocol AMADatabaseProtocol;
@protocol AMADatabaseKeyValueStorageProviding;
@class AMADatabaseMigrationManager;
@class AMATableSchemeController;

@interface AMADatabaseMigrationTestsUtils : NSObject

+ (id<AMADatabaseProtocol>)databaseForName:(NSString *)databaseName
                          migrationManager:(AMADatabaseMigrationManager *)migrationManager;

+ (id<AMADatabaseProtocol>)databaseForBackupName:(NSString *)backupName
                                migrationManager:(AMADatabaseMigrationManager *)migrationManager;

+ (id<AMADatabaseProtocol>)databaseWithPath:(NSString *)databasePath
                           migrationManager:(AMADatabaseMigrationManager *)migrationManager
                            storageProvider:(id<AMADatabaseKeyValueStorageProviding>)storageProvider
                           schemeController:(AMATableSchemeController *)schemeController;

+ (NSString *)pathForDatabase:(NSString *)databaseName;

@end
