#import "AMAMockScreenshotReporter.h"

@implementation AMAMockScreenshotReporter

- (void)reportScreenshot
{ 
    [self.reportScreenshotExpectation fulfill];
}

@end
