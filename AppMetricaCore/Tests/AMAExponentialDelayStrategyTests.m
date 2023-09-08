#import <Kiwi/Kiwi.h>
#import "AMAExponentialDelayStrategy.h"
#import "AMAExponentialBackoff.h"

@interface AMAExponentialBackoff ()

@property (nonatomic, assign) NSInteger retryCount;

@end

@interface AMAExponentialDelayStrategy ()

@property (nonatomic, assign, readonly) NSTimeInterval slotDelayInterval;
@property (nonatomic, strong, readonly) AMAExponentialBackoff *slotIndexGenerator;
@property (nonatomic, strong) NSDate *lastDelayRequestDate;

@end

SPEC_BEGIN(AMAExponentialDelayStrategyTests)

describe(@"AMAExponentialBackoff", ^{
    __block AMAExponentialDelayStrategy *strategy = nil;
    beforeEach(^{
        /*
         Initialize strategy with integer numbers to avoid floating point inprecision
         */
        strategy = [[AMAExponentialDelayStrategy alloc] initWithSlotDelayInterval:1 maxRetryCount:5];

        NSDate *date = [NSDate date];
        strategy.lastDelayRequestDate = date;

    });

    context(@"Delay generation algorithm check", ^{
        beforeEach(^{
            [strategy.slotIndexGenerator stub:@selector(next) andReturn:theValue(3)];
        });
        it(@"Delay should be 0", ^{
            NSTimeInterval delay = strategy.slotDelayInterval * [strategy.slotIndexGenerator next];
            NSDate *futureDate = [strategy.lastDelayRequestDate dateByAddingTimeInterval:delay];
            [NSDate stub:@selector(date) andReturn: futureDate];

            [[theValue(strategy.delay) should] equal:theValue(0)];
        });

        it(@"Delay should be 3", ^{
            /*
             make small step to the past to achive border case
             */
            NSTimeInterval nextCallInterval =
                (strategy.slotDelayInterval * [strategy.slotIndexGenerator next]) - 0.0000001;

            NSDate *futureDate = [strategy.lastDelayRequestDate dateByAddingTimeInterval:nextCallInterval];
            [NSDate stub:@selector(date) andReturn: futureDate];

            [[theValue(strategy.delay) should] equal:theValue(3)];
        });
    });

    context(@"Retry count check", ^{
        beforeEach(^{
            strategy.slotIndexGenerator.retryCount = 5;
        });
        it(@"Should reset retry count when retry count max value reached", ^{
            [strategy delay];

            [[theValue(strategy.slotIndexGenerator.retryCount) should] equal:theValue(1)];
        });
    });
});

SPEC_END
