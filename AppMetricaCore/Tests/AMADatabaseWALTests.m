
#import <Foundation/Foundation.h>
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaFMDB/AppMetricaFMDB.h>

#import "AMADatabase.h"
#import "AMATableSchemeController.h"
#import "AMAStringDatabaseKeyValueStorageConverter.h"
#import "AMATableDescriptionProvider.h"
#import "AMADatabaseConstants.h"
#import "AMADatabaseMigrationProvider.h"
#import "AMADatabaseMigrationManager.h"
#import "AMADatabaseFactory.h"
#import "AMAKeyValueStorageProvidersFactory.h"
#import "AMAStorageKeys.h"
#import "AMADatabaseObjectProvider.h"
#import "AMADataMigrationTo5140.h"
#import "AMADatabaseMigrationTestsUtils.h"

SPEC_BEGIN(AMADatabaseWALTests)

describe(@"AMADatabaseWAL", ^{
    
    NSString *const dbName = @"waltest";
    NSString *const dbFileName = [NSString stringWithFormat:@"%@.sqlite", dbName];
    NSString *const dbFileNameShm = [NSString stringWithFormat:@"%@.sqlite-shm", dbName];
    NSString *const dbFileNameWal = [NSString stringWithFormat:@"%@.sqlite-wal", dbName];;
    NSFileManager *const fileManager = [NSFileManager defaultManager];
    
    id<AMADatabaseProtocol> __block database;
    
    NSString *(^testDatabasePath)() = ^{ return [AMAFileUtility.persistentPath stringByAppendingPathComponent:dbFileName]; };
    
    id<AMADatabaseProtocol> (^createDatabase)(AMADatabaseMigrationManager *) = ^(AMADatabaseMigrationManager *migrationManager) {
        NSString *path = testDatabasePath();
        return [AMADatabaseMigrationTestsUtils databaseWithPath:path migrationManager:migrationManager];
    };
    
    afterEach(^{
        database = nil;
        
        NSDirectoryEnumerator<NSString *> *enumerator = [fileManager enumeratorAtPath:AMAFileUtility.persistentPath];
        [enumerator skipDescendants];
        
        NSString *fileName;
        while (fileName = [enumerator nextObject]) {
            if ([fileName hasPrefix:dbName]) {
                NSString *filePath = [AMAFileUtility.persistentPath stringByAppendingPathComponent:dbName];
                [fileManager removeItemAtPath:filePath error:nil];
            }
        }
        
    });
    
    context(@"New database", ^{
        beforeEach(^{
            AMADatabaseMigrationManager *migrationManager = [[AMADatabaseMigrationManager alloc] initWithCurrentSchemeVersion:kAMAConfigurationDatabaseSchemaVersion
                                                                                schemeMigrations:@[]
                                                                                apiKeyMigrations:@[]
                                                                                  dataMigrations:@[ [AMADataMigrationTo5140 new] ]
                                                                               libraryMigrations:@[]];
            database = createDatabase(migrationManager);
        });
        
        it(@"Should create wal and shm file", ^{
            [fileManager fileExistsAtPath:[AMAFileUtility.persistentPath stringByAppendingPathComponent:dbFileName]];
            [fileManager fileExistsAtPath:[AMAFileUtility.persistentPath stringByAppendingPathComponent:dbFileNameShm]];
            [fileManager fileExistsAtPath:[AMAFileUtility.persistentPath stringByAppendingPathComponent:dbFileNameWal]];
        });
        
        it(@"Should check pragma journal_mode", ^{
            [database inDatabase:^(AMAFMDatabase *db) {
                AMAFMResultSet *resultSet = [db executeQuery:@"pragma journal_mode;"];
                [[theValue([resultSet next]) should] beYes];
                [[[resultSet stringForColumnIndex:0] should] equal:@"wal"];
            }];
        });
        
        it(@"Should check pragma synchronous", ^{
            [database inDatabase:^(AMAFMDatabase *db) {
                AMAFMResultSet *resultSet = [db executeQuery:@"pragma synchronous;"];
                [[theValue([resultSet next]) should] beYes];
                [[theValue([resultSet intForColumnIndex:0]) should] equal:theValue(1)];
            }];
        });
        
        it(@"Should check pragma auto_vacuum", ^{
            [database inDatabase:^(AMAFMDatabase *db) {
                AMAFMResultSet *resultSet = [db executeQuery:@"pragma auto_vacuum;"];
                [[theValue([resultSet next]) should] beYes];
                [[theValue([resultSet intForColumnIndex:0]) should] equal:theValue(1)];
            }];
        });
    });
    
    context(@"Migration", ^{
        beforeEach(^{
            AMADatabaseMigrationManager *migrationManager = [[AMADatabaseMigrationManager alloc] initWithCurrentSchemeVersion:kAMAConfigurationDatabaseSchemaVersion
                                                                                schemeMigrations:@[]
                                                                                apiKeyMigrations:@[]
                                                                                  dataMigrations:@[]
                                                                               libraryMigrations:@[]];
            database = createDatabase(migrationManager);
            [database inDatabase:^(AMAFMDatabase *db) {
                [db executeUpdate:@"INSERT INTO kv (k, v) VALUES (?, ?)" withArgumentsInArray:@[ @"random-key", @"random-value"]];
            }];
            
            database = nil;
            
            AMADatabaseMigrationManager *newMigrationManager = [[AMADatabaseMigrationManager alloc] initWithCurrentSchemeVersion:kAMAConfigurationDatabaseSchemaVersion
                                                                                schemeMigrations:@[]
                                                                                apiKeyMigrations:@[]
                                                                                  dataMigrations:@[ [AMADataMigrationTo5140 new] ]
                                                                               libraryMigrations:@[]];
            database = createDatabase(newMigrationManager);
        });
        
        it(@"Should create wal and shm file", ^{
            [fileManager fileExistsAtPath:[AMAFileUtility.persistentPath stringByAppendingPathComponent:dbFileName]];
            [fileManager fileExistsAtPath:[AMAFileUtility.persistentPath stringByAppendingPathComponent:dbFileNameShm]];
            [fileManager fileExistsAtPath:[AMAFileUtility.persistentPath stringByAppendingPathComponent:dbFileNameWal]];
        });
        
        it(@"Should check pragma journal_mode", ^{
            [database inDatabase:^(AMAFMDatabase *db) {
                AMAFMResultSet *resultSet = [db executeQuery:@"pragma journal_mode;"];
                [[theValue([resultSet next]) should] beYes];
                [[[resultSet stringForColumnIndex:0] should] equal:@"wal"];
            }];
        });
        
        it(@"Should check pragma synchronous", ^{
            [database inDatabase:^(AMAFMDatabase *db) {
                AMAFMResultSet *resultSet = [db executeQuery:@"pragma synchronous;"];
                [[theValue([resultSet next]) should] beYes];
                [[theValue([resultSet intForColumnIndex:0]) should] equal:theValue(1)];
            }];
        });
        
        it(@"Should check pragma auto_vacuum", ^{
            [database inDatabase:^(AMAFMDatabase *db) {
                AMAFMResultSet *resultSet = [db executeQuery:@"pragma auto_vacuum;"];
                [[theValue([resultSet next]) should] beYes];
                [[theValue([resultSet intForColumnIndex:0]) should] equal:theValue(1)];
            }];
        });
    });
    
    
    
});

SPEC_END
