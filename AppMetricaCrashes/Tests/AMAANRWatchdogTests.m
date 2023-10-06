
#import <Kiwi/Kiwi.h>

#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>

#import "AMAANRWatchdog.h"

SPEC_BEGIN(AMAANRWatchdogTests)

describe(@"AMAANRWatchdog", ^{

    NSTimeInterval const kANRDuration = 0.5;
    NSTimeInterval const kCheckPeriod = 0.01;

    AMAANRWatchdog *__block ANRDetector = nil;
    AMAAsyncExecutor *__block watchingExecutor = nil;
    AMAManualCurrentQueueExecutor *__block observedExecutor = nil;

    id __block delegate = nil;

    NSInteger __block hitTimes = 0;

    beforeEach(^{
        watchingExecutor = [[AMAAsyncExecutor alloc] initWithQueue:dispatch_queue_create("Watching test queue", NULL)];
        observedExecutor = [[AMAManualCurrentQueueExecutor alloc] init];
        hitTimes = 0;
        delegate = [KWMock mockForProtocol:@protocol(AMAANRWatchdogDelegate)];
        [delegate stub:@selector(ANRWatchdogDidDetectANR:)
             withBlock:^id(NSArray *params) {
                 hitTimes++;
                 return nil;
             }];

        ANRDetector = [[AMAANRWatchdog alloc] initWithWatchdogInterval:kANRDuration
                                                          pingInterval:kCheckPeriod
                                                      watchingExecutor:watchingExecutor
                                                      observedExecutor:observedExecutor];
        ANRDetector.delegate = delegate;
    });

    it(@"Should report of ANR once", ^{
        [ANRDetector start];
        [[expectFutureValue(theValue(hitTimes)) shouldEventuallyBeforeTimingOutAfter(1)] equal:theValue(1)];
    });

    it(@"Should report of ANR twice", ^{
        [ANRDetector start];
        [NSThread sleepForTimeInterval:kANRDuration + 0.1];
        [observedExecutor execute];
        [[expectFutureValue(theValue(hitTimes)) shouldEventuallyBeforeTimingOutAfter(1)] equal:theValue(2)];
    });

    it(@"Should not report of ANR", ^{
        [ANRDetector start];
        [observedExecutor execute];
        [[expectFutureValue(theValue(hitTimes)) shouldEventuallyBeforeTimingOutAfter(1)] equal:theValue(0)];
    });
});

SPEC_END
