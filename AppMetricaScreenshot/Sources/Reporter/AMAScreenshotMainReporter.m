
#import <AppMetricaCoreExtension/AppMetricaCoreExtension.h>
#import "AMAScreenshotMainReporter.h"
#import "AMAScreenshotEventName.h"

@implementation AMAScreenshotMainReporter

- (void)reportScreenshot
{
    [AMAAppMetrica reportSystemEvent:AMAScreenshotEventName onFailure:nil];
}

@end
