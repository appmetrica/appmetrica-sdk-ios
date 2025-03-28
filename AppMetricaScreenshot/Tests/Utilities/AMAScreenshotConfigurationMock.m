
#import "AMAScreenshotConfigurationMock.h"

@implementation AMAScreenshotConfigurationMock

- (BOOL)screenshotEnabled
{
    [self.screenshotEnabledGetterExpectation fulfill];
    return self.screenshotEnabledValue;
}

- (void)setScreenshotEnabled:(BOOL)screenshotEnabled
{
    [self.screenshotEnabledSetterExpectation fulfill];
    self.screenshotEnabledValue = screenshotEnabled;
}

@end
