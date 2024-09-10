
#import <Kiwi/Kiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMADatabaseFactory.h"
#import "AMADatabase.h"
#import "AMADatabaseConstants.h"
#import "AMAStorageKeys.h"
#import "AMATableSchemeController.h"
#import "AMATableDescriptionProvider.h"
#import "AMADatabaseMigrationManager.h"
#import "AMAStorageTrimManager.h"
#import "AMADatabaseKeyValueStorageProvider.h"
#import "AMADatabaseObjectProvider.h"
#import "AMAEventsCleaner.h"
#import "AMABinaryDatabaseKeyValueStorageConverter.h"
#import "AMAStringDatabaseKeyValueStorageConverter.h"
#import "AMAProxyDataToStringKVSDataProvider.h"
#import "AMAJSONFileKVSDataProvider.h"

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
#import "AMADataMigrationTo500.h"
#import "AMALocationDataMigrationTo500.h"
#import "AMAReporterDataMigrationTo500.h"
#import "AMADataMigrationTo580.h"

#import "AMALocationDatabaseSchemeMigrationTo2.h"

#import "AMAReporterDatabaseSchemeMigrationTo2.h"

SPEC_BEGIN(AMADatabaseFactoryTests)

describe(@"AMADatabaseFactory", ^{

    NSString *const persistentPathForApiKey = @"/persistent/path/for/apikey";
    NSString *const applicationSupportDirectoryPath = @"/persistent/path";

    AMADatabaseObjectProviderBlock const objectProvider = ^id (AMAFMResultSet *rs, NSUInteger columdIdx) {
        return nil;
    };
    
#if TARGET_OS_TV
    void (^testValidDataStorageTVOS)(NSString *, void (^)(void)) = ^(NSString *suiteName,
                                                                     void(^createDatabaseBlock)(void)) {
        it(@"Should create valid data storage for tvOS", ^{
            NSUserDefaults *defaultsAlloced = [NSUserDefaults nullMock];
            NSUserDefaults *defaults = [NSUserDefaults nullMock];
            [NSUserDefaults stub:@selector(alloc) andReturn:defaultsAlloced];
            [defaultsAlloced stub:@selector(initWithSuiteName:)
                        andReturn:defaults
                    withArguments:suiteName];
            
            NSObject *provider = [AMAUserDefaultsKVSDataProvider stubbedNullMockForInit:@selector(initWithUserDefaults:)];
            
            KWCaptureSpy *spy = [provider captureArgument:@selector(initWithUserDefaults:) atIndex:0];
            createDatabaseBlock();
            [[spy.argument should] equal:defaults];
        });
    };
#endif

    SEL const migrationManagerInitSelector = @selector(initWithCurrentSchemeVersion:
                                                       schemeMigrations:
                                                       apiKeyMigrations:
                                                       dataMigrations:
                                                       libraryMigrations:);
    
    SEL const databaseInitSelector = @selector(initWithTableSchemeController:
                                               databasePath:migrationManager:
                                               trimManager:
                                               keyValueStorageProvider:
                                               criticalKeyValueKeys:);

    AMAStringDatabaseKeyValueStorageConverter *__block stringConverter = nil;
    AMABinaryDatabaseKeyValueStorageConverter *__block binaryConverter = nil;
    
    AMAProxyDataToStringKVSDataProvider *__block proxyDataProvider = nil;
    AMADiskFileStorage *__block diskFileStorage = nil;
    AMAJSONFileKVSDataProvider *__block JSONDataProvider = nil;
    
    AMADatabaseKeyValueStorageProvider *__block keyValueStorageProvider = nil;
    AMAEventsCleaner *__block eventsCleaner = nil;
    AMAStorageTrimManager *__block trimManager = nil;
    AMADatabaseMigrationManager *__block migrationManager = nil;
    AMATableSchemeController *__block tableSchemeController = nil;
    AMADatabase *__block database = nil;

    beforeEach(^{
        [AMAFileUtility stub:@selector(persistentPath) andReturn:applicationSupportDirectoryPath];
        [AMAFileUtility stub:@selector(persistentPathForApiKey:) andReturn:persistentPathForApiKey];

        stringConverter = [AMAStringDatabaseKeyValueStorageConverter stubbedNullMockForDefaultInit];
        binaryConverter = [AMABinaryDatabaseKeyValueStorageConverter stubbedNullMockForDefaultInit];

        diskFileStorage = [AMADiskFileStorage stubbedNullMockForInit:@selector(initWithPath:options:)];
        JSONDataProvider = [AMAJSONFileKVSDataProvider stubbedNullMockForInit:@selector(initWithFileStorage:)];
        proxyDataProvider =
            [AMAProxyDataToStringKVSDataProvider stubbedNullMockForInit:@selector(initWithUnderlyingDataProvider:)];
        
        keyValueStorageProvider =
            [AMADatabaseKeyValueStorageProvider stubbedNullMockForInit:@selector(initWithTableName:
                                                                                 converter:
                                                                                 objectProvider:
                                                                                 backingKVSDataProvider:)];
        eventsCleaner = [AMAEventsCleaner nullMock];
        trimManager = [AMAStorageTrimManager stubbedNullMockForInit:@selector(initWithApiKey:eventsCleaner:)];
        migrationManager = [AMADatabaseMigrationManager stubbedNullMockForInit:migrationManagerInitSelector];
        tableSchemeController = [AMATableSchemeController stubbedNullMockForInit:@selector(initWithTableSchemes:)];
        database = [AMADatabase stubbedNullMockForInit:databaseInitSelector];
    });

    context(@"Configuration database path", ^{

        it(@"Should return valid path", ^{
            [[[AMADatabaseFactory configurationDatabasePath] should] equal: [applicationSupportDirectoryPath stringByAppendingPathComponent:@"storage.sqlite"]];
        });
    });

    context(@"Configuration database", ^{
        NSObject *(^createDatabase)(void) = ^{
            return (NSObject *)[AMADatabaseFactory configurationDatabase];
        };

        it(@"Should create valid table scheme controller", ^{
            NSDictionary *scheme = @{
                @"kv": [AMATableDescriptionProvider stringKVTableMetaInfo],
            };
            [[tableSchemeController should] receive:@selector(initWithTableSchemes:) withArguments:scheme];
            createDatabase();
        });

        context(@"Migration manager", ^{
            NSUInteger __block currentSchemeVersion = 0;
            NSArray *__block schemeMigrations = nil;
            NSArray *__block apiKeyMigrations = nil;
            NSArray *__block dataMigrations = nil;
            NSArray *__block libraryMigrations = nil;
            beforeAll(^{
                [migrationManager stub:migrationManagerInitSelector withBlock:^id(NSArray *params) {
                    currentSchemeVersion = [params[0] unsignedIntegerValue];
                    schemeMigrations = params[1];
                    apiKeyMigrations = params[2];
                    dataMigrations = params[3];
                    libraryMigrations = params[4];
                    return migrationManager;
                }];
                createDatabase();
            });
            it(@"Should have valid version", ^{
                [[theValue(currentSchemeVersion) should] equal:theValue(20)];
            });
            context(@"Scheme migrations", ^{
                it(@"Should have valid migrations count", ^{
                    [[schemeMigrations should] haveCountOf:19];
                });
                it(@"Should have migration to 2", ^{
                    [[schemeMigrations[0] should] beKindOfClass:[AMAConfigurationDatabaseSchemeMigrationTo2 class]];
                });
                it(@"Should have migration to 3", ^{
                    [[schemeMigrations[1] should] beKindOfClass:[AMAConfigurationDatabaseSchemeMigrationTo3 class]];
                });
                it(@"Should have migration to 4", ^{
                    [[schemeMigrations[2] should] beKindOfClass:[AMAConfigurationDatabaseSchemeMigrationTo4 class]];
                });
                it(@"Should have migration to 5", ^{
                    [[schemeMigrations[3] should] beKindOfClass:[AMAConfigurationDatabaseSchemeMigrationTo5 class]];
                });
                it(@"Should have migration to 6", ^{
                    [[schemeMigrations[4] should] beKindOfClass:[AMAConfigurationDatabaseSchemeMigrationTo6 class]];
                });
                it(@"Should have migration to 7", ^{
                    [[schemeMigrations[5] should] beKindOfClass:[AMAConfigurationDatabaseSchemeMigrationTo7 class]];
                });
                it(@"Should have migration to 8", ^{
                    [[schemeMigrations[6] should] beKindOfClass:[AMAConfigurationDatabaseSchemeMigrationTo8 class]];
                });
                it(@"Should have migration to 9", ^{
                    [[schemeMigrations[7] should] beKindOfClass:[AMAConfigurationDatabaseSchemeMigrationTo9 class]];
                });
                it(@"Should have migration to 10", ^{
                    [[schemeMigrations[8] should] beKindOfClass:[AMAConfigurationDatabaseSchemeMigrationTo10 class]];
                });
                it(@"Should have migration to 11", ^{
                    [[schemeMigrations[9] should] beKindOfClass:[AMAConfigurationDatabaseSchemeMigrationTo11 class]];
                });
                it(@"Should have migration to 12", ^{
                    [[schemeMigrations[10] should] beKindOfClass:[AMAConfigurationDatabaseSchemeMigrationTo12 class]];
                });
                it(@"Should have migration to 13", ^{
                    [[schemeMigrations[11] should] beKindOfClass:[AMAConfigurationDatabaseSchemeMigrationTo13 class]];
                });
                it(@"Should have migration to 14", ^{
                    [[schemeMigrations[12] should] beKindOfClass:[AMAConfigurationDatabaseSchemeMigrationTo14 class]];
                });
                it(@"Should have migration to 15", ^{
                    [[schemeMigrations[13] should] beKindOfClass:[AMAConfigurationDatabaseSchemeMigrationTo15 class]];
                });
                it(@"Should have migration to 16", ^{
                    [[schemeMigrations[14] should] beKindOfClass:[AMAConfigurationDatabaseSchemeMigrationTo16 class]];
                });
                it(@"Should have migration to 17", ^{
                    [[schemeMigrations[15] should] beKindOfClass:[AMAConfigurationDatabaseSchemeMigrationTo17 class]];
                });
                it(@"Should have migration to 18", ^{
                    [[schemeMigrations[16] should] beKindOfClass:[AMAConfigurationDatabaseSchemeMigrationTo18 class]];
                });
                it(@"Should have migration to 19", ^{
                    [[schemeMigrations[17] should] beKindOfClass:[AMAConfigurationDatabaseSchemeMigrationTo19 class]];
                });
                it(@"Should have migration to 20", ^{
                    [[schemeMigrations[18] should] beKindOfClass:[AMAConfigurationDatabaseSchemeMigrationTo20 class]];
                });
            });
            context(@"API key migrations", ^{
                it(@"Should have 19th migration finalization", ^{
                    [[apiKeyMigrations[0] should] beKindOfClass:[AMAMigrationTo19FinalizationOnApiKeySpecified class]];
                });
            });
            it(@"Should have data migrations", ^{
                [[dataMigrations[0] should] beKindOfClass:[AMADataMigrationTo500 class]];
                [[dataMigrations[1] should] beKindOfClass:[AMADataMigrationTo580 class]];
            });
            context(@"Library migrations", ^{
                it(@"Should have 3.2.0 migration", ^{
                    [[libraryMigrations[0] should] beKindOfClass:[AMALibraryMigration320 class]];
                });
            });
        });

#if TARGET_OS_TV
        testValidDataStorageTVOS([@"io.appmetrica." stringByAppendingString:@"storage.bak"], ^{
            createDatabase();
        });
#else
        it(@"Should create valid data storage for iOS", ^{
            NSString *expectedPath = [applicationSupportDirectoryPath stringByAppendingPathComponent:@"storage.bak"];
            AMADiskFileStorageOptions expectedOptions =
                AMADiskFileStorageOptionNoBackup | AMADiskFileStorageOptionCreateDirectory;
            [[diskFileStorage should] receive:@selector(initWithPath:options:)
                                withArguments:expectedPath, theValue(expectedOptions)];
            createDatabase();
        });

        it(@"Should create valid backing provider", ^{
            [[JSONDataProvider should] receive:@selector(initWithFileStorage:) withArguments:diskFileStorage];
            createDatabase();
        });

        it(@"Should create valid key value storage provider", ^{
            [AMADatabaseObjectProvider stub:@selector(blockForStrings) andReturn:objectProvider];
            [[keyValueStorageProvider should] receive:@selector(initWithTableName:
                                                                converter:
                                                                objectProvider:
                                                                backingKVSDataProvider:)
                                        withArguments:@"kv", stringConverter, objectProvider, JSONDataProvider];
            createDatabase();
        });
#endif

        it(@"Should set key value storage provider database", ^{
            [[keyValueStorageProvider should] receive:@selector(setDatabase:) withArguments:database];
            createDatabase();
        });

        it(@"Should create database with valid parameters", ^{
            NSString *databasePath = [applicationSupportDirectoryPath stringByAppendingPathComponent:@"storage.sqlite"];
            NSArray *criticalKeys = @[
                AMAStorageStringKeyUUID,
            ];
            [[database should] receive:databaseInitSelector
                         withArguments:tableSchemeController, databasePath, migrationManager,
                                       nil, keyValueStorageProvider, criticalKeys];
            createDatabase();
        });

        it(@"Should return database", ^{
            [[createDatabase() should] equal:database];
        });
    });

    context(@"Reporter database", ^{
        NSString *const apiKey = @"API_KEY";
        
        NSObject *(^createDatabase)(BOOL) = ^NSObject *(BOOL main) {
            return (NSObject *)[AMADatabaseFactory reporterDatabaseForApiKey:apiKey main:main eventsCleaner:eventsCleaner];
        };
        
        void (^testReporterDatabase)(BOOL, NSObject *(^)(BOOL)) = ^(BOOL main, NSObject *(^createDatabaseBlock)(BOOL)) {
            
            it(@"Should create valid table scheme controller", ^{
                NSDictionary *scheme = @{
                    @"events": [AMATableDescriptionProvider eventsTableMetaInfo],
                    @"sessions": [AMATableDescriptionProvider sessionsTableMetaInfo],
                    @"kv": [AMATableDescriptionProvider binaryKVTableMetaInfo],
                };
                [[tableSchemeController should] receive:@selector(initWithTableSchemes:) withArguments:scheme];
                createDatabaseBlock(main);
            });
            
            context(@"Migration manager", ^{
                NSUInteger __block currentSchemeVersion = 0;
                NSArray *__block schemeMigrations = nil;
                NSArray *__block apiKeyMigrations = nil;
                NSArray *__block dataMigrations = nil;
                NSArray *__block libraryMigrations = nil;
                beforeAll(^{
                    [migrationManager stub:migrationManagerInitSelector withBlock:^id(NSArray *params) {
                        currentSchemeVersion = [params[0] unsignedIntegerValue];
                        schemeMigrations = params[1];
                        apiKeyMigrations = params[2];
                        dataMigrations = params[3];
                        libraryMigrations = params[4];
                        return migrationManager;
                    }];
                    createDatabaseBlock(main);
                });
                it(@"Should have valid version", ^{
                    [[theValue(currentSchemeVersion) should] equal:theValue(2)];
                });
                context(@"Scheme migrations", ^{
                    it(@"Should have valid migrations count", ^{
                        [[schemeMigrations should] haveCountOf:1];
                    });
                    it(@"Should have migration to 2", ^{
                        [[schemeMigrations[0] should] beKindOfClass:[AMAReporterDatabaseSchemeMigrationTo2 class]];
                    });
                });
                it(@"Should not have API key migrations", ^{
                    [[apiKeyMigrations should] beEmpty];
                });
                it(@"Should have data migrations", ^{
                    [[dataMigrations[0] should] beKindOfClass:[AMAReporterDataMigrationTo500 class]];
                });
                it(@"Should not have library migrations", ^{
                    [[libraryMigrations should] beEmpty];
                });
            });
            
#if TARGET_OS_TV
            if (main) {
                testValidDataStorageTVOS([@"io.appmetrica." stringByAppendingString:[apiKey stringByAppendingString:@".bak"]],
                                         ^{createDatabaseBlock(NO);});
            }
            else {
                testValidDataStorageTVOS([@"io.appmetrica." stringByAppendingString:[kAMAMainReporterDBPath stringByAppendingString:@".bak"]],
                                         ^{createDatabaseBlock(YES);});
            }
#else
            it(@"Should create valid data storage for iOS", ^{
                NSString *expectedPath = [persistentPathForApiKey stringByAppendingPathComponent:@"data.bak"];
                AMADiskFileStorageOptions expectedOptions =
                AMADiskFileStorageOptionNoBackup | AMADiskFileStorageOptionCreateDirectory;
                [[diskFileStorage should] receive:@selector(initWithPath:options:)
                                    withArguments:expectedPath, theValue(expectedOptions)];
                createDatabaseBlock(main);
            });
            
            it(@"Should create valid backing provider", ^{
                [[JSONDataProvider should] receive:@selector(initWithFileStorage:) withArguments:diskFileStorage];
                createDatabaseBlock(main);
            });
            
            it(@"Should create valid proxy backing provider", ^{
                [[proxyDataProvider should] receive:@selector(initWithUnderlyingDataProvider:)
                                      withArguments:JSONDataProvider];
                createDatabaseBlock(main);
            });
            
            it(@"Should create valid key value storage provider", ^{
                [AMADatabaseObjectProvider stub:@selector(blockForDataBlobs) andReturn:objectProvider];
                [[keyValueStorageProvider should] receive:@selector(initWithTableName:
                                                                    converter:
                                                                    objectProvider:
                                                                    backingKVSDataProvider:)
                                            withArguments:@"kv", binaryConverter, objectProvider, proxyDataProvider];
                createDatabaseBlock(main);
            });
#endif
            
            it(@"Should set key value storage provider database", ^{
                [[keyValueStorageProvider should] receive:@selector(setDatabase:) withArguments:database];
                createDatabaseBlock(main);
            });
            
            it(@"Should fetch path for valid api key", ^{
                NSString *path = main ? kAMAMainReporterDBPath : apiKey;
                [[AMAFileUtility should] receive:@selector(persistentPathForApiKey:) withArguments:path];
                createDatabaseBlock(main);
            });
            
            it(@"Should create valid trim manager", ^{
                [[trimManager should] receive:@selector(initWithApiKey:eventsCleaner:)
                                withArguments:apiKey, eventsCleaner];
                createDatabaseBlock(main);
            });
            
            it(@"Should create database with valid parameters", ^{
                NSString *databasePath = [persistentPathForApiKey stringByAppendingPathComponent:@"data.sqlite"];
                NSArray *criticalKeys = @[];
                [[database should] receive:databaseInitSelector
                             withArguments:tableSchemeController, databasePath, migrationManager,
                 trimManager, keyValueStorageProvider, criticalKeys];
                createDatabaseBlock(main);
            });
            
            it(@"Should return database", ^{
                [[createDatabaseBlock(main) should] equal:database];
            });
        };
        
        context(@"Test reporter database", ^{
            testReporterDatabase(NO, createDatabase);
        });
        
        context(@"Test main reporter database", ^{
            testReporterDatabase(YES, createDatabase);
        });
    });

    context(@"Location database", ^{
        NSObject *(^createDatabase)(void) = ^{
            return (NSObject *)[AMADatabaseFactory locationDatabase];
        };

        it(@"Should create valid table scheme controller", ^{
            NSDictionary *scheme = @{
                @"items": [AMATableDescriptionProvider locationsTableMetaInfo],
                @"visits": [AMATableDescriptionProvider visitsTableMetaInfo],
                @"kv": [AMATableDescriptionProvider stringKVTableMetaInfo],
            };
            KWCaptureSpy *spy = [tableSchemeController captureArgument:@selector(initWithTableSchemes:) atIndex:0];
            createDatabase();
            [[spy.argument should] equal:scheme];
        });

        context(@"Migration manager", ^{
            NSUInteger __block currentSchemeVersion = 0;
            NSArray *__block schemeMigrations = nil;
            NSArray *__block apiKeyMigrations = nil;
            NSArray *__block dataMigrations = nil;
            NSArray *__block libraryMigrations = nil;
            beforeAll(^{
                [migrationManager stub:migrationManagerInitSelector withBlock:^id(NSArray *params) {
                    currentSchemeVersion = [params[0] unsignedIntegerValue];
                    schemeMigrations = params[1];
                    apiKeyMigrations = params[2];
                    dataMigrations = params[3];
                    libraryMigrations = params[4];
                    return migrationManager;
                }];
                createDatabase();
            });
            it(@"Should have valid version", ^{
                [[theValue(currentSchemeVersion) should] equal:theValue(2)];
            });
            context(@"Scheme migrations", ^{
                it(@"Should have valid migrations count", ^{
                    [[schemeMigrations should] haveCountOf:1];
                });
                it(@"Should have migration to 2", ^{
                    [[schemeMigrations[0] should] beKindOfClass:[AMALocationDatabaseSchemeMigrationTo2 class]];
                });
            });
            it(@"Should not have API key migrations", ^{
                [[apiKeyMigrations should] beEmpty];
            });
            it(@"Should have data migrations", ^{
                [[dataMigrations[0] should] beKindOfClass:[AMALocationDataMigrationTo500 class]];
            });
            it(@"Should not have library migrations", ^{
                [[libraryMigrations should] beEmpty];
            });
        });

#if TARGET_OS_TV
        testValidDataStorageTVOS([@"io.appmetrica." stringByAppendingString:@"l_data.bak"],
                                 ^{createDatabase();});
#else
        it(@"Should create valid data storage for iOS", ^{
            NSString *expectedPath = [applicationSupportDirectoryPath stringByAppendingPathComponent:@"l_data.bak"];
            AMADiskFileStorageOptions expectedOptions =
                AMADiskFileStorageOptionNoBackup | AMADiskFileStorageOptionCreateDirectory;
            [[diskFileStorage should] receive:@selector(initWithPath:options:)
                                withArguments:expectedPath, theValue(expectedOptions)];
            createDatabase();
        });

        it(@"Should create valid backing provider", ^{
            [[JSONDataProvider should] receive:@selector(initWithFileStorage:) withArguments:diskFileStorage];
            createDatabase();
        });

        it(@"Should create valid key value storage provider", ^{
            [AMADatabaseObjectProvider stub:@selector(blockForStrings) andReturn:objectProvider];
            [[keyValueStorageProvider should] receive:@selector(initWithTableName:
                                                                converter:
                                                                objectProvider:
                                                                backingKVSDataProvider:)
                                        withArguments:@"kv", stringConverter, objectProvider, JSONDataProvider];
            createDatabase();
        });
#endif

        it(@"Should set key value storage provider database", ^{
            [[keyValueStorageProvider should] receive:@selector(setDatabase:) withArguments:database];
            createDatabase();
        });

        it(@"Should create database with valid parameters", ^{
            NSString *databasePath = [applicationSupportDirectoryPath stringByAppendingPathComponent:@"l_data.sqlite"];
            NSArray *criticalKeys = @[];
            [[database should] receive:databaseInitSelector
                         withArguments:tableSchemeController, databasePath, migrationManager,
                                       nil, keyValueStorageProvider, criticalKeys];
            createDatabase();
        });

        it(@"Should return database", ^{
            [[createDatabase() should] equal:database];
        });
    });

});

SPEC_END
