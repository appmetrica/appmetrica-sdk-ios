#import <Kiwi/Kiwi.h>
#import "AMAExponentialBackoff.h"

@interface AMAExponentialBackoff ()

@property (nonatomic, assign) NSInteger retryCount;

@end

SPEC_BEGIN(AMAExponentialBackoffTests)

describe(@"AMAExponentialBackoff", ^{
    __block AMAExponentialBackoff *backoff = nil;

    context(@"Slot index check", ^{
        beforeEach(^{
            backoff = [[AMAExponentialBackoff alloc] initWithMaxRetryCount:5];
        });

        it(@"Index should be less then 2", ^{
            NSInteger index = [backoff next];

            [[theValue(index) should] beLessThan:theValue(2)];

        });

        it(@"Index should be less then 4", ^{
            [backoff next];
            NSInteger index = [backoff next];

            [[theValue(index) should] beLessThan:theValue(4)];

        });

        it(@"Index should be less then 8", ^{
            [backoff next];
            [backoff next];
            NSInteger index = [backoff next];

            [[theValue(index) should] beLessThan:theValue(8)];

        });

        it(@"Index should be less then 16", ^{
            [backoff next];
            [backoff next];
            [backoff next];
            NSInteger index = [backoff next];

            [[theValue(index) should] beLessThan:theValue(16)];

        });

        it(@"Index should be less then 32", ^{
            [backoff next];
            [backoff next];
            [backoff next];
            [backoff next];
            NSInteger index = [backoff next];

            [[theValue(index) should] beLessThan:theValue(32)];

        });
    });

    context(@"Reset check", ^{
        it(@"Retry count should equals 0 after reset", ^{
            backoff = [[AMAExponentialBackoff alloc] initWithMaxRetryCount:5];
            backoff.retryCount = 3;
            [backoff reset];

            [[theValue(backoff.retryCount) should] equal:theValue(0)];
        });
    });

    context(@"Max retry count reached check", ^{
        beforeEach(^{
            backoff = [[AMAExponentialBackoff alloc] initWithMaxRetryCount:18];
            backoff.retryCount = 18;
        });

        it(@"Should not increase retryCount", ^{
            [backoff next];

            [[theValue(backoff.retryCount) should] equal:theValue(18)];
        });

        it(@"maxRetryCountReached shoud be YES", ^{
            [[theValue(backoff.maxRetryCountReached) should] beYes];
        });

    });
});

SPEC_END
