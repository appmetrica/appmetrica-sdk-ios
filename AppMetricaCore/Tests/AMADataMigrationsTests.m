
#import <Kiwi/Kiwi.h>
#import <sqlite3.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import <AppMetricaKeychain/AppMetricaKeychain.h>
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
#import "AMADataMigrationTo500.h"
#import "AMADataMigrationTo5100.h"
#import "AMALocationDataMigrationTo500.h"
#import "AMALocationDataMigrationTo5100.h"
#import "AMAReporterDataMigrationTo500.h"
#import "AMAReporterDataMigrationTo580.h"
#import "AMADataMigrationTo590.h"
#import "AMAReporterDataMigrationTo5100.h"
#import "AMADataMigrationTo580.h"
#import "AMADatabaseMigrationManager.h"
#import "AMAReporterTestHelper.h"
#import "AMADate.h"
#import "AMAFileEventValue.h"
#import "AMAEnvironmentContainer.h"
#import <AppMetricaPlatform/AppMetricaPlatform.h>
#import <AppMetricaFMDB/AppMetricaFMDB.h>
#import "AMAMigrationTo500Utils.h"
#import "AMATableDescriptionProvider.h"
#import "AMAKeyValueStorageProvidersFactory.h"
#import "AMAInstantFeaturesConfiguration+Migration.h"
#import "AMABinaryDatabaseKeyValueStorageConverter.h"
#import "AMAEventsCleaner.h"
#import "AMASharedReporterProvider.h"
#import "AMAEventBuilder.h"
#import "AMALegacyEventExtrasProvider.h"
#import "AMAEventNameHashesCollection.h"
#import "AMAEventNameHashesStorageFactory+Migration.h"
#import "AMAEventNameHashesStorage.h"
#import "AMAEventSerializer+Migration.h"
#import "AMASessionSerializer+Migration.h"
#import "AMALocationStorage.h"
#import "AMALocationCollectingConfiguration.h"
#import "AMALocationSerializer.h"
#import <AppMetricaEncodingUtils/AppMetricaEncodingUtils.h>
#import "AMALocationEncoderFactory.h"
#import "AMALocationMigrationTo500EncoderFactory.h"
#import "AMALocationMigrationTo5100EncoderFactory.h"
#import "AMALocation.h"
#import "AMAVisit.h"
#import "AMAMetricaConfiguration.h"
#import "AMAMetricaPersistentConfiguration.h"
#import "AMADatabaseMigrationTestsUtils.h"
#import "AMAStartupParametersConfiguration.h"
#import "AMADatabaseHelper.h"
#import "AMAAppMetricaUUIDMigrator.h"
#import "AMAReporterStateStorage.h"

@import AppMetricaIdentifiers;

@interface AMAMigrationTo500Utils ()

+ (NSString *)crashReportsWithBundleName:(NSString *)bundleName;

@end

SPEC_BEGIN(AMADataMigrationsTests)

describe(@"AMADataMigrationsTests", ^{
    AMAReporterTestHelper *__block reporterTestHelper = nil;
    AMAMetricaPersistentConfiguration *__block persistentMock = nil;
    AMAMetricaConfiguration *__block configuration = nil;
    AMAInstantFeaturesConfiguration *__block instantMock = nil;
    
    NSString *const key = @"foo";
    NSString *const value = @"bar";
    
    beforeEach(^{
        reporterTestHelper = [[AMAReporterTestHelper alloc] init];
        
        configuration = [AMAMetricaConfiguration nullMock];
        persistentMock = [AMAMetricaPersistentConfiguration nullMock];
        instantMock = [AMAInstantFeaturesConfiguration nullMock];
        [AMAInstantFeaturesConfiguration stub:@selector(sharedInstance) andReturn:instantMock];
        
        [configuration stub:@selector(persistent) andReturn:persistentMock];
        [configuration stub:@selector(startup) andReturn:[AMAStartupParametersConfiguration nullMock]];
        [configuration stub:@selector(instant) andReturn:instantMock];
        [AMAMetricaConfiguration stub:@selector(sharedInstance) andReturn:configuration];
    });
    
    AMAReporterStorage *(^reporterStorage)(id<AMADatabaseProtocol>, NSString *, BOOL) = ^(id<AMADatabaseProtocol> database,
                                                                                          NSString *apiKey,
                                                                                          BOOL main) {
        AMAEnvironmentContainer *eventEnvironment = [[AMAEnvironmentContainer alloc] init];
        AMAEventsCleaner *eventsCleaner = [[AMAEventsCleaner alloc] initWithReporterProvider:nil];
        return [[AMAReporterStorage alloc] initWithApiKey:apiKey
                                         eventEnvironment:eventEnvironment
                                            eventsCleaner:eventsCleaner
                                                 database:database
                                                     main:main];
    };
    
    context(@"Configuration database", ^{
        id<AMADatabaseProtocol> __block migrationDatabase = nil;
        id<AMADatabaseDataMigration> __block migration = nil;
        NSString *__block basePath = nil;
        
        beforeEach(^{
            [AMADatabaseMigrationTestsUtils cleanDatabase];
        });
        
        afterEach(^{
            [AMADatabaseMigrationTestsUtils cleanDatabase];
        });
        
        context(@"Migration to 5.0.0", ^{
            beforeEach(^{
                basePath = [AMAMigrationTo500Utils migrationPath];
                migration = [AMADataMigrationTo500 new];
                migrationDatabase = [AMADatabaseMigrationTestsUtils configurationDatabase:basePath];
                
                [AMADatabaseMigrationTestsUtils includeDataMigration:migration
                                                         contentType:AMADatabaseContentTypeConfiguration
                                                          inDatabase:migrationDatabase];
            });
            
            it(@"Should migrate value", ^{
                [migrationDatabase inDatabase:^(AMAFMDatabase *db) {
                    id<AMAKeyValueStoring> storage = [migrationDatabase.storageProvider storageForDB:db];
                    
                    [storage saveString:value forKey:key error:nil];
                }];
                
                id<AMADatabaseProtocol> migratedDB = [AMADatabaseFactory configurationDatabase];
                [migratedDB inDatabase:^(AMAFMDatabase *db) {
                    id<AMAKeyValueStoring> storage = [migratedDB.storageProvider storageForDB:db];
                    
                    [[[storage stringForKey:key error:nil] should] equal:value];
                    [[[storage stringForKey:migration.migrationKey error:nil] should] equal:@"1"];
                }];
            });
            
            it(@"Should use correct version", ^{
                NSString *version = @"0.1.2.3.4";
                [AMAPlatformDescription stub:@selector(SDKVersionName) andReturn:version];
                
                [migrationDatabase inDatabase:^(AMAFMDatabase *db) {
                    id<AMAKeyValueStoring> storage = [migrationDatabase.storageProvider storageForDB:db];
                    
                    [storage saveString:@"4.5.4" forKey:kAMADatabaseKeyLibraryVersion error:nil];
                }];
                
                id<AMADatabaseProtocol> migratedDB = [AMADatabaseFactory configurationDatabase];
                [migratedDB inDatabase:^(AMAFMDatabase *db) {
                    id<AMAKeyValueStoring> storage = [migratedDB.storageProvider storageForDB:db];
                    
                    [[[storage stringForKey:kAMADatabaseKeyLibraryVersion error:nil] should] equal:version];
                    [[[storage stringForKey:migration.migrationKey error:nil] should] equal:@"1"];
                }];
            });
            
            it(@"Should migrate ad url to extended params", ^{
                NSString *const adUrl = @"ad_url";
                NSDictionary *const expected = @{@"get_ad" : adUrl};
                NSString *const adHostKey = @"get_ad.host";
                
                [migrationDatabase inDatabase:^(AMAFMDatabase *db) {
                    id<AMAKeyValueStoring> storage = [migrationDatabase.storageProvider storageForDB:db];
                    
                    [storage saveString:adUrl forKey:adHostKey error:nil];
                }];
                
                id<AMADatabaseProtocol> migratedDB = [AMADatabaseFactory configurationDatabase];
                [migratedDB inDatabase:^(AMAFMDatabase *db) {
                    id<AMAKeyValueStoring> storage = [migratedDB.storageProvider storageForDB:db];
                    
                    [[[storage jsonDictionaryForKey:AMAStorageStringKeyExtendedParameters error:nil] should] equal:expected];
                    [[[storage stringForKey:migration.migrationKey error:nil] should] equal:@"1"];
                }];
            });
            
            it(@"Should reset startup update date", ^{
                id<AMADatabaseProtocol> migratedDB = [AMADatabaseFactory configurationDatabase];
                [migratedDB inDatabase:^(AMAFMDatabase *db) {
                    id<AMAKeyValueStoring> storage = [migratedDB.storageProvider storageForDB:db];
                    
                    [[[storage dateForKey:AMAStorageStringKeyStartupUpdatedAt error:nil] should] equal:[NSDate distantPast]];
                    [[[storage stringForKey:migration.migrationKey error:nil] should] equal:@"1"];
                }];
            });
            
            it(@"Should migrate uuid", ^{
                NSString *const uuid = @"768a11f6f9f4422fa5ec19eb0d8e074a";
                AMAInstantFeaturesConfiguration *migrationConfiguration = [AMAInstantFeaturesConfiguration migrationInstance];
                [migrationConfiguration setUUID:uuid];
                
                [[instantMock should] receive:@selector(setUUID:) withArguments:uuid];
                
                id<AMADatabaseProtocol> migratedDB = [AMADatabaseFactory configurationDatabase];
                [migratedDB inDatabase:^(AMAFMDatabase *db) {
                    id<AMAKeyValueStoring> storage = [migratedDB.storageProvider storageForDB:db];
                    [[[storage stringForKey:migration.migrationKey error:nil] should] equal:@"1"];
                }];
            });
            
            it(@"Should not migrate uuid if configuration does not exist", ^{
                [[instantMock shouldNot] receive:@selector(setUUID:)];
                
                id<AMADatabaseProtocol> migratedDB = [AMADatabaseFactory configurationDatabase];
                [migratedDB inDatabase:^(AMAFMDatabase *db) {
                    id<AMAKeyValueStoring> storage = [migratedDB.storageProvider storageForDB:db];
                    [[[storage stringForKey:migration.migrationKey error:nil] should] equal:@"1"];
                }];
            });
            
            context(@"DeviceID migration", ^{
                NSString *const deviceID = @"E621E1F8-C36C-495A-93FC-0C247A3E6E5F";
                NSString *const deviceIDHash = @"deviceIDHash";
                AMAKeychain *__block keychainMock = nil;
                NSString *const appIdentifierPrefix = @"appIdentifierPrefix";
                AMAKeychainBridge *__block keychainBridge = nil;
                
                beforeEach(^{
                    keychainMock = [AMAKeychain nullMock];
                    [AMAPlatformDescription stub:@selector(appIdentifierPrefix) andReturn:appIdentifierPrefix];
                    keychainBridge = [[AMAKeychainBridge alloc] init];
                });
                
                void (^stubKeychain)(NSString *, NSString *, AMAKeychain *) = ^(NSString *serviceIdentifier,
                                                                                NSString *accessGroup,
                                                                                AMAKeychain *mockedKeychain) {
                    AMAKeychain *allocedKeychain = [AMAKeychain nullMock];
                    [AMAKeychain stub:@selector(alloc) andReturn:allocedKeychain];
                    [allocedKeychain stub:@selector(initWithService:accessGroup:bridge:)
                                andReturn:mockedKeychain
                            withArguments:serviceIdentifier, accessGroup, kw_any()];
                };
                
                it(@"Should migrate deviceID with storage", ^{
                    NSString *const format = @"fallback-keychain-%@";
                    stubKeychain(kAMAMigrationKeychainAppServiceIdentifier, @"", NULL);
                    
                    [migrationDatabase inDatabase:^(AMAFMDatabase *db) {
                        id<AMAKeyValueStoring> storage = [migrationDatabase.storageProvider storageForDB:db];
                        
                        [storage saveString:deviceID
                                     forKey:[NSString stringWithFormat:format, kAMAMigrationDeviceIDStorageKey]
                                      error:nil];
                        [storage saveString:deviceIDHash
                                     forKey:[NSString stringWithFormat:format, kAMAMigrationDeviceIDHashStorageKey]
                                      error:nil];
                    }];
                    
                    
                    [[persistentMock should] receive:@selector(setDeviceID:) withArguments:deviceID];
                    [[persistentMock should] receive:@selector(setDeviceIDHash:) withArguments:deviceIDHash];
                    
                    id<AMADatabaseProtocol> migratedDB = [AMADatabaseFactory configurationDatabase];
                    [migratedDB inDatabase:^(AMAFMDatabase *db) {
                        id<AMAKeyValueStoring> storage = [migratedDB.storageProvider storageForDB:db];
                        
                        [[[storage stringForKey:[NSString stringWithFormat:format, [AMAAppMetricaIdentifiersKeys deviceID]] error:nil] should] equal:deviceID];
                        [[[storage stringForKey:[NSString stringWithFormat:format, [AMAAppMetricaIdentifiersKeys deviceIDHash]] error:nil] should] equal:deviceIDHash];
                        [[[storage stringForKey:migration.migrationKey error:nil] should] equal:@"1"];
                    }];
                });
                
                it(@"Should migrate deviceID with keychain if no prev db", ^{
                    [[NSFileManager defaultManager] removeItemAtPath:basePath error:nil];
                    
                    NSString *accessGroup = [appIdentifierPrefix stringByAppendingString:kAMAMigrationKeychainAccessGroup];
                    stubKeychain(kAMAMigrationKeychainVendorServiceIdentifier, accessGroup, keychainMock);
                    
                    [keychainMock stub:@selector(isAvailable) andReturn:theValue(YES)];
                    [keychainMock stub:@selector(stringValueForKey:error:)
                             andReturn:deviceID
                         withArguments:kAMAMigrationDeviceIDStorageKey, kw_any()];
                    [keychainMock stub:@selector(stringValueForKey:error:)
                             andReturn:deviceIDHash
                         withArguments:kAMAMigrationDeviceIDHashStorageKey, kw_any()];
                    
                    
                    [[persistentMock should] receive:@selector(setDeviceID:) withArguments:deviceID];
                    [[persistentMock should] receive:@selector(setDeviceIDHash:) withArguments:deviceIDHash];
                    
                    id<AMADatabaseProtocol> migratedDB = [AMADatabaseFactory configurationDatabase];
                    [migratedDB inDatabase:^(AMAFMDatabase *db) {
                        id<AMAKeyValueStoring> storage = [migratedDB.storageProvider storageForDB:db];
                        [[[storage stringForKey:migration.migrationKey error:nil] should] equal:@"1"];
                    }];
                });
                
                it(@"Should migrate deviceID with fallback keychain", ^{
                    NSString *accessGroup = [appIdentifierPrefix stringByAppendingString:kAMAMigrationKeychainAccessGroup];
                    stubKeychain(kAMAMigrationKeychainVendorServiceIdentifier, accessGroup, keychainMock);
                    
                    [keychainMock stub:@selector(isAvailable) andReturn:theValue(YES)];
                    [keychainMock stub:@selector(stringValueForKey:error:)
                             andReturn:deviceID
                         withArguments:kAMAMigrationDeviceIDStorageKey, kw_any()];
                    [keychainMock stub:@selector(stringValueForKey:error:)
                             andReturn:deviceIDHash
                         withArguments:kAMAMigrationDeviceIDHashStorageKey, kw_any()];
                    
                    
                    [[persistentMock should] receive:@selector(setDeviceID:) withArguments:deviceID];
                    [[persistentMock should] receive:@selector(setDeviceIDHash:) withArguments:deviceIDHash];
                    
                    id<AMADatabaseProtocol> migratedDB = [AMADatabaseFactory configurationDatabase];
                    [migratedDB inDatabase:^(AMAFMDatabase *db) {
                        id<AMAKeyValueStoring> storage = [migratedDB.storageProvider storageForDB:db];
                        [[[storage stringForKey:migration.migrationKey error:nil] should] equal:@"1"];
                    }];
                });
                it(@"Should migrate deviceID with app keychain", ^{
                    stubKeychain(kAMAMigrationKeychainAppServiceIdentifier, @"", keychainMock);
                    
                    [keychainMock stub:@selector(isAvailable) andReturn:theValue(YES)];
                    [keychainMock stub:@selector(stringValueForKey:error:)
                             andReturn:deviceID
                         withArguments:kAMAMigrationDeviceIDStorageKey, kw_any()];
                    [keychainMock stub:@selector(stringValueForKey:error:)
                             andReturn:deviceIDHash
                         withArguments:kAMAMigrationDeviceIDHashStorageKey, kw_any()];
                    
                    
                    [[persistentMock should] receive:@selector(setDeviceID:) withArguments:deviceID];
                    [[persistentMock should] receive:@selector(setDeviceIDHash:) withArguments:deviceIDHash];
                    
                    id<AMADatabaseProtocol> migratedDB = [AMADatabaseFactory configurationDatabase];
                    [migratedDB inDatabase:^(AMAFMDatabase *db) {
                        id<AMAKeyValueStoring> storage = [migratedDB.storageProvider storageForDB:db];
                        [[[storage stringForKey:migration.migrationKey error:nil] should] equal:@"1"];
                    }];
                });
            });
            
            it(@"Should migrate crash reports directory", ^{
                NSFileManager *fileManager = [NSFileManager defaultManager];
                NSString *oldDirPath = [AMAMigrationTo500Utils crashReportsWithBundleName:kAMAMigrationBundle];
                NSString *newDirPath = [AMAMigrationTo500Utils crashReportsWithBundleName:[AMAPlatformDescription SDKBundleName]];
                
                [AMAFileUtility deleteFileAtPath:oldDirPath];
                [AMAFileUtility deleteFileAtPath:newDirPath];
                
                [[theValue([fileManager fileExistsAtPath:newDirPath]) should] beNo];
                
                [fileManager createDirectoryAtPath:oldDirPath
                       withIntermediateDirectories:YES
                                        attributes:nil
                                             error:nil];
                
                id<AMADatabaseProtocol> migratedDB = [AMADatabaseFactory configurationDatabase];
                [migratedDB inDatabase:^(AMAFMDatabase *db) {
                    id<AMAKeyValueStoring> storage = [migratedDB.storageProvider storageForDB:db];
                    [[[storage stringForKey:migration.migrationKey error:nil] should] equal:@"1"];
                }];
                
                [[theValue([fileManager fileExistsAtPath:oldDirPath]) should] beNo];
                [[theValue([fileManager fileExistsAtPath:newDirPath]) should] beYes];
            });
        });
        
        context(@"Migration to 5.8.0", ^{
            beforeEach(^{
                basePath = [AMAFileUtility persistentPath];
                migration = [AMADataMigrationTo580 new];
                migrationDatabase = [AMADatabaseMigrationTestsUtils configurationDatabase:basePath];
                
                [AMADatabaseMigrationTestsUtils includeDataMigration:migration
                                                         contentType:AMADatabaseContentTypeConfiguration
                                                          inDatabase:migrationDatabase];
            });
            it(@"Should reset startup update date", ^{
                id<AMADatabaseProtocol> migratedDB = [AMADatabaseFactory configurationDatabase];
                [migratedDB inDatabase:^(AMAFMDatabase *db) {
                    id<AMAKeyValueStoring> storage = [migratedDB.storageProvider storageForDB:db];
                    
                    [[[storage dateForKey:AMAStorageStringKeyStartupUpdatedAt error:nil] should] equal:[NSDate distantPast]];
                    [[[storage stringForKey:migration.migrationKey error:nil] should] equal:@"1"];
                }];
            });
        });
        
        context(@"Migration to 5.9.0", ^{
            AMAAppMetricaUUIDMigrator *__block migrator = nil;
            NSObject<AMAIdentifierProviding> *__block identifierProviderMock = nil;
            
            beforeEach(^{
                basePath = [AMAFileUtility persistentPath];
                migration = [AMADataMigrationTo590 new];
                migrationDatabase = [AMADatabaseMigrationTestsUtils configurationDatabase:basePath];
                
                [AMADatabaseMigrationTestsUtils includeDataMigration:migration
                                                         contentType:AMADatabaseContentTypeConfiguration
                                                          inDatabase:migrationDatabase];
                
                identifierProviderMock = [KWMock nullMockForProtocol:@protocol(AMAIdentifierProviding)];
                [configuration stub:@selector(identifierProvider) andReturn:identifierProviderMock];
            });
            
            __auto_type testMigrationIdentifiers = ^(BOOL isExtension) {
                it(@"Should migrate uuid to identifier provider", ^{
                    NSString *const expectedUUID = @"appmetrica_uuid";
                    NSString *__block resultUUID = nil;
                    
                    migrator = [AMAAppMetricaUUIDMigrator stubbedNullMockForDefaultInit];
                    [migrator stub:@selector(migrateAppMetricaUUID) andReturn:expectedUUID];
                    
                    [identifierProviderMock stub:@selector(updateAppMetricaUUID:) withBlock:^id(NSArray *params) {
                        resultUUID = params[0];
                        return nil;
                    }];
                    
                    id<AMADatabaseProtocol> migratedDB = [AMADatabaseFactory configurationDatabase];
                    [migratedDB inDatabase:^(AMAFMDatabase *db) {
                        id<AMAKeyValueStoring> storage = [migratedDB.storageProvider storageForDB:db];
                        [[[storage stringForKey:migration.migrationKey error:nil] should] equal:@"1"];
                    }];
                    if (isExtension) {
                        [[resultUUID should] beNil];
                    }
                    else {
                        [[resultUUID should] equal:expectedUUID];
                    }
                });
                
                it(@"Should migrate deviceID to identifier provider", ^{
                    NSString *const expectedDeviceID = @"appmetrica_deviceID";
                    NSString *const expectedDeviceIDHash = @"appmetrica_deviceIDHash";
                    NSString *__block resultDeviceID = nil;
                    NSString *__block resultDeviceIDHash = nil;
                    
                    [identifierProviderMock stub:@selector(updateDeviceID:) withBlock:^id(NSArray *params) {
                        resultDeviceID = params[0];
                        return nil;
                    }];
                    [identifierProviderMock stub:@selector(updateDeviceIdHash:) withBlock:^id(NSArray *params) {
                        resultDeviceIDHash = params[0];
                        return nil;
                    }];
                    
                    NSString *(^dbStorageKey)(NSString *) = ^NSString *(NSString *key) {
                        return [NSString stringWithFormat:@"fallback-keychain-%@", key];
                    };
                    
                    id<AMADatabaseProtocol> migratedDB = [AMADatabaseFactory configurationDatabase];
                    id<AMAKeyValueStoring> dbStorage = migratedDB.storageProvider.cachingStorage;
                    
                    [(NSObject *)dbStorage stub:@selector(stringForKey:error:)
                                      andReturn:expectedDeviceID
                                  withArguments:dbStorageKey(AMAAppMetricaIdentifiersKeys.deviceID), kw_any()];
                    
                    [(NSObject *)dbStorage stub:@selector(stringForKey:error:)
                                      andReturn:expectedDeviceIDHash
                                  withArguments:dbStorageKey(AMAAppMetricaIdentifiersKeys.deviceIDHash), kw_any()];
                    
                    [migratedDB inDatabase:^(AMAFMDatabase *db) {
                        id<AMAKeyValueStoring> storage = [migratedDB.storageProvider storageForDB:db];
                        [[[storage stringForKey:migration.migrationKey error:nil] should] equal:@"1"];
                    }];
                    
                    if (isExtension) {
                        [[resultDeviceID should] beNil];
                        [[resultDeviceIDHash should] beNil];
                    }
                    else {
                        [[resultDeviceID should] equal:expectedDeviceID];
                        [[resultDeviceIDHash should] equal:expectedDeviceIDHash];
                    }
                });
            };
            context(@"Should migrate within App", ^{
                beforeEach(^{
                    [AMAPlatformDescription stub:@selector(isExtension) andReturn:theValue(NO)];
                });
                testMigrationIdentifiers(NO);
            });
            
            context(@"Should migrate within Extension", ^{
                beforeEach(^{
                    [AMAPlatformDescription stub:@selector(isExtension) andReturn:theValue(YES)];
                });
                testMigrationIdentifiers(YES);
            });
            
        });
        
        context(@"Migration to 5.10.0", ^{
            beforeEach(^{
                basePath = [AMAFileUtility persistentPath];
                migration = [AMADataMigrationTo5100 new];
                migrationDatabase = [AMADatabaseMigrationTestsUtils configurationDatabase:basePath];
                
                [AMADatabaseMigrationTestsUtils includeDataMigration:migration
                                                         contentType:AMADatabaseContentTypeConfiguration
                                                          inDatabase:migrationDatabase];
            });
            
            it(@"Should reset startup update date", ^{
                id<AMADatabaseProtocol> migratedDB = [AMADatabaseFactory configurationDatabase];
                [migratedDB inDatabase:^(AMAFMDatabase *db) {
                    id<AMAKeyValueStoring> storage = [migratedDB.storageProvider storageForDB:db];
                    
                    [[[storage dateForKey:AMAStorageStringKeyStartupUpdatedAt error:nil] should] equal:[NSDate distantPast]];
                    [[[storage stringForKey:migration.migrationKey error:nil] should] equal:@"1"];
                }];
            });
        });
    });
    
    context(@"Reporter database", ^{
        NSString *const apiKey = [AMAReporterTestHelper defaultApiKey];
        __auto_type *const eventHashesCollection = [[AMAEventNameHashesCollection alloc] initWithCurrentVersion:@"2.3.4"
                                                                                  hashesCountFromCurrentVersion:9
                                                                                       handleNewEventsAsUnknown:YES
                                                                                                eventNameHashes:[[NSSet setWithArray:@[@13, @4, @8293]]
                                                                                                                 mutableCopy]];
        id<AMADatabaseProtocol> __block migrationDatabase = nil;
        id<AMADatabaseDataMigration> __block migration = nil;
        NSString *__block basePath = nil;
        
        beforeEach(^{
            [AMADatabaseMigrationTestsUtils cleanDatabase];
        });
        
        afterEach(^{
            [AMADatabaseMigrationTestsUtils cleanDatabase];
        });
        
        AMAEvent *(^buildEvent)(AMAReporterStorage *, AMASession *session) = ^(AMAReporterStorage *reporterStorage,
                                                                               AMASession *session) {
            AMAEventBuilder *eventBuilder = [[AMAEventBuilder alloc] initWithStateStorage:reporterStorage.stateStorage
                                                                              preloadInfo:nil];
            
            NSDictionary *const extras = @{ @"extras" : [@"value" dataUsingEncoding:NSUTF8StringEncoding] };
            NSDictionary *const params = @{ @"foo" : @"bar" };
            
            AMAEvent *event = [eventBuilder eventWithType:99
                                                     name:@"eventName"
                                                    value:@"eventValue"
                                         eventEnvironment:params
                                           appEnvironment:params
                                                   extras:extras
                                                    error:nil];
            NSDate *creationDate = [NSDate date];
            event.createdAt = creationDate;
            event.timeSinceSession = [creationDate timeIntervalSinceDate:session.startDate.deviceDate];
            event.sessionOid = session.oid;
            event.location = [[CLLocation alloc] initWithLatitude:22.0 longitude:33.0];
            event.appEnvironment = params;
            event.profileID = @"profileID";
            
            return event;
        };
        
        void (^compareEventAndSession)(AMASession *session, AMAEvent *, AMASession *, AMAEvent *) = ^(AMASession *sessionToMigrate,
                                                                                                      AMAEvent *eventToMigrate,
                                                                                                      AMASession *migratedSession,
                                                                                                      AMAEvent *migratedEvent) {
            [[migratedEvent shouldNot] beNil];
            [[eventToMigrate shouldNot] beNil];
            
            [[theValue(migratedEvent.type) should] equal:theValue(eventToMigrate.type)];
            [[migratedEvent.oid should] equal:eventToMigrate.oid];
            [[theValue(migratedEvent.sequenceNumber) should] equal:theValue(eventToMigrate.sequenceNumber)];
            [[theValue(migratedEvent.globalNumber) should] equal:theValue(eventToMigrate.globalNumber)];
            [[theValue(migratedEvent.numberOfType) should] equal:theValue(eventToMigrate.numberOfType)];
            [[migratedEvent.name should] equal:eventToMigrate.name];
            [[migratedEvent.eventEnvironment should] equal:eventToMigrate.eventEnvironment];
            [[[migratedEvent.value dataWithError:nil] should] equal:[eventToMigrate.value dataWithError:nil]];
            [[migratedEvent.sessionOid should] equal:eventToMigrate.sessionOid];
            [[migratedEvent.createdAt should] equal:eventToMigrate.createdAt];
            [[theValue(migratedEvent.timeSinceSession) should] equal:theValue(eventToMigrate.timeSinceSession)];
            [[theValue(migratedEvent.location.coordinate.latitude) should] equal:theValue(eventToMigrate.location.coordinate.latitude)];
            [[theValue(migratedEvent.location.coordinate.longitude) should] equal:theValue(eventToMigrate.location.coordinate.longitude)];
            [[theValue(migratedEvent.locationEnabled) should] equal:theValue(eventToMigrate.locationEnabled)];
            [[theValue(migratedEvent.firstOccurrence) should] equal:theValue(eventToMigrate.firstOccurrence)];
            [[migratedEvent.appEnvironment should] equal:eventToMigrate.appEnvironment];
            [[migratedEvent.profileID should] equal:eventToMigrate.profileID];
            [[theValue(migratedEvent.source) should] equal:theValue(eventToMigrate.source)];
            [[theValue(migratedEvent.attributionIDChanged) should] equal:theValue(eventToMigrate.attributionIDChanged)];
            [[migratedEvent.openID should] equal:eventToMigrate.openID];
            
            [[migratedSession shouldNot] beNil];
            [[sessionToMigrate shouldNot] beNil];
            
            [[migratedSession.oid should] equal:sessionToMigrate.oid];
            [[migratedSession.startDate should] equal:sessionToMigrate.startDate];
            [[migratedSession.lastEventTime should] equal:sessionToMigrate.lastEventTime];
            [[migratedSession.pauseTime should] equal:sessionToMigrate.pauseTime];
            [[migratedSession.sessionID should] equal:sessionToMigrate.sessionID];
            [[migratedSession.attributionID should] equal:sessionToMigrate.attributionID];
            [[theValue(migratedSession.type) should] equal:theValue(sessionToMigrate.type)];
        };
        
#pragma mark - Test reporter migration to 5.0.0
        __auto_type testMigrationReporterDataTo500 = ^(BOOL isMainBeforeMigration,
                                                       BOOL isMainAfterMigration) {
            it(@"Should migrate value", ^{
                [migrationDatabase inDatabase:^(AMAFMDatabase *db) {
                    id<AMAKeyValueStoring> storage = [migrationDatabase.storageProvider storageForDB:db];
                    
                    [storage saveString:value forKey:key error:nil];
                }];
                
                id<AMADatabaseProtocol> migratedDB = [AMADatabaseFactory reporterDatabaseForApiKey:apiKey
                                                                                              main:isMainAfterMigration
                                                                                     eventsCleaner:nil];
                
                [migratedDB inDatabase:^(AMAFMDatabase *db) {
                    id<AMAKeyValueStoring> storage = [migratedDB.storageProvider storageForDB:db];
                    
                    [[[storage stringForKey:key error:nil] should] equal:value];
                    
                    [[theValue([storage boolNumberForKey:migration.migrationKey error:nil].boolValue) should] beYes];
                }];
            });
            
            it(@"Should migrate event hashes", ^{
                NSString *migrationPath = [basePath stringByAppendingPathComponent:apiKey];
                AMAEventNameHashesStorage *migrationStorage = [AMAEventNameHashesStorageFactory migrationStorageForPath:migrationPath];
                [migrationStorage saveCollection:eventHashesCollection];
                
                // After migration
                id<AMADatabaseProtocol> migratedDB = [AMADatabaseFactory reporterDatabaseForApiKey:apiKey
                                                                                              main:isMainAfterMigration
                                                                                     eventsCleaner:nil];
                [migratedDB inDatabase:^(AMAFMDatabase *db) {
                    id<AMAKeyValueStoring> storage = [migratedDB.storageProvider storageForDB:db];
                    [[theValue([storage boolNumberForKey:migration.migrationKey error:nil].boolValue) should] beYes];
                }];
                
                AMAEventNameHashesStorage *migratedStorage = [AMAEventNameHashesStorageFactory storageForApiKey:apiKey
                                                                                                           main:isMainAfterMigration];
                AMAEventNameHashesCollection *loadedCollection = [migratedStorage loadCollection];
                
                [[loadedCollection.currentVersion should] equal:eventHashesCollection.currentVersion];
                [[theValue(loadedCollection.hashesCountFromCurrentVersion) should] equal:theValue(eventHashesCollection.hashesCountFromCurrentVersion)];
                [[theValue(loadedCollection.handleNewEventsAsUnknown) should] equal:theValue(eventHashesCollection.handleNewEventsAsUnknown)];
                [[loadedCollection.eventNameHashes should] equal:eventHashesCollection.eventNameHashes];
            });
            
            it(@"Should not migrate event hashes if no reporter db", ^{
                NSString *migrationPath = [[AMAMigrationTo500Utils migrationPath] stringByAppendingPathComponent:apiKey];
                AMAEventNameHashesStorage *migrationStorage = [AMAEventNameHashesStorageFactory migrationStorageForPath:migrationPath];
                [migrationStorage saveCollection:eventHashesCollection];
                
                [[NSFileManager defaultManager] removeItemAtPath:[[[AMAMigrationTo500Utils migrationPath]
                                                                   stringByAppendingPathComponent:apiKey]
                                                                  stringByAppendingPathComponent:@"data.sqlite"] error:nil];
                
                // After migration
                id<AMADatabaseProtocol> migratedDB = [AMADatabaseFactory reporterDatabaseForApiKey:apiKey
                                                                                              main:isMainAfterMigration
                                                                                     eventsCleaner:nil];
                [migratedDB inDatabase:^(AMAFMDatabase *db) {
                    id<AMAKeyValueStoring> storage = [migratedDB.storageProvider storageForDB:db];
                    [[theValue([storage boolNumberForKey:migration.migrationKey error:nil].boolValue) should] beYes];
                }];
                
                AMAEventNameHashesStorage *currentStorage = [AMAEventNameHashesStorageFactory storageForApiKey:apiKey
                                                                                                          main:isMainAfterMigration];
                AMAEventNameHashesCollection *loadedCollection = [currentStorage loadCollection];
                
                [[loadedCollection.currentVersion should] beNil];
                [[theValue(loadedCollection.hashesCountFromCurrentVersion) should] beZero];
                [[theValue(loadedCollection.handleNewEventsAsUnknown) should] beNo];
                [[loadedCollection.eventNameHashes should] beNil];
            });
            
            it(@"Should migrate events and sessions", ^{
                AMAReporterStorage *migrationStorage = reporterStorage(migrationDatabase,
                                                                       apiKey,
                                                                       isMainBeforeMigration);
                
                AMASessionSerializer *migrationSessionSerializer = [[AMASessionSerializer alloc] migrationTo500Init];
                [migrationStorage.sessionStorage stub:@selector(serializer) andReturn:migrationSessionSerializer];
                
                AMAEventSerializer *migrationEventSerializer = [[AMAEventSerializer alloc] migrationTo500Init];
                [migrationStorage.eventStorage stub:@selector(eventSerializer) andReturn:migrationEventSerializer];
                
                AMAEventBuilder *eventBuilder = [[AMAEventBuilder alloc] initWithStateStorage:migrationStorage.stateStorage
                                                                                  preloadInfo:nil];
                AMASession *sessionToMigrate = [migrationStorage.sessionStorage newGeneralSessionCreatedAt:[NSDate date] error:nil];
                AMAEvent *eventToMigrate = buildEvent(migrationStorage, sessionToMigrate);
                
                // Add event
                [migrationStorage.eventStorage addEvent:eventToMigrate toSession:sessionToMigrate error:nil];
                
                // Create legacy extras
                NSDictionary *const legacyExtras = @{@"user_id":@"user id",
                                                     @"type":@"user type",
                                                     @"options":@{@"key":@"value"}};
                NSData *legacyExtrasValue = [AMALegacyEventExtrasProvider packExtras:legacyExtras];
                NSMutableDictionary *expectedExtras = [@{ @"ai" : legacyExtrasValue } mutableCopy];
                [expectedExtras addEntriesFromDictionary:eventToMigrate.extras];
                
                [migrationDatabase inDatabase:^(AMAFMDatabase *db) {
                    id<AMAKeyValueStoring> storage = [migrationDatabase.storageProvider storageForDB:db];
                    
                    [storage saveString:[AMAJSONSerialization stringWithJSONObject:legacyExtras error:nil] forKey:@"user_info" error:nil];
                }];
                
                // After migration
                id<AMAAppMetricaExtendedReporting> reporter = [AMAAppMetrica extendedReporterForApiKey:apiKey];
                [(NSObject *)reporter stub:@selector(setSessionExtras:forKey:)];
                [[(NSObject *)reporter should] receive:@selector(setSessionExtras:forKey:) withArguments:legacyExtrasValue, @"ai"];
                
                id<AMADatabaseProtocol> migratedDB = [AMADatabaseFactory reporterDatabaseForApiKey:apiKey
                                                                                              main:isMainAfterMigration
                                                                                     eventsCleaner:nil];
                AMAReporterStorage *migratedStorage = reporterStorage(migratedDB, apiKey, isMainAfterMigration);
                
                AMAEventSerializer *eventSerializer = [[AMAEventSerializer alloc] migrationTo5100Init];
                [migratedStorage.eventStorage stub:@selector(eventSerializer) andReturn:eventSerializer];
                
                AMASessionSerializer *sessionSerializer = [[AMASessionSerializer alloc] migrationTo5100Init];
                [migratedStorage.sessionStorage stub:@selector(serializer) andReturn:sessionSerializer];
                
                
                AMAEvent *migratedEvent = [[migratedStorage.eventStorage allEvents] firstObject];
                [[migratedEvent.extras should] equal:expectedExtras];
                
                AMASession *migratedSession = [migratedStorage.sessionStorage lastSessionWithError:nil];
                
                compareEventAndSession(sessionToMigrate, eventToMigrate, migratedSession, migratedEvent);
                
                [migratedDB inDatabase:^(AMAFMDatabase *db) {
                    [AMADatabaseHelper deleteFirstRowsWithCount:1
                                                         filter:nil
                                                          order:nil
                                                    valuesArray:nil
                                                      tableName:kAMASessionTableName
                                                             db:db
                                                          error:nil];
                    
                    [AMADatabaseHelper deleteFirstRowsWithCount:1
                                                         filter:nil
                                                          order:nil
                                                    valuesArray:nil
                                                      tableName:kAMAEventTableName
                                                             db:db
                                                          error:nil];
                }];
            });
        };
        
        context(@"Migration to 5.0.0", ^{
            __auto_type prepareMigration = ^(BOOL main) {
                basePath = [AMAMigrationTo500Utils migrationPath];
                migration = [[AMAReporterDataMigrationTo500 alloc] initWithApiKey:apiKey main:main];
                migrationDatabase = [AMADatabaseMigrationTestsUtils reporterDatabase:basePath apiKey:apiKey];
                
                [AMADatabaseMigrationTestsUtils includeDataMigration:migration
                                                         contentType:AMADatabaseContentTypeReporter
                                                          inDatabase:migrationDatabase];
            };
            
            context(@"Main reporter migrates since old-format DB is created and migrated in 5.8.0", ^{
                beforeEach(^{
                    prepareMigration(YES);
                });
                context(@"with appID", ^{
                    testMigrationReporterDataTo500(YES, YES);
                });
                
                context(@"with SDK Bundle", ^{
                    beforeEach(^{
                        [AMAPlatformDescription stub:@selector(appID) andReturn:nil];
                    });
                    testMigrationReporterDataTo500(YES, YES);
                });
            });
            
            context(@"Main reporter migration to 5.0.0 without 5.8.0", ^{
                BOOL const isMainAfterMigration = NO;
                beforeEach(^{
                    // Exclude 5.8.0 migration for non-main old format db
                    // All data after migration stay in non-main reporter db
                    basePath = [AMAFileUtility persistentPath];
                    migration = [[AMAReporterDataMigrationTo500 alloc] initWithApiKey:apiKey main:YES];
                    migrationDatabase = [AMADatabaseMigrationTestsUtils reporterDatabase:basePath apiKey:apiKey main:NO];
                    [AMADatabaseMigrationTestsUtils includeDataMigration:migration
                                                             contentType:AMADatabaseContentTypeReporter
                                                              inDatabase:migrationDatabase];
                    
                    prepareMigration(NO);
                });
                context(@"with appID", ^{
                    testMigrationReporterDataTo500(YES, isMainAfterMigration);
                });
                
                context(@"with SDK Bundle", ^{
                    beforeEach(^{
                        [AMAPlatformDescription stub:@selector(appID) andReturn:nil];
                    });
                    testMigrationReporterDataTo500(YES, isMainAfterMigration);
                });
            });
            
            context(@"secondary reporter migration to 5.0.0", ^{
                beforeEach(^{
                    prepareMigration(NO);
                });
                context(@"with appID", ^{
                    testMigrationReporterDataTo500(NO, NO);
                });
                
                context(@"with SDK Bundle", ^{
                    beforeEach(^{
                        [AMAPlatformDescription stub:@selector(appID) andReturn:nil];
                    });
                    testMigrationReporterDataTo500(NO, NO);
                });
            });
        });
        
#pragma mark - Test reporter migration to 5.8.0
        __auto_type testMigrationReporterDataTo580 = ^(BOOL main) {
            it(@"Should migrate kv and backup", ^{
                [migrationDatabase inDatabase:^(AMAFMDatabase *db) {
                    [migrationDatabase.storageProvider addBackingKeys:@[key]];
                    
                    id<AMAKeyValueStoring> storage = [migrationDatabase.storageProvider storageForDB:db];
                    [storage saveString:value forKey:key error:nil];
                }];
                
                id<AMADatabaseProtocol> migratedDB = [AMADatabaseFactory reporterDatabaseForApiKey:apiKey
                                                                                              main:main
                                                                                     eventsCleaner:nil];
                
                [migratedDB inDatabase:^(AMAFMDatabase *db) {
                    id<AMAKeyValueStoring> storage = [migratedDB.storageProvider storageForDB:db];
                    
                    if (main) {
                        [[[storage stringForKey:key error:nil] should] equal:value];
                        
                        NSString *bakPath = [[AMAFileUtility persistentPathForApiKey:kAMAMainReporterDBPath]
                                                stringByAppendingPathComponent:@"data.bak"];
                        [[theValue([AMAFileUtility fileExistsAtPath:bakPath]) should] beYes];
                    }
                    else {
                        NSString *path = [[AMAFileUtility persistentPath]
                                          stringByAppendingPathComponent:kAMAMainReporterDBPath];
                        [[theValue([AMAFileUtility fileExistsAtPath:path]) should] beNo];
                    }
                    
                    [[theValue([storage boolNumberForKey:migration.migrationKey error:nil].boolValue) should] beYes];
                }];
            });
            
            it(@"Should migrate event hashes", ^{
                NSString *migrationPath = [basePath stringByAppendingPathComponent:apiKey];
                AMAEventNameHashesStorage *migrationStorage = [AMAEventNameHashesStorageFactory migrationStorageForPath:migrationPath];
                [migrationStorage saveCollection:eventHashesCollection];
                
                // After migration
                id<AMADatabaseProtocol> migratedDB = [AMADatabaseFactory reporterDatabaseForApiKey:apiKey
                                                                                              main:main
                                                                                     eventsCleaner:nil];
                [migratedDB inDatabase:^(AMAFMDatabase *db) {
                    id<AMAKeyValueStoring> storage = [migratedDB.storageProvider storageForDB:db];
                    [[theValue([storage boolNumberForKey:migration.migrationKey error:nil].boolValue) should] beYes];
                }];
                AMAEventNameHashesStorage *migratedStorage = [AMAEventNameHashesStorageFactory storageForApiKey:apiKey
                                                                                                           main:YES];
                AMAEventNameHashesCollection *loadedCollection = [migratedStorage loadCollection];
                
                if (main) {
                    [[loadedCollection.currentVersion should] equal:eventHashesCollection.currentVersion];
                    [[theValue(loadedCollection.hashesCountFromCurrentVersion) should] equal:theValue(eventHashesCollection.hashesCountFromCurrentVersion)];
                    [[theValue(loadedCollection.handleNewEventsAsUnknown) should] equal:theValue(eventHashesCollection.handleNewEventsAsUnknown)];
                    [[loadedCollection.eventNameHashes should] equal:eventHashesCollection.eventNameHashes];
                }
                else {
                    [[loadedCollection.currentVersion should] beNil];
                    [[theValue(loadedCollection.hashesCountFromCurrentVersion) should] beZero];
                    [[theValue(loadedCollection.handleNewEventsAsUnknown) should] beNo];
                    [[loadedCollection.eventNameHashes should] beNil];
                }
            });
            
            it(@"Should migrate events and sessions", ^{
                AMAReporterStorage *migrationStorage = reporterStorage(migrationDatabase,
                                                                       apiKey,
                                                                       main);
                
                AMAEventBuilder *eventBuilder = [[AMAEventBuilder alloc] initWithStateStorage:migrationStorage.stateStorage
                                                                                  preloadInfo:nil];
                AMASession *sessionToMigrate = [migrationStorage.sessionStorage newGeneralSessionCreatedAt:[NSDate date] error:nil];
                AMAEvent *eventToMigrate = buildEvent(migrationStorage, sessionToMigrate);
                
                // Add event
                [migrationStorage.eventStorage addEvent:eventToMigrate toSession:sessionToMigrate error:nil];
                
                // After migration
                id<AMADatabaseProtocol> migratedDB = [AMADatabaseFactory reporterDatabaseForApiKey:apiKey
                                                                                              main:main
                                                                                     eventsCleaner:nil];
                [migratedDB inDatabase:^(AMAFMDatabase *db) {
                    id<AMAKeyValueStoring> storage = [migratedDB.storageProvider storageForDB:db];
                    [[theValue([storage boolNumberForKey:migration.migrationKey error:nil].boolValue) should] beYes];
                }];
                
                if (main) {
                    AMAReporterStorage *migratedStorage = reporterStorage(migratedDB, apiKey, main);
                    
                    AMAEvent *migratedEvent = [[migratedStorage.eventStorage allEvents] firstObject];
                    [[migratedEvent.extras should] equal:eventToMigrate.extras];
                    
                    AMASession *migratedSession = [migratedStorage.sessionStorage lastSessionWithError:nil];
                    
                    compareEventAndSession(sessionToMigrate, eventToMigrate, migratedSession, migratedEvent);
                }
                else {
                    NSString *path = [[AMAFileUtility persistentPath]
                                      stringByAppendingPathComponent:kAMAMainReporterDBPath];
                    [[theValue([AMAFileUtility fileExistsAtPath:path]) should] beNo];
                }
                
                [migratedDB inDatabase:^(AMAFMDatabase *db) {
                    [AMADatabaseHelper deleteFirstRowsWithCount:1
                                                         filter:nil
                                                          order:nil
                                                    valuesArray:nil
                                                      tableName:kAMASessionTableName
                                                             db:db
                                                          error:nil];
                    
                    [AMADatabaseHelper deleteFirstRowsWithCount:1
                                                         filter:nil
                                                          order:nil
                                                    valuesArray:nil
                                                      tableName:kAMAEventTableName
                                                             db:db
                                                          error:nil];
                }];
            });
        };
        
        context(@"Migration to 5.8.0", ^{
            __auto_type prepareMigration = ^(BOOL main) {
                basePath = [AMAFileUtility persistentPath];
                migration = [[AMAReporterDataMigrationTo580 alloc] initWithApiKey:apiKey main:main];
                migrationDatabase = [AMADatabaseMigrationTestsUtils reporterDatabase:basePath apiKey:apiKey];
                
                [AMADatabaseMigrationTestsUtils includeDataMigration:migration
                                                         contentType:AMADatabaseContentTypeReporter
                                                          inDatabase:migrationDatabase];
            };
            context(@"main reporter", ^{
                beforeEach(^{
                    prepareMigration(YES);
                });
                testMigrationReporterDataTo580(YES);
            });
            context(@"secondary reporter should not migrate", ^{
                beforeEach(^{
                    prepareMigration(NO);
                });
                testMigrationReporterDataTo580(NO);
            });
        });
        
#pragma mark - Test reporter migration to 5.10.0
        context(@"Migration to 5.10.0", ^{
            __auto_type prepareMigration = ^(BOOL main) {
                basePath = [AMAFileUtility persistentPath];
                migration = [[AMAReporterDataMigrationTo5100 alloc] initWithApiKey:apiKey];
                migrationDatabase = [AMADatabaseMigrationTestsUtils reporterDatabase:basePath apiKey:apiKey main:main];
                
                [AMADatabaseMigrationTestsUtils includeDataMigration:migration
                                                         contentType:AMADatabaseContentTypeReporter
                                                          inDatabase:migrationDatabase];
            };
            __auto_type testMigrationReporterDataTo5100 = ^(BOOL main) {
                it(@"Should migrate events and sessions", ^{
                    AMAReporterStorage *migrationStorage = reporterStorage(migrationDatabase,
                                                                           apiKey,
                                                                           main);
                    
                    AMASessionSerializer *migrationSessionSerializer = [[AMASessionSerializer alloc] migrationTo5100Init];
                    [migrationStorage.sessionStorage stub:@selector(serializer) andReturn:migrationSessionSerializer];
                    
                    AMAEventSerializer *migrationEventSerializer = [[AMAEventSerializer alloc] migrationTo5100Init];
                    [migrationStorage.eventStorage stub:@selector(eventSerializer) andReturn:migrationEventSerializer];
                    
                    AMAEventBuilder *eventBuilder = [[AMAEventBuilder alloc] initWithStateStorage:migrationStorage.stateStorage
                                                                                      preloadInfo:nil];
                    AMASession *sessionToMigrate = [migrationStorage.sessionStorage newGeneralSessionCreatedAt:[NSDate date] error:nil];
                    AMAEvent *eventToMigrate = buildEvent(migrationStorage, sessionToMigrate);
                    
                    // Add event
                    [migrationStorage.eventStorage addEvent:eventToMigrate toSession:sessionToMigrate error:nil];
                    
                    // After migration
                    id<AMADatabaseProtocol> migratedDB = [AMADatabaseFactory reporterDatabaseForApiKey:apiKey
                                                                                                  main:main
                                                                                         eventsCleaner:nil];
                    [migratedDB inDatabase:^(AMAFMDatabase *db) {
                        id<AMAKeyValueStoring> storage = [migratedDB.storageProvider storageForDB:db];
                        [[theValue([storage boolNumberForKey:migration.migrationKey error:nil].boolValue) should] beYes];
                    }];
                    
                    AMAReporterStorage *migratedStorage = reporterStorage(migratedDB, apiKey, main);
                    
                    
                    AMAEventSerializer *eventSerializer = [[AMAEventSerializer alloc] init];
                    [migratedStorage.eventStorage stub:@selector(eventSerializer) andReturn:eventSerializer];
                    
                    AMASessionSerializer *sessionSerializer = [[AMASessionSerializer alloc] init];
                    [migratedStorage.sessionStorage stub:@selector(serializer) andReturn:sessionSerializer];
                    
                    
                    AMAEvent *migratedEvent = [[migratedStorage.eventStorage allEvents] firstObject];
                    [[migratedEvent.extras should] equal:eventToMigrate.extras];
                    
                    AMASession *migratedSession = [migratedStorage.sessionStorage lastSessionWithError:nil];
                    
                    compareEventAndSession(sessionToMigrate, eventToMigrate, migratedSession, migratedEvent);
                    
                    [migratedDB inDatabase:^(AMAFMDatabase *db) {
                        [AMADatabaseHelper deleteFirstRowsWithCount:1
                                                             filter:nil
                                                              order:nil
                                                        valuesArray:nil
                                                          tableName:kAMASessionTableName
                                                                 db:db
                                                              error:nil];
                        
                        [AMADatabaseHelper deleteFirstRowsWithCount:1
                                                             filter:nil
                                                              order:nil
                                                        valuesArray:nil
                                                          tableName:kAMAEventTableName
                                                                 db:db
                                                              error:nil];
                    }];
                });
            };
            context(@"main reporter", ^{
                beforeEach(^{
                    prepareMigration(YES);
                });
                context(@"with appID", ^{
                    testMigrationReporterDataTo5100(YES);
                });
                context(@"with SDK Bundle", ^{
                    beforeEach(^{
                        [AMAPlatformDescription stub:@selector(appID) andReturn:nil];
                    });
                    testMigrationReporterDataTo5100(YES);
                });
            });
            context(@"secondary reporter", ^{
                beforeEach(^{
                    prepareMigration(NO);
                });
                context(@"with appID", ^{
                    testMigrationReporterDataTo5100(NO);
                });
                context(@"with SDK Bundle", ^{
                    beforeEach(^{
                        [AMAPlatformDescription stub:@selector(appID) andReturn:nil];
                    });
                    testMigrationReporterDataTo5100(NO);
                });
            });
        });
    });
    
#pragma mark - Location migration
    context(@"Location database", ^{
        id<AMADatabaseProtocol> __block migrationDatabase = nil;
        id<AMADatabaseDataMigration> __block migration = nil;
        NSString *__block basePath = nil;
        
        beforeEach(^{
            [AMADatabaseMigrationTestsUtils cleanDatabase];
        });
        
        afterEach(^{
            [AMADatabaseMigrationTestsUtils cleanDatabase];
        });
        
        AMALocationStorage *(^locationStorage)(id<AMADatabaseProtocol>, id<AMALocationEncoderProviding>) = ^(id<AMADatabaseProtocol> database,
                                                                                                             id<AMALocationEncoderProviding> encoderFactory) {
            return [[AMALocationStorage alloc] initWithConfiguration:[[AMALocationCollectingConfiguration alloc] init]
                                                          serializer:[[AMALocationSerializer alloc] init]
                                                            database:database
                                                             crypter:[encoderFactory encoder]];
        };
        
        AMALocation *(^buildLocation)() = ^() {
            return [[AMALocation alloc] initWithIdentifier:@9
                                               collectDate:[NSDate dateWithTimeIntervalSince1970:23.0]
                                                  location:[[CLLocation alloc] initWithLatitude:22.0
                                                                                      longitude:33.0]
                                                  provider:AMALocationProviderGPS];
        };
        
        AMAVisit *(^buildVisit)() = ^() {
            return [AMAVisit visitWithIdentifier:@8
                                     collectDate:[NSDate dateWithTimeIntervalSince1970:25.0]
                                     arrivalDate:[NSDate dateWithTimeIntervalSince1970:24.0]
                                   departureDate:[NSDate dateWithTimeIntervalSince1970:26.0]
                                        latitude:23.0
                                       longitude:24.0
                                       precision:5];
        };
        
        __auto_type testMigrationLocation = ^(id<AMALocationEncoderProviding> migrationEncoderFactory,
                                              id<AMALocationEncoderProviding> encoderFactory) {
            it(@"Should migrate kv table", ^{
                [migrationDatabase inDatabase:^(AMAFMDatabase *db) {
                    id<AMAKeyValueStoring> storage = [migrationDatabase.storageProvider storageForDB:db];
                    
                    [storage saveString:value forKey:key error:nil];
                }];
                
                id<AMADatabaseProtocol> migratedDB = [AMADatabaseFactory locationDatabase];
                [migratedDB inDatabase:^(AMAFMDatabase *db) {
                    id<AMAKeyValueStoring> storage = [migratedDB.storageProvider storageForDB:db];
                    
                    [[[storage stringForKey:key error:nil] should] equal:value];
                    
                    [[[storage stringForKey:migration.migrationKey error:nil] should] equal:@"1"];
                }];
            });
            
            it(@"Should migrate visits and locations", ^{
                AMALocationStorage *migrationStorage = locationStorage(migrationDatabase, migrationEncoderFactory);
                
                AMAVisit *visitToMigrate = buildVisit();
                [migrationStorage addVisit:visitToMigrate];
                
                AMALocation *locationToMigrate = buildLocation();
                [migrationStorage addLocations:@[locationToMigrate]];
                
                // After migration
                id<AMADatabaseProtocol> migratedDB = [AMADatabaseFactory locationDatabase];
                [migratedDB inDatabase:^(AMAFMDatabase *db) {
                    id<AMAKeyValueStoring> storage = [migratedDB.storageProvider storageForDB:db];
                    [[[storage stringForKey:migration.migrationKey error:nil] should] equal:@"1"];
                }];
                
                AMALocationStorage *migratedStorage = locationStorage(migratedDB, encoderFactory);
                
                AMAVisit *migratedVisit = [[migratedStorage visitsWithLimit:1] firstObject];
                
                [[migratedVisit shouldNot] beNil];
                [[visitToMigrate shouldNot] beNil];
                
                [[migratedVisit.collectDate should] equal:visitToMigrate.collectDate];
                [[migratedVisit.departureDate should] equal:visitToMigrate.departureDate];
                [[migratedVisit.arrivalDate should] equal:visitToMigrate.arrivalDate];
                [[theValue(migratedVisit.latitude) should] equal:theValue(visitToMigrate.latitude)];
                [[theValue(migratedVisit.longitude) should] equal:theValue(visitToMigrate.longitude)];
                [[theValue(migratedVisit.precision) should] equal:theValue(visitToMigrate.precision)];
                
                AMALocation *migratedLocation = [[migratedStorage locationsWithLimit:1] firstObject];
                
                [[migratedLocation shouldNot] beNil];
                [[locationToMigrate shouldNot] beNil];
                
                [[migratedLocation.collectDate should] equal:locationToMigrate.collectDate];
                [[theValue(migratedLocation.location.coordinate.latitude) should] equal:theValue(locationToMigrate.location.coordinate.latitude)];
                [[theValue(migratedLocation.location.coordinate.longitude) should] equal:theValue(locationToMigrate.location.coordinate.longitude)];
                [[theValue(migratedLocation.provider) should] equal:theValue(locationToMigrate.provider)];
                
                [migratedStorage purgeVisitsWithIdentifiers:@[visitToMigrate.identifier]];
                [migratedStorage purgeLocationsWithIdentifiers:@[locationToMigrate.identifier]];
            });
        };
        
        context(@"Migration to 5.0.0", ^{
            beforeEach(^{
                basePath = [AMAMigrationTo500Utils migrationPath];
                migration = [AMALocationDataMigrationTo500 new];
                migrationDatabase = [AMADatabaseMigrationTestsUtils locationDatabase:basePath];
                
                [AMADatabaseMigrationTestsUtils includeDataMigration:migration
                                                         contentType:AMADatabaseContentTypeLocation
                                                          inDatabase:migrationDatabase];
            });
            
            context(@"Migration with appID", ^{
                testMigrationLocation([[AMALocationMigrationTo500EncoderFactory alloc] init],
                                      [[AMALocationMigrationTo5100EncoderFactory alloc] init]);
            });
            
            context(@"Migration with SDK Bundle", ^{
                beforeEach(^{
                    [AMAPlatformDescription stub:@selector(appID) andReturn:nil];
                });
                testMigrationLocation([[AMALocationMigrationTo500EncoderFactory alloc] init],
                                      [[AMALocationMigrationTo5100EncoderFactory alloc] init]);
            });
        });
        
        context(@"Migration to 5.10.0", ^{
            beforeEach(^{
                basePath = [AMAFileUtility persistentPath];
                migration = [AMALocationDataMigrationTo5100 new];
                migrationDatabase = [AMADatabaseMigrationTestsUtils locationDatabase:basePath];
                
                [AMADatabaseMigrationTestsUtils includeDataMigration:migration
                                                         contentType:AMADatabaseContentTypeLocation
                                                          inDatabase:migrationDatabase];
            });
            
            context(@"Migration with appID", ^{
                testMigrationLocation([[AMALocationMigrationTo5100EncoderFactory alloc] init],
                                      [[AMALocationEncoderFactory alloc] init]);
            });
            
            context(@"Migration with SDK Bundle", ^{
                beforeEach(^{
                    [AMAPlatformDescription stub:@selector(appID) andReturn:nil];
                });
                testMigrationLocation([[AMALocationMigrationTo5100EncoderFactory alloc] init],
                                      [[AMALocationEncoderFactory alloc] init]);
            });
        });
    });
});

SPEC_END
