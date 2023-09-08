
#import <UIKit/UIKit.h>
#import <Kiwi/Kiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMAMetricaConfiguration.h"
#import "AMAMetricaInMemoryConfiguration.h"
#import "AMAStartupParametersConfiguration.h"
#import "AMAMetricaPersistentConfiguration.h"
#import "AMAMockDatabase.h"
#import "AMAKeychainBridgeMock.h"
#import "AMAKeychainStoring.h"
#import "AMAInstantFeaturesConfiguration.h"
#import "AMAReporterTestHelper.h"

SPEC_BEGIN(AMAMetricaConfigurationTests)

describe(@"AMAMetricaConfiguration", ^{
    NSString *const apiKey = [AMAReporterTestHelper defaultApiKey];
    
    AMAMetricaConfiguration *__block configuration = nil;
    id<AMADatabaseProtocol> __block database = nil;
    AMAKeychainBridge *__block keychainBridge = nil;

    beforeEach(^{
        keychainBridge = [[AMAKeychainBridgeMock alloc] init];
        database = [AMAMockDatabase configurationDatabase];
        configuration = [[AMAMetricaConfiguration alloc] initWithKeychainBridge:keychainBridge database:database];
    });

    it(@"Should add nessesary backup keys", ^{
        database = [AMAMockDatabase configurationDatabase];
        NSSet *__block actualKeys = nil;
        [((NSObject *)database.storageProvider) stub:@selector(addBackingKeys:) withBlock:^id(NSArray *params) {
            actualKeys = [NSSet setWithArray:params[0]];
            return nil;
        }];
        (void)[[AMAMetricaConfiguration alloc] initWithKeychainBridge:nil database:database];
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

    context(@"with invalid identifier", ^{
        NSString *invalidIFV = @"invalidIdentifier";

        beforeEach(^{
            [[[UIDevice currentDevice] identifierForVendor] stub:@selector(UUIDString) andReturn:invalidIFV];
        });

        it(@"should return default value in case of invalid ifv", ^{
            [[configuration.persistent.deviceID shouldNot] equal:invalidIFV];
        });
    });

    context(@"Sets metrica started", ^{
        it(@"Should have metrica started initially NO", ^{
            [[theValue(configuration.inMemory.metricaStarted) should] beNo];
        });
        it(@"Should set metrica started", ^{
            [configuration.inMemory markMetricaStarted];
            [[theValue(configuration.inMemory.metricaStarted) should] beYes];
        });
    });
    context(@"Sets metrica impl created", ^{
        it(@"Should have metrica impl created initially NO", ^{
            [[theValue(configuration.inMemory.metricaImplCreated) should] beNo];
        });
        it(@"Should set metrica impl created", ^{
            [configuration.inMemory markMetricaImplCreated];
            [[theValue(configuration.inMemory.metricaImplCreated) should] beYes];
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
            configuration = [[AMAMetricaConfiguration alloc] initWithKeychainBridge:keychainBridge database:mockedDatabase];
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
                [allocedPersistent stub:@selector(initWithStorage:keychain:inMemoryConfiguration:) andReturn:persistent];
            });
            it(@"Should return persistent configuration with valid storage", ^{
                id<AMAKeyValueStoring> storage = database.storageProvider.cachingStorage;
                
                [[allocedPersistent should] receive:@selector(initWithStorage:keychain:inMemoryConfiguration:) withArguments:storage, kw_any(), kw_any()];
                
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
            AMAReporterConfiguration *appConfiguration = [[AMAReporterConfiguration alloc] initWithApiKey:apiKey];
            
            [configuration setAppConfiguration:appConfiguration];
            
            [[configuration.appConfiguration should] equal:appConfiguration];
        });
        it(@"Should return configuration for api key if app configuration set", ^{
            AMAReporterConfiguration *appConfiguration = [[AMAReporterConfiguration alloc] initWithApiKey:apiKey];
            
            [configuration setAppConfiguration:appConfiguration];
            
            [[[configuration configurationForApiKey:apiKey] should] equal:appConfiguration];
        });
        it(@"Should return configuration for api key if configuration set", ^{
            AMAReporterConfiguration *appConfiguration = [[AMAReporterConfiguration alloc] initWithApiKey:apiKey];
            
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
});

SPEC_END
