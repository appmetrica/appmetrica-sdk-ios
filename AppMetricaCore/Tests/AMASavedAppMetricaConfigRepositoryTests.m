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

    void (^stubUpdateWithCurrent)(AMAAppMetricaConfigurationSnapshot *, BOOL) =
        ^(AMAAppMetricaConfigurationSnapshot *current, BOOL didUpdate) {
            [persistent stub:@selector(updateAppMetricaClientConfigurationSnapshot:result:)
                   withBlock:^id(NSArray *params) {
                AMAConfigurationSnapshotUpdate update = params[0];
                AMAAppMetricaConfigurationSnapshot *updated = nil;
                if (current != nil) {
                    updated = update(current);
                }
                [AMATestUtilities fillObjectPointerParameter:params[1] withValue:updated];
                return theValue(didUpdate);
            }];
        };

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
        stubUpdateWithCurrent(nil, YES);
        BOOL didUpdate = NO;
        [[[repository validSavedConfigDidUpdate:&didUpdate] should] beNil];
        [[theValue(didUpdate) should] beYes];
    });

    it(@"Should report didUpdate NO when lock update fails", ^{
        stubUpdateWithCurrent(nil, NO);
        BOOL didUpdate = YES;
        [[[repository validSavedConfigDidUpdate:&didUpdate] should] beNil];
        [[theValue(didUpdate) should] beNo];
    });

    it(@"Should lazy-migrate missing timestamp into the same snapshot", ^{
        AMAAppMetricaConfigurationSnapshot *snapshot =
            [[AMAAppMetricaConfigurationSnapshot alloc] initWithConfiguration:configuration
                                                                      savedAt:nil
                                                                       source:AMAAppMetricaConfigurationSnapshotSourceGroup];
        __block AMAAppMetricaConfigurationSnapshot *updatedSnapshot = nil;
        [persistent stub:@selector(updateAppMetricaClientConfigurationSnapshot:result:)
               withBlock:^id(NSArray *params) {
            AMAConfigurationSnapshotUpdate update = params[0];
            updatedSnapshot = update(snapshot);
            [AMATestUtilities fillObjectPointerParameter:params[1] withValue:updatedSnapshot];
            return theValue(YES);
        }];

        BOOL didUpdate = NO;
        [[[repository validSavedConfigDidUpdate:&didUpdate] should] equal:configuration];
        [[updatedSnapshot.savedAt should] equal:now];
        [[theValue(updatedSnapshot.source) should] equal:theValue(AMAAppMetricaConfigurationSnapshotSourceGroup)];
        [[theValue(didUpdate) should] beYes];
    });

    it(@"Should return valid config within TTL", ^{
        NSDate *savedAt = [now dateByAddingTimeInterval:-10.0 * 24.0 * 60.0 * 60.0];
        AMAAppMetricaConfigurationSnapshot *snapshot =
            [[AMAAppMetricaConfigurationSnapshot alloc] initWithConfiguration:configuration
                                                                      savedAt:savedAt
                                                                       source:AMAAppMetricaConfigurationSnapshotSourcePrivate];
        stubUpdateWithCurrent(snapshot, YES);

        [[[repository validSavedConfigDidUpdate:NULL] should] equal:configuration];
    });

    it(@"Should not expire when clock skews backwards", ^{
        NSDate *savedAt = [now dateByAddingTimeInterval:60.0];
        AMAAppMetricaConfigurationSnapshot *snapshot =
            [[AMAAppMetricaConfigurationSnapshot alloc] initWithConfiguration:configuration
                                                                      savedAt:savedAt
                                                                       source:AMAAppMetricaConfigurationSnapshotSourcePrivate];
        __block AMAAppMetricaConfigurationSnapshot *updatedSnapshot = nil;
        [persistent stub:@selector(updateAppMetricaClientConfigurationSnapshot:result:)
               withBlock:^id(NSArray *params) {
            AMAConfigurationSnapshotUpdate update = params[0];
            updatedSnapshot = update(snapshot);
            [AMATestUtilities fillObjectPointerParameter:params[1] withValue:updatedSnapshot];
            return theValue(YES);
        }];

        [[[repository validSavedConfigDidUpdate:NULL] should] equal:configuration];
        [[updatedSnapshot.savedAt should] equal:savedAt];
    });

    it(@"Should clear expired config for the snapshot source", ^{
        NSDate *savedAt = [now dateByAddingTimeInterval:-AMASavedAppMetricaConfigTtlChecker.savedAppMetricaConfigTTL];
        AMAAppMetricaConfigurationSnapshot *snapshot =
            [[AMAAppMetricaConfigurationSnapshot alloc] initWithConfiguration:configuration
                                                                      savedAt:savedAt
                                                                       source:AMAAppMetricaConfigurationSnapshotSourceGroup];
        __block AMAAppMetricaConfigurationSnapshot *updatedSnapshot = (id)[NSNull null];
        [persistent stub:@selector(updateAppMetricaClientConfigurationSnapshot:result:)
               withBlock:^id(NSArray *params) {
            AMAConfigurationSnapshotUpdate update = params[0];
            updatedSnapshot = update(snapshot);
            [AMATestUtilities fillObjectPointerParameter:params[1] withValue:updatedSnapshot];
            return theValue(YES);
        }];

        [[[repository validSavedConfigDidUpdate:NULL] should] beNil];
        [[updatedSnapshot should] beNil];
    });

    it(@"Should save configuration and refresh TTL", ^{
        [[persistent should] receive:@selector(saveAppMetricaClientConfigurationSnapshot:)
                       withArguments:kw_any()];

        [repository saveConfiguration:configuration refreshTTL:YES];
    });

    it(@"Should save configuration without refreshing TTL", ^{
        NSDate *savedAt = [now dateByAddingTimeInterval:-10];
        AMAAppMetricaConfigurationSnapshot *current =
            [[AMAAppMetricaConfigurationSnapshot alloc] initWithConfiguration:configuration
                                                                      savedAt:savedAt
                                                                       source:AMAAppMetricaConfigurationSnapshotSourcePrivate];
        __block AMAAppMetricaConfigurationSnapshot *saved = nil;
        [persistent stub:@selector(saveAppMetricaClientConfigurationSnapshotUsingCurrent:)
               withBlock:^id(NSArray *params) {
            AMAConfigurationSnapshotBuilder builder = params[0];
            saved = builder(current);
            return nil;
        }];

        [repository saveConfiguration:configuration refreshTTL:NO];

        [[saved.savedAt should] equal:savedAt];
        [[saved.configuration should] equal:configuration];
    });

});

SPEC_END
