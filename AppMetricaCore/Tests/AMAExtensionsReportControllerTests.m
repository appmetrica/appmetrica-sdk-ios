
#import <Kiwi/Kiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMAExtensionsReportController.h"
#import "AMAExtensionReportProvider.h"
#import "AMAExtensionsReportExecutionConditionProvider.h"
#import "AMAInternalEventsReporter.h"

SPEC_BEGIN(AMAExtensionsReportControllerTests)

describe(@"AMAExtensionsReportController", ^{

    NSDictionary *const report = @{ @"foo": @"bar" };
    NSTimeInterval const launchDelay = 23.42;

    AMAInternalEventsReporter *__block internalReporter = nil;
    AMAExtensionsReportExecutionConditionProvider *__block conditionProvider = nil;
    NSObject<AMAExecutionCondition> *__block condition = nil;
    AMAExtensionReportProvider *__block reportProvider = nil;
    NSObject<AMADelayedExecuting> *__block executor = nil;
    AMAExtensionsReportController *__block controller = nil;

    beforeEach(^{
        condition = [KWMock nullMockForProtocol:@protocol(AMAExecutionCondition)];

        internalReporter = [AMAInternalEventsReporter nullMock];
        conditionProvider = [AMAExtensionsReportExecutionConditionProvider nullMock];
        reportProvider = [AMAExtensionReportProvider nullMock];
        executor = [[AMACurrentQueueExecutor alloc] init];

        [conditionProvider stub:@selector(enabled) andReturn:theValue(YES)];
        [condition stub:@selector(shouldExecute) andReturn:theValue(YES)];
        [conditionProvider stub:@selector(executionCondition) andReturn:condition];
        [conditionProvider stub:@selector(launchDelay) andReturn:theValue(launchDelay)];
        [reportProvider stub:@selector(report) andReturn:report];

        controller = [[AMAExtensionsReportController alloc] initWithReporter:internalReporter
                                                           conditionProvider:conditionProvider
                                                                    provider:reportProvider
                                                                    executor:executor];
    });

    it(@"Should report", ^{
        [[internalReporter should] receive:@selector(reportExtensionsReportWithParameters:) withArguments:report];
        [controller reportIfNeeded];
    });
    it(@"Should after startup is updated", ^{
        [[internalReporter should] receive:@selector(reportExtensionsReportWithParameters:)];
        [controller startupUpdateCompletedWithConfiguration:nil];
    });
    context(@"Executor", ^{
        AMAManualCurrentQueueExecutor *__block manualExecutor = nil;
        beforeEach(^{
            manualExecutor = [[AMAManualCurrentQueueExecutor alloc] init];
            controller = [[AMAExtensionsReportController alloc] initWithReporter:internalReporter
                                                               conditionProvider:conditionProvider
                                                                        provider:reportProvider
                                                                        executor:manualExecutor];
        });
        it(@"Should not report outside executor", ^{
            [[internalReporter shouldNot] receive:@selector(reportExtensionsReportWithParameters:)];
            [controller reportIfNeeded];
        });
        it(@"Should report after execution started", ^{
            [[internalReporter should] receive:@selector(reportExtensionsReportWithParameters:)];
            [controller reportIfNeeded];
            [manualExecutor execute];
        });
        it(@"Should pass valid delay", ^{
            KWCaptureSpy *spy = [manualExecutor captureArgument:@selector(executeAfterDelay:block:) atIndex:0];
            [controller reportIfNeeded];
            [[spy.argument should] equal:launchDelay withDelta:0.001];
        });
        it(@"Should check condition in executor", ^{
            [[internalReporter shouldNot] receive:@selector(reportExtensionsReportWithParameters:)];
            [controller reportIfNeeded];
            [condition stub:@selector(shouldExecute) andReturn:theValue(NO)];
            [manualExecutor execute];
        });
    });
    context(@"Disabled", ^{
        beforeEach(^{
            [conditionProvider stub:@selector(enabled) andReturn:theValue(NO)];
        });
        it(@"Should not run executor", ^{
            [[executor shouldNot] receive:@selector(executeAfterDelay:block:)];
            [controller reportIfNeeded];
        });
        it(@"Should not report", ^{
            [[internalReporter shouldNot] receive:@selector(reportExtensionsReportWithParameters:)];
            [controller reportIfNeeded];
        });
    });
    context(@"Condition not passed", ^{
        beforeEach(^{
            [condition stub:@selector(shouldExecute) andReturn:theValue(NO)];
        });
        it(@"Should not run executor", ^{
            [[executor shouldNot] receive:@selector(executeAfterDelay:block:)];
            [controller reportIfNeeded];
        });
        it(@"Should not report", ^{
            [[internalReporter shouldNot] receive:@selector(reportExtensionsReportWithParameters:)];
            [controller reportIfNeeded];
        });
    });
    
    it(@"Should conform to AMAStartupCompletionObserving", ^{
        [[controller should] conformToProtocol:@protocol(AMAStartupCompletionObserving)];
    });
});

SPEC_END
