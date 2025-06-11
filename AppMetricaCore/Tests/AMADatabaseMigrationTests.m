
#import <Kiwi/Kiwi.h>
#import <sqlite3.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMADatabase.h"
#import "AMATableSchemeController.h"
#import "AMAStringDatabaseKeyValueStorageConverter.h"
#import "AMADatabaseFactory.h"
#import "AMADatabaseProtocol.h"
#import "AMADatabaseSchemeMigration.h"
#import "AMASessionStorage+AMATestUtilities.h"
#import "AMAEventStorage+TestUtilities.h"
#import "AMAReporter.h"
#import "AMAReporterStorage.h"
#import "AMAEvent.h"
#import "AMADatabaseKeyValueStorageProvider.h"
#import "AMADatabaseObjectProvider.h"
#import "AMAStorageKeys.h"
#import "AMADatabaseConstants.h"
#import "AMAConfigurationDatabaseSchemeMigrationTo2.h"
#import "AMAConfigurationDatabaseSchemeMigrationTo3.h"
#import "AMAConfigurationDatabaseSchemeMigrationTo4.h"
#import "AMAConfigurationDatabaseSchemeMigrationTo5.h"
#import "AMAConfigurationDatabaseSchemeMigrationTo6.h"
#import "AMAConfigurationDatabaseSchemeMigrationTo7.h"
#import "AMAConfigurationDatabaseSchemeMigrationTo8.h"
#import "AMAConfigurationDatabaseSchemeMigrationTo9.h"
#import "AMAConfigurationDatabaseSchemeMigrationTo10.h"
#import "AMAConfigurationDatabaseSchemeMigrationTo11.h"
#import "AMAConfigurationDatabaseSchemeMigrationTo12.h"
#import "AMAConfigurationDatabaseSchemeMigrationTo13.h"
#import "AMAConfigurationDatabaseSchemeMigrationTo14.h"
#import "AMAConfigurationDatabaseSchemeMigrationTo15.h"
#import "AMAConfigurationDatabaseSchemeMigrationTo16.h"
#import "AMAConfigurationDatabaseSchemeMigrationTo17.h"
#import "AMAConfigurationDatabaseSchemeMigrationTo18.h"
#import "AMAConfigurationDatabaseSchemeMigrationTo19.h"
#import "AMAConfigurationDatabaseSchemeMigrationTo20.h"
#import "AMAMigrationTo19FinalizationOnApiKeySpecified.h"
#import "AMALibraryMigration320.h"
#import "AMALocationDatabaseSchemeMigrationTo2.h"
#import "AMAReporterDatabaseSchemeMigrationTo2.h"
#import "AMADatabaseMigrationManager.h"
#import "AMAReporterTestHelper.h"
#import "AMAReportRequestProvider.h"
#import "AMAReportRequestModel.h"
#import "AMAReportEventsBatch.h"
#import "AMADate.h"
#import "AMABinaryEventValue.h"
#import "AMAStringEventValue.h"
#import "AMAFileEventValue.h"
#import "AMAReporterStateStorage.h"
#import "AMAEnvironmentContainer.h"
#import <CoreLocation/CoreLocation.h>
#import <AppMetricaPlatform/AppMetricaPlatform.h>
#import <AppMetricaFMDB/AppMetricaFMDB.h>
#import "AMADatabaseMigrationTestsUtils.h"

SPEC_BEGIN(AMADatabaseMigrationTests)

describe(@"AMADatabaseMigrationTests", ^{
    AMAReporterTestHelper *__block reporterTestHelper = nil;
    id<AMADatabaseProtocol> __block database = nil;

    beforeEach(^{
        reporterTestHelper = [[AMAReporterTestHelper alloc] init];
    });

    context(@"Migration", ^{
        NSString *apiKey = @"1111"; // this key is hardcoded in storage backups

// TODO: fix test in https://nda.ya.ru/t/-41ZPniX7FFYn8
//        it(@"Should perform full stack migrations", ^{
//            NSString *initialStorageName = @"storage-version-2"; // We don't support first migration
//            NSString *storagePath = [AMADatabaseMigrationTestsUtils pathForDatabase:initialStorageName];
//            database = [AMADatabaseFactory configurationDatabase];
//
//            NSFileManager *fileManager = [NSFileManager defaultManager];
//            [fileManager removeItemAtPath:database.databasePath error:nil];
//            [fileManager copyItemAtPath:storagePath toPath:database.databasePath error:nil];
//
//            [database migrateToMainApiKey:apiKey];
//
//            AMAReporterStorage *storage = reporterTestHelper.appReporter.reporterStorage;
//            AMASessionStorage *sessionStorage = storage.sessionStorage;
//            AMAEventStorage *eventStorage = storage.eventStorage;
//
//            AMASession *session = [sessionStorage lastGeneralSessionWithError:nil];
//            [[session should] beNonNil];
//            AMAEvent *event = [[eventStorage amatest_allSavedEvents] firstObject];
//            [[event should] beNonNil];
//        });

        context(@"Migration from scheme version 1 to 2", ^{
            beforeAll(^{
                AMADatabaseMigrationManager *migrationManager =
                    [[AMADatabaseMigrationManager alloc] initWithCurrentSchemeVersion:2
                                                                     schemeMigrations:@[[AMAConfigurationDatabaseSchemeMigrationTo2 new]]
                                                                     apiKeyMigrations:@[]
                                                                       dataMigrations:@[]
                                                                    libraryMigrations:@[]];
                database = [AMADatabaseMigrationTestsUtils databaseForName:@"storage-version-1"
                                                          migrationManager:migrationManager];
                [database migrateToMainApiKey:apiKey];
            });
            it(@"Should add column `type` in sessions table", ^{
                [database inDatabase:^(AMAFMDatabase *db) {
                    [[theValue([db columnExists:@"type" inTableWithName:@"sessions"]) should] beYes];
                }];
            });
            it(@"Should add column `api_key` in sessions table", ^{
                [database inDatabase:^(AMAFMDatabase *db) {
                    [[theValue([db columnExists:@"api_key" inTableWithName:@"sessions"]) should] beYes];
                }];
            });
            it(@"Should write schema version", ^{
                NSString *migratedSchemaVersion =
                    [database.storageProvider.syncStorage stringForKey:kAMADatabaseKeySchemaVersion error:nil];
                [[theValue([migratedSchemaVersion intValue]) should] equal:theValue(2)];
            });
        });

        context(@"Migration from scheme version 2 to 3", ^{
            beforeAll(^{
                AMADatabaseMigrationManager *migrationManager =
                    [[AMADatabaseMigrationManager alloc] initWithCurrentSchemeVersion:3
                                                                     schemeMigrations:@[[AMAConfigurationDatabaseSchemeMigrationTo3 new]]
                                                                     apiKeyMigrations:@[]
                                                                       dataMigrations:@[]
                                                                    libraryMigrations:@[]];
                database = [AMADatabaseMigrationTestsUtils databaseForName:@"storage-version-2"
                                                          migrationManager:migrationManager];
            });
            it(@"Should add column `app_state` in sessions table", ^{
                [database inDatabase:^(AMAFMDatabase *db) {
                    [[theValue([db columnExists:@"app_state" inTableWithName:@"sessions"]) should] beYes];
                }];
            });
            it(@"Should add column `finished` in sessions table", ^{
                [database inDatabase:^(AMAFMDatabase *db) {
                    [[theValue([db columnExists:@"finished" inTableWithName:@"sessions"]) should] beYes];
                }];
            });
            it(@"Should write schema version", ^{
                NSString *migratedSchemaVersion =
                    [database.storageProvider.syncStorage stringForKey:kAMADatabaseKeySchemaVersion error:nil];
                [[theValue([migratedSchemaVersion intValue]) should] equal:theValue(3)];
            });
        });

        context(@"Migration from scheme version 3 to 4", ^{
            double const delta = 0.001f;
            NSDictionary *__block eventDictionary = nil;
            beforeAll(^{
                AMADatabaseMigrationManager *migrationManager =
                    [[AMADatabaseMigrationManager alloc] initWithCurrentSchemeVersion:4
                                                                     schemeMigrations:@[[AMAConfigurationDatabaseSchemeMigrationTo4 new]]
                                                                     apiKeyMigrations:@[]
                                                                       dataMigrations:@[]
                                                                    libraryMigrations:@[]];
                database = [AMADatabaseMigrationTestsUtils databaseForName:@"storage-version-3"
                                                          migrationManager:migrationManager];
                [database inDatabase:^(AMAFMDatabase *db) {
                    AMAFMResultSet *rs = [db executeQuery:@"SELECT * FROM events ORDER BY id DESC LIMIT 1"];
                    [[theValue([rs next]) should] beYes];
                    eventDictionary = rs.resultDictionary;
                }];
            });
            it(@"Should copy latitude from session to event", ^{
                double latitude = [eventDictionary[@"latitude"] doubleValue];
                double inDatabaseSessionLatitude = 123.123f;
                [[theValue(latitude) should] equal:inDatabaseSessionLatitude withDelta:delta];
            });
            it(@"Should copy longitude from session to event", ^{
                double longitude = [eventDictionary[@"longitude"] doubleValue];
                double inDatabaseSessionLongitude = 456.456f;
                [[theValue(longitude) should] equal:inDatabaseSessionLongitude withDelta:delta];
            });
            it(@"Should set speed to -1", ^{
                [[theValue([eventDictionary[@"location_speed"] doubleValue]) should] equal:-1 withDelta:delta];
            });
            it(@"Should set course to -1", ^{
                [[theValue([eventDictionary[@"location_direction"] doubleValue]) should] equal:-1 withDelta:delta];
            });
            it(@"Should set vert accuracy to -1", ^{
                [[theValue([eventDictionary[@"location_vertical_accuracy"] doubleValue]) should] equal:-1
                                                                                             withDelta:delta];
            });
            it(@"Should write schema version", ^{
                NSString *migratedSchemaVersion =
                    [database.storageProvider.syncStorage stringForKey:kAMADatabaseKeySchemaVersion error:nil];
                [[theValue([migratedSchemaVersion intValue]) should] equal:theValue(4)];
            });
        });

        context(@"Migration from scheme version 4_fresh to 5", ^{
            beforeAll(^{
                AMADatabaseMigrationManager *migrationManager =
                    [[AMADatabaseMigrationManager alloc] initWithCurrentSchemeVersion:5
                                                                     schemeMigrations:@[[AMAConfigurationDatabaseSchemeMigrationTo5 new]]
                                                                     apiKeyMigrations:@[]
                                                                       dataMigrations:@[]
                                                                    libraryMigrations:@[]];
                database = [AMADatabaseMigrationTestsUtils databaseForName:@"storage-version-4_fresh"
                                                          migrationManager:migrationManager];
            });
            it(@"Should write schema version", ^{
                NSString *migratedSchemaVersion =
                    [database.storageProvider.syncStorage stringForKey:kAMADatabaseKeySchemaVersion error:nil];
                [[theValue([migratedSchemaVersion intValue]) should] equal:theValue(5)];
            });
        });

        context(@"Migration from scheme version 4 to 5", ^{
            beforeAll(^{
                AMADatabaseMigrationManager *migrationManager =
                    [[AMADatabaseMigrationManager alloc] initWithCurrentSchemeVersion:5
                                                                     schemeMigrations:@[[AMAConfigurationDatabaseSchemeMigrationTo5 new]]
                                                                     apiKeyMigrations:@[]
                                                                       dataMigrations:@[]
                                                                    libraryMigrations:@[]];
                database = [AMADatabaseMigrationTestsUtils databaseForName:@"storage-version-4"
                                                          migrationManager:migrationManager];
            });
            it(@"Should add column `latitude` to `errors` table", ^{
                [database inDatabase:^(AMAFMDatabase *db) {
                    [[theValue([db columnExists:@"latitude" inTableWithName:@"errors"]) should] beYes];
                }];
            });
            it(@"Should add column `longitude` to `errors` table", ^{
                [database inDatabase:^(AMAFMDatabase *db) {
                    [[theValue([db columnExists:@"longitude" inTableWithName:@"errors"]) should] beYes];
                }];
            });
            it(@"Should add column `speed` to `errors` table", ^{
                [database inDatabase:^(AMAFMDatabase *db) {
                    [[theValue([db columnExists:@"location_speed" inTableWithName:@"errors"]) should] beYes];
                }];
            });
            it(@"Should add column `location_direction` to `errors` table", ^{
                [database inDatabase:^(AMAFMDatabase *db) {
                    [[theValue([db columnExists:@"location_direction" inTableWithName:@"errors"]) should] beYes];
                }];
            });
            it(@"Should add column `location_horizontal_accuracy` to `errors` table", ^{
                [database inDatabase:^(AMAFMDatabase *db) {
                    [[theValue([db columnExists:@"location_horizontal_accuracy" inTableWithName:@"errors"]) should] beYes];
                }];
            });
            it(@"Should add column `location_vertical_accuracy` to `errors` table", ^{
                [database inDatabase:^(AMAFMDatabase *db) {
                    [[theValue([db columnExists:@"location_vertical_accuracy" inTableWithName:@"errors"]) should] beYes];
                }];
            });
            it(@"Should add column `location_timestamp` to `errors` table", ^{
                [database inDatabase:^(AMAFMDatabase *db) {
                    [[theValue([db columnExists:@"location_timestamp" inTableWithName:@"errors"]) should] beYes];
                }];
            });
            it(@"Should add column `location_altitude` to `errors` table", ^{
                [database inDatabase:^(AMAFMDatabase *db) {
                    [[theValue([db columnExists:@"location_altitude" inTableWithName:@"errors"]) should] beYes];
                }];
            });
            it(@"Should write schema version", ^{
                NSString *migratedSchemaVersion =
                    [database.storageProvider.syncStorage stringForKey:kAMADatabaseKeySchemaVersion error:nil];
                [[theValue([migratedSchemaVersion intValue]) should] equal:theValue(5)];
            });
        });

        context(@"Migration from scheme version 5 to 6", ^{
            beforeAll(^{
                AMADatabaseMigrationManager *migrationManager =
                    [[AMADatabaseMigrationManager alloc] initWithCurrentSchemeVersion:6
                                                                     schemeMigrations:@[[AMAConfigurationDatabaseSchemeMigrationTo6 new]]
                                                                     apiKeyMigrations:@[]
                                                                       dataMigrations:@[]
                                                                    libraryMigrations:@[]];
                database = [AMADatabaseMigrationTestsUtils databaseForName:@"storage-version-5"
                                                          migrationManager:migrationManager];
            });
            it(@"Should add column `server_time_offset` to `sessions` table", ^{
                [database inDatabase:^(AMAFMDatabase *db) {
                    [[theValue([db columnExists:@"server_time_offset" inTableWithName:@"sessions"]) should] beYes];
                }];
            });
            it(@"Should add column `user_info` to `events` table", ^{
                [database inDatabase:^(AMAFMDatabase *db) {
                    [[theValue([db columnExists:@"user_info" inTableWithName:@"events"]) should] beYes];
                }];
            });
            it(@"Should write schema version", ^{
                NSString *migratedSchemaVersion =
                    [database.storageProvider.syncStorage stringForKey:kAMADatabaseKeySchemaVersion error:nil];
                [[theValue([migratedSchemaVersion intValue]) should] equal:theValue(6)];
            });
        });

        context(@"Migration from scheme version 6 to 7", ^{
            beforeAll(^{
                AMADatabaseMigrationManager *migrationManager =
                    [[AMADatabaseMigrationManager alloc] initWithCurrentSchemeVersion:7
                                                                     schemeMigrations:@[[AMAConfigurationDatabaseSchemeMigrationTo7 new]]
                                                                     apiKeyMigrations:@[]
                                                                       dataMigrations:@[]
                                                                    libraryMigrations:@[]];
                database = [AMADatabaseMigrationTestsUtils databaseForName:@"storage-version-6"
                                                          migrationManager:migrationManager];
            });
            it(@"Should change column `api_key` type in `sessions` table", ^{
                [database inDatabase:^(AMAFMDatabase *db) {
                    AMAFMResultSet *schema = [db getTableSchema:@"sessions"];

                    NSString *type = nil;
                    while ([schema next]) {
                        NSString *column = [schema stringForColumn:@"name"];
                        if ([column isEqual:@"api_key"]) {
                            type = [schema stringForColumn:@"type"];
                        }
                    }

                    [[type should] equal:@"STRING"];
                }];
            });
            it(@"Should write schema version", ^{
                NSString *migratedSchemaVersion =
                    [database.storageProvider.syncStorage stringForKey:kAMADatabaseKeySchemaVersion error:nil];
                [[theValue([migratedSchemaVersion intValue]) should] equal:theValue(7)];
            });
        });

        context(@"Migration from scheme version 7 to 8", ^{
            beforeAll(^{
                AMADatabaseMigrationManager *migrationManager =
                    [[AMADatabaseMigrationManager alloc] initWithCurrentSchemeVersion:8
                                                                     schemeMigrations:@[[AMAConfigurationDatabaseSchemeMigrationTo8 new]]
                                                                     apiKeyMigrations:@[]
                                                                       dataMigrations:@[]
                                                                    libraryMigrations:@[]];
                database = [AMADatabaseMigrationTestsUtils databaseForName:@"storage-version-7"
                                                          migrationManager:migrationManager];
            });
            it(@"Should move column `environment` to `error_environment` in `events` and `errors` tables", ^{
                [database inDatabase:^(AMAFMDatabase *db) {
                    [[theValue([db columnExists:@"error_environment" inTableWithName:@"events"]) should] beYes];
                    [[theValue([db columnExists:@"environment" inTableWithName:@"events"]) should] beNo];
                    [[theValue([db columnExists:@"error_environment" inTableWithName:@"errors"]) should] beYes];
                    [[theValue([db columnExists:@"environment" inTableWithName:@"errors"]) should] beNo];
                }];
            });
            it(@"Should add column `app_environment` to `events` and `errors` tables", ^{
                [database inDatabase:^(AMAFMDatabase *db) {
                    [[theValue([db columnExists:@"app_environment" inTableWithName:@"events"]) should] beYes];
                    [[theValue([db columnExists:@"app_environment" inTableWithName:@"errors"]) should] beYes];
                }];
            });
            it(@"Should add column `is_truncated` to `events` and `errors` tables", ^{
                [database inDatabase:^(AMAFMDatabase *db) {
                    [[theValue([db columnExists:@"is_truncated" inTableWithName:@"events"]) should] beYes];
                    [[theValue([db columnExists:@"is_truncated" inTableWithName:@"errors"]) should] beYes];
                }];
            });
            it(@"Should write schema version", ^{
                NSString *migratedSchemaVersion =
                    [database.storageProvider.syncStorage stringForKey:kAMADatabaseKeySchemaVersion error:nil];
                [[theValue([migratedSchemaVersion intValue]) should] equal:theValue(8)];
            });
        });

        context(@"Migration from scheme version 8 to 9", ^{
            beforeAll(^{
                AMADatabaseMigrationManager *migrationManager =
                    [[AMADatabaseMigrationManager alloc] initWithCurrentSchemeVersion:9
                                                                     schemeMigrations:@[[AMAConfigurationDatabaseSchemeMigrationTo9 new]]
                                                                     apiKeyMigrations:@[]
                                                                       dataMigrations:@[]
                                                                    libraryMigrations:@[]];
                database = [AMADatabaseMigrationTestsUtils databaseForName:@"storage-version-8"
                                                          migrationManager:migrationManager];
            });
            it(@"Should change column `is_truncated` to `bytes_truncated` in `events` and `errors` tables", ^{
                [database inDatabase:^(AMAFMDatabase *db) {
                    [[theValue([db columnExists:@"bytes_truncated" inTableWithName:@"events"]) should] beYes];
                    [[theValue([db columnExists:@"is_truncated" inTableWithName:@"events"]) should] beNo];
                    [[theValue([db columnExists:@"bytes_truncated" inTableWithName:@"errors"]) should] beYes];
                    [[theValue([db columnExists:@"is_truncated" inTableWithName:@"errors"]) should] beNo];
                }];
            });
            it(@"Should remove previous.bundle_version", ^{
                NSString *value = [database.storageProvider.syncStorage stringForKey:@"previous.bundle_version" error:nil];
                [[value should] beNil];
            });
            it(@"Should remove previous.os_version", ^{
                NSString *value = [database.storageProvider.syncStorage stringForKey:@"previous.os_version" error:nil];
                [[value should] beNil];
            });
            it(@"Should remove add.was.terminated", ^{
                NSString *value = [database.storageProvider.syncStorage stringForKey:@"add.was.terminated" error:nil];
                [[value should] beNil];
            });
            it(@"Should remove app.was.in.background", ^{
                NSString *value = [database.storageProvider.syncStorage stringForKey:@"app.was.in.background" error:nil];
                [[value should] beNil];
            });
            it(@"Should write schema version", ^{
                NSString *migratedSchemaVersion =
                    [database.storageProvider.syncStorage stringForKey:kAMADatabaseKeySchemaVersion error:nil];
                [[theValue([migratedSchemaVersion intValue]) should] equal:theValue(9)];
            });
        });

        context(@"Migration from scheme version 9 to 10", ^{
            beforeAll(^{
                AMADatabaseMigrationManager *migrationManager =
                    [[AMADatabaseMigrationManager alloc] initWithCurrentSchemeVersion:10
                                                                     schemeMigrations:@[[AMAConfigurationDatabaseSchemeMigrationTo10 new]]
                                                                     apiKeyMigrations:@[]
                                                                       dataMigrations:@[]
                                                                    libraryMigrations:@[]];
                database = [AMADatabaseMigrationTestsUtils databaseForName:@"storage-version-9"
                                                          migrationManager:migrationManager];
            });
            it(@"Should change column `updated_at` to `last_event_time` and `pause_time` in `sessions` table", ^{
                [database inDatabase:^(AMAFMDatabase *db) {
                    [[theValue([db columnExists:@"last_event_time" inTableWithName:@"sessions"]) should] beYes];
                    [[theValue([db columnExists:@"pause_time" inTableWithName:@"sessions"]) should] beYes];
                    [[theValue([db columnExists:@"updated_at" inTableWithName:@"sessions"]) should] beNo];
                }];
            });
            it(@"Should use value of `updated_at` as values of `last_event_time` and `pause_time`", ^{
                [database inDatabase:^(AMAFMDatabase *db) {
                    NSString *query = @"SELECT * FROM sessions WHERE api_key = ? ORDER BY id DESC LIMIT 1";
                    AMAFMResultSet *rs = [db executeQuery:query, @"1111"];
                    [[theValue([rs next]) should] beYes];
                    [[[rs stringForColumn:@"pause_time"] should] equal:@"1418742210.99402"];
                    [[[rs stringForColumn:@"last_event_time"] should] equal:@"1418742210.99402"];
                    [rs close];
                }];
            });
            it(@"Should write schema version", ^{
                NSString *migratedSchemaVersion =
                    [database.storageProvider.syncStorage stringForKey:kAMADatabaseKeySchemaVersion error:nil];
                [[theValue([migratedSchemaVersion intValue]) should] equal:theValue(10)];
            });
        });

        context(@"Migration from scheme version 10 to 11", ^{
            beforeAll(^{
                AMADatabaseMigrationManager *migrationManager =
                    [[AMADatabaseMigrationManager alloc] initWithCurrentSchemeVersion:11
                                                                     schemeMigrations:@[[AMAConfigurationDatabaseSchemeMigrationTo11 new]]
                                                                     apiKeyMigrations:@[]
                                                                       dataMigrations:@[]
                                                                    libraryMigrations:@[]];
                database = [AMADatabaseMigrationTestsUtils databaseForName:@"storage-version-10"
                                                          migrationManager:migrationManager];
            });
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            context(@"Crash reports moved in events table", ^{
                NSString *crashName = @"migration_test_crash"; // hardcoded in storage-version-10 errors table
                NSDictionary *__block eventDictionary = nil;
                beforeAll(^{
                    [database inDatabase:^(AMAFMDatabase *db) {
                        NSString *query = @"SELECT * FROM events WHERE name = ? and type = ? ORDER BY id DESC LIMIT 1";
                        AMAFMResultSet *rs = [db executeQuery:query, crashName, @(3)];
                        [[theValue([rs next]) should] beYes];
                        eventDictionary = rs.resultDictionary;
                        [rs close];
                    }];
                });
                it(@"Should have correct id", ^{
                    [[eventDictionary[@"id"] should] equal:@25]; // first empty id in storage-version-10 events table
                });
                it(@"Should have correct name", ^{
                    [[eventDictionary[@"name"] should] equal:crashName];
                });
                it(@"Should have correct type", ^{
                    [[theValue([eventDictionary[@"type"] integerValue]) should] equal:theValue(3)];
                });
            });
#pragma clang diagnostic pop
            it(@"Should drop errors table", ^{
                [database inDatabase:^(AMAFMDatabase *db) {
                    [[theValue([db tableExists:@"errors"]) should] beNo];
                }];
            });
            it(@"Should write schema version", ^{
                NSString *migratedSchemaVersion =
                    [database.storageProvider.syncStorage stringForKey:kAMADatabaseKeySchemaVersion error:nil];
                [[theValue([migratedSchemaVersion intValue]) should] equal:theValue(11)];
            });
        });

        context(@"Migration from scheme version 11 to 12", ^{
            beforeAll(^{
                AMADatabaseMigrationManager *migrationManager =
                    [[AMADatabaseMigrationManager alloc] initWithCurrentSchemeVersion:12
                                                                     schemeMigrations:@[[AMAConfigurationDatabaseSchemeMigrationTo12 new]]
                                                                     apiKeyMigrations:@[]
                                                                       dataMigrations:@[]
                                                                    libraryMigrations:@[]];
                database = [AMADatabaseMigrationTestsUtils databaseForName:@"storage-version-11"
                                                          migrationManager:migrationManager];
            });
            it(@"Should migrate reportsURL into reportHosts", ^{
                NSString *jsonString = [database.storageProvider.syncStorage stringForKey:AMAStorageStringKeyReportHosts error:nil];
                NSArray *hosts = [AMAJSONSerialization arrayWithJSONString:jsonString error:NULL];
                [[hosts should] equal:@[ @"http://appmetrica.heroism.com" ]];
            });
            it(@"Should drop reportsURL", ^{
                NSString *reportsURL = [database.storageProvider.syncStorage stringForKey:AMAStorageStringKeyReportsURL error:nil];
                [[reportsURL should] beNil];
            });
            it(@"Should write schema version", ^{
                NSString *migratedSchemaVersion =
                    [database.storageProvider.syncStorage stringForKey:kAMADatabaseKeySchemaVersion error:nil];
                [[theValue([migratedSchemaVersion intValue]) should] equal:theValue(12)];
            });
        });
        context(@"Migration from scheme version 12 to 13", ^{
            beforeAll(^{
                AMADatabaseMigrationManager *migrationManager =
                    [[AMADatabaseMigrationManager alloc] initWithCurrentSchemeVersion:13
                                                                     schemeMigrations:@[[AMAConfigurationDatabaseSchemeMigrationTo13 new]]
                                                                     apiKeyMigrations:@[]
                                                                       dataMigrations:@[]
                                                                    libraryMigrations:@[]];
                database = [AMADatabaseMigrationTestsUtils databaseForName:@"storage-version-12"
                                                          migrationManager:migrationManager];
            });
            it(@"Should migrate with locationEnabled set to -1 (undefined)", ^{
                [database inDatabase:^(AMAFMDatabase *db) {
                    AMAFMResultSet *rs = [db executeQuery:@"SELECT location_enabled FROM events LIMIT 1"];
                    [[theValue([rs next]) should] beYes];
                    [[theValue([rs intForColumnIndex:0]) should] equal:theValue(AMAOptionalBoolUndefined)];
                    [rs close];
                }];
            });
            it(@"Should write schema version", ^{
                NSString *migratedSchemaVersion =
                    [database.storageProvider.syncStorage stringForKey:kAMADatabaseKeySchemaVersion error:nil];
                [[theValue([migratedSchemaVersion intValue]) should] equal:theValue(13)];
            });
        });
        context(@"Migration from scheme version 13 to 14", ^{
            beforeAll(^{
                AMADatabaseMigrationManager *migrationManager =
                    [[AMADatabaseMigrationManager alloc] initWithCurrentSchemeVersion:14
                                                                     schemeMigrations:@[[AMAConfigurationDatabaseSchemeMigrationTo14 new]]
                                                                     apiKeyMigrations:@[]
                                                                       dataMigrations:@[]
                                                                    libraryMigrations:@[]];
                database = [AMADatabaseMigrationTestsUtils databaseForName:@"storage-version-13"
                                                          migrationManager:migrationManager];
            });
            it(@"Should migrate new empty field user_profile_id", ^{
                [database inDatabase:^(AMAFMDatabase *db) {
                    AMAFMResultSet *rs = [db executeQuery:@"SELECT user_profile_id FROM events LIMIT 1"];
                    [[theValue([rs next]) should] beYes];
                    [[[rs stringForColumnIndex:0] should] beNil];
                    [rs close];
                }];
            });
            it(@"Should write schema version", ^{
                NSString *migratedSchemaVersion =
                    [database.storageProvider.syncStorage stringForKey:kAMADatabaseKeySchemaVersion error:nil];
                [[theValue([migratedSchemaVersion intValue]) should] equal:theValue(14)];
            });
        });
        context(@"Migration from scheme version 14 to 15", ^{
            beforeEach(^{
                AMADatabaseMigrationManager *migrationManager =
                    [[AMADatabaseMigrationManager alloc] initWithCurrentSchemeVersion:15
                                                                     schemeMigrations:@[[AMAConfigurationDatabaseSchemeMigrationTo15 new]]
                                                                     apiKeyMigrations:@[]
                                                                       dataMigrations:@[]
                                                                    libraryMigrations:@[]];
                database = [AMADatabaseMigrationTestsUtils databaseForName:@"storage-version-14"
                                                          migrationManager:migrationManager];
            });
            it(@"Should write schema version", ^{
                NSString *migratedSchemaVersion =
                    [database.storageProvider.syncStorage stringForKey:kAMADatabaseKeySchemaVersion error:nil];
                [[theValue([migratedSchemaVersion intValue]) should] equal:theValue(15)];
            });
        });
        context(@"Migration from scheme version 15 to 16", ^{
            beforeEach(^{
                AMADatabaseMigrationManager *migrationManager =
                    [[AMADatabaseMigrationManager alloc] initWithCurrentSchemeVersion:16
                                                                     schemeMigrations:@[[AMAConfigurationDatabaseSchemeMigrationTo16 new]]
                                                                     apiKeyMigrations:@[]
                                                                       dataMigrations:@[]
                                                                    libraryMigrations:@[]];
                database = [AMADatabaseMigrationTestsUtils databaseForName:@"storage-version-15"
                                                          migrationManager:migrationManager];
            });
            it(@"Should add column session_id in sessions table", ^{
                [database inDatabase:^(AMAFMDatabase *db) {
                    [[theValue([db columnExists:@"session_id" inTableWithName:@"sessions"]) should] beYes];
                }];
            });
            it(@"Should write schema version", ^{
                NSString *migratedSchemaVersion =
                    [database.storageProvider.syncStorage stringForKey:kAMADatabaseKeySchemaVersion error:nil];
                [[theValue([migratedSchemaVersion intValue]) should] equal:theValue(16)];
            });
        });
        context(@"Migration from scheme version 16 to 17", ^{
            beforeEach(^{
                AMADatabaseMigrationManager *migrationManager =
                    [[AMADatabaseMigrationManager alloc] initWithCurrentSchemeVersion:17
                                                                     schemeMigrations:@[[AMAConfigurationDatabaseSchemeMigrationTo17 new]]
                                                                     apiKeyMigrations:@[]
                                                                       dataMigrations:@[]
                                                                    libraryMigrations:@[]];
                database = [AMADatabaseMigrationTestsUtils databaseForBackupName:@"storage-version-16"
                                                                migrationManager:migrationManager];
            });
            it(@"Should add startup.has.first to kv", ^{
                BOOL hadFirstStartup = [database.storageProvider.syncStorage boolNumberForKey:AMAStorageStringKeyHadFirstStartup
                                                                                        error:nil].boolValue;
                [[theValue(hadFirstStartup) should] equal:theValue(YES)];
            });
            it(@"Should write schema version", ^{
                NSString *migratedSchemaVersion =
                    [database.storageProvider.syncStorage stringForKey:kAMADatabaseKeySchemaVersion error:nil];
                [[theValue([migratedSchemaVersion intValue]) should] equal:theValue(17)];
            });
        });
        context(@"Migration from scheme version 17 to 18", ^{
            beforeEach(^{
                AMADatabaseMigrationManager *migrationManager =
                    [[AMADatabaseMigrationManager alloc] initWithCurrentSchemeVersion:18
                                                                     schemeMigrations:@[[AMAConfigurationDatabaseSchemeMigrationTo18 new]]
                                                                     apiKeyMigrations:@[]
                                                                       dataMigrations:@[]
                                                                    libraryMigrations:@[]];
                database = [AMADatabaseMigrationTestsUtils databaseForBackupName:@"storage-version-17"
                                                                migrationManager:migrationManager];
            });
            it(@"Should migrate new zero field global_number", ^{
                [database inDatabase:^(AMAFMDatabase *db) {
                    AMAFMResultSet *rs = [db executeQuery:@"SELECT global_number FROM events LIMIT 1"];
                    [[theValue([rs next]) should] beYes];
                    [[theValue([rs longLongIntForColumnIndex:0]) should] beZero];
                    [rs close];
                }];
            });
            it(@"Should migrate new zero field number_of_type", ^{
                [database inDatabase:^(AMAFMDatabase *db) {
                    AMAFMResultSet *rs = [db executeQuery:@"SELECT number_of_type FROM events LIMIT 1"];
                    [[theValue([rs next]) should] beYes];
                    [[theValue([rs longLongIntForColumnIndex:0]) should] beZero];
                    [rs close];
                }];
            });
            it(@"Should write schema version", ^{
                NSString *migratedSchemaVersion =
                    [database.storageProvider.syncStorage stringForKey:kAMADatabaseKeySchemaVersion error:nil];
                [[theValue([migratedSchemaVersion intValue]) should] equal:theValue(18)];
            });
        });
        context(@"Migration from scheme version 18 to 19", ^{
            AMADatabaseMigrationManager *__block migrationManager = nil;
            beforeEach(^{
                migrationManager =
                    [[AMADatabaseMigrationManager alloc] initWithCurrentSchemeVersion:19
                                                                     schemeMigrations:@[[AMAConfigurationDatabaseSchemeMigrationTo19 new]]
                                                                     apiKeyMigrations:@[[AMAMigrationTo19FinalizationOnApiKeySpecified new]]
                                                                       dataMigrations:@[]
                                                                    libraryMigrations:@[]];
                database = [AMADatabaseMigrationTestsUtils databaseForBackupName:@"storage-version-18"
                                                                migrationManager:migrationManager];
            });
            context(@"Migrated", ^{
                AMAReporterStorage *__block storage = nil;
                beforeEach(^{
                    [database ensureMigrated];
                    [migrationManager applyApiKeyMigrationsWithKey:[AMAReporterTestHelper defaultApiKey]
                                                        toDatabase:database];
                });
                context(@"Main reporter", ^{
                    beforeEach(^{
                        storage = reporterTestHelper.appReporter.reporterStorage;
                    });
                    it(@"Should have valid events count", ^{
                        [[theValue([storage.eventStorage totalCountOfEventsWithTypes:@[]]) should] equal:theValue(23)];
                    });
                    context(@"State", ^{
                        AMAReporterStateStorage *__block stateStorage = nil;
                        beforeEach(^{
                            stateStorage = storage.stateStorage;
                        });
                        it(@"Should have valid session ID", ^{
                            NSNumber *sessionID =
                                [stateStorage.sessionIDStorage valueWithStorage:storage.keyValueStorageProvider.syncStorage];
                            [[sessionID should] equal:@10000000005];
                        });
                        it(@"Should have valid attribution ID", ^{
                            NSNumber *sessionID =
                            [stateStorage.attributionIDStorage valueWithStorage:storage.keyValueStorageProvider.syncStorage];
                            [[sessionID should] equal:@2];
                        });
                        it(@"Should have first event sent", ^{
                            [[theValue(stateStorage.firstEventSent) should] beYes];
                        });
                        it(@"Should have init event sent", ^{
                            [[theValue(stateStorage.initEventSent) should] beYes];
                        });
                        it(@"Should have valid profile ID", ^{
                            [[stateStorage.profileID should] equal:@"PROFILE_ID"];
                        });
                    });
                    context(@"Report request", ^{
                        NSArray *__block requestModels = nil;
                        beforeAll(^{
                            requestModels = [storage.reportRequestProvider requestModels];
                        });
                        it(@"Should have valid count", ^{
                            [[requestModels should] haveCountOf:3];
                        });
                        context(@"First request model", ^{
                            AMAReportRequestModel *__block requestModel = nil;
                            beforeAll(^{
                                requestModel = requestModels.firstObject;
                            });
                            it(@"Should have valid apiKey", ^{
                                [[requestModel.apiKey should] equal:[AMAReporterTestHelper defaultApiKey]];
                            });
                            it(@"Should have valid attributionID", ^{
                                [[requestModel.attributionID should] equal:@"1"];
                            });
                            it(@"Should have nil appEnvironment", ^{
                                [[requestModel.appEnvironment should] beNil];
                            });
                            it(@"Should have valid appState", ^{
                                NSDictionary *expected = @{
                                    @"analytics_sdk_build_number": @"0",
                                    @"analytics_sdk_build_type": @"static",
                                    @"analytics_sdk_version_name": @"3.7.1",
                                    @"app_build_number": @"0",
                                    @"app_debuggable": @"1",
                                    @"app_version_name": @"371",
                                    @"deviceid": @"96A20D12-E5D6-4F36-8886-77B3E56B64C0",
                                    @"ifa": @"C3531E71-A803-465C-8923-32A9389E667C",
                                    @"ifv": @"189973FE-FE69-40D8-BFC5-5E00744585E4",
                                    @"is_rooted": @"1",
                                    @"limit_ad_tracking": @"0",
                                    @"locale": @"en_US",
                                    @"os_api_level": @"12",
                                    @"os_version": @"12.2",
                                    @"uuid": @"59a050e331fe457ab300882db3e2f2c5",
                                };
                                [[requestModel.appState.dictionaryRepresentation should] equal:expected];
                            });
                            it(@"Should have valid events batches count", ^{
                                [[requestModel.eventsBatches should] haveCountOf:2];
                            });
                            context(@"Event bacth", ^{
                                AMAReportEventsBatch *__block batch = nil;
                                beforeAll(^{
                                    batch = requestModel.eventsBatches[1];
                                });
                                context(@"Session", ^{
                                    AMASession *__block session = nil;
                                    beforeAll(^{
                                        session = batch.session;
                                    });
                                    it(@"Should have valid start time", ^{
                                        NSTimeInterval interval = session.startDate.deviceDate.timeIntervalSince1970;
                                        [[theValue(interval) should] equal:1568284188.62191 withDelta:0.001];
                                    });
                                    it(@"Should have valid seq number", ^{
                                        [[theValue(session.eventSeq) should] equal:theValue(10)];
                                    });
                                    it(@"Should have valid type", ^{
                                        [[theValue(session.type) should] equal:theValue(AMASessionTypeGeneral)];
                                    });
                                    it(@"Should be finished", ^{
                                        [[theValue(session.finished) should] beYes];
                                    });
                                    it(@"Should have valid sessionID", ^{
                                        [[session.sessionID should] equal:@10000000001];
                                    });
                                });
                                it(@"Should have valid events count", ^{
                                    [[batch.events should] haveCountOf:10];
                                });
                                context(@"Start event", ^{
                                    AMAEvent *__block event = nil;
                                    beforeAll(^{
                                        event = batch.events[0];
                                    });
                                    it(@"Should have valid type", ^{
                                        [[theValue(event.type) should] equal:theValue(AMAEventTypeStart)];
                                    });
                                    it(@"Should have valid createdAt", ^{
                                        NSTimeInterval interval = event.createdAt.timeIntervalSince1970;
                                        [[theValue(interval) should] equal:1568284188.62191 withDelta:0.001];
                                    });
                                    it(@"Should have valid number in session", ^{
                                        [[theValue(event.sequenceNumber) should] equal:theValue(0)];
                                    });
                                    it(@"Should have valid number of type", ^{
                                        [[theValue(event.numberOfType) should] equal:theValue(1)];
                                    });
                                    it(@"Should have valid global number", ^{
                                        [[theValue(event.globalNumber) should] equal:theValue(3)];
                                    });
                                    it(@"Should have no location", ^{
                                        [[event.location should] beNil];
                                    });
                                });
                                context(@"Revenue event", ^{
                                    AMAEvent *__block event = nil;
                                    beforeAll(^{
                                        event = batch.events[3];
                                    });
                                    it(@"Should have valid type", ^{
                                        [[theValue(event.type) should] equal:theValue(AMAEventTypeRevenue)];
                                    });
                                    it(@"Should have valid createdAt", ^{
                                        NSTimeInterval interval = event.createdAt.timeIntervalSince1970;
                                        [[theValue(interval) should] equal:1568284198.57149 withDelta:0.001];
                                    });
                                    it(@"Should have valid value type", ^{
                                        [[((NSObject *)event.value) should] beKindOfClass:[AMABinaryEventValue class]];
                                    });
                                    it(@"Should have non-empty value", ^{
                                        [[((AMABinaryEventValue *)event.value).data shouldNot] beEmpty];
                                    });
                                });
                                context(@"Client event", ^{
                                    AMAEvent *__block event = nil;
                                    beforeAll(^{
                                        event = batch.events[6];
                                    });
                                    it(@"Should have valid type", ^{
                                        [[theValue(event.type) should] equal:theValue(AMAEventTypeClient)];
                                    });
                                    it(@"Should have valid createdAt", ^{
                                        NSTimeInterval interval = event.createdAt.timeIntervalSince1970;
                                        [[theValue(interval) should] equal:1568284198.58189 withDelta:0.001];
                                    });
                                    it(@"Should have valid name", ^{
                                        [[event.name should] equal:@"EVENT_1"];
                                    });
                                    it(@"Should have valid value type", ^{
                                        [[((NSObject *)event.value) should] beKindOfClass:[AMAStringEventValue class]];
                                    });
                                    it(@"Should have non-empty value", ^{
                                        [[((AMAStringEventValue *)event.value).value should] equal:@"{\"foo\":\"bar\"}"];
                                    });
                                    context(@"Location", ^{
                                        CLLocation *__block location = nil;
                                        beforeAll(^{
                                            location = event.location;
                                        });
                                        it(@"Should have valid latitude", ^{
                                            [[theValue(location.coordinate.latitude) should] equal:37.33155419
                                                                                         withDelta:0.0000001];
                                        });
                                        it(@"Should have valid latitude", ^{
                                            [[theValue(location.coordinate.longitude) should] equal:-122.03068145
                                                                                          withDelta:0.0000001];
                                        });
                                        it(@"Should have valid altitude", ^{
                                            [[theValue(location.altitude) should] equal:23.15 withDelta:0.01];
                                        });
#if TARGET_OS_TV
                                        it(@"Should have invalid direction for tv", ^{
                                            [[theValue(location.course) should] equal:theValue(-1)];
                                        });
                                        it(@"Should have invalid speed for tv", ^{
                                            [[theValue(location.speed) should] equal:theValue(-1)];
                                        });
#else
                                        it(@"Should have valid direction", ^{
                                            [[theValue(location.course) should] equal:241.62 withDelta:0.01];
                                        });
                                        it(@"Should have valid speed", ^{
                                            [[theValue(location.speed) should] equal:4.14 withDelta:0.01];
                                        });
#endif
                                        it(@"Should have valid horizontal accuracy", ^{
                                            [[theValue(location.horizontalAccuracy) should] equal:30.0 withDelta:0.1];
                                        });
                                        it(@"Should have valid vertical accuracy", ^{
                                            [[theValue(location.verticalAccuracy) should] equal:10.0 withDelta:0.1];
                                        });
                                        it(@"Should have valid timestamp", ^{
                                            [[theValue(location.timestamp.timeIntervalSince1970) should] equal:1568284196.46777
                                                                                                     withDelta:0.001];
                                        });
                                    });
                                });
                            });
                        });
                        context(@"Last request model", ^{
                            AMAReportRequestModel *__block requestModel = nil;
                            beforeAll(^{
                                requestModel = requestModels.lastObject;
                            });
                            it(@"Should have valid apiKey", ^{
                                [[requestModel.apiKey should] equal:[AMAReporterTestHelper defaultApiKey]];
                            });
                            it(@"Should have valid attributionID", ^{
                                [[requestModel.attributionID should] equal:@"2"];
                            });
                            it(@"Should have nil appEnvironment", ^{
                                [[requestModel.appEnvironment should] beNil];
                            });
                            it(@"Should have valid events batches count", ^{
                                [[requestModel.eventsBatches should] haveCountOf:3];
                            });
                            context(@"Second event bacth", ^{
                                AMAReportEventsBatch *__block batch = nil;
                                beforeAll(^{
                                    batch = requestModel.eventsBatches[1];
                                });
                                context(@"Session", ^{
                                    AMASession *__block session = nil;
                                    beforeAll(^{
                                        session = batch.session;
                                    });
                                    it(@"Should have valid start time", ^{
                                        NSTimeInterval interval = session.startDate.deviceDate.timeIntervalSince1970;
                                        [[theValue(interval) should] equal:1568284335.37126 withDelta:0.001];
                                    });
                                    it(@"Should have valid seq number", ^{
                                        [[theValue(session.eventSeq) should] equal:theValue(2)];
                                    });
                                    it(@"Should have valid type", ^{
                                        [[theValue(session.type) should] equal:theValue(AMASessionTypeBackground)];
                                    });
                                    it(@"Should be finished", ^{
                                        [[theValue(session.finished) should] beYes];
                                    });
                                    it(@"Should have valid sessionID", ^{
                                        [[session.sessionID should] equal:@10000000004];
                                    });
                                });
                                it(@"Should have valid events count", ^{
                                    [[batch.events should] haveCountOf:2];
                                });
                                context(@"Crash event", ^{
                                    AMAEvent *__block event = nil;
                                    beforeAll(^{
                                        event = batch.events[1];
                                    });
                                    it(@"Should have valid type", ^{
                                        [[theValue(event.type) should] equal:theValue(AMAEventTypeProtobufCrash)];
                                    });
                                    it(@"Should have valid createdAt", ^{
                                        NSTimeInterval interval = event.createdAt.timeIntervalSince1970;
                                        [[theValue(interval) should] equal:1568284335.37126 withDelta:0.001];
                                    });
                                    it(@"Should have valid value type", ^{
                                        [[((NSObject *)event.value) should] beKindOfClass:[AMAFileEventValue class]];
                                    });
                                    it(@"Should have valid file path", ^{
                                        [[((AMAFileEventValue *)event.value).relativeFilePath should] equal:@"015EFEA0-FA89-44EC-BBFB-FD429BF01EF6.crash"];
                                    });
                                    it(@"Should have valid encryption type", ^{
                                        [[theValue(((AMAFileEventValue *)event.value).encryptionType) should] equal:theValue(AMAEventEncryptionTypeNoEncryption)];
                                    });
                                });
                            });
                            context(@"Third event bacth", ^{
                                AMAReportEventsBatch *__block batch = nil;
                                beforeAll(^{
                                    batch = requestModel.eventsBatches[2];
                                });
                                context(@"Session", ^{
                                    AMASession *__block session = nil;
                                    beforeAll(^{
                                        session = batch.session;
                                    });
                                    it(@"Should have valid start time", ^{
                                        NSTimeInterval interval = session.startDate.deviceDate.timeIntervalSince1970;
                                        [[theValue(interval) should] equal:1568284335.41832 withDelta:0.001];
                                    });
                                    it(@"Should have valid seq number", ^{
                                        [[theValue(session.eventSeq) should] equal:theValue(2)];
                                    });
                                    it(@"Should have valid type", ^{
                                        [[theValue(session.type) should] equal:theValue(AMASessionTypeGeneral)];
                                    });
                                    it(@"Should be finished", ^{
                                        [[theValue(session.finished) should] beNo];
                                    });
                                    it(@"Should have valid sessionID", ^{
                                        [[session.sessionID should] equal:@10000000005];
                                    });
                                });
                                it(@"Should have valid events count", ^{
                                    [[batch.events should] haveCountOf:1];
                                });
                            });
                        });
                    });
                });
                context(@"Second reporter", ^{
                    beforeEach(^{
                        storage = [reporterTestHelper appReporterForApiKey:@"6e0b1717-fe18-4112-a5e9-95102fbf0747"].reporterStorage;
                    });
                    it(@"Should have valid events count", ^{
                        [[theValue([storage.eventStorage totalCountOfEventsWithTypes:@[]]) should] equal:theValue(10)];
                    });
                    context(@"State", ^{
                        AMAReporterStateStorage *__block stateStorage = nil;
                        beforeEach(^{
                            stateStorage = storage.stateStorage;
                        });
                        it(@"Should have first event sent", ^{
                            [[theValue(stateStorage.firstEventSent) should] beYes];
                        });
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                        it(@"Should have empty referrer event sent", ^{
                            [[theValue(stateStorage.emptyReferrerEventSent) should] beYes];
                        });
#pragma clang diagnostic pop
                        it(@"Should have valid app environment", ^{
                            [[stateStorage.appEnvironment.dictionaryEnvironment should] equal:@{@"foo": @"bar"}];
                        });
                    });
                });
                context(@"Library reporter", ^{
                    beforeEach(^{
                        storage = [reporterTestHelper appReporterForApiKey:@"20799a27-fa80-4b36-b2db-0f8141f24180"].reporterStorage;
                    });
                    it(@"Should have valid events count", ^{
                        [[theValue([storage.eventStorage totalCountOfEventsWithTypes:@[]]) should] equal:theValue(11)];
                    });
                    context(@"State", ^{
                        AMAReporterStateStorage *__block stateStorage = nil;
                        beforeEach(^{
                            stateStorage = storage.stateStorage;
                        });
                        it(@"Should have first event sent", ^{
                            [[theValue(stateStorage.firstEventSent) should] beYes];
                        });
                        it(@"Should have update event sent", ^{
                            [[theValue(stateStorage.updateEventSent) should] beYes];
                        });
                    });
                });
            });
            it(@"Should write schema version", ^{
                NSString *migratedSchemaVersion =
                    [database.storageProvider.syncStorage stringForKey:kAMADatabaseKeySchemaVersion error:nil];
                [[theValue([migratedSchemaVersion intValue]) should] equal:theValue(19)];
            });
        });
        context(@"Migration from scheme version 19 to 20", ^{
            beforeEach(^{
                AMADatabaseMigrationManager *migrationManager =
                    [[AMADatabaseMigrationManager alloc] initWithCurrentSchemeVersion:20
                                                                     schemeMigrations:@[[AMAConfigurationDatabaseSchemeMigrationTo20 new]]
                                                                     apiKeyMigrations:@[]
                                                                       dataMigrations:@[]
                                                                    libraryMigrations:@[]];
                database = [AMADatabaseMigrationTestsUtils databaseForBackupName:@"storage-version-19"
                                                                migrationManager:migrationManager];
            });
            it(@"Should change KV column types", ^{
                [database inDatabase:^(AMAFMDatabase *db) {
                    AMAFMResultSet *rs = [db getTableSchema:@"kv"];
                    NSMutableDictionary *types = [NSMutableDictionary dictionary];
                    while ([rs next]) {
                        types[[rs stringForColumn:@"name"]] = [rs stringForColumn:@"type"];
                    }
                    [[types should] equal:@{ @"k": @"TEXT", @"v": @"TEXT" }];
                    [rs close];
                }];
            });
            context(@"KV items", ^{
                it(@"Should migrate device ID", ^{
                    [database inDatabase:^(AMAFMDatabase *db) {
                        NSString *key = @"fallback-keychain-YMMMetricaPersistentConfigurationDeviceIDStorageKey";
                        NSString *value = [[database.storageProvider storageForDB:db] stringForKey:key error:nil];
                        [[value should] equal:@"8B1C3660-9F81-4FC4-A720-85032F5F9849"];
                    }];
                });
                it(@"Should migrate UUID", ^{
                    [database inDatabase:^(AMAFMDatabase *db) {
                        NSString *key = @"uuid";
                        NSString *value = [[database.storageProvider storageForDB:db] stringForKey:key error:nil];
                        [[value should] equal:@"59a050e331fe457ab300882db3e2f2c5"];
                    }];
                });
                it(@"Should migrate startup update date", ^{
                    [database inDatabase:^(AMAFMDatabase *db) {
                        NSString *key = @"startup.updated_at";
                        NSString *value = [[database.storageProvider storageForDB:db] stringForKey:key error:nil];
                        [[value should] equal:@"1568284190.23964"];
                    }];
                });
                it(@"Should remove device ID hash", ^{
                    [database inDatabase:^(AMAFMDatabase *db) {
                        NSString *key = @"fallback-keychain-YMMMetricaPersistentConfigurationDeviceIDHashStorageKey";
                        NSString *value = [[database.storageProvider storageForDB:db] stringForKey:key error:nil];
                        [[value should] beNil];
                    }];
                });
            });
            it(@"Should write schema version", ^{
                NSString *migratedSchemaVersion =
                [database.storageProvider.syncStorage stringForKey:kAMADatabaseKeySchemaVersion error:nil];
                [[theValue([migratedSchemaVersion intValue]) should] equal:theValue(20)];
            });
        });
    });
    context(@"Library version migration", ^{
        context(@"Migration to 3.2.0", ^{
            beforeEach(^{
                AMADatabaseMigrationManager *migrationManager =
                    [[AMADatabaseMigrationManager alloc] initWithCurrentSchemeVersion:19
                                                                     schemeMigrations:@[]
                                                                     apiKeyMigrations:@[]
                                                                       dataMigrations:@[]
                                                                    libraryMigrations:@[[[AMALibraryMigration320 alloc] init]]];
                database = [AMADatabaseMigrationTestsUtils databaseForBackupName:@"storage-library-initial"
                                                                migrationManager:migrationManager];
            });
            it(@"Should reset startup.updated_at value", ^{
                NSDate *date = [database.storageProvider.syncStorage dateForKey:AMAStorageStringKeyStartupUpdatedAt error:nil];
                [[date should] equal:[NSDate distantPast]];
            });
            it(@"Should write library version", ^{
                NSString *migratedLibraryVersion = [database.storageProvider.syncStorage stringForKey:kAMADatabaseKeyLibraryVersion
                                                                                                error:nil];
                [[migratedLibraryVersion should] equal:[AMAPlatformDescription SDKVersionName]];
            });
        });
    });
});

SPEC_END
