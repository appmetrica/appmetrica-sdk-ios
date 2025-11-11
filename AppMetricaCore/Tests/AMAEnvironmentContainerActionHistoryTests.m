
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMAEnvironmentContainerActionHistory.h"
#import "AMAEnvironmentContainerAction.h"

SPEC_BEGIN(AMAEnvironmentContainerActionHistoryTests)

describe(@"AMAEnvironmentContainerActionHistory", ^{
    let(history, ^{
       return [AMAEnvironmentContainerActionHistory new];
    });

    it(@"should track add value action", ^{
        [history trackAddValue:@"foo" forKey:@"bar"];
        NSArray *actions = history.trackedActions;
        [[actions should] haveCountOf:1];
        [[actions.firstObject should] beKindOfClass:[AMAEnvironmentContainerAddValueAction class]];
    });

    it(@"should track clear action", ^{
        [history trackClearEnvironment];
        NSArray *actions = history.trackedActions;
        [[actions should] haveCountOf:1];
        [[actions.firstObject should] beKindOfClass:[AMAEnvironmentContainerClearAction class]];
    });
});

SPEC_END
