
#import "AMACore.h"
#import "AMAInternalStateReportingController.h"
#import "AMAMetricaConfiguration.h"
#import "AMAStartupParametersConfiguration.h"
#import "AMADataSendingRestrictionController.h"
#import "AMAAppMetrica+Internal.h"
#import "AMAReporter.h"
#import "AMAReporterNotifications.h"
#import "AMAReporterStateStorage.h"

static NSTimeInterval const kAMADefaultInterval = 5 * 60 * 60;

@interface AMAInternalStateReportingController ()

@property (nonatomic, strong, readonly) id<AMAExecuting> executor;
@property (nonatomic, strong, readonly) AMADataSendingRestrictionController *restrictionController;
@property (nonatomic, strong, readonly) NSMutableDictionary *reporterStateStorages;

@end

@implementation AMAInternalStateReportingController

- (instancetype)initWithExecutor:(id<AMAExecuting>)executor
{
    return [self initWithExecutor:executor
            restrictionController:[AMADataSendingRestrictionController sharedInstance]];
}

- (instancetype)initWithExecutor:(id<AMAExecuting>)executor
           restrictionController:(AMADataSendingRestrictionController *)restrictionController
{
    self = [super init];
    if (self != nil) {
        _executor = executor;
        _restrictionController = restrictionController;

        _reporterStateStorages = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark - Public -

- (void)registerStorage:(AMAReporterStateStorage *)stateStorage forApiKey:(NSString *)apiKey
{
    @synchronized (self) {
        self.reporterStateStorages[apiKey] = stateStorage;
    }
}

- (void)start
{
    [self trigger];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleDidAddEventNotification:)
                                                 name:kAMAReporterDidAddEventNotification
                                               object:nil];
}

- (void)shutdown
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kAMAReporterDidAddEventNotification
                                                  object:nil];
}

#pragma mark - Private -

- (void)handleDidAddEventNotification:(NSNotification *)notification
{
    [self trigger];
}

- (BOOL)shouldSendForRestriction:(AMADataSendingRestriction)restriction lastSendDate:(NSDate *)lastSendDate
{
    BOOL shouldSend = YES;
    NSNumber *sendIntervalNumber =
        [AMAMetricaConfiguration sharedInstance].startup.statSendingDisabledReportingInterval;
    NSTimeInterval sendInterval = sendIntervalNumber != nil ? [sendIntervalNumber doubleValue] : kAMADefaultInterval;

    shouldSend = shouldSend && restriction == AMADataSendingRestrictionForbidden;
    shouldSend = shouldSend && [[NSDate date] timeIntervalSinceDate:lastSendDate] >= sendInterval;
    return shouldSend;
}

- (NSDictionary *)stateForRestriction:(AMADataSendingRestriction)restriction
{
    return @{
        @"stat_sending": @{
            @"disabled": [NSNumber numberWithBool:restriction == AMADataSendingRestrictionForbidden],
        },
    };
}

- (NSDictionary *)nextStatesToSend
{
    NSMutableDictionary *statesToSend = nil;
    @synchronized (self) {
        if (self.reporterStateStorages.count > 0) {
            statesToSend = [NSMutableDictionary dictionary];
            NSMutableDictionary *dict = self.reporterStateStorages;
            [dict enumerateKeysAndObjectsUsingBlock:^(NSString *apiKey, AMAReporterStateStorage *storage, BOOL *stop) {
                AMADataSendingRestriction restriction = [self.restrictionController restrictionForApiKey:apiKey];
                if ([self shouldSendForRestriction:restriction lastSendDate:storage.lastStateSendDate]) {
                    statesToSend[apiKey] = [self stateForRestriction:restriction];
                    [storage markStateSentNow];
                }
            }];
        }
    }
    return [statesToSend copy];
}

- (void)trigger
{
    NSDictionary *statesToSend = [self nextStatesToSend];
    if (statesToSend.count > 0) {
        [self.executor execute:^{
            [statesToSend enumerateKeysAndObjectsUsingBlock:^(NSString *apiKey, NSDictionary *state, BOOL *stop) {
                AMAReporter *reporter = (AMAReporter *)[AMAAppMetrica reporterForApiKey:apiKey];
                
                //TODO: Remove as unnecessary
                [reporter reportInternalState:state onFailure:NULL];
            }];
        }];
    }
}

@end
