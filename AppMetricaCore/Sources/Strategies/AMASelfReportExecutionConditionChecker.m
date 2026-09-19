
#import "AMASelfReportExecutionConditionChecker.h"
#import "AMAStartupController.h"

@implementation AMASelfReportExecutionConditionChecker

- (BOOL)canBeExecuted:(AMAStartupController *)startupController
{
    return startupController.startupUpdateRequired == NO;
}

@end
