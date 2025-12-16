
#import <UIKit/UIKit.h>
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import <AppMetricaStorageUtils/AppMetricaStorageUtils.h>
#import "AMAMetricaConfiguration.h"
#import "AMAMetricaInMemoryConfiguration.h"
#import "AMAStartupParametersConfiguration.h"
#import "AMAMetricaPersistentConfiguration.h"
#import "AMAMockDatabase.h"
#import "AMAKeychainBridgeMock.h"
#import "AMAInstantFeaturesConfiguration.h"
#import "AMAReporterTestHelper.h"
#import <AppMetricaKeychain/AppMetricaKeychain.h>
#import "AMAAppGroupIdentifierProvider.h"
@import AppMetricaIdentifiers;

@interface AMAMetricaConfiguration (TestExtension)
- (AMAIdentifierProviderConfiguration*)createIdentifierProviderConfiguration;
- (id<AMAIdentifierProviding>)createIdentifierProvider;
- (NSString *)groupLockPath;
- (id<AMAFileStorage>)groupIdentifiersFileStorage;
@end

SPEC_BEGIN(AMAMetricaConfigurationTests)

describe(@"AMAMetricaConfiguration", ^{
    NSString *const apiKey = [AMAReporterTestHelper defaultApiKey];
    
    AMAMetricaConfiguration *__block configuration = nil;
    id<AMADatabaseProtocol> __block database = nil;
    AMAKeychainBridge *__block keychainBridge = nil;
    AMAAppGroupIdentifierProvider *__block appGroupIdentifierProvider = nil;

    beforeEach(^{
        keychainBridge = [[AMAKeychainBridgeMock alloc] init];
        database = [AMAMockDatabase configurationDatabase];
        appGroupIdentifierProvider = [AMAAppGroupIdentifierProvider nullMock];
        
        configuration =
            [[AMAMetricaConfiguration alloc] initWithKeychainBridge:keychainBridge
                                                            database:database
                                         appGroupIdentifierProvider:appGroupIdentifierProvider];
    });

    it(@"Should add nessesary backup keys", ^{
        database = [AMAMockDatabase configurationDatabase];
        NSSet *__block actualKeys = nil;
        [((NSObject *)database.storageProvider) stub:@selector(addBackingKeys:) withBlock:^id(NSArray *params) {
            actualKeys = [NSSet setWithArray:params[0]];
            return nil;
        }];
        (void)[[AMAMetricaConfiguration alloc] initWithKeychainBridge:nil database:database appGroupIdentifierProvider:[AMAAppGroupIdentifierProvider new]];
        [[actualKeys should] equal:[NSSet setWithArray:@[
            @"fallback-keychain-AMAMetricaPersistentConfigurationDeviceIDStorageKey",
            @"fallback-keychain-AMAMetricaPersistentConfigurationDeviceIDHashStorageKey",
        ]]];
    });
    
	context(@"Default values", ^{
        it(@"Should provide max protobuf message size", ^{
            [[theValue(configuration.inMemory.maxProtobufMsgSize) should] equal:theValue(1024 * 245)];
        });
    });

    context(@"With invalid identifier", ^{
        NSString *invalidIFV = @"invalidIdentifier";

        beforeEach(^{
            [[[UIDevice currentDevice] identifierForVendor] stub:@selector(UUIDString) andReturn:invalidIFV];
        });
        afterEach(^{
            [[[UIDevice currentDevice] identifierForVendor] clearStubs];
        });

        it(@"should return default value in case of invalid ifv", ^{
            [[configuration.persistent.deviceID shouldNot] equal:invalidIFV];
        });
    });

    context(@"Sets metrica started", ^{
        it(@"Should have metrica started initially NO", ^{
            [[theValue(configuration.inMemory.appMetricaStarted) should] beNo];
        });
        it(@"Should set metrica started", ^{
            [configuration.inMemory markAppMetricaStarted];
            [[theValue(configuration.inMemory.appMetricaStarted) should] beYes];
        });
    });
    context(@"Sets metrica impl created", ^{
        it(@"Should have metrica impl created initially NO", ^{
            [[theValue(configuration.inMemory.appMetricaImplCreated) should] beNo];
        });
        it(@"Should set metrica impl created", ^{
            [configuration.inMemory markAppMetricaImplCreated];
            [[theValue(configuration.inMemory.appMetricaImplCreated) should] beYes];
        });
    });
    context(@"Sets first startup update date", ^{
        NSDate *firstUpdateDate = [NSDate date];
        it(@"Should store only first saved date", ^{
            NSDate *nextDate = [firstUpdateDate dateByAddingTimeInterval:60.0 * 60.0];
            configuration.persistent.firstStartupUpdateDate = firstUpdateDate;
            configuration.persistent.firstStartupUpdateDate = nextDate;
            NSDate *savedDate = configuration.persistent.firstStartupUpdateDate;

            NSTimeInterval savedInterval = [savedDate timeIntervalSince1970];
            NSTimeInterval expectedInterval = [firstUpdateDate timeIntervalSince1970];
            [[theValue(savedInterval) should] equal:expectedInterval withDelta:0.1];
        });
    });
    context(@"UUID old storage", ^{
        id __block mockedDatabase = nil;
        beforeEach(^{
            mockedDatabase = [KWMock nullMockForProtocol:@protocol(AMADatabaseProtocol)];
            configuration = [[AMAMetricaConfiguration alloc] initWithKeychainBridge:keychainBridge database:mockedDatabase appGroupIdentifierProvider:[AMAAppGroupIdentifierProvider new]];
        });
        it(@"Should ensure migration", ^{
            [[mockedDatabase should] receive:@selector(ensureMigrated)];
            [configuration UUIDOldStorage];
        });
        it (@"Should return valid storage", ^{
            id storageProvider = [KWMock nullMockForProtocol:@protocol(AMADatabaseProtocol)];
            id cachingStorage = [KWMock nullMockForProtocol:@protocol(AMAKeychainStoring)];
            [mockedDatabase stub:@selector(storageProvider) andReturn:storageProvider];
            [storageProvider stub:@selector(cachingStorage) andReturn:cachingStorage];
            id storage = configuration.UUIDOldStorage;
            [[storage should] equal:cachingStorage];
        });
    });
    context(@"Configuration", ^{
        context(@"Persistent configuration", ^{
                AMAMetricaPersistentConfiguration *__block persistent = [AMAMetricaPersistentConfiguration nullMock];
                AMAMetricaPersistentConfiguration *__block allocedPersistent = [AMAMetricaPersistentConfiguration nullMock];
            
            beforeEach(^{
                [AMAMetricaPersistentConfiguration stub:@selector(alloc) andReturn:allocedPersistent];
                [allocedPersistent stub:@selector(initWithStorage:identifierManager:inMemoryConfiguration:) andReturn:persistent];
            });
            afterEach(^{
                [AMAMetricaPersistentConfiguration clearStubs];
            });
            
            it(@"Should return persistent configuration with valid storage", ^{
                id<AMAKeyValueStoring> storage = database.storageProvider.cachingStorage;
                
                [[allocedPersistent should] receive:@selector(initWithStorage:identifierManager:inMemoryConfiguration:) withArguments:storage, kw_any(), kw_any()];
                
                [[configuration.persistent should] equal:persistent];
            });
            it(@"Should return NO if persistent is nil", ^{
                [[theValue([configuration persistentConfigurationCreated]) should] beNo];
            });
            it(@"Should return YES if persistent is create", ^{
                AMAMetricaPersistentConfiguration *persistentConfiguration = configuration.persistent;
                
                [[theValue([configuration persistentConfigurationCreated]) should] beYes];
            });
        });
        it(@"Should return instant configuration", ^{
            [[configuration.instant should] equal:[AMAInstantFeaturesConfiguration sharedInstance]];
        });
        context(@"Startup configuration", ^{
            AMAStartupParametersConfiguration *__block startup = [AMAStartupParametersConfiguration nullMock];
            AMAStartupParametersConfiguration *__block allocedStartup = [AMAStartupParametersConfiguration nullMock];
            
            beforeEach(^{
                [AMAStartupParametersConfiguration stub:@selector(alloc) andReturn:allocedStartup];
                [allocedStartup stub:@selector(initWithStorage:) andReturn:startup];
            });
            afterEach(^{
                [AMAStartupParametersConfiguration clearStubs];
            });
            
            it(@"Should return startup configuration with storage", ^{
                id<AMAKeyValueStoring> storage = [KWMock nullMockForProtocol:@protocol(AMAKeyValueStoring)];
                [(NSObject *)database.storageProvider stub:@selector(nonPersistentStorageForKeys:error:) andReturn:storage];
                
                [[allocedStartup should] receive:@selector(initWithStorage:) withArguments:storage];
                
                [[configuration.startup should] equal:startup];
            });
            it(@"Should return startup copy configuration with storage", ^{
                id<AMAKeyValueStoring> storage = [KWMock nullMockForProtocol:@protocol(AMAKeyValueStoring)];
                [(NSObject *)database.storageProvider stub:@selector(nonPersistentStorageForStorage:error:) andReturn:storage];
                
                [[allocedStartup should] receive:@selector(initWithStorage:) withArguments:storage];
                
                [[configuration.startupCopy should] equal:startup];
            });
        });
        it(@"Should synchronize startup", ^{
            [[(NSObject *)database.storageProvider should] receive:@selector(saveStorage:error:) withArguments:configuration.startup.storage, kw_any()];
            
            [configuration synchronizeStartup];
        });
        it(@"Should update startup configuration", ^{
            AMAStartupParametersConfiguration *startup = [AMAStartupParametersConfiguration nullMock];
            
            [[configuration.startup shouldNot] equal:startup];
            
            [configuration updateStartupConfiguration:startup];
            
            [[configuration.startup should] equal:startup];
        });
        it(@"Should return database detected inconsistency description", ^{
            NSString *description = @"detectedInconsistencyDescription";
            [(NSObject *)database stub:@selector(detectedInconsistencyDescription) andReturn:description];
            
            [[configuration.detectedInconsistencyDescription should] equal:description];
        });
        it(@"Should reset database inconsistency description", ^{
            [[(NSObject *)database should] receive:@selector(resetDetectedInconsistencyDescription)];
            
            [configuration resetDetectedInconsistencyDescription];
        });
        it(@"Should set app configuration", ^{
            AMAReporterConfiguration *appConfiguration = [[AMAReporterConfiguration alloc] initWithAPIKey:apiKey];
            
            [configuration setAppConfiguration:appConfiguration];
            
            [[configuration.appConfiguration should] equal:appConfiguration];
        });
        it(@"Should return configuration for api key if app configuration set", ^{
            AMAReporterConfiguration *appConfiguration = [[AMAReporterConfiguration alloc] initWithAPIKey:apiKey];
            
            [configuration setAppConfiguration:appConfiguration];
            
            [[[configuration configurationForApiKey:apiKey] should] equal:appConfiguration];
        });
        it(@"Should return configuration for api key if configuration set", ^{
            AMAReporterConfiguration *appConfiguration = [[AMAReporterConfiguration alloc] initWithAPIKey:apiKey];
            
            [configuration setConfiguration:appConfiguration];
            
            [[[configuration configurationForApiKey:apiKey] should] equal:appConfiguration];
        });
        it(@"Should migrate to main apiKey", ^{
            [[(NSObject *)database should] receive:@selector(migrateToMainApiKey:) withArguments:apiKey];
            
            [configuration handleMainApiKey:apiKey];
        });
        it(@"Should ensure migrated", ^{
            [[(NSObject *)database should] receive:@selector(ensureMigrated)];
            
            [configuration ensureMigrated];
        });
        it(@"Should return UUIDOldStorage", ^{
            [[(NSObject *)database should] receive:@selector(ensureMigrated)];
            
            [[(NSObject *)[configuration UUIDOldStorage] should] equal:database.storageProvider.cachingStorage];
        });
    });
    
    context(@"IdentifierProviderConfiguration", ^{
        AMAKeychain *__block privateKeychain;
        AMAKeychain *__block groupKeychain;
        AMADiskFileStorage *__block privateFile;
        AMADiskFileStorage *__block groupFile;
        NSString *const lockFilePath = @"/tmp/file.lock";
        
        beforeEach(^{
            privateKeychain = [[AMAKeychain alloc] initWithService:@"io.appmetrica.private" accessGroup:@"" bridge:keychainBridge];
            groupKeychain = [[AMAKeychain alloc] initWithService:@"io.appmetrica.group" accessGroup:@"" bridge:keychainBridge];
            privateFile = [AMADiskFileStorage nullMock];
            groupFile = [AMADiskFileStorage nullMock];
            
            [configuration stub:@selector(privateKeychain) andReturn:privateKeychain];
            [configuration stub:@selector(groupKeychain) andReturn:groupKeychain];
            [configuration stub:@selector(privateIdentifiersFileStorage) andReturn:privateFile];
            [configuration stub:@selector(groupIdentifiersFileStorage) andReturn:groupFile];
            [configuration stub:@selector(groupLockPath) andReturn:lockFilePath];
        });
        
        afterEach(^{
            [configuration clearStubs];
        });
        
        void(^compareConfig)(AMAIdentifierProviderConfiguration*) = ^(AMAIdentifierProviderConfiguration *config){
            [[(NSObject*)config.privateKeychain should] equal:privateKeychain];
            [[(NSObject*)config.groupKeychain should] equal:groupKeychain];
            [[(NSObject*)config.privateFileStorage should] equal:privateFile];
            [[(NSObject*)config.groupFileStorage should] equal:groupFile];
            [[config.groupLockFilePath should] equal:lockFilePath];
        };
        
        context(@"if app", ^{
            beforeEach(^{
                [AMAPlatformDescription stub:@selector(isExtension) andReturn:theValue(NO)];
            });
            afterEach(^{
                [AMAPlatformDescription clearStubs];
            });
            
            it(@"Should create config", ^{
                AMAIdentifierProviderConfiguration *config = [configuration createIdentifierProviderConfiguration];
                
                compareConfig(config);
            });
        });
        
    });
    
    context(@"IdentifierProvider", ^{
        AMAIdentifierProviderConfiguration *__block config;
        
        beforeEach(^{
            config = [AMAIdentifierProviderConfiguration nullMock];
            [configuration stub:@selector(createIdentifierProviderConfiguration) andReturn:config];
        });
        
        afterEach(^{
            [AMAIdentifierProvider clearStubs];
            [configuration clearStubs];
        });
        
        it(@"should use config", ^{
            id<AMAIdentifierProviding> provider = [configuration createIdentifierProvider];
            [[(NSObject*)provider should] beKindOfClass:[AMAIdentifierProvider class]];
            AMAIdentifierProvider *prov = (AMAIdentifierProvider*)provider;
            
            void *provConfig = (__bridge void *)(prov.config);
            void *expectedConfig = (__bridge void *)config;
            
            [[thePointerValue(provConfig) should] equal:thePointerValue(expectedConfig)];
            
        });
        
        it(@"should get corrent config and run env", ^{
            AMAIdentifierProvider *provider = [AMAIdentifierProvider nullMock];
            [AMAIdentifierProvider stub:@selector(alloc) andReturn:provider];
            [provider stub:@selector(initWithConfig:env:) andReturn:provider];
            [[provider should] receive:@selector(initWithConfig:env:) withArguments:config, theValue([AMAPlatformDescription runEnvronment])];
            
            id<AMAIdentifierProviding> createdProvider = [configuration createIdentifierProvider];
            void *createdProv = (__bridge void *)createdProvider;
            void *expectedProv = (__bridge void *)provider;
            
            [[thePointerValue(createdProv) should] equal:thePointerValue(expectedProv)];
        });
    });
    
    context(@"Paths in AppGroup", ^{
        
        NSString *const appGroupPath = NSTemporaryDirectory();
        NSString *const appGroupName = @"io.appmetrica.appgroup";
        
        afterEach(^{
            [AMAFileUtility clearStubs];
        });
        
        context(@"if AppGroup is set and available", ^{
            beforeEach(^{
                [AMAFileUtility stub:@selector(persistentPathForApplicationGroup:) andReturn:appGroupPath];
                [appGroupIdentifierProvider stub:@selector(appGroupIdentifier) andReturn:appGroupName];
                [AMAFileUtility stub:@selector(createPathIfNeeded:)];
            });
            
            it(@"groupLockPath", ^{
                NSString *const expectedResultPath = [NSString stringWithFormat:@"%@%@", appGroupPath, @"identifiers.lock"];
                
                NSString *const resultPath = [configuration groupLockPath];
                
                [[resultPath should] equal:expectedResultPath];
            });
            
            it(@"groupIdentifierPath", ^{
                NSString *const expectedResultPath = [NSString stringWithFormat:@"%@%@", appGroupPath, @"identifiers.json"];
                
                id<AMAFileStorage> identifiersFile = [configuration groupIdentifiersFileStorage];
                [[identifiersFile.class should] equal:AMADiskFileStorage.class];
                AMADiskFileStorage *diskIdentifiersFile = (AMADiskFileStorage *)identifiersFile;
                [[diskIdentifiersFile.path should] equal:expectedResultPath];
            });
        });
        
        context(@"if AppGroup is set and unavailable", ^{
            beforeEach(^{
                [AMAFileUtility stub:@selector(persistentPathForApplicationGroup:) andReturn:nil];
                [appGroupIdentifierProvider stub:@selector(appGroupIdentifier) andReturn:appGroupName];
                [AMAFileUtility stub:@selector(createPathIfNeeded:)];
            });
            
            it(@"groupLockPath", ^{
                [[configuration groupLockPath] shouldBeNil];
            });
            it(@"groupIdentifierPath", ^{
                [(NSObject *)[configuration groupIdentifiersFileStorage] shouldBeNil];
            });
        });
        
        context(@"if AppGroup is not set", ^{
            beforeEach(^{
                [AMAFileUtility stub:@selector(persistentPathForApplicationGroup:) andReturn:appGroupPath];
                [appGroupIdentifierProvider stub:@selector(appGroupIdentifier) andReturn:nil];
                [AMAFileUtility stub:@selector(createPathIfNeeded:)];
            });
            
            it(@"groupLockPath", ^{
                [[configuration groupLockPath] shouldBeNil];
            });
            it(@"groupIdentifierPath", ^{
                [(NSObject *)[configuration groupIdentifiersFileStorage] shouldBeNil];
            });
        });
    });
    
    
});

SPEC_END
