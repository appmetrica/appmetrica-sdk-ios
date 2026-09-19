
#import "AMADefaultReportExecutionConditionChecker.h"
#import "AMAStartupController.h"

@implementation AMADefaultReportExecutionConditionChecker

- (BOOL)canBeExecuted:(AMAStartupController *)startupController
{
    if (startupController.startupUpdateRequired) {
        [startupController update];
    }
    return startupController.startupUpdateRequired == NO;
}


@end
