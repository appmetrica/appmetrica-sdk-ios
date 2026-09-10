#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMASavedAppMetricaConfigRepository.h"
#import "AMASavedAppMetricaConfigTtlChecker.h"
#import "AMAMetricaPersistentConfiguration.h"
#import "AMAAppMetricaConfiguration.h"
#import "AMAAppMetricaConfigurationSnapshot.h"

SPEC_BEGIN(AMASavedAppMetricaConfigRepositoryTests)

describe(@"AMASavedAppMetricaConfigRepository", ^{

    AMAMetricaPersistentConfiguration *__block persistent = nil;
    AMADateProviderMock *__block dateProvider = nil;
    AMASavedAppMetricaConfigRepository *__block repository = nil;
    AMAAppMetricaConfiguration *__block configuration = nil;
    NSDate *__block now = nil;

    beforeEach(^{
        persistent = [AMAMetricaPersistentConfiguration nullMock];
        dateProvider = [[AMADateProviderMock alloc] init];
        now = [NSDate dateWithTimeIntervalSince1970:1700000000.0];
        [dateProvider freezeWithDate:now];
        configuration = [[AMAAppMetricaConfiguration alloc] initWithAPIKey:@"550e8400-e29b-41d4-a716-446655440000"];
        repository = [[AMASavedAppMetricaConfigRepository alloc] initWithPersistentConfiguration:persistent
                                                                                    dateProvider:dateProvider];
    });

    it(@"Should return nil when config is absent", ^{
        [persistent stub:@selector(appMetricaClientConfigurationSnapshot) andReturn:nil];
        [[persistent shouldNot] receive:@selector(clearAppMetricaClientConfigurationSnapshot:)];

        [[[repository validSavedConfig] should] beNil];
    });

    it(@"Should lazy-migrate missing timestamp into the same snapshot", ^{
        AMAAppMetricaConfigurationSnapshot *snapshot =
            [[AMAAppMetricaConfigurationSnapshot alloc] initWithConfiguration:configuration
                                                                      savedAt:nil
                                                                       source:AMAAppMetricaConfigurationSnapshotSourceGroup];
        [persistent stub:@selector(appMetricaClientConfigurationSnapshot) andReturn:snapshot];
        [[persistent should] receive:@selector(saveAppMetricaClientConfigurationSnapshot:) withArguments:kw_any()];
        [[persistent shouldNot] receive:@selector(clearAppMetricaClientConfigurationSnapshot:)];

        [[[repository validSavedConfig] should] equal:configuration];
    });

    it(@"Should return valid config within TTL", ^{
        NSDate *savedAt = [now dateByAddingTimeInterval:-10.0 * 24.0 * 60.0 * 60.0];
        AMAAppMetricaConfigurationSnapshot *snapshot =
            [[AMAAppMetricaConfigurationSnapshot alloc] initWithConfiguration:configuration
                                                                      savedAt:savedAt
                                                                       source:AMAAppMetricaConfigurationSnapshotSourcePrivate];
        [persistent stub:@selector(appMetricaClientConfigurationSnapshot) andReturn:snapshot];
        [[persistent shouldNot] receive:@selector(clearAppMetricaClientConfigurationSnapshot:)];
        [[persistent shouldNot] receive:@selector(saveAppMetricaClientConfigurationSnapshot:)];

        [[[repository validSavedConfig] should] equal:configuration];
    });

    it(@"Should keep config when clock skews backwards", ^{
        NSDate *savedAt = [now dateByAddingTimeInterval:1.0];
        AMAAppMetricaConfigurationSnapshot *snapshot =
            [[AMAAppMetricaConfigurationSnapshot alloc] initWithConfiguration:configuration
                                                                      savedAt:savedAt
                                                                       source:AMAAppMetricaConfigurationSnapshotSourcePrivate];
        [persistent stub:@selector(appMetricaClientConfigurationSnapshot) andReturn:snapshot];
        [[persistent shouldNot] receive:@selector(clearAppMetricaClientConfigurationSnapshot:)];

        [[[repository validSavedConfig] should] equal:configuration];
    });

    it(@"Should clear expired config for the snapshot source", ^{
        NSDate *savedAt = [now dateByAddingTimeInterval:-AMASavedAppMetricaConfigTtlChecker.savedAppMetricaConfigTTL];
        AMAAppMetricaConfigurationSnapshot *snapshot =
            [[AMAAppMetricaConfigurationSnapshot alloc] initWithConfiguration:configuration
                                                                      savedAt:savedAt
                                                                       source:AMAAppMetricaConfigurationSnapshotSourceGroup];
        [persistent stub:@selector(appMetricaClientConfigurationSnapshot) andReturn:snapshot];
        [[persistent should] receive:@selector(clearAppMetricaClientConfigurationSnapshot:) withArguments:snapshot];

        [[[repository validSavedConfig] should] beNil];
    });

    it(@"Should save configuration and refresh TTL", ^{
        AMAAppMetricaConfigurationSnapshot *current =
            [[AMAAppMetricaConfigurationSnapshot alloc] initWithConfiguration:configuration
                                                                      savedAt:[now dateByAddingTimeInterval:-10]
                                                                       source:AMAAppMetricaConfigurationSnapshotSourcePrivate];
        [persistent stub:@selector(appMetricaClientConfigurationSnapshot) andReturn:current];
        [[persistent should] receive:@selector(saveAppMetricaClientConfigurationSnapshot:) withArguments:kw_any()];

        [repository saveConfiguration:configuration refreshTTL:YES];
    });

    it(@"Should save configuration without refreshing TTL", ^{
        NSDate *savedAt = [now dateByAddingTimeInterval:-10];
        AMAAppMetricaConfigurationSnapshot *current =
            [[AMAAppMetricaConfigurationSnapshot alloc] initWithConfiguration:configuration
                                                                      savedAt:savedAt
                                                                       source:AMAAppMetricaConfigurationSnapshotSourcePrivate];
        [persistent stub:@selector(appMetricaClientConfigurationSnapshot) andReturn:current];
        KWCaptureSpy *spy = [persistent captureArgument:@selector(saveAppMetricaClientConfigurationSnapshot:) atIndex:0];

        [repository saveConfiguration:configuration refreshTTL:NO];

        AMAAppMetricaConfigurationSnapshot *saved = spy.argument;
        [[saved.savedAt should] equal:savedAt];
        [[saved.configuration should] equal:configuration];
    });

});

SPEC_END
