
#import "AMACore.h"
#import "AMAModulesStatusReporter.h"

#import "AMAInternalEventsReporter.h"
#import "AMAMetricaPersistentConfiguration.h"
#import "AMAModulesController.h"
#import "AMAModulesStatusReportState.h"

static NSString *const kAMAModulesStatusParameterKey = @"modulesStatus";
static NSString *const kAMALastSendTimeParameterKey = @"lastSendTime";
static NSString *const kAMAModuleNameKey = @"moduleName";
static NSString *const kAMAModuleLoadedKey = @"loaded";

static const NSTimeInterval kAMAModulesStatusReportInterval = 24.0 * 60.0 * 60.0;

@interface AMAModulesStatusReporter ()

@property (nonatomic, strong, readonly) AMAInternalEventsReporter *reporter;
@property (nonatomic, strong, readonly) AMAModulesController *modulesController;
@property (nonatomic, strong, readonly) AMAMetricaPersistentConfiguration *persistentConfiguration;
@property (nonatomic, strong, readonly) id<AMADateProviding> dateProvider;

@end

@implementation AMAModulesStatusReporter

- (instancetype)initWithReporter:(AMAInternalEventsReporter *)reporter
               modulesController:(AMAModulesController *)modulesController
         persistentConfiguration:(AMAMetricaPersistentConfiguration *)persistentConfiguration
                    dateProvider:(id<AMADateProviding>)dateProvider
{
    self = [super init];
    if (self != nil) {
        _reporter = reporter;
        _modulesController = modulesController;
        _persistentConfiguration = persistentConfiguration;
        _dateProvider = dateProvider;
    }
    return self;
}

- (void)report
{
    NSDictionary<NSString *, NSNumber *> *statuses = self.modulesController.moduleStatuses;
    if (statuses.count == 0) {
        return;
    }

    AMAModulesStatusReportState *previousState = self.persistentConfiguration.modulesStatusReportState;
    NSDate *currentDate = [self.dateProvider currentDate];
    if ([self shouldReportWithStatuses:statuses previousState:previousState currentDate:currentDate] == NO) {
        return;
    }

    int64_t lastSendTime = (int64_t)(currentDate.timeIntervalSince1970 * 1000.0);
    NSDictionary *parameters = @{
        kAMAModulesStatusParameterKey: [self modulesStatusArrayFromStatuses:statuses],
        kAMALastSendTimeParameterKey: @(lastSendTime),
    };
    [self.reporter reportModulesStatusWithParameters:parameters];

    AMAModulesStatusReportState *updatedState = [[AMAModulesStatusReportState alloc]
        initWithLastSentDate:currentDate
        moduleStatuses:statuses];
    self.persistentConfiguration.modulesStatusReportState = updatedState;
}

#pragma mark - Private -

- (BOOL)shouldReportWithStatuses:(NSDictionary<NSString *, NSNumber *> *)statuses
                   previousState:(AMAModulesStatusReportState *)previousState
                     currentDate:(NSDate *)currentDate
{
    if (previousState == nil) {
        return YES;
    }
    if ([previousState.moduleStatuses isEqualToDictionary:statuses] == NO) {
        return YES;
    }
    NSDate *lastSentDate = previousState.lastSentDate;
    if (lastSentDate == nil) {
        return YES;
    }
    NSTimeInterval elapsed = [currentDate timeIntervalSinceDate:lastSentDate];
    return elapsed >= kAMAModulesStatusReportInterval;
}

- (NSArray<NSDictionary<NSString *, id> *> *)modulesStatusArrayFromStatuses:
    (NSDictionary<NSString *, NSNumber *> *)statuses
{
    NSArray<NSString *> *sortedNames = [statuses.allKeys sortedArrayUsingSelector:@selector(compare:)];
    NSMutableArray<NSDictionary<NSString *, id> *> *result = [NSMutableArray arrayWithCapacity:sortedNames.count];
    for (NSString *name in sortedNames) {
        BOOL loaded = [statuses[name] boolValue];
        [result addObject:@{
            kAMAModuleNameKey: name,
            kAMAModuleLoadedKey: @(loaded),
        }];
    }
    return [result copy];
}

@end
