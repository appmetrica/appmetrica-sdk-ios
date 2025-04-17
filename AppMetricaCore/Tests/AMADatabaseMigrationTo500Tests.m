
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
#import "AMALocationDataMigrationTo500.h"
#import "AMAReporterDataMigrationTo500.h"
#import "AMAReporterDataMigrationTo580.h"
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
#import "AMALocationEncoderFactory+Migration.h"
#import "AMALocation.h"
#import "AMAVisit.h"
#import "AMAMetricaConfiguration.h"
#import "AMAMetricaPersistentConfiguration.h"
#import "AMADatabaseMigrationTestsUtils.h"
#import "AMAStartupParametersConfiguration.h"
#import "AMADatabaseHelper.h"
#import "AMAAppMetricaUUIDMigrator.h"

@import AppMetricaIdentifiers;

@interface AMAMigrationTo500Utils ()

+ (NSString *)crashReportsWithBundleName:(NSString *)bundleName;

@end

SPEC_BEGIN(AMADatabaseMigrationTo500Tests)

describe(@"AMADatabaseMigrationTo500Tests", ^{
    AMAReporterTestHelper *__block reporterTestHelper = nil;
    AMAMetricaPersistentConfiguration *__block persistentMock = nil;
    AMAMetricaConfiguration *__block configuration = nil;
    AMAInstantFeaturesConfiguration *__block instantMock = nil;

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
    
    context(@"Migration to 5.0.0", ^{
        
        void (^cleanDatabase)(void) = ^{
            [[NSFileManager defaultManager] removeItemAtPath:[AMAMigrationTo500Utils migrationPath] error:nil];
            [[NSFileManager defaultManager] removeItemAtPath:AMAFileUtility.persistentPath error:nil];
        };
        
        afterEach(^{
            cleanDatabase();
        });
        
        context(@"Data migration", ^{
            NSString *const key = @"foo";
            NSString *const value = @"bar";
            NSString *const adUrl = @"ad_url";
            
            id<AMADatabaseProtocol> __block migrationDatabase = nil;
            
            beforeEach(^{
                cleanDatabase();
                
                AMADatabaseMigrationManager *migrationManager =
                    [[AMADatabaseMigrationManager alloc] initWithCurrentSchemeVersion:20
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
                
                migrationDatabase = [AMADatabaseMigrationTestsUtils databaseWithPath:[[AMAMigrationTo500Utils migrationPath]
                                                                                      stringByAppendingPathComponent:@"storage.sqlite"]
                                                                    migrationManager:migrationManager
                                                                     storageProvider:storageProvider
                                                                    schemeController:tableSchemeController];
                
                [migrationDatabase inDatabase:^(AMAFMDatabase *db) {
                    id<AMAKeyValueStoring> storage = [migrationDatabase.storageProvider storageForDB:db];
                    
                    [storage saveString:value forKey:key error:nil];
                    [storage saveString:@"4.5.0" forKey:@"library.version" error:nil];
                    [storage saveString:adUrl forKey:@"get_ad.host" error:nil];
                }];
            });

            it(@"Should migrate kv table", ^{
                NSString *version = @"0.1.2.3.4";
                [AMAPlatformDescription stub:@selector(SDKVersionName) andReturn:version];
                id<AMADatabaseProtocol> newDB = [AMADatabaseFactory configurationDatabase];
                [newDB inDatabase:^(AMAFMDatabase *db) {
                    id<AMAKeyValueStoring> storage = [newDB.storageProvider storageForDB:db];

                    [[[storage stringForKey:key error:nil] should] equal:value];
                    [[[storage stringForKey:kAMADatabaseKeyLibraryVersion error:nil] should] equal:version];
                    [[[storage stringForKey:AMAStorageStringKeyDidApplyDataMigrationFor500 error:nil] should] equal:@"1"];

                    // Should reset startup update date
                    [[[storage dateForKey:AMAStorageStringKeyStartupUpdatedAt error:nil] should] equal:[NSDate distantPast]];
                    
                    // Should migrate ad url to extended params
                    [[[storage jsonDictionaryForKey:AMAStorageStringKeyExtendedParameters error:nil] should] equal:@{@"get_ad" : adUrl}];
                }];
            });
            
            it(@"Should reset startup update date during migration to 5.8.0", ^{
                [AMADataMigrationTo500 stubbedNullMockForDefaultInit];
                id<AMADatabaseProtocol> newDB = [AMADatabaseFactory configurationDatabase];
                [newDB inDatabase:^(AMAFMDatabase *db) {
                    id<AMAKeyValueStoring> storage = [newDB.storageProvider storageForDB:db];

                    [[[storage stringForKey:AMAStorageStringKeyDidApplyDataMigrationFor580 error:nil] should] equal:@"1"];
                    [[[storage stringForKey:AMAStorageStringKeyDidApplyDataMigrationFor500 error:nil] should] beNil];

                    // Should reset startup update date
                    [[[storage dateForKey:AMAStorageStringKeyStartupUpdatedAt error:nil] should] equal:[NSDate distantPast]];
                }];
            });
            
            
            __auto_type testMigrationTo590 = ^(BOOL isExtension) {
                context(@"Migration to 5.9.0", ^{
                    AMAAppMetricaUUIDMigrator *__block migrator = nil;
                    NSObject<AMAIdentifierProviding> *__block identifierProviderMock = nil;
                    
                    beforeEach(^{
                        [AMADataMigrationTo500 stubbedNullMockForDefaultInit];
                        [AMADataMigrationTo580 stubbedNullMockForDefaultInit];
                        
                        identifierProviderMock = [KWMock nullMockForProtocol:@protocol(AMAIdentifierProviding)];
                        [configuration stub:@selector(identifierProvider) andReturn:identifierProviderMock];
                    });
                    
                    it(@"Should migrate uuid to identifier provider", ^{
                        NSString *const expectedUUID = @"appmetrica_uuid";
                        NSString *__block resultUUID = nil;
                        
                        migrator = [AMAAppMetricaUUIDMigrator stubbedNullMockForDefaultInit];
                        [migrator stub:@selector(migrateAppMetricaUUID) andReturn:expectedUUID];
                        
                        [identifierProviderMock stub:@selector(updateAppMetricaUUID:) withBlock:^id(NSArray *params) {
                            resultUUID = params[0];
                            return nil;
                        }];
                        
                        id<AMADatabaseProtocol> newDB = [AMADatabaseFactory configurationDatabase];
                        [newDB inDatabase:^(AMAFMDatabase *db) {
                            id<AMAKeyValueStoring> storage = [newDB.storageProvider storageForDB:db];
                            
                            [[[storage stringForKey:AMAStorageStringKeyDidApplyDataMigrationFor500 error:nil] should] beNil];
                            [[[storage stringForKey:AMAStorageStringKeyDidApplyDataMigrationFor580 error:nil] should] beNil];
                            
                            [[[storage stringForKey:AMAStorageStringKeyDidApplyDataMigrationFor590 error:nil] should] equal:@"1"];
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
                        
                        id<AMADatabaseProtocol> newDB = [AMADatabaseFactory configurationDatabase];
                        id<AMAKeyValueStoring> dbStorage = newDB.storageProvider.cachingStorage;
                        
                        [(NSObject *)dbStorage stub:@selector(stringForKey:error:)
                                          andReturn:expectedDeviceID
                                      withArguments:dbStorageKey(AMAAppMetricaIdentifiersKeys.deviceID), kw_any()];
                        
                        [(NSObject *)dbStorage stub:@selector(stringForKey:error:)
                                          andReturn:expectedDeviceIDHash
                                      withArguments:dbStorageKey(AMAAppMetricaIdentifiersKeys.deviceIDHash), kw_any()];
                        
                        [newDB inDatabase:^(AMAFMDatabase *db) {
                            id<AMAKeyValueStoring> storage = [newDB.storageProvider storageForDB:db];
                            
                            [[[storage stringForKey:AMAStorageStringKeyDidApplyDataMigrationFor500 error:nil] should] beNil];
                            [[[storage stringForKey:AMAStorageStringKeyDidApplyDataMigrationFor580 error:nil] should] beNil];
                            
                            [[[storage stringForKey:AMAStorageStringKeyDidApplyDataMigrationFor590 error:nil] should] equal:@"1"];
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
                });
            };
            
            context(@"Should migrate within App", ^{
                beforeEach(^{
                    [AMAPlatformDescription stub:@selector(isExtension) andReturn:theValue(NO)];
                });
                testMigrationTo590(NO);
            });
            
            context(@"Should migrate within Extension", ^{
                beforeEach(^{
                    [AMAPlatformDescription stub:@selector(isExtension) andReturn:theValue(YES)];
                });
                testMigrationTo590(YES);
            });
            
            context(@"UUID", ^{
                NSString *const uuid = @"768a11f6f9f4422fa5ec19eb0d8e074a";
                it(@"Should migrate uuid", ^{
                    AMAInstantFeaturesConfiguration *migrationConfiguration = [AMAInstantFeaturesConfiguration migrationInstance];
                    [migrationConfiguration setUUID:uuid];
                    
                    [[instantMock should] receive:@selector(setUUID:) withArguments:uuid];
                    
                    id<AMADatabaseProtocol> newDB = [AMADatabaseFactory configurationDatabase];
                    
                    [newDB inDatabase:^(AMAFMDatabase *db) {
                        id<AMAKeyValueStoring> storage = [newDB.storageProvider storageForDB:db];
                        [[[storage stringForKey:AMAStorageStringKeyDidApplyDataMigrationFor500 error:nil] should] equal:@"1"];
                    }];
                });
                
                it(@"Should not migrate uuid if the file does not exist", ^{
                    [AMAFileUtility stub:@selector(fileExistsAtPath:)
                               andReturn:theValue(NO)
                           withArguments:[[AMAMigrationTo500Utils migrationPath] stringByAppendingPathComponent:kAMAInstantFileName]];
                    AMAInstantFeaturesConfiguration *migrationConfiguration = [AMAInstantFeaturesConfiguration migrationInstance];
                    [migrationConfiguration setUUID:uuid];
                    
                    [[instantMock shouldNot] receive:@selector(setUUID:) withArguments:uuid];
                    
                    id<AMADatabaseProtocol> newDB = [AMADatabaseFactory configurationDatabase];
                    
                    [newDB inDatabase:^(AMAFMDatabase *db) {
                        id<AMAKeyValueStoring> storage = [newDB.storageProvider storageForDB:db];
                        [[[storage stringForKey:AMAStorageStringKeyDidApplyDataMigrationFor500 error:nil] should] equal:@"1"];
                    }];
                });
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
                
                it(@"Should migrate deviceID with keychain if no old db exists", ^{
                    [[NSFileManager defaultManager] removeItemAtPath:[AMAMigrationTo500Utils migrationPath] error:nil];
                    
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
                    
                    id<AMADatabaseProtocol> newDB = [AMADatabaseFactory configurationDatabase];
                    
                    [newDB inDatabase:^(AMAFMDatabase *db) {
                        id<AMAKeyValueStoring> storage = [newDB.storageProvider storageForDB:db];
                        [[[storage stringForKey:AMAStorageStringKeyDidApplyDataMigrationFor500 error:nil] should] equal:@"1"];
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
                    
                    id<AMADatabaseProtocol> newDB = [AMADatabaseFactory configurationDatabase];
                    
                    [newDB inDatabase:^(AMAFMDatabase *db) {
                        id<AMAKeyValueStoring> storage = [newDB.storageProvider storageForDB:db];
                        [[[storage stringForKey:AMAStorageStringKeyDidApplyDataMigrationFor500 error:nil] should] equal:@"1"];
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
                    
                    id<AMADatabaseProtocol> newDB = [AMADatabaseFactory configurationDatabase];
                    
                    [newDB inDatabase:^(AMAFMDatabase *db) {
                        id<AMAKeyValueStoring> storage = [newDB.storageProvider storageForDB:db];
                        [[[storage stringForKey:AMAStorageStringKeyDidApplyDataMigrationFor500 error:nil] should] equal:@"1"];
                    }];
                });
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
                    
                    id<AMADatabaseProtocol> newDB = [AMADatabaseFactory configurationDatabase];
                    
                    [newDB inDatabase:^(AMAFMDatabase *db) {
                        id<AMAKeyValueStoring> storage = [newDB.storageProvider storageForDB:db];
                        [[[storage stringForKey:AMAStorageStringKeyDidApplyDataMigrationFor500 error:nil] should] equal:@"1"];
                        
                        [[[storage stringForKey:[NSString stringWithFormat:format, [AMAAppMetricaIdentifiersKeys deviceID]] error:nil] should] equal:deviceID];
                        [[[storage stringForKey:[NSString stringWithFormat:format, [AMAAppMetricaIdentifiersKeys deviceIDHash]] error:nil] should] equal:deviceIDHash];
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
                
                id<AMADatabaseProtocol> newDB = [AMADatabaseFactory configurationDatabase];
                
                [newDB inDatabase:^(AMAFMDatabase *db) {
                    id<AMAKeyValueStoring> storage = [newDB.storageProvider storageForDB:db];
                    
                    [[[storage stringForKey:AMAStorageStringKeyDidApplyDataMigrationFor500 error:nil] should] equal:@"1"];
                }];
                
                [[theValue([fileManager fileExistsAtPath:oldDirPath]) should] beNo];
                [[theValue([fileManager fileExistsAtPath:newDirPath]) should] beYes];
            });
            
        });
        
        //FIXME: https://nda.ya.ru/t/rdPvwj0x7DfZdu
        context(@"Reporter data migration", ^{
            NSString *const key = @"foo";
            NSString *const value = @"bar";
            id<AMADatabaseProtocol> __block migrationDatabase = nil;
            NSString *const apiKey = [AMAReporterTestHelper defaultApiKey];

            AMASharedReporterProvider *__block reporterProvider = nil;
            AMAEventsCleaner *__block eventsCleaner = nil;

            beforeEach(^{
                cleanDatabase();

                reporterProvider = [[AMASharedReporterProvider alloc] initWithApiKey:apiKey];
                eventsCleaner = [[AMAEventsCleaner alloc] initWithReporterProvider:reporterProvider];

                AMADatabaseMigrationManager *migrationManager =
                    [[AMADatabaseMigrationManager alloc] initWithCurrentSchemeVersion:2
                                                                     schemeMigrations:@[]
                                                                     apiKeyMigrations:@[]
                                                                       dataMigrations:@[]
                                                                    libraryMigrations:@[]];
                AMATableSchemeController *tableSchemeController = [[AMATableSchemeController alloc] initWithTableSchemes:@{
                    kAMAEventTableName: [AMATableDescriptionProvider eventsTableMetaInfo],
                    kAMASessionTableName: [AMATableDescriptionProvider sessionsTableMetaInfo],
                    kAMAKeyValueTableName: [AMATableDescriptionProvider binaryKVTableMetaInfo],
                }];
                id<AMADatabaseKeyValueStorageProviding> storageProvider =
                    [AMAKeyValueStorageProvidersFactory databaseProviderForTableName:kAMAKeyValueTableName
                                                                           converter:[[AMABinaryDatabaseKeyValueStorageConverter alloc] init]
                                                                      objectProvider:[AMADatabaseObjectProvider blockForDataBlobs]
                                                              backingKVSDataProvider:nil];

                migrationDatabase = [AMADatabaseMigrationTestsUtils databaseWithPath:[[[AMAMigrationTo500Utils migrationPath]
                                                                                       stringByAppendingPathComponent:apiKey]
                                                                                      stringByAppendingPathComponent:@"data.sqlite"]
                                                                    migrationManager:migrationManager
                                                                     storageProvider:storageProvider
                                                                    schemeController:tableSchemeController];
            });
            
            __auto_type testMigrationData500 = ^(BOOL main) {
                
                it(@"Should migrate kv table", ^{
                    [AMADataMigrationTo580 stubbedNullMockForDefaultInit];
                    [migrationDatabase inDatabase:^(AMAFMDatabase *db) {
                        id<AMAKeyValueStoring> storage = [migrationDatabase.storageProvider storageForDB:db];
                        
                        [storage saveString:value forKey:key error:nil];
                    }];
                    
                    id<AMADatabaseProtocol> newDB = [AMADatabaseFactory reporterDatabaseForApiKey:apiKey
                                                                                             main:main
                                                                                    eventsCleaner:eventsCleaner];
                    
                    [newDB inDatabase:^(AMAFMDatabase *db) {
                        id<AMAKeyValueStoring> storage = [newDB.storageProvider storageForDB:db];
                        
                        [[[storage stringForKey:key error:nil] should] equal:value];
                        [[theValue([storage boolNumberForKey:AMAStorageStringKeyDidApplyDataMigrationFor500 error:nil].boolValue) should] beYes];
                    }];
                });
                
                it(@"Should migrate event hashes", ^{
                    [AMAReporterDataMigrationTo580 stubbedNullMockForInit:@selector(initWithApiKey:main:)];
                    NSMutableSet *eventNameHashes = [NSMutableSet set];
                    [eventNameHashes addObjectsFromArray:@[@13, @4, @8293]];
                    
                    [migrationDatabase inDatabase:^(AMAFMDatabase *db) {
                        id<AMAKeyValueStoring> storage = [migrationDatabase.storageProvider storageForDB:db];
                        
                        [storage saveString:value forKey:key error:nil];
                    }];
                    
                    NSString *migrationPath = [[AMAMigrationTo500Utils migrationPath] stringByAppendingPathComponent:apiKey];
                    AMAEventNameHashesStorage *migrationStorage = [AMAEventNameHashesStorageFactory migrationStorageForPath:migrationPath];
                    
                    AMAEventNameHashesCollection *eventHashesCollection = [[AMAEventNameHashesCollection alloc] initWithCurrentVersion:@"2.3.4"
                                                                                                         hashesCountFromCurrentVersion:9
                                                                                                              handleNewEventsAsUnknown:YES
                                                                                                                       eventNameHashes:eventNameHashes];
                    [migrationStorage saveCollection:eventHashesCollection];
                    
                    // After migration
                    id<AMADatabaseProtocol> newDB = [AMADatabaseFactory reporterDatabaseForApiKey:apiKey
                                                                                             main:main
                                                                                    eventsCleaner:eventsCleaner];
                    [newDB inDatabase:^(AMAFMDatabase *db) {
                        id<AMAKeyValueStoring> storage = [newDB.storageProvider storageForDB:db];
                        [[theValue([storage boolNumberForKey:AMAStorageStringKeyDidApplyDataMigrationFor500 error:nil].boolValue) should] beYes];
                    }];
                    
                    AMAEventNameHashesStorage *currentStorage = [AMAEventNameHashesStorageFactory storageForApiKey:apiKey main:NO];
                    AMAEventNameHashesCollection *loadedCollection = [currentStorage loadCollection];
                    
                    [[loadedCollection.currentVersion should] equal:eventHashesCollection.currentVersion];
                    [[theValue(loadedCollection.hashesCountFromCurrentVersion) should] equal:theValue(eventHashesCollection.hashesCountFromCurrentVersion)];
                    [[theValue(loadedCollection.handleNewEventsAsUnknown) should] equal:theValue(eventHashesCollection.handleNewEventsAsUnknown)];
                    [[loadedCollection.eventNameHashes should] equal:eventHashesCollection.eventNameHashes];
                });
                
                it(@"Should not migrate event hashes if db file does not exist", ^{
                    [AMAReporterDataMigrationTo580 stubbedNullMockForInit:@selector(initWithApiKey:main:)];
                    NSMutableSet *eventNameHashes = [NSMutableSet set];
                    [eventNameHashes addObjectsFromArray:@[@13, @4, @8293]];
                    
                    [migrationDatabase inDatabase:^(AMAFMDatabase *db) {
                        id<AMAKeyValueStoring> storage = [migrationDatabase.storageProvider storageForDB:db];
                        
                        [storage saveString:value forKey:key error:nil];
                    }];
                    
                    [AMAFileUtility stub:@selector(fileExistsAtPath:)
                               andReturn:theValue(NO)
                           withArguments:[[[AMAMigrationTo500Utils migrationPath]
                                           stringByAppendingPathComponent:apiKey]
                                          stringByAppendingPathComponent:@"data.sqlite"]];
                    
                    NSString *migrationPath = [[AMAMigrationTo500Utils migrationPath] stringByAppendingPathComponent:apiKey];
                    AMAEventNameHashesStorage *migrationStorage = [AMAEventNameHashesStorageFactory migrationStorageForPath:migrationPath];
                    
                    AMAEventNameHashesCollection *eventHashesCollection = [[AMAEventNameHashesCollection alloc] initWithCurrentVersion:@"2.3.4"
                                                                                                         hashesCountFromCurrentVersion:9
                                                                                                              handleNewEventsAsUnknown:YES
                                                                                                                       eventNameHashes:eventNameHashes];
                    [migrationStorage saveCollection:eventHashesCollection];
                    
                    // After migration
                    id<AMADatabaseProtocol> newDB = [AMADatabaseFactory reporterDatabaseForApiKey:apiKey
                                                                                             main:main
                                                                                    eventsCleaner:eventsCleaner];
                    [newDB inDatabase:^(AMAFMDatabase *db) {
                        id<AMAKeyValueStoring> storage = [newDB.storageProvider storageForDB:db];
                        [[theValue([storage boolNumberForKey:AMAStorageStringKeyDidApplyDataMigrationFor500 error:nil].boolValue) should] beYes];
                    }];
                    
                    AMAEventNameHashesStorage *currentStorage = [AMAEventNameHashesStorageFactory storageForApiKey:apiKey main:NO];
                    AMAEventNameHashesCollection *loadedCollection = [currentStorage loadCollection];
                    
                    [[loadedCollection.currentVersion should] beNil];
                    [[theValue(loadedCollection.hashesCountFromCurrentVersion) should] beZero];
                    [[theValue(loadedCollection.handleNewEventsAsUnknown) should] beNo];
                    [[loadedCollection.eventNameHashes should] beNil];
                });
            };
            
            context(@"Should migrate main reporter", ^{
                testMigrationData500(YES);
            });
            
            context(@"Should migrate non main reporter", ^{
                testMigrationData500(NO);
            });
            
            AMAReporterStorage *(^buildReporterStorage)(id<AMADatabaseProtocol>, NSString *) = ^(id<AMADatabaseProtocol> database, NSString *apiKey) {
                AMAEnvironmentContainer *eventEnvironment = [[AMAEnvironmentContainer alloc] init];

                return [[AMAReporterStorage alloc] initWithApiKey:apiKey
                                                 eventEnvironment:eventEnvironment
                                                    eventsCleaner:eventsCleaner
                                                         database:database
                                                             main:NO];
            };
            
            context(@"5.8.0 Migration", ^{
                it(@"Should migrate key value table for main reporter", ^{
                    [AMADataMigrationTo500 stubbedNullMockForDefaultInit];
                    id<AMADatabaseProtocol> prevDB = [AMADatabaseFactory reporterDatabaseForApiKey:apiKey main:NO eventsCleaner:eventsCleaner];
                    [prevDB inDatabase:^(AMAFMDatabase *db) {
                        id<AMAKeyValueStoring> storage = [prevDB.storageProvider storageForDB:db];
                        
                        [storage saveString:value forKey:key error:nil];
                    }];
                    
                    // After migration
                    id<AMADatabaseProtocol> newDB = [AMADatabaseFactory reporterDatabaseForApiKey:apiKey main:YES eventsCleaner:eventsCleaner];
                    [newDB inDatabase:^(AMAFMDatabase *db) {
                        id<AMAKeyValueStoring> storage = [newDB.storageProvider storageForDB:db];
                        
                        [[[storage stringForKey:key error:nil] should] equal:value];
                    }];
                });
                
                it(@"Should migrate event hashes for main reporter", ^{
                    [AMAReporterDataMigrationTo500 stubbedNullMockForInit:@selector(initWithApiKey:)];
                    id<AMADatabaseProtocol> prevDB = [AMADatabaseFactory reporterDatabaseForApiKey:apiKey main:NO eventsCleaner:eventsCleaner];
                    [prevDB inDatabase:^(AMAFMDatabase *db) {
                        id<AMAKeyValueStoring> storage = [prevDB.storageProvider storageForDB:db];
                        
                        [storage saveString:value forKey:key error:nil];
                    }];
                    
                    NSMutableSet *eventNameHashes = [NSMutableSet set];
                    [eventNameHashes addObjectsFromArray:@[@13, @4, @8293]];
                    
                    AMAEventNameHashesStorage *migrationStorage = [AMAEventNameHashesStorageFactory storageForApiKey:apiKey main:NO];
                    
                    AMAEventNameHashesCollection *eventHashesCollection = [[AMAEventNameHashesCollection alloc] initWithCurrentVersion:@"2.3.4"
                                                                                                         hashesCountFromCurrentVersion:9
                                                                                                              handleNewEventsAsUnknown:YES
                                                                                                                       eventNameHashes:eventNameHashes];
                    [migrationStorage saveCollection:eventHashesCollection];
                    
                    // After migration
                    id<AMADatabaseProtocol> newDB = [AMADatabaseFactory reporterDatabaseForApiKey:apiKey
                                                                                             main:YES
                                                                                    eventsCleaner:eventsCleaner];
                    [newDB inDatabase:^(AMAFMDatabase *db) {
                        id<AMAKeyValueStoring> storage = [newDB.storageProvider storageForDB:db];
                        [[theValue([storage boolNumberForKey:AMAStorageStringKeyDidApplyDataMigrationFor580 error:nil].boolValue) should] beYes];
                    }];
                    
                    AMAEventNameHashesStorage *currentStorage = [AMAEventNameHashesStorageFactory storageForApiKey:apiKey main:YES];
                    AMAEventNameHashesCollection *loadedCollection = [currentStorage loadCollection];
                    
                    [[loadedCollection.currentVersion should] equal:eventHashesCollection.currentVersion];
                    [[theValue(loadedCollection.hashesCountFromCurrentVersion) should] equal:theValue(eventHashesCollection.hashesCountFromCurrentVersion)];
                    [[theValue(loadedCollection.handleNewEventsAsUnknown) should] equal:theValue(eventHashesCollection.handleNewEventsAsUnknown)];
                    [[loadedCollection.eventNameHashes should] equal:eventHashesCollection.eventNameHashes];
                });
                
                it(@"Should not migrate event hashes for main reporter if the file does not exist", ^{
                    [AMAReporterDataMigrationTo500 stubbedNullMockForInit:@selector(initWithApiKey:)];
                    id<AMADatabaseProtocol> prevDB = [AMADatabaseFactory reporterDatabaseForApiKey:apiKey main:NO eventsCleaner:eventsCleaner];
                    [prevDB inDatabase:^(AMAFMDatabase *db) {
                        id<AMAKeyValueStoring> storage = [prevDB.storageProvider storageForDB:db];
                        
                        [storage saveString:value forKey:key error:nil];
                    }];
                    
                    [AMAFileUtility stub:@selector(fileExistsAtPath:)
                               andReturn:theValue(NO)
                           withArguments:[[AMAFileUtility persistentPathForApiKey:apiKey]
                                          stringByAppendingPathComponent:kAMAEventHashesFileName]];
                    
                    NSMutableSet *eventNameHashes = [NSMutableSet set];
                    [eventNameHashes addObjectsFromArray:@[@13, @4, @8293]];
                    
                    AMAEventNameHashesStorage *migrationStorage = [AMAEventNameHashesStorageFactory storageForApiKey:apiKey main:NO];
                    
                    AMAEventNameHashesCollection *eventHashesCollection = [[AMAEventNameHashesCollection alloc] initWithCurrentVersion:@"2.3.4"
                                                                                                         hashesCountFromCurrentVersion:9
                                                                                                              handleNewEventsAsUnknown:YES
                                                                                                                       eventNameHashes:eventNameHashes];
                    [migrationStorage saveCollection:eventHashesCollection];
                    
                    // After migration
                    id<AMADatabaseProtocol> newDB = [AMADatabaseFactory reporterDatabaseForApiKey:apiKey
                                                                                             main:YES
                                                                                    eventsCleaner:eventsCleaner];
                    [newDB inDatabase:^(AMAFMDatabase *db) {
                        id<AMAKeyValueStoring> storage = [newDB.storageProvider storageForDB:db];
                        [[theValue([storage boolNumberForKey:AMAStorageStringKeyDidApplyDataMigrationFor580 error:nil].boolValue) should] beYes];
                    }];
                    
                    AMAEventNameHashesStorage *currentStorage = [AMAEventNameHashesStorageFactory storageForApiKey:apiKey main:YES];
                    AMAEventNameHashesCollection *loadedCollection = [currentStorage loadCollection];
                    
                    [[loadedCollection.currentVersion should] beNil];
                    [[theValue(loadedCollection.hashesCountFromCurrentVersion) should] beZero];
                    [[theValue(loadedCollection.handleNewEventsAsUnknown) should] beNo];
                    [[loadedCollection.eventNameHashes should] beNil];
                });
                
                it(@"Should migrate events and sessions", ^{
                    NSDictionary *const extras = @{ @"extras" : [@"value" dataUsingEncoding:NSUTF8StringEncoding] };
                    NSDictionary *const params = @{ @"foo" : @"bar" };
                    
                    [AMAReporterDataMigrationTo500 stubbedNullMockForInit:@selector(initWithApiKey:)];
                    id<AMADatabaseProtocol> prevDB = [AMADatabaseFactory reporterDatabaseForApiKey:apiKey main:NO eventsCleaner:eventsCleaner];
                    [prevDB inDatabase:^(AMAFMDatabase *db) {
                        id<AMAKeyValueStoring> storage = [prevDB.storageProvider storageForDB:db];
                        
                        [storage saveString:value forKey:key error:nil];
                    }];

                    AMAReporterStorage *migrationStorage = buildReporterStorage(prevDB, apiKey);

                    AMAEventBuilder *eventBuilder = [[AMAEventBuilder alloc] initWithStateStorage:migrationStorage.stateStorage
                                                                                      preloadInfo:nil];

                    AMASessionSerializer *migrationSessionSerializer = [[AMASessionSerializer alloc] init];
                    [migrationStorage.sessionStorage stub:@selector(serializer) andReturn:migrationSessionSerializer];
                    NSDate *creationDate = [NSDate date];
                    AMASession *sessionToMigrate = [migrationStorage.sessionStorage newGeneralSessionCreatedAt:creationDate error:nil];

                    AMAEvent *eventToMigrate = [eventBuilder eventWithType:99
                                                                      name:@"eventName"
                                                                     value:@"eventValue"
                                                          eventEnvironment:params
                                                            appEnvironment:params
                                                                    extras:extras
                                                                     error:nil];
                    eventToMigrate.createdAt = creationDate;
                    eventToMigrate.timeSinceSession = [creationDate timeIntervalSinceDate:sessionToMigrate.startDate.deviceDate];
                    eventToMigrate.sessionOid = sessionToMigrate.oid;
                    eventToMigrate.location = [[CLLocation alloc] initWithLatitude:22.0 longitude:33.0];
                    eventToMigrate.appEnvironment = params;
                    eventToMigrate.profileID = @"profileID";


                    AMAEventSerializer *migrationEventSerializer = [[AMAEventSerializer alloc] init];
                    [migrationStorage.eventStorage stub:@selector(eventSerializer) andReturn:migrationEventSerializer];

                    [migrationStorage.eventStorage addEvent:eventToMigrate toSession:sessionToMigrate error:nil];

                    // After migration
                    id<AMADatabaseProtocol> newDB = [AMADatabaseFactory reporterDatabaseForApiKey:apiKey
                                                                                             main:YES
                                                                                    eventsCleaner:eventsCleaner];
                    AMAReporterStorage *newReporterStorage = buildReporterStorage(newDB, apiKey);


                    AMAEvent *migratedEvent = [[newReporterStorage.eventStorage allEvents] firstObject];

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

                    [[migratedEvent.extras should] equal:eventToMigrate.extras];


                    AMASession *migratedSession = [newReporterStorage.sessionStorage lastSessionWithError:nil];

                    [[migratedSession.oid should] equal:sessionToMigrate.oid];
                    [[migratedSession.startDate should] equal:sessionToMigrate.startDate];
                    [[migratedSession.lastEventTime should] equal:sessionToMigrate.lastEventTime];
                    [[migratedSession.pauseTime should] equal:sessionToMigrate.pauseTime];
                    [[migratedSession.sessionID should] equal:sessionToMigrate.sessionID];
                    [[migratedSession.attributionID should] equal:sessionToMigrate.attributionID];
                    [[theValue(migratedSession.type) should] equal:theValue(sessionToMigrate.type)];


                    [newDB inDatabase:^(AMAFMDatabase *db) {
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
            });
            
            __auto_type testMigrationEventsAndSessions = ^() {
                it(@"Should migrate events and sessions", ^{
                    [AMAReporterDataMigrationTo580 stubbedNullMockForInit:@selector(initWithApiKey:main:)];
                    NSDictionary *const extras = @{ @"extras" : [@"value" dataUsingEncoding:NSUTF8StringEncoding] };
                    NSDictionary *const legacyExtras = @{@"user_id":@"user id",
                                                         @"type":@"user type",
                                                         @"options":@{@"key":@"value"}};

                    NSDictionary *const params = @{ @"foo" : @"bar" };

                    AMAReporterStorage *migrationStorage = buildReporterStorage(migrationDatabase, apiKey);

                    AMAEventBuilder *eventBuilder = [[AMAEventBuilder alloc] initWithStateStorage:migrationStorage.stateStorage
                                                                                      preloadInfo:nil];

                    AMASessionSerializer *migrationSessionSerializer = [[AMASessionSerializer alloc] migrationInit];
                    [migrationStorage.sessionStorage stub:@selector(serializer) andReturn:migrationSessionSerializer];
                    NSDate *creationDate = [NSDate date];
                    AMASession *sessionToMigrate = [migrationStorage.sessionStorage newGeneralSessionCreatedAt:creationDate error:nil];

                    AMAEvent *eventToMigrate = [eventBuilder eventWithType:99
                                                                      name:@"eventName"
                                                                     value:@"eventValue"
                                                          eventEnvironment:params
                                                            appEnvironment:params
                                                                    extras:extras
                                                                     error:nil];
                    eventToMigrate.createdAt = creationDate;
                    eventToMigrate.timeSinceSession = [creationDate timeIntervalSinceDate:sessionToMigrate.startDate.deviceDate];
                    eventToMigrate.sessionOid = sessionToMigrate.oid;
                    eventToMigrate.location = [[CLLocation alloc] initWithLatitude:22.0 longitude:33.0];
                    eventToMigrate.appEnvironment = params;
                    eventToMigrate.profileID = @"profileID";


                    AMAEventSerializer *migrationEventSerializer = [[AMAEventSerializer alloc] migrationInit];
                    [migrationStorage.eventStorage stub:@selector(eventSerializer) andReturn:migrationEventSerializer];

                    [migrationStorage.eventStorage addEvent:eventToMigrate toSession:sessionToMigrate error:nil];

                    NSData *legacyExtrasValue = [AMALegacyEventExtrasProvider packExtras:legacyExtras];
                    NSMutableDictionary *expectedExtras = [@{ @"ai" : legacyExtrasValue } mutableCopy];
                    [expectedExtras addEntriesFromDictionary:extras];


                    [migrationDatabase inDatabase:^(AMAFMDatabase *db) {
                        id<AMAKeyValueStoring> storage = [migrationDatabase.storageProvider storageForDB:db];

                        [storage saveString:[AMAJSONSerialization stringWithJSONObject:legacyExtras error:nil] forKey:@"user_info" error:nil];
                    }];

                    // After migration
                    id<AMAAppMetricaExtendedReporting> reporter = [AMAAppMetrica extendedReporterForApiKey:apiKey];
                    [(NSObject *)reporter stub:@selector(setSessionExtras:forKey:)];
                    [[(NSObject *)reporter should] receive:@selector(setSessionExtras:forKey:) withArguments:legacyExtrasValue, @"ai"];

                    id<AMADatabaseProtocol> newDB = [AMADatabaseFactory reporterDatabaseForApiKey:apiKey
                                                                                             main:NO
                                                                                    eventsCleaner:eventsCleaner];
                    AMAReporterStorage *newReporterStorage = buildReporterStorage(newDB, apiKey);


                    AMAEvent *migratedEvent = [[newReporterStorage.eventStorage allEvents] firstObject];

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

                    [[migratedEvent.extras should] equal:expectedExtras];


                    AMASession *migratedSession = [newReporterStorage.sessionStorage lastSessionWithError:nil];

                    [[migratedSession.oid should] equal:sessionToMigrate.oid];
                    [[migratedSession.startDate should] equal:sessionToMigrate.startDate];
                    [[migratedSession.lastEventTime should] equal:sessionToMigrate.lastEventTime];
                    [[migratedSession.pauseTime should] equal:sessionToMigrate.pauseTime];
                    [[migratedSession.sessionID should] equal:sessionToMigrate.sessionID];
                    [[migratedSession.attributionID should] equal:sessionToMigrate.attributionID];
                    [[theValue(migratedSession.type) should] equal:theValue(sessionToMigrate.type)];


                    [newDB inDatabase:^(AMAFMDatabase *db) {
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

            context(@"Migration with appID", ^{
                testMigrationEventsAndSessions();
            });

            context(@"Migration with SDK Bundle", ^{
                beforeEach(^{
                    [AMAPlatformDescription stub:@selector(appID) andReturn:nil];
                });
                testMigrationEventsAndSessions();
            });
        });

        context(@"Location data migration", ^{
            id<AMADatabaseProtocol> __block migrationDatabase = nil;

            beforeEach(^{
                cleanDatabase();

                AMADatabaseMigrationManager *migrationManager =
                    [[AMADatabaseMigrationManager alloc] initWithCurrentSchemeVersion:2
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

                migrationDatabase = [AMADatabaseMigrationTestsUtils databaseWithPath:[[AMAMigrationTo500Utils migrationPath]
                                                                                      stringByAppendingPathComponent:@"l_data.sqlite"]
                                                                    migrationManager:migrationManager
                                                                     storageProvider:storageProvider
                                                                    schemeController:tableSchemeController];
            });

            it(@"Should migrate kv table", ^{
                NSString *const key = @"foo";
                NSString *const value = @"bar";

                [migrationDatabase inDatabase:^(AMAFMDatabase *db) {
                    id<AMAKeyValueStoring> storage = [migrationDatabase.storageProvider storageForDB:db];

                    [storage saveString:value forKey:key error:nil];
                }];

                id<AMADatabaseProtocol> newDB = [AMADatabaseFactory locationDatabase];
                [newDB inDatabase:^(AMAFMDatabase *db) {
                    id<AMAKeyValueStoring> storage = [newDB.storageProvider storageForDB:db];

                    [[[storage stringForKey:key error:nil] should] equal:value];
                    [[[storage stringForKey:AMAStorageStringKeyDidApplyDataMigrationFor500 error:nil] should] equal:@"1"];
                }];
            });

            __auto_type testMigrationVisitsAndLocations = ^() {
                it(@"Should migrate visits and locations", ^{
                    AMALocationStorage *migrationStorage = [[AMALocationStorage alloc] initWithConfiguration:[[AMALocationCollectingConfiguration alloc] init]
                                                                                                  serializer:[[AMALocationSerializer alloc] init]
                                                                                                    database:migrationDatabase
                                                                                                     crypter:[AMALocationEncoderFactory migrationEncoder]];

                    NSDate *visitDate = [NSDate dateWithTimeIntervalSince1970:22.0];
                    AMAVisit *visitToMigrate = [AMAVisit visitWithIdentifier:@8
                                                                 collectDate:visitDate
                                                                 arrivalDate:visitDate
                                                               departureDate:visitDate
                                                                    latitude:23.0
                                                                   longitude:24.0
                                                                   precision:5];
                    [migrationStorage addVisit:visitToMigrate];

                    NSDate *locationDate = [NSDate dateWithTimeIntervalSince1970:23.0];
                    AMALocation *locationToMigrate = [[AMALocation alloc] initWithIdentifier:@9
                                                                                 collectDate:locationDate
                                                                                    location:[[CLLocation alloc] initWithLatitude:22.0 longitude:33.0]
                                                                                    provider:AMALocationProviderGPS];
                    [migrationStorage addLocations:@[locationToMigrate]];

                    // After migration
                    id<AMADatabaseProtocol> newDB = [AMADatabaseFactory locationDatabase];
                    AMALocationStorage *locationStorage = [[AMALocationStorage alloc] initWithConfiguration:[[AMALocationCollectingConfiguration alloc] init]
                                                                                                 serializer:[[AMALocationSerializer alloc] init]
                                                                                                   database:newDB
                                                                                                    crypter:[AMALocationEncoderFactory encoder]];
                    AMAVisit *migratedVisit = [[locationStorage visitsWithLimit:1] firstObject];

                    [[migratedVisit.collectDate should] equal:visitToMigrate.collectDate];
                    [[migratedVisit.departureDate should] equal:visitToMigrate.departureDate];
                    [[migratedVisit.arrivalDate should] equal:visitToMigrate.arrivalDate];
                    [[theValue(migratedVisit.latitude) should] equal:theValue(visitToMigrate.latitude)];
                    [[theValue(migratedVisit.longitude) should] equal:theValue(visitToMigrate.longitude)];
                    [[theValue(migratedVisit.precision) should] equal:theValue(visitToMigrate.precision)];

                    AMALocation *migratedLocation = [[locationStorage locationsWithLimit:1] firstObject];

                    [[migratedLocation.collectDate should] equal:locationToMigrate.collectDate];
                    [[theValue(migratedLocation.location.coordinate.latitude) should] equal:theValue(locationToMigrate.location.coordinate.latitude)];
                    [[theValue(migratedLocation.location.coordinate.longitude) should] equal:theValue(locationToMigrate.location.coordinate.longitude)];
                    [[theValue(migratedLocation.provider) should] equal:theValue(locationToMigrate.provider)];

                    [locationStorage purgeVisitsWithIdentifiers:@[visitToMigrate.identifier]];
                    [locationStorage purgeLocationsWithIdentifiers:@[locationToMigrate.identifier]];
                });
            };

            context(@"Migration with appID", ^{
                testMigrationVisitsAndLocations();
            });

            context(@"Migration with SDK Bundle", ^{
                beforeEach(^{
                    [AMAPlatformDescription stub:@selector(appID) andReturn:nil];
                });
                testMigrationVisitsAndLocations();
            });
        });
    });
});

SPEC_END
