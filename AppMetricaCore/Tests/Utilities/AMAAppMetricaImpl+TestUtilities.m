
#import "AMAAppMetricaImpl+TestUtilities.h"
#import "AMAEventCountDispatchStrategy.h"
#import "AMATimerDispatchStrategy.h"
#import "AMAReporterStorage.h"

@implementation AMAAppMetricaImpl (TestUtilities)

- (AMAEventCountDispatchStrategy *)eventCountDispatchStrategyInSet:(NSSet *)strategies forApiKey:(NSString *)apiKey
{
    AMAEventCountDispatchStrategy *countStrategy = nil;
    for (AMADispatchStrategy *strategy in strategies) {
        if ([strategy isKindOfClass:[AMAEventCountDispatchStrategy class]] && [strategy.storage.apiKey isEqual:apiKey]) {
            countStrategy = (AMAEventCountDispatchStrategy *)strategy;
        }
    }
    return countStrategy;
}

- (AMATimerDispatchStrategy *)timerDispatchStrategyInSet:(NSSet *)strategies forApiKey:(NSString *)apiKey
{
    AMATimerDispatchStrategy *timerStrategy = nil;
    for (AMADispatchStrategy *strategy in strategies) {
        if ([strategy isKindOfClass:[AMATimerDispatchStrategy class]] && [strategy.storage.apiKey isEqual:apiKey]) {
            timerStrategy = (AMATimerDispatchStrategy *)strategy;
        }
    }
    return timerStrategy;
}

@end
