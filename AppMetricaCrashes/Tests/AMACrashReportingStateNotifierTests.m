
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMACrashReportingStateNotifier.h"

SPEC_BEGIN(AMACrashReportingStateNotifierTests)

describe(@"AMACrashReportingStateNotifier", ^{

    NSTimeInterval const timeout = 1.0;
    dispatch_queue_t const queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

    AMACrashReportingStateNotifier *__block notifier = nil;

    beforeEach(^{
        notifier = [[AMACrashReportingStateNotifier alloc] init];
    });

    it(@"Should not raise for nil block", ^{
        [[theBlock(^{
            [notifier addObserverWithCompletionQueue:queue completionBlock:nil];
        }) shouldNot] raise];
    });
    it(@"Should not raise for nil queue", ^{
        [[theBlock(^{
            [notifier addObserverWithCompletionQueue:nil completionBlock:^(NSDictionary * _Nullable state) { }];
        }) shouldNot] raise];
    });
    context(@"One block", ^{
        NSDictionary *__block resultState = nil;
        beforeEach(^{
            resultState = nil;
            [notifier addObserverWithCompletionQueue:queue completionBlock:^(NSDictionary * _Nullable state) {
                resultState = state;
            }];
        });
        it(@"Should notify not enabled", ^{
            [notifier notifyWithEnabled:NO crashedLastLaunch:nil];
            [[expectFutureValue(resultState) shouldEventuallyBeforeTimingOutAfter(timeout)] equal:@{
                kAMACrashReportingStateEnabledKey: @NO,
            }];
        });
        it(@"Should notify not crashed", ^{
            [notifier notifyWithEnabled:YES crashedLastLaunch:@NO];
            [[expectFutureValue(resultState) shouldEventuallyBeforeTimingOutAfter(timeout)] equal:@{
                kAMACrashReportingStateEnabledKey: @YES,
                kAMACrashReportingStateCrashedLastLaunchKey: @NO,
            }];
        });
        it(@"Should notify crashed", ^{
            [notifier notifyWithEnabled:YES crashedLastLaunch:@YES];
            [[expectFutureValue(resultState) shouldEventuallyBeforeTimingOutAfter(timeout)] equal:@{
                kAMACrashReportingStateEnabledKey: @YES,
                kAMACrashReportingStateCrashedLastLaunchKey: @YES,
            }];
        });
    });
    context(@"Two blocks", ^{
        it(@"Should notify both", ^{
            NSUInteger __block notificationsCount = 0;
            [notifier addObserverWithCompletionQueue:queue completionBlock:^(NSDictionary * _Nullable state) {
                ++notificationsCount;
            }];
            [notifier addObserverWithCompletionQueue:queue completionBlock:^(NSDictionary * _Nullable state) {
                ++notificationsCount;
            }];
            [notifier notifyWithEnabled:NO crashedLastLaunch:@YES];
            [[expectFutureValue(theValue(notificationsCount)) shouldEventuallyBeforeTimingOutAfter(timeout)] equal:theValue(2)];
        });
    });

});

SPEC_END
