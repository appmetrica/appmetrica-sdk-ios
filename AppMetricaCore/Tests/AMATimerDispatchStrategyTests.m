
#import <Kiwi/Kiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMATimerDispatchStrategy.h"
#import "AMAMetricaConfiguration.h"
#import "AMAReporterTestHelper.h"
#import "AMADispatchStrategy+Private.h"
#import "AMAReporter.h"
#import "AMAReportExecutionConditionChecker.h"
#import "AMAStartupController.h"

SPEC_BEGIN(AMATimerDispatchStrategyTests)

describe(@"AMATimerDispatchStrategy", ^{

    NSString *apiKey = @"550e8400-e29b-41d4-a716-446655440000";
    AMATimerDispatchStrategy * __block timerStrategy = nil;
    AMATestDelayedManualExecutor * __block manualExecutor = nil;
    AMAReporterTestHelper *__block reporterTestHelper = nil;
    AMAReporterStorage *__block reporterStorage = nil;
    NSObject<AMADispatchStrategyDelegate> *__block delegate = nil;
    id __block conditionChecker = nil;

    NSUInteger dispatchPeriod = 1;

    beforeEach(^{
        reporterTestHelper = [[AMAReporterTestHelper alloc] init];
        reporterStorage = reporterTestHelper.appReporter.reporterStorage;
        delegate = [KWMock nullMockForProtocol:@protocol(AMADispatchStrategyDelegate)];

        AMAMutableReporterConfiguration *configuration = [[AMAMutableReporterConfiguration alloc] initWithApiKey:apiKey];
        configuration.dispatchPeriod = dispatchPeriod;
        [[AMAMetricaConfiguration sharedInstance] stub:@selector(configurationForApiKey:) andReturn:configuration];
        conditionChecker = [KWMock nullMockForProtocol:@protocol(AMAReportExecutionConditionChecker)];

        manualExecutor = [AMATestDelayedManualExecutor new];
        timerStrategy = [[AMATimerDispatchStrategy alloc] initWithDelegate:delegate
                                                                   storage:reporterStorage
                                                                  executor:manualExecutor
                                                 executionConditionChecker:conditionChecker];
    });

    it(@"Should trigger dispatch after timeout", ^{
        [timerStrategy start];
        [[timerStrategy should] receive:@selector(triggerDispatch)];
        [timerStrategy.executor execute:nil];
    });

    it(@"Should triger with proper delayed timeout", ^{
        [timerStrategy start];
        NSTimeInterval delayInterval = manualExecutor.delayInterval;
        [[theValue(delayInterval) should] equal:theValue(dispatchPeriod)];
    });

    it(@"Shouldn't invoke dispatch after shutdown", ^{
        [timerStrategy start];
        [timerStrategy shutdown];
        [[timerStrategy shouldNot] receive:@selector(triggerDispatch)];
        [timerStrategy.executor execute:nil];

    });
    context(@"Can be executed", ^{
        AMAStartupController *__block controller = nil;
        beforeEach(^{
            controller = [AMAStartupController nullMock];
        });
        it(@"Should return YES", ^{
            [conditionChecker stub:@selector(canBeExecuted:) andReturn:theValue(YES) withArguments:controller];
            [[theValue([timerStrategy canBeExecuted:controller]) should] beYes];
        });
        it(@"Should return NO", ^{
            [conditionChecker stub:@selector(canBeExecuted:) andReturn:theValue(NO) withArguments:controller];
            [[theValue([timerStrategy canBeExecuted:controller]) should] beNo];
        });
    });
    
    it(@"Should be subclass of DispatchStrategy", ^{
        [[timerStrategy should] beKindOfClass:AMADispatchStrategy.class];
    });
});

SPEC_END
