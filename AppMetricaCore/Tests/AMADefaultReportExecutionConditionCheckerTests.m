
#import <Kiwi/Kiwi.h>
#import "AMAStartupController.h"
#import "AMADefaultReportExecutionConditionChecker.h"

SPEC_BEGIN(AMADefaultReportExecutionConditionCheckerTests)

describe(@"AMADefaultReportExecutionConditionChecker", ^{
    AMAStartupController *__block controller = nil;
    AMADefaultReportExecutionConditionChecker *__block conditionChecker = nil;
    beforeEach(^{
        controller = [AMAStartupController nullMock];
        conditionChecker = [[AMADefaultReportExecutionConditionChecker alloc] init];
    });
    context(@"Can be executed", ^{
        context(@"Startup is up-to-date", ^{
            beforeEach(^{
                [controller stub:@selector(upToDate) andReturn:theValue(YES)];
            });
            it(@"Should return YES", ^{
                [[theValue([conditionChecker canBeExecuted:controller]) should] beYes];
            });
            it(@"Should not trigger startup update", ^{
                [[controller shouldNot] receive:@selector(update)];
                [conditionChecker canBeExecuted:controller];
            });
        });
        context(@"Startup is not up-to-date", ^{
            beforeEach(^{
                [controller stub:@selector(upToDate) andReturn:theValue(NO)];
            });
            it(@"Should return NO", ^{
                [[theValue([conditionChecker canBeExecuted:controller]) should] beNo];
            });
            it(@"Should trigger startup update", ^{
                [[controller should] receive:@selector(update)];
                [conditionChecker canBeExecuted:controller];
            });
            it(@"Should return YES if startup was updated", ^{
                [controller stub:@selector(upToDate)
                       andReturn:theValue(NO)
                           times:@1
                 afterThatReturn:theValue(YES)];
                [[theValue([conditionChecker canBeExecuted:controller]) should] beYes];
            });
        });
    });
    it(@"Should conform to AMAReportExecutionConditionChecker", ^{
        [[conditionChecker should] conformToProtocol:@protocol(AMAReportExecutionConditionChecker)];
    });
});

SPEC_END
