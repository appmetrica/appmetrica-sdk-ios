
#import <Kiwi/Kiwi.h>
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>

SPEC_BEGIN(AMABlockTimerTests)

describe(@"AMABlockTimer", ^{

    NSTimeInterval const timeout = 2.3;
    dispatch_queue_t const queue = dispatch_get_main_queue();
    AMABlockTimerBlock const emptyBlock = ^(AMABlockTimer *timer) {};

    AMATimer *__block baseTimerMock = nil;

    beforeEach(^{
        baseTimerMock = [AMATimer nullMock];
        [baseTimerMock stub:@selector(initWithTimeout:callbackQueue:) andReturn:baseTimerMock];
        [AMATimer stub:@selector(alloc) andReturn:baseTimerMock];
    });

    it(@"Should create base timer with valid arguments", ^{
        [[baseTimerMock should] receive:@selector(initWithTimeout:callbackQueue:)
                          withArguments:theValue(timeout), queue];
        id timer __unused = [[AMABlockTimer alloc] initWithTimeout:timeout callbackQueue:queue block:emptyBlock];
    });
    it(@"Should set base timer delegate", ^{
        KWCaptureSpy *spy = [baseTimerMock captureArgument:@selector(setDelegate:) atIndex:0];
        AMABlockTimer *timer = [[AMABlockTimer alloc] initWithTimeout:timeout callbackQueue:queue block:emptyBlock];
        [[spy.argument should] equal:timer];
    });
    it(@"Should dispatch start to base timer", ^{
        AMABlockTimer *timer = [[AMABlockTimer alloc] initWithTimeout:timeout callbackQueue:queue block:emptyBlock];
        [[baseTimerMock should] receive:@selector(start)];
        [timer start];
    });
    it(@"Should dispatch invalidation to base timer", ^{
        AMABlockTimer *timer = [[AMABlockTimer alloc] initWithTimeout:timeout callbackQueue:queue block:emptyBlock];
        [[baseTimerMock should] receive:@selector(invalidate)];
        [timer invalidate];
    });
    it(@"Should dispatch base timer fire to block", ^{
        BOOL __block executed = NO;
        AMABlockTimerBlock const block = ^(AMABlockTimer *timer) {
            executed = YES;
        };
        AMABlockTimer *timer = [[AMABlockTimer alloc] initWithTimeout:timeout callbackQueue:queue block:block];
        [timer performSelector:@selector(timerDidFire:) withObject:baseTimerMock];
        [[theValue(executed) should] beYes];
    });
});

SPEC_END

