
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>

SPEC_BEGIN(AMAFirstExecutionConditionTests)

describe(@"AMAFirstExecutionCondition", ^{

    NSTimeInterval const delay = 23;

    NSDate *__block firstStartupUpdate = nil;
    NSDate *__block lastStartupUpdate = nil;
    AMAFirstExecutionCondition *__block condition = nil;
    NSObject<AMAExecutionCondition> *__block underlyingCondition = nil;

    beforeEach(^{
        underlyingCondition = [KWMock nullMockForProtocol:@protocol(AMAExecutionCondition)];
    });

    context(@"First execution", ^{
        __auto_type test = ^(id lastExecuted) {
            context(@"No first startup", ^{
                beforeEach(^{
                    condition = [[AMAFirstExecutionCondition alloc] initWithFirstStartupUpdate:nil
                                                                             lastStartupUpdate:nil
                                                                                  lastExecuted:lastExecuted
                                                                          lastServerTimeOffset:nil
                                                                                         delay:delay
                                                                           underlyingCondition:underlyingCondition];
                });
                it(@"Should return NO", ^{
                    [[theValue([condition shouldExecute]) should] beNo];
                });
                it(@"Should not call underlying condition", ^{
                    [[underlyingCondition shouldNot] receive:@selector(shouldExecute)];
                    [condition shouldExecute];
                });
            });
            context(@"Before delay", ^{
                beforeEach(^{
                    firstStartupUpdate = [NSDate dateWithTimeIntervalSince1970:4];
                    lastStartupUpdate = [NSDate dateWithTimeIntervalSince1970:8];
                    condition = [[AMAFirstExecutionCondition alloc] initWithFirstStartupUpdate:firstStartupUpdate
                                                                             lastStartupUpdate:lastStartupUpdate
                                                                                  lastExecuted:lastExecuted
                                                                          lastServerTimeOffset:@0
                                                                                         delay:delay
                                                                           underlyingCondition:underlyingCondition];
                });
                it(@"Should return NO", ^{
                    [[theValue([condition shouldExecute]) should] beNo];
                });
                it(@"Should not call underlying condition", ^{
                    [[underlyingCondition shouldNot] receive:@selector(shouldExecute)];
                    [condition shouldExecute];
                });
            });
            context(@"After delay", ^{
                beforeEach(^{
                    firstStartupUpdate = [NSDate dateWithTimeIntervalSince1970:4];
                    lastStartupUpdate = [NSDate dateWithTimeIntervalSince1970:42];
                    condition = [[AMAFirstExecutionCondition alloc] initWithFirstStartupUpdate:firstStartupUpdate
                                                                             lastStartupUpdate:lastStartupUpdate
                                                                                  lastExecuted:lastExecuted
                                                                          lastServerTimeOffset:@0
                                                                                         delay:delay
                                                                           underlyingCondition:underlyingCondition];
                });
                it(@"Should return YES if undelying condition returns YES", ^{
                    [underlyingCondition stub:@selector(shouldExecute) andReturn:theValue(YES)];
                    [[theValue([condition shouldExecute]) should] beYes];
                });
                it(@"Should return NO if undelying condition returns NO", ^{
                    [underlyingCondition stub:@selector(shouldExecute) andReturn:theValue(NO)];
                    [[theValue([condition shouldExecute]) should] beNo];
                });
                it(@"Should return YES if undelying condition is nil", ^{
                    condition = [[AMAFirstExecutionCondition alloc] initWithFirstStartupUpdate:firstStartupUpdate
                                                                             lastStartupUpdate:lastStartupUpdate
                                                                                  lastExecuted:lastExecuted
                                                                          lastServerTimeOffset:@0
                                                                                         delay:delay
                                                                           underlyingCondition:nil];
                    [[theValue([condition shouldExecute]) should] beYes];
                });
            });
        };
        context(@"lastExecuted is nil", ^{
            test(nil);
        });
        context(@"lastExecuted is distantPast", ^{
            test(NSDate.distantPast);
        });
    });

    context(@"Not the first execution", ^{
        beforeEach(^{
            firstStartupUpdate = [NSDate dateWithTimeIntervalSince1970:4];
            lastStartupUpdate = [NSDate dateWithTimeIntervalSince1970:42];
            NSDate *lastExecuted = [NSDate dateWithTimeIntervalSince1970:16];
            condition = [[AMAFirstExecutionCondition alloc] initWithFirstStartupUpdate:firstStartupUpdate
                                                                     lastStartupUpdate:lastStartupUpdate
                                                                          lastExecuted:lastExecuted
                                                                  lastServerTimeOffset:@0
                                                                                 delay:delay
                                                                   underlyingCondition:underlyingCondition];
        });
        it(@"Should return YES if undelying condition returns YES", ^{
            [underlyingCondition stub:@selector(shouldExecute) andReturn:theValue(YES)];
            [[theValue([condition shouldExecute]) should] beYes];
        });
        it(@"Should return NO if undelying condition returns NO", ^{
            [underlyingCondition stub:@selector(shouldExecute) andReturn:theValue(NO)];
            [[theValue([condition shouldExecute]) should] beNo];
        });
        it(@"Should return YES if undelying condition is nil", ^{
            condition = [[AMAFirstExecutionCondition alloc] initWithFirstStartupUpdate:firstStartupUpdate
                                                                     lastStartupUpdate:lastStartupUpdate
                                                                          lastExecuted:nil
                                                                  lastServerTimeOffset:@0
                                                                                 delay:delay
                                                                   underlyingCondition:nil];
            [[theValue([condition shouldExecute]) should] beYes];
        });
    });
    
    it(@"Should comform to AMAExecutionCondition", ^{
        [[condition should] conformToProtocol:@protocol(AMAExecutionCondition)];
    });
});

SPEC_END
