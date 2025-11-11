
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMAAppMetrica+TestUtilities.h"
#import "AMADispatchStrategy.h"
#import "AMADispatchStrategy+Private.h"
#import "AMADispatchStrategiesFactory.h"

@implementation AMAAppMetrica (TestUtilities)

+ (void)amatest_stubStrategiesWithTypeMask:(unsigned int)typeMask
{
    NSArray *strategies = [AMADispatchStrategiesFactory strategiesForStorage:nil
                                                                    typeMask:typeMask
                                                                    delegate:nil
                                                   executionConditionChecker:nil];
    __block AMADispatchStrategy *timerStrategy = [strategies firstObject];
    [AMADispatchStrategiesFactory stub:@selector(strategiesForStorage:typeMask:delegate:executionConditionChecker:) withBlock:^id(NSArray *params) {
        timerStrategy.delegate = params[2];
        timerStrategy.storage = params[0];
        AMATestDelayedManualExecutor *executor = [AMATestDelayedManualExecutor new];
        timerStrategy.executor = executor;
        return @[timerStrategy];
    }];
}

@end
