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
#import "AMAImmediateExclusiveLock.h"

@import AppMetricaSynchronization;

SPEC_BEGIN(AMASavedAppMetricaConfigRepositoryAppGroupTests)

describe(@"AMASavedAppMetricaConfigRepository App Group TTL", ^{

    NSString *const apiKeyV1 = @"550e8400-e29b-41d4-a716-446655440000";
    NSString *const apiKeyV2 = @"ac3b4427-dc2e-4b1e-adb7-7fbc0c34821f";

    AMADateProviderMock *__block dateProvider = nil;
    AMAStorageMock *__block sharedGroupBackend = nil;

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

    beforeEach(^{
        day0 = [NSDate dateWithTimeIntervalSince1970:1700000000.0];
        dateProvider = [[AMADateProviderMock alloc] init];
        [dateProvider freezeWithDate:day0];

        sharedGroupBackend = [AMAStorageMock new];

        mainPrivateStorage = [[AMAAppMetricaConfigurationFileStorage alloc]
                              initWithFileStorage:[AMAStorageMock new]];
        extensionPrivateStorage = [[AMAAppMetricaConfigurationFileStorage alloc]
                                   initWithFileStorage:[AMAStorageMock new]];
        mainGroupStorage = [[AMAAppMetricaConfigurationFileStorage alloc]
                            initWithFileStorage:sharedGroupBackend];
        extensionGroupStorage = [[AMAAppMetricaConfigurationFileStorage alloc]
                                 initWithFileStorage:sharedGroupBackend];

        mainCoordinator = [[AMAAppMetricaConfigurationStorageCoordinator alloc]
                           initWithPrivateStorage:mainPrivateStorage
                                     groupStorage:mainGroupStorage
                                             lock:[AMAImmediateExclusiveLock new]];
        extensionCoordinator = [[AMAAppMetricaConfigurationStorageCoordinator alloc]
                                initWithPrivateStorage:extensionPrivateStorage
                                          groupStorage:extensionGroupStorage
                                                  lock:[AMAImmediateExclusiveLock new]];

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

        [AMAPlatformDescription stub:@selector(runEnvronment) andReturn:theValue(AMARunEnvironmentExtension)];
        AMAAppMetricaConfiguration *extensionDay0 = [extensionRepository validSavedConfigDidUpdate:NULL];
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

        // Cold start extension: recreate file storages keeping backends.
        extensionPrivateStorage = [[AMAAppMetricaConfigurationFileStorage alloc]
                                   initWithFileStorage:extensionPrivateStorage.fileStorage];
        extensionGroupStorage = [[AMAAppMetricaConfigurationFileStorage alloc]
                                 initWithFileStorage:sharedGroupBackend];
        extensionCoordinator = [[AMAAppMetricaConfigurationStorageCoordinator alloc]
                                initWithPrivateStorage:extensionPrivateStorage
                                          groupStorage:extensionGroupStorage
                                                  lock:[AMAImmediateExclusiveLock new]];
        extensionPersistent = [[AMAMetricaPersistentConfiguration alloc] initWithStorage:extensionKV
                                                                   inMemoryConfiguration:inMemory
                                                          appMetricaConfigurationStorage:extensionCoordinator];
        extensionRepository = [[AMASavedAppMetricaConfigRepository alloc]
                               initWithPersistentConfiguration:extensionPersistent
                               dateProvider:dateProvider];

        [AMAPlatformDescription stub:@selector(runEnvronment) andReturn:theValue(AMARunEnvironmentExtension)];
        NSDate *day31 = [day0 dateByAddingTimeInterval:31.0 * 24.0 * 60.0 * 60.0];
        [dateProvider freezeWithDate:day31];

        AMAAppMetricaConfiguration *extensionDay31 = [extensionRepository validSavedConfigDidUpdate:NULL];

        [[extensionDay31.APIKey should] equal:apiKeyV2];
        [[extensionDay31.customHosts should] equal:@[ @"https://example.test" ]];

        AMAAppMetricaConfigurationFileStorage *freshGroupReader =
            [[AMAAppMetricaConfigurationFileStorage alloc] initWithFileStorage:sharedGroupBackend];
        [[[freshGroupReader loadSnapshot].configuration.APIKey should] equal:apiKeyV2];
    });

    it(@"shouldWaitForExclusiveLockBeforeSavingWhileExtensionUpdatesExpiredConfig", ^{
        NSString *lockPath = [NSTemporaryDirectory() stringByAppendingPathComponent:
                              [NSString stringWithFormat:@"ama-config-race-%@.lock", NSUUID.UUID.UUIDString]];
        AMAFileLockExecutor *mainLock = [[AMAFileLockExecutor alloc] initWithFilePath:lockPath];
        AMAFileLockExecutor *extensionLock = [[AMAFileLockExecutor alloc] initWithFilePath:lockPath];

        mainCoordinator = [[AMAAppMetricaConfigurationStorageCoordinator alloc]
                           initWithPrivateStorage:mainPrivateStorage
                                     groupStorage:mainGroupStorage
                                             lock:mainLock];
        extensionCoordinator = [[AMAAppMetricaConfigurationStorageCoordinator alloc]
                                initWithPrivateStorage:extensionPrivateStorage
                                          groupStorage:extensionGroupStorage
                                                  lock:extensionLock];
        mainPersistent = [[AMAMetricaPersistentConfiguration alloc] initWithStorage:mainKV
                                                              inMemoryConfiguration:inMemory
                                                     appMetricaConfigurationStorage:mainCoordinator];
        extensionPersistent = [[AMAMetricaPersistentConfiguration alloc] initWithStorage:extensionKV
                                                                   inMemoryConfiguration:inMemory
                                                          appMetricaConfigurationStorage:extensionCoordinator];
        extensionRepository = [[AMASavedAppMetricaConfigRepository alloc]
                               initWithPersistentConfiguration:extensionPersistent
                               dateProvider:dateProvider];

        [AMAPlatformDescription stub:@selector(runEnvronment) andReturn:theValue(AMARunEnvironmentMainApp)];
        AMAAppMetricaConfiguration *v1 = [[AMAAppMetricaConfiguration alloc] initWithAPIKey:apiKeyV1];
        [mainPersistent saveAppMetricaClientConfigurationSnapshot:
            [[AMAAppMetricaConfigurationSnapshot alloc] initWithConfiguration:v1
                                                                      savedAt:day0
                                                                       source:AMAAppMetricaConfigurationSnapshotSourcePrivate]];

        NSDate *day31 = [day0 dateByAddingTimeInterval:31.0 * 24.0 * 60.0 * 60.0];
        [dateProvider freezeWithDate:day31];

        dispatch_semaphore_t enteredDate = dispatch_semaphore_create(0);
        dispatch_semaphore_t resumeDate = dispatch_semaphore_create(0);
        [dateProvider stub:@selector(currentDate) withBlock:^id(NSArray *params) {
            dispatch_semaphore_signal(enteredDate);
            dispatch_semaphore_wait(resumeDate, DISPATCH_TIME_FOREVER);
            return day31;
        }];

        __block AMAAppMetricaConfiguration *extensionResult = (id)[NSNull null];
        dispatch_semaphore_t extensionDone = dispatch_semaphore_create(0);
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
            [AMAPlatformDescription stub:@selector(runEnvronment) andReturn:theValue(AMARunEnvironmentExtension)];
            extensionResult = [extensionRepository validSavedConfigDidUpdate:NULL];
            dispatch_semaphore_signal(extensionDone);
        });

        [[theValue(dispatch_semaphore_wait(enteredDate, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)))) should] equal:theValue(0)];

        AMAAppMetricaConfiguration *v2 = [[AMAAppMetricaConfiguration alloc] initWithAPIKey:apiKeyV2];
        dispatch_semaphore_t saveDone = dispatch_semaphore_create(0);
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
            [AMAPlatformDescription stub:@selector(runEnvronment) andReturn:theValue(AMARunEnvironmentMainApp)];
            [mainPersistent saveAppMetricaClientConfigurationSnapshot:
                [[AMAAppMetricaConfigurationSnapshot alloc] initWithConfiguration:v2
                                                                          savedAt:day31
                                                                           source:AMAAppMetricaConfigurationSnapshotSourcePrivate]];
            dispatch_semaphore_signal(saveDone);
        });

        // Give the save a chance to race; it must block on flock until resume.
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];
        // Non-zero = still blocked (historically 1; modern Darwin returns KERN_OPERATION_TIMED_OUT / 49).
        [[theValue(dispatch_semaphore_wait(saveDone, DISPATCH_TIME_NOW)) shouldNot] equal:theValue(0)];

        dispatch_semaphore_signal(resumeDate);
        [[theValue(dispatch_semaphore_wait(extensionDone, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)))) should] equal:theValue(0)];
        [[theValue(dispatch_semaphore_wait(saveDone, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)))) should] equal:theValue(0)];

        [[extensionResult should] beNil];
        AMAAppMetricaConfigurationFileStorage *freshGroupReader =
            [[AMAAppMetricaConfigurationFileStorage alloc] initWithFileStorage:sharedGroupBackend];
        [[[freshGroupReader loadSnapshot].configuration.APIKey should] equal:apiKeyV2];
        [[NSFileManager defaultManager] removeItemAtPath:lockPath error:nil];
    });

    it(@"shouldNotOverwriteConcurrentSaveWithLazyTimestampMigration", ^{
        NSString *lockPath = [NSTemporaryDirectory() stringByAppendingPathComponent:
                              [NSString stringWithFormat:@"ama-config-lazy-%@.lock", NSUUID.UUID.UUIDString]];
        AMAFileLockExecutor *mainLock = [[AMAFileLockExecutor alloc] initWithFilePath:lockPath];
        AMAFileLockExecutor *extensionLock = [[AMAFileLockExecutor alloc] initWithFilePath:lockPath];

        mainCoordinator = [[AMAAppMetricaConfigurationStorageCoordinator alloc]
                           initWithPrivateStorage:mainPrivateStorage
                                     groupStorage:mainGroupStorage
                                             lock:mainLock];
        extensionCoordinator = [[AMAAppMetricaConfigurationStorageCoordinator alloc]
                                initWithPrivateStorage:extensionPrivateStorage
                                          groupStorage:extensionGroupStorage
                                                  lock:extensionLock];
        mainPersistent = [[AMAMetricaPersistentConfiguration alloc] initWithStorage:mainKV
                                                              inMemoryConfiguration:inMemory
                                                     appMetricaConfigurationStorage:mainCoordinator];
        extensionPersistent = [[AMAMetricaPersistentConfiguration alloc] initWithStorage:extensionKV
                                                                   inMemoryConfiguration:inMemory
                                                          appMetricaConfigurationStorage:extensionCoordinator];
        extensionRepository = [[AMASavedAppMetricaConfigRepository alloc]
                               initWithPersistentConfiguration:extensionPersistent
                               dateProvider:dateProvider];

        [AMAPlatformDescription stub:@selector(runEnvronment) andReturn:theValue(AMARunEnvironmentMainApp)];
        AMAAppMetricaConfiguration *v1 = [[AMAAppMetricaConfiguration alloc] initWithAPIKey:apiKeyV1];
        [mainPersistent saveAppMetricaClientConfigurationSnapshot:
            [[AMAAppMetricaConfigurationSnapshot alloc] initWithConfiguration:v1
                                                                      savedAt:nil
                                                                       source:AMAAppMetricaConfigurationSnapshotSourcePrivate]];

        dispatch_semaphore_t enteredDate = dispatch_semaphore_create(0);
        dispatch_semaphore_t resumeDate = dispatch_semaphore_create(0);
        [dateProvider stub:@selector(currentDate) withBlock:^id(NSArray *params) {
            dispatch_semaphore_signal(enteredDate);
            dispatch_semaphore_wait(resumeDate, DISPATCH_TIME_FOREVER);
            return day0;
        }];

        __block AMAAppMetricaConfiguration *extensionResult = nil;
        dispatch_semaphore_t extensionDone = dispatch_semaphore_create(0);
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
            [AMAPlatformDescription stub:@selector(runEnvronment) andReturn:theValue(AMARunEnvironmentExtension)];
            extensionResult = [extensionRepository validSavedConfigDidUpdate:NULL];
            dispatch_semaphore_signal(extensionDone);
        });

        [[theValue(dispatch_semaphore_wait(enteredDate, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)))) should] equal:theValue(0)];

        NSDate *day20 = [day0 dateByAddingTimeInterval:20.0 * 24.0 * 60.0 * 60.0];
        AMAAppMetricaConfiguration *v2 = [[AMAAppMetricaConfiguration alloc] initWithAPIKey:apiKeyV2];
        dispatch_semaphore_t saveDone = dispatch_semaphore_create(0);
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
            [AMAPlatformDescription stub:@selector(runEnvronment) andReturn:theValue(AMARunEnvironmentMainApp)];
            [mainPersistent saveAppMetricaClientConfigurationSnapshot:
                [[AMAAppMetricaConfigurationSnapshot alloc] initWithConfiguration:v2
                                                                          savedAt:day20
                                                                           source:AMAAppMetricaConfigurationSnapshotSourcePrivate]];
            dispatch_semaphore_signal(saveDone);
        });

        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];
        [[theValue(dispatch_semaphore_wait(saveDone, DISPATCH_TIME_NOW)) shouldNot] equal:theValue(0)];

        dispatch_semaphore_signal(resumeDate);
        [[theValue(dispatch_semaphore_wait(extensionDone, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)))) should] equal:theValue(0)];
        [[theValue(dispatch_semaphore_wait(saveDone, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)))) should] equal:theValue(0)];

        [[extensionResult.APIKey should] equal:apiKeyV1];
        AMAAppMetricaConfigurationFileStorage *freshGroupReader =
            [[AMAAppMetricaConfigurationFileStorage alloc] initWithFileStorage:sharedGroupBackend];
        [[[freshGroupReader loadSnapshot].configuration.APIKey should] equal:apiKeyV2];
        [[NSFileManager defaultManager] removeItemAtPath:lockPath error:nil];
    });

});

SPEC_END
