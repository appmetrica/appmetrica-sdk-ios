
#import <Kiwi/Kiwi.h>
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>

SPEC_BEGIN(AMAGapExecutionConditionTests)

describe(@"AMAGapExecutionCondition", ^{
    
    NSDate *__block firstStartupUpdate = nil;
    NSDate *__block lastStartupUpdate = nil;
    AMAGapExecutionCondition *__block condition = nil;
    NSObject<AMAExecutionCondition> *__block underlyingCondition = nil;
    
    beforeEach(^{
        underlyingCondition = [KWMock nullMockForProtocol:@protocol(AMAExecutionCondition)];
    });
    
    NSTimeInterval const gap = 23;
    
    context(@"Within the gap", ^{
        beforeEach(^{
            firstStartupUpdate = [NSDate dateWithTimeIntervalSince1970:4];
            lastStartupUpdate = [NSDate dateWithTimeIntervalSince1970:8];
            
            condition = [[AMAGapExecutionCondition alloc] initWithFirstStartupUpdate:firstStartupUpdate
                                                                   lastStartupUpdate:lastStartupUpdate
                                                                lastServerTimeOffset:@0
                                                                                 gap:gap
                                                                 underlyingCondition:underlyingCondition];
        });
        it(@"Should return YES if underlying condition returns YES", ^{
            [underlyingCondition stub:@selector(shouldExecute) andReturn:theValue(YES)];
            [[theValue(condition.shouldExecute) should] beYes];
        });
        it(@"Should return NO if underlying condition returns NO", ^{
            [underlyingCondition stub:@selector(shouldExecute) andReturn:theValue(NO)];
            [[theValue(condition.shouldExecute) should] beNo];
        });
        it(@"Should return YES if underlying condition is nil", ^{
            condition = [[AMAGapExecutionCondition alloc] initWithFirstStartupUpdate:firstStartupUpdate
                                                                   lastStartupUpdate:lastStartupUpdate
                                                                lastServerTimeOffset:@0
                                                                                 gap:gap
                                                                 underlyingCondition:nil];
            [[theValue(condition.shouldExecute) should] beYes];
        });
    });
    context(@"After the gap", ^{
        beforeEach(^{
            firstStartupUpdate = [NSDate dateWithTimeIntervalSince1970:4];
            lastStartupUpdate = [NSDate dateWithTimeIntervalSince1970:42];
            condition = [[AMAGapExecutionCondition alloc] initWithFirstStartupUpdate:firstStartupUpdate
                                                                   lastStartupUpdate:lastStartupUpdate
                                                                lastServerTimeOffset:@0
                                                                                 gap:gap
                                                                 underlyingCondition:underlyingCondition];
        });
        it(@"Should return NO", ^{
            [[theValue(condition.shouldExecute) should] beNo];
        });
        it(@"Should not call underlying condition", ^{
            [[underlyingCondition shouldNot] receive:@selector(shouldExecute)];
            [condition shouldExecute];
        });
    });
    it(@"Should comform to AMAExecutionCondition", ^{
        [[condition should] conformToProtocol:@protocol(AMAExecutionCondition)];
    });
});

SPEC_END
