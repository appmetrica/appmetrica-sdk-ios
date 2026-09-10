#import "AMASavedAppMetricaConfigRepository.h"
#import "AMASavedAppMetricaConfigTtlChecker.h"
#import "AMAMetricaPersistentConfiguration.h"
#import "AMAAppMetricaConfigurationSnapshot.h"
#import "AMACore.h"
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>

@interface AMASavedAppMetricaConfigRepository ()

@property (nonatomic, strong, readonly) AMAMetricaPersistentConfiguration *persistent;
@property (nonatomic, strong, readonly) id<AMADateProviding> dateProvider;

@end

@implementation AMASavedAppMetricaConfigRepository

- (instancetype)initWithPersistentConfiguration:(AMAMetricaPersistentConfiguration *)persistent
{
    return [self initWithPersistentConfiguration:persistent
                                    dateProvider:[[AMADateProvider alloc] init]];
}

- (instancetype)initWithPersistentConfiguration:(AMAMetricaPersistentConfiguration *)persistent
                                   dateProvider:(id<AMADateProviding>)dateProvider
{
    self = [super init];
    if (self != nil) {
        _persistent = persistent;
        _dateProvider = dateProvider;
    }
    return self;
}

- (AMAAppMetricaConfiguration *)validSavedConfig
{
    AMAAppMetricaConfigurationSnapshot *snapshot = [self.persistent appMetricaClientConfigurationSnapshot];
    if (snapshot.configuration == nil) {
        return nil;
    }

    NSDate *savedAt = snapshot.savedAt;
    NSDate *now = self.dateProvider.currentDate;
    if (savedAt == nil) {
        // Existing released configuration.json has no savedAt yet — stamp now into the same snapshot.
        AMALogInfo(@"No timestamp for saved config. Lazy migrate with now=%@", now);
        AMAAppMetricaConfigurationSnapshot *migrated = [snapshot snapshotByUpdatingSavedAt:now];
        [self.persistent saveAppMetricaClientConfigurationSnapshot:migrated];
        return snapshot.configuration;
    }

    if ([AMASavedAppMetricaConfigTtlChecker isExpiredForSavedAt:savedAt now:now]) {
        AMALogInfo(@"Saved config expired. savedAt=%@, now=%@. Clearing source=%ld.",
                   savedAt, now, (long)snapshot.source);
        [self.persistent clearAppMetricaClientConfigurationSnapshot:snapshot];
        return nil;
    }

    return snapshot.configuration;
}

- (void)saveConfiguration:(AMAAppMetricaConfiguration *)configuration
               refreshTTL:(BOOL)refreshTTL
{
    AMAAppMetricaConfigurationSnapshot *current = [self.persistent appMetricaClientConfigurationSnapshot];
    NSDate *savedAt = refreshTTL ? self.dateProvider.currentDate : current.savedAt;
    AMAAppMetricaConfigurationSnapshot *updated =
        [[AMAAppMetricaConfigurationSnapshot alloc] initWithConfiguration:configuration
                                                                  savedAt:savedAt
                                                                   source:AMAAppMetricaConfigurationSnapshotSourcePrivate];
    [self.persistent saveAppMetricaClientConfigurationSnapshot:updated];
}

@end
