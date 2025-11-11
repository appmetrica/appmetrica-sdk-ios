
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>

SPEC_BEGIN(AMAIntervalExecutionConditionTests)

describe(@"AMAIntervalExecutionCondition", ^{

    NSTimeInterval const interval = 23;
    NSObject<AMAExecutionCondition> *__block underlyingCondition = nil;

    AMAIntervalExecutionCondition *__block condition = nil;
    AMADateProviderMock *__block dateProvider = nil;

    beforeEach(^{
        underlyingCondition = [KWMock nullMockForProtocol:@protocol(AMAExecutionCondition)];
        dateProvider = [[AMADateProviderMock alloc] init];
    });

    context(@"Fisrt execution", ^{
        __auto_type test = ^(id lastExecuted) {
            beforeEach(^{
                condition = [[AMAIntervalExecutionCondition alloc] initWithLastExecuted:lastExecuted
                                                                               interval:interval
                                                                    underlyingCondition:underlyingCondition
                                                                           dateProvider:dateProvider];
            });
            context(@"Undelying condition returns YES", ^{
                
                it(@"Should return YES", ^{
                    [underlyingCondition stub:@selector(shouldExecute) andReturn:theValue(YES)];
                    [[theValue([condition shouldExecute]) should] beYes];
                });
                it(@"Should call undelying condition", ^{
                    [underlyingCondition stub:@selector(shouldExecute) andReturn:theValue(YES)];
                    [[underlyingCondition should] receive:@selector(shouldExecute)];
                    [condition shouldExecute];
                });
            });
            context(@"Undelying condition returns NO", ^{
                
                it(@"Should return NO", ^{
                    [underlyingCondition stub:@selector(shouldExecute) andReturn:theValue(NO)];
                    [[theValue([condition shouldExecute]) should] beNo];
                });
                it(@"Should call undelying condition", ^{
                    [underlyingCondition stub:@selector(shouldExecute) andReturn:theValue(YES)];
                    [[underlyingCondition should] receive:@selector(shouldExecute)];
                    [condition shouldExecute];
                });
            });
            it(@"Should return YES if undelying condition is nil", ^{
                condition = [[AMAIntervalExecutionCondition alloc] initWithLastExecuted:nil
                                                                               interval:interval
                                                                    underlyingCondition:nil];
                [[theValue([condition shouldExecute]) should] beYes];
            });
        };
        
        context(@"lastExecuted is nil", ^{
            test(nil);
        });
        context(@"lastExecuted is distantPast", ^{
            test(NSDate.distantPast);
        });
    });

    context(@"Before interval", ^{
        beforeEach(^{
            NSDate *date = [dateProvider freeze];
            condition = [[AMAIntervalExecutionCondition alloc] initWithLastExecuted:[date dateByAddingTimeInterval:-16]
                                                                           interval:interval
                                                                underlyingCondition:underlyingCondition
                                                                       dateProvider:dateProvider];
        });
        it(@"Should return NO", ^{
            [[theValue([condition shouldExecute]) should] beNo];
        });
        it(@"Should not call underlying condition", ^{
            [[underlyingCondition shouldNot] receive:@selector(shouldExecute)];
            [condition shouldExecute];
        });
    });

    context(@"After interval", ^{
        beforeEach(^{
            NSDate *date = [dateProvider freeze];
            condition = [[AMAIntervalExecutionCondition alloc] initWithLastExecuted:[date dateByAddingTimeInterval:-42]
                                                                           interval:interval
                                                                underlyingCondition:underlyingCondition
                                                                       dateProvider:dateProvider];
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
            condition = [[AMAIntervalExecutionCondition alloc] initWithLastExecuted:nil
                                                                           interval:interval
                                                                underlyingCondition:nil];
            [[theValue([condition shouldExecute]) should] beYes];
        });
    });
    
    it(@"Should comform to AMAExecutionCondition", ^{
        [[condition should] conformToProtocol:@protocol(AMAExecutionCondition)];
    });
});

SPEC_END
