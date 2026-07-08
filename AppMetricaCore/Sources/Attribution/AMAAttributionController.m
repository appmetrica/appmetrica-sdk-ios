
#import "AMAAttributionController.h"
#import "AMAAttributionModelConfiguration.h"
#import "AMAReporter.h"
#import "AMAAttributionChecker.h"
#import "AMAMetricaConfiguration.h"
#import "AMAMetricaPersistentConfiguration.h"
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>

@interface AMAAttributionController ()

@property (nonatomic, strong, readonly) id<AMAAsyncExecuting> executor;
@property (nonatomic, assign, readwrite) BOOL inited;

@end

@implementation AMAAttributionController

- (instancetype)initWithExecutor:(id<AMAAsyncExecuting>)executor
{
    return [self initWithExecutor:executor
                            config:[AMAMetricaConfiguration sharedInstance].persistent.attributionModelConfiguration];
}

- (instancetype)initWithExecutor:(id<AMAAsyncExecuting>)executor
                           config:(AMAAttributionModelConfiguration *)config
{
    self = [super init];
    if (self != nil) {
        _executor = executor;
        _config = config;
    }
    return self;
}

#pragma mark - Public -

// NOTE: ivar set synchronously; only the heavier surveillance setup is deferred onto `executor`.
- (void)setMainReporter:(AMAReporter *)mainReporter
{
    @synchronized (self) {
        _mainReporter = mainReporter;
    }
    [self.executor execute:^{
        @synchronized (self) {
            AMALogInfo(@"config: %@, inited: %d", self.config, self.inited);
            [self maybeSetUpEventsSurveillanceWithReporter:mainReporter config:self.config];
        }
    }];
}

- (void)setConfig:(AMAAttributionModelConfiguration *)config
{
    @synchronized (self) {
        _config = config;
    }
    [self.executor execute:^{
        @synchronized (self) {
            AMALogInfo(@"reporter: %@, config: %@, inited: %d", self.mainReporter, config, self.inited);
            if (self.mainReporter != nil) {
                [self maybeSetUpEventsSurveillanceWithReporter:self.mainReporter config:config];
            }
        }
    }];
}

#pragma mark - Private -

- (void)maybeSetUpEventsSurveillanceWithReporter:(AMAReporter *)reporter
                                          config:(AMAAttributionModelConfiguration *)config
{
    if (self.inited) {
        AMALogInfo(@"Already inited");
        return;
    }
    if (config == nil) {
        if ([AMAMetricaConfiguration sharedInstance].persistent.hadFirstStartup) {
            AMALogInfo(@"Set initial attribution checked");
            [AMAMetricaConfiguration sharedInstance].persistent.checkedInitialAttribution = YES;
        }
        AMALogInfo(@"No config");
        return;
    }
    if (@available(iOS 14.0, *)) {
        NSDate *registerForAttributionTime = [AMAMetricaConfiguration sharedInstance].persistent.registerForAttributionTime;
        AMAIntervalExecutionCondition *condition = [[AMAIntervalExecutionCondition alloc]
            initWithLastExecuted:registerForAttributionTime
                        interval:[AMATimeUtilities intervalWithNumber:config.stopSendingTimeSeconds defaultInterval:0]
             underlyingCondition:nil
        ];
        BOOL shouldExecute = condition.shouldExecute == NO;
        AMALogInfo(@"should execute? %d", shouldExecute);
        if (shouldExecute) {
            reporter.attributionChecker = [[AMAAttributionChecker alloc] initWithConfig:config reporter:reporter];
        }
    }
    self.inited = YES;
}

@end
