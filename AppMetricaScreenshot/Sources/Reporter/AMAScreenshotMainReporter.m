
#import <AppMetricaCore/AppMetricaCore.h>
#import "AMAScreenshotMainReporter.h"
#import "AMAScreenshotEventName.h"

@implementation AMAScreenshotMainReporter

- (void)reportScreenshot
{
    [AMAAppMetrica reportEvent:AMAScreenshotEventName onFailure:nil];
}

@end
