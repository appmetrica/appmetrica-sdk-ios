#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import <AppMetricaPlatform/AppMetricaPlatform.h>
#import "AMASavedAppMetricaConfigRepository.h"
#import "AMASavedAppMetricaConfigTtlChecker.h"
#import "AMAMetricaPersistentConfiguration.h"
#import "AMAMetricaInMemoryConfiguration.h"
#import "AMAAppMetricaConfiguration.h"
#import "AMAAppMetricaConfigurationSnapshot.h"
#import "AMAAppMetricaConfigurationFileStorage.h"
#import "AMAAppMetricaConfigurationStorageCoordinator.h"

SPEC_BEGIN(AMASavedAppMetricaConfigRepositoryAppGroupTests)

describe(@"AMASavedAppMetricaConfigRepository App Group TTL", ^{

    NSString *const apiKeyV1 = @"550e8400-e29b-41d4-a716-446655440000";
    NSString *const apiKeyV2 = @"ac3b4427-dc2e-4b1e-adb7-7fbc0c34821f";

    AMADateProviderMock *__block dateProvider = nil;
    AMAStorageMock *__block sharedGroupBackend = nil;
    AMAManualCurrentQueueExecutor *__block groupExecutor = nil;
    AMAManualCurrentQueueExecutor *__block mainPrivateExecutor = nil;
    AMAManualCurrentQueueExecutor *__block extensionPrivateExecutor = nil;

    AMAAppMetricaConfigurationFileStorage *__block mainPrivateStorage = nil;
    AMAAppMetricaConfigurationFileStorage *__block extensionPrivateStorage = nil;
    AMAAppMetricaConfigurationFileStorage *__block mainGroupStorage = nil;
    AMAAppMetricaConfigurationFileStorage *__block extensionGroupStorage = nil;

    AMAAppMetricaConfigurationStorageCoordinator *__block mainCoordinator = nil;
    AMAAppMetricaConfigurationStorageCoordinator *__block extensionCoordinator = nil;

    AMAKeyValueStorageMock *__block mainKV = nil;
    AMAKeyValueStorageMock *__block extensionKV = nil;
    AMAMetricaInMemoryConfiguration *__block inMemory = nil;

    AMAMetricaPersistentConfiguration *__block mainPersistent = nil;
    AMAMetricaPersistentConfiguration *__block extensionPersistent = nil;
    AMASavedAppMetricaConfigRepository *__block extensionRepository = nil;

    NSDate *__block day0 = nil;

    void (^flushExecutors)(void) = ^{
        [mainPrivateExecutor execute];
        [extensionPrivateExecutor execute];
        [groupExecutor execute];
    };

    beforeEach(^{
        day0 = [NSDate dateWithTimeIntervalSince1970:1700000000.0];
        dateProvider = [[AMADateProviderMock alloc] init];
        [dateProvider freezeWithDate:day0];

        sharedGroupBackend = [AMAStorageMock new];
        groupExecutor = [AMAManualCurrentQueueExecutor new];
        mainPrivateExecutor = [AMAManualCurrentQueueExecutor new];
        extensionPrivateExecutor = [AMAManualCurrentQueueExecutor new];

        mainPrivateStorage = [[AMAAppMetricaConfigurationFileStorage alloc]
                              initWithFileStorage:[AMAStorageMock new]
                              executor:mainPrivateExecutor];
        extensionPrivateStorage = [[AMAAppMetricaConfigurationFileStorage alloc]
                                   initWithFileStorage:[AMAStorageMock new]
                                   executor:extensionPrivateExecutor];
        mainGroupStorage = [[AMAAppMetricaConfigurationFileStorage alloc]
                            initWithFileStorage:sharedGroupBackend
                            executor:groupExecutor];
        extensionGroupStorage = [[AMAAppMetricaConfigurationFileStorage alloc]
                                 initWithFileStorage:sharedGroupBackend
                                 executor:groupExecutor];

        mainCoordinator = [[AMAAppMetricaConfigurationStorageCoordinator alloc]
                           initWithPrivateStorage:mainPrivateStorage
                           groupStorage:mainGroupStorage];
        extensionCoordinator = [[AMAAppMetricaConfigurationStorageCoordinator alloc]
                                initWithPrivateStorage:extensionPrivateStorage
                                groupStorage:extensionGroupStorage];

        mainKV = [AMAKeyValueStorageMock new];
        extensionKV = [AMAKeyValueStorageMock new];
        inMemory = [AMAMetricaInMemoryConfiguration nullMock];

        mainPersistent = [[AMAMetricaPersistentConfiguration alloc] initWithStorage:mainKV
                                                              inMemoryConfiguration:inMemory
                                                     appMetricaConfigurationStorage:mainCoordinator];
        extensionPersistent = [[AMAMetricaPersistentConfiguration alloc] initWithStorage:extensionKV
                                                                   inMemoryConfiguration:inMemory
                                                          appMetricaConfigurationStorage:extensionCoordinator];
        extensionRepository = [[AMASavedAppMetricaConfigRepository alloc]
                               initWithPersistentConfiguration:extensionPersistent
                               dateProvider:dateProvider];
    });

    afterEach(^{
        [AMAPlatformDescription clearStubs];
    });

    it(@"shouldNotDeleteRefreshedGroupConfigUsingExtensionLocalTimestamp", ^{
        [AMAPlatformDescription stub:@selector(runEnvronment) andReturn:theValue(AMARunEnvironmentMainApp)];

        AMAAppMetricaConfiguration *v1 = [[AMAAppMetricaConfiguration alloc] initWithAPIKey:apiKeyV1];
        [mainPersistent saveAppMetricaClientConfigurationSnapshot:
            [[AMAAppMetricaConfigurationSnapshot alloc] initWithConfiguration:v1
                                                                      savedAt:day0
                                                                       source:AMAAppMetricaConfigurationSnapshotSourcePrivate]];
        flushExecutors();

        [AMAPlatformDescription stub:@selector(runEnvronment) andReturn:theValue(AMARunEnvironmentExtension)];
        AMAAppMetricaConfiguration *extensionDay0 = [extensionRepository validSavedConfig];
        flushExecutors();
        [[extensionDay0.APIKey should] equal:apiKeyV1];

        [AMAPlatformDescription stub:@selector(runEnvronment) andReturn:theValue(AMARunEnvironmentMainApp)];
        NSDate *day20 = [day0 dateByAddingTimeInterval:20.0 * 24.0 * 60.0 * 60.0];
        [dateProvider freezeWithDate:day20];
        AMAAppMetricaConfiguration *v2 = [[AMAAppMetricaConfiguration alloc] initWithAPIKey:apiKeyV2];
        v2.customHosts = @[ @"https://example.test" ];
        [mainPersistent saveAppMetricaClientConfigurationSnapshot:
            [[AMAAppMetricaConfigurationSnapshot alloc] initWithConfiguration:v2
                                                                      savedAt:day20
                                                                       source:AMAAppMetricaConfigurationSnapshotSourcePrivate]];
        flushExecutors();

        // Cold start extension: recreate file storages keeping backends.
        extensionPrivateStorage = [[AMAAppMetricaConfigurationFileStorage alloc]
                                   initWithFileStorage:extensionPrivateStorage.fileStorage
                                   executor:extensionPrivateExecutor];
        extensionGroupStorage = [[AMAAppMetricaConfigurationFileStorage alloc]
                                 initWithFileStorage:sharedGroupBackend
                                 executor:groupExecutor];
        extensionCoordinator = [[AMAAppMetricaConfigurationStorageCoordinator alloc]
                                initWithPrivateStorage:extensionPrivateStorage
                                groupStorage:extensionGroupStorage];
        extensionPersistent = [[AMAMetricaPersistentConfiguration alloc] initWithStorage:extensionKV
                                                                   inMemoryConfiguration:inMemory
                                                          appMetricaConfigurationStorage:extensionCoordinator];
        extensionRepository = [[AMASavedAppMetricaConfigRepository alloc]
                               initWithPersistentConfiguration:extensionPersistent
                               dateProvider:dateProvider];

        [AMAPlatformDescription stub:@selector(runEnvronment) andReturn:theValue(AMARunEnvironmentExtension)];
        NSDate *day31 = [day0 dateByAddingTimeInterval:31.0 * 24.0 * 60.0 * 60.0];
        [dateProvider freezeWithDate:day31];

        AMAAppMetricaConfiguration *extensionDay31 = [extensionRepository validSavedConfig];
        flushExecutors();

        [[extensionDay31.APIKey should] equal:apiKeyV2];
        [[extensionDay31.customHosts should] equal:@[ @"https://example.test" ]];

        AMAAppMetricaConfigurationFileStorage *freshGroupReader =
            [[AMAAppMetricaConfigurationFileStorage alloc] initWithFileStorage:sharedGroupBackend
                                                                      executor:groupExecutor];
        [[[freshGroupReader loadSnapshot].configuration.APIKey should] equal:apiKeyV2];
    });

});

SPEC_END
