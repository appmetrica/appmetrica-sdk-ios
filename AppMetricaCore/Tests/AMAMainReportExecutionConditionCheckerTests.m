
#import <Kiwi/Kiwi.h>
#import "AMAMainReportExecutionConditionChecker.h"
#import "AMAStartupController.h"
#import "AMAMetricaPersistentConfiguration.h"
#import "AMAMetricaConfiguration.h"

SPEC_BEGIN(AMAMainReportExecutionConditionCheckerTests)

describe(@"AMAMainReportExecutionConditionChecker", ^{

    AMAMetricaPersistentConfiguration *__block persistentConfiguration = nil;
    AMAStartupController *__block startupController = nil;
    AMAMainReportExecutionConditionChecker *__block checker = nil;

    beforeEach(^{
        startupController = [AMAStartupController nullMock];
        persistentConfiguration = [AMAMetricaPersistentConfiguration nullMock];
        AMAMetricaConfiguration *metricaConfiguration = [AMAMetricaConfiguration nullMock];
        [AMAMetricaConfiguration stub:@selector(sharedInstance) andReturn:metricaConfiguration];
        [metricaConfiguration stub:@selector(persistent) andReturn:persistentConfiguration];
        checker = [[AMAMainReportExecutionConditionChecker alloc] init];
    });
    afterEach(^{
        [AMAMetricaConfiguration clearStubs];
    });
    context(@"Can be executed", ^{
        context(@"Startup is not up-to-date", ^{
            beforeEach(^{
                [startupController stub:@selector(upToDate) andReturn:theValue(NO)];
                [persistentConfiguration stub:@selector(checkedInitialAttribution) andReturn:theValue(YES)];
            });
            it(@"Should be NO", ^{
                [[theValue([checker canBeExecuted:startupController]) should] beNo];
            });
            it(@"Should update startup", ^{
                [[startupController should] receive:@selector(update)];
                [checker canBeExecuted:startupController];
            });
            it(@"Should be YES if startup was updated", ^{
                [startupController stub:@selector(upToDate) andReturn:theValue(NO) times:@1 afterThatReturn:theValue(YES)];
                [[theValue([checker canBeExecuted:startupController]) should] beYes];
            });
            it(@"Should be YES if startup was updated but attribution was not checked", ^{
                [persistentConfiguration stub:@selector(checkedInitialAttribution) andReturn:theValue(NO)];
                [startupController stub:@selector(upToDate) andReturn:theValue(NO) times:@1 afterThatReturn:theValue(YES)];
                [[theValue([checker canBeExecuted:startupController]) should] beNo];
            });
        });
        context(@"Startup is up-to-date", ^{
            beforeEach(^{
                [startupController stub:@selector(upToDate) andReturn:theValue(YES)];
            });
            it(@"Should not update startup", ^{
                [[startupController shouldNot] receive:@selector(update)];
                [checker canBeExecuted:startupController];
            });
            it(@"Should be NO if attribution was not checked", ^{
                [persistentConfiguration stub:@selector(checkedInitialAttribution) andReturn:theValue(NO)];
                [[theValue([checker canBeExecuted:startupController]) should] beNo];
            });
            it(@"Should be YES if attribution was checked", ^{
                [persistentConfiguration stub:@selector(checkedInitialAttribution) andReturn:theValue(YES)];
                [[theValue([checker canBeExecuted:startupController]) should] beYes];
            });
        });
    });
    
    it(@"Should AMAReportExecutionConditionChecker", ^{
        [[checker should] conformToProtocol:@protocol(AMAReportExecutionConditionChecker)];
    });
});

SPEC_END
