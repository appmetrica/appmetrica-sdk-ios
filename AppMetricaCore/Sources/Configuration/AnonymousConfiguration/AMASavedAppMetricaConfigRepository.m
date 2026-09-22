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

- (AMAAppMetricaConfiguration *)validSavedConfigDidUpdate:(BOOL *)didUpdate
{
    __block AMAAppMetricaConfigurationSnapshot *snapshot = nil;
    BOOL updated = [self.persistent updateAppMetricaClientConfigurationSnapshot:
        ^AMAAppMetricaConfigurationSnapshot *(AMAAppMetricaConfigurationSnapshot *current) {
            NSDate *now = self.dateProvider.currentDate;

            if (current.savedAt == nil) {
                AMALogInfo(@"No timestamp for saved config. Lazy migrate with now=%@", now);
                return [current snapshotByUpdatingSavedAt:now];
            }

            if ([AMASavedAppMetricaConfigTtlChecker isExpiredForSavedAt:current.savedAt now:now]) {
                AMALogInfo(@"Saved config expired. savedAt=%@, now=%@. Clearing source=%ld.",
                           current.savedAt, now, (long)current.source);
                return nil;
            }

            return current;
        }
        result:&snapshot
    ];
    if (didUpdate != NULL) {
        *didUpdate = updated;
    }
    return snapshot.configuration;
}

- (void)saveConfiguration:(AMAAppMetricaConfiguration *)configuration
               refreshTTL:(BOOL)refreshTTL
{
    if (refreshTTL) {
        AMAAppMetricaConfigurationSnapshot *snapshot =
            [[AMAAppMetricaConfigurationSnapshot alloc] initWithConfiguration:configuration
                                                                      savedAt:self.dateProvider.currentDate
                                                                       source:AMAAppMetricaConfigurationSnapshotSourcePrivate];
        [self.persistent saveAppMetricaClientConfigurationSnapshot:snapshot];
        return;
    }

    [self.persistent saveAppMetricaClientConfigurationSnapshotUsingCurrent:
        ^AMAAppMetricaConfigurationSnapshot *(AMAAppMetricaConfigurationSnapshot *current) {
            return [[AMAAppMetricaConfigurationSnapshot alloc] initWithConfiguration:configuration
                                                                              savedAt:current.savedAt
                                                                               source:AMAAppMetricaConfigurationSnapshotSourcePrivate];
        }
    ];
}

@end
