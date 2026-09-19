
#import "AMAMainReportExecutionConditionChecker.h"
#import "AMAStartupController.h"
#import "AMAAttributionController.h"
#import "AMAMetricaConfiguration.h"
#import "AMAMetricaPersistentConfiguration.h"

@implementation AMAMainReportExecutionConditionChecker

- (BOOL)canBeExecuted:(AMAStartupController *)startupController
{
    if (startupController.startupUpdateRequired) {
        [startupController update];
    }

    return startupController.startupUpdateRequired == NO && [AMAMetricaConfiguration sharedInstance].persistent.checkedInitialAttribution;
}


@end
