
#import <Kiwi/Kiwi.h>
#import "AMAStartupController.h"
#import "AMASelfReportExecutionConditionChecker.h"

SPEC_BEGIN(AMASelfReportExecutionConditionCheckerTests)

describe(@"AMASelfReportExecutionConditionChecker", ^{

    AMAStartupController *__block controller = nil;
    AMASelfReportExecutionConditionChecker *__block checker = nil;

    beforeEach(^{
        controller = [AMAStartupController nullMock];
        checker = [[AMASelfReportExecutionConditionChecker alloc] init];
    });
    context(@"Can be executed", ^{
        context(@"Startup is not up-to-date", ^{
            beforeEach(^{
                [controller stub:@selector(upToDate) andReturn:theValue(NO)];
            });
            it(@"Should be NO", ^{
                [[theValue([checker canBeExecuted:controller]) should] beNo];
            });
            it(@"Should not update startup", ^{
                [[controller shouldNot] receive:@selector(update)];
                [checker canBeExecuted:controller];
            });
        });
        context(@"Startup is up-to-date", ^{
            beforeEach(^{
                [controller stub:@selector(upToDate) andReturn:theValue(YES)];
            });
            it(@"Should be NO", ^{
                [[theValue([checker canBeExecuted:controller]) should] beYes];
            });
            it(@"Should not update startup", ^{
                [[controller shouldNot] receive:@selector(update)];
                [checker canBeExecuted:controller];
            });
        });
    });
});

SPEC_END
