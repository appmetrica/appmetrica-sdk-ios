
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>
#import "AMADispatchQueueTestHelper.h"

SPEC_BEGIN(AMAExecutingTests)

describe(@"AMAExecuting", ^{

    NSString *const domain = @"io.appmetrica.CoreUtils";

    NSTimeInterval const timeout = 0.7;
    NSTimeInterval const delta = 0.2;

    context(@"AMAExecutor", ^{
        it(@"Shoud create queue with same identifier", ^{
            NSObject *identifier = [[NSObject alloc] init];
            [[AMAQueuesFactory should] receive:@selector(serialQueueForIdentifierObject:domain:)
                                 withArguments:identifier, domain];
            id instance __unused = [[AMAExecutor alloc] initWithIdentifier:identifier];
        });
        it(@"Should use self as default identifier", ^{
            KWCaptureSpy *spy = [AMAQueuesFactory captureArgument:@selector(serialQueueForIdentifierObject:domain:)
                                                          atIndex:0];
            AMAExecutor *executor = [[AMAExecutor alloc] init];
            [[spy.argument should] equal:executor];
        });
        context(@"Default identifier", ^{
            AMAExecutor *__block executor = nil;

            beforeEach(^{
                executor = [[AMAExecutor alloc] init];
            });
            
            context(@"Async", ^{
                it(@"Should dispatch async", ^{
                    BOOL __block executed = NO;
                    [executor execute:^{
                        [NSThread sleepForTimeInterval:timeout];
                        executed = YES;
                    }];
                    [[theValue(executed) should] beNo];
                });
            });

            context(@"Sync", ^{
                it(@"Should execute and return object", ^{
                    NSString *expectedResult = @"Result";
                    id result = [executor syncExecute:^id {
                        return expectedResult;
                    }];
                    [[result should] equal:expectedResult];
                });
                
                it(@"Should execute and return nil", ^{
                    id result = [executor syncExecute:^id {
                        return nil;
                    }];
                    [[result should] beNil];
                });
            });
        });
    });

    context(@"AMADelayedExecutor", ^{
        it(@"Shoud create queue with same identifier", ^{
            NSObject *identifier = [[NSObject alloc] init];
            [[AMAQueuesFactory should] receive:@selector(serialQueueForIdentifierObject:domain:)
                                 withArguments:identifier, domain];
            id instance __unused = [[AMADelayedExecutor alloc] initWithIdentifier:identifier];
        });
        it(@"Should use self as default identifier", ^{
            KWCaptureSpy *spy = [AMAQueuesFactory captureArgument:@selector(serialQueueForIdentifierObject:domain:)
                                                          atIndex:0];
            AMADelayedExecutor *executor = [[AMADelayedExecutor alloc] init];
            [[spy.argument should] equal:executor];
        });
        context(@"Default identifier", ^{
            AMADelayedExecutor *__block executor = nil;

            beforeEach(^{
                executor = [[AMADelayedExecutor alloc] init];
            });
            it(@"Should dispatch async", ^{
                BOOL __block executed = NO;
                [executor execute:^{
                    [NSThread sleepForTimeInterval:timeout];
                    executed = YES;
                }];
                [[theValue(executed) should] beNo];
            });
            it(@"Should dispatch with delay", ^{
                NSDate *start = [NSDate date];
                NSDate *__block finish = nil;
                [executor executeAfterDelay:timeout block:^{
                    finish = [NSDate date];
                }];
                [NSThread sleepForTimeInterval:timeout];

                KWFutureObject *future = expectFutureValue(theValue([finish timeIntervalSinceDate:start]));
                [[future shouldEventuallyBeforeTimingOutAfter(timeout+delta)] equal:timeout withDelta:delta];
            });
            it(@"Should dispatch two blocks with delay", ^{
                NSUInteger __block executedCount = 0;
                [executor executeAfterDelay:timeout / 2 block:^{
                    ++executedCount;
                }];
                [executor executeAfterDelay:timeout / 2 block:^{
                    ++executedCount;
                }];

                KWFutureObject *future = expectFutureValue(theValue(executedCount));
                [[future shouldEventuallyBeforeTimingOutAfter(timeout)] equal:theValue(2)];
            });
        });
    });

    context(@"AMACancelableDelayedExecutor", ^{
        it(@"Shoud create queue with same identifier", ^{
            NSObject *identifier = [[NSObject alloc] init];
            [[AMAQueuesFactory should] receive:@selector(serialQueueForIdentifierObject:domain:)
                                 withArguments:identifier, domain];
            id instance __unused = [[AMACancelableDelayedExecutor alloc] initWithIdentifier:identifier];
        });
        it(@"Should use self as default identifier", ^{
            KWCaptureSpy *spy = [AMAQueuesFactory captureArgument:@selector(serialQueueForIdentifierObject:domain:)
                                                          atIndex:0];
            AMACancelableDelayedExecutor *executor = [[AMACancelableDelayedExecutor alloc] init];
            [[spy.argument should] equal:executor];
        });
        context(@"Default identifier", ^{
            AMACancelableDelayedExecutor *__block executor = nil;

            beforeEach(^{
                executor = [[AMACancelableDelayedExecutor alloc] init];
            });
            it(@"Should dispatch async", ^{
                BOOL __block executed = NO;
                [executor execute:^{
                    [NSThread sleepForTimeInterval:timeout];
                    executed = YES;
                }];
                [[theValue(executed) should] beNo];
            });
            it(@"Should dispatch with delay", ^{
                NSDate *start = [NSDate date];
                NSDate *__block finish = nil;
                [executor executeAfterDelay:timeout block:^{
                    finish = [NSDate date];
                }];
                [NSThread sleepForTimeInterval:timeout];

                KWFutureObject *future = expectFutureValue(theValue([finish timeIntervalSinceDate:start]));
                [[future shouldEventuallyBeforeTimingOutAfter(timeout+delta)] equal:timeout withDelta:delta];
            });
            it(@"Should dispatch two blocks with delay", ^{
                NSUInteger __block executedCount = 0;
                [executor executeAfterDelay:timeout / 2 block:^{
                    ++executedCount;
                }];
                [executor executeAfterDelay:timeout / 2 block:^{
                    ++executedCount;
                }];

                KWFutureObject *future = expectFutureValue(theValue(executedCount));
                [[future shouldEventuallyBeforeTimingOutAfter(timeout)] equal:theValue(2)];
            });
            it(@"Should not dispatch if cancelled", ^{
                BOOL __block executed = NO;
                [executor executeAfterDelay:timeout block:^{
                    executed = YES;
                }];
                [NSThread sleepForTimeInterval:timeout / 2];
                [executor cancelDelayed];

                KWFutureObject *future = expectFutureValue(theValue(executed));
                [[future shouldNotEventuallyBeforeTimingOutAfter(timeout)] beYes];
            });
        });
    });

});

SPEC_END

