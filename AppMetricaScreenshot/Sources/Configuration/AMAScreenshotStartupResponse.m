
#import "AMAScreenshotStartupResponse.h"

static BOOL AMAScreenshotFeatureDefaultEnabled = YES;

@implementation AMAScreenshotStartupResponse

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.featureEnabled = AMAScreenshotFeatureDefaultEnabled;
        self.captorEnabled = AMAScreenshotFeatureDefaultEnabled;
    }
    return self;
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[AMAScreenshotStartupResponse class]]) {
        AMAScreenshotStartupResponse *other = object;
        return self.featureEnabled == other.featureEnabled &&
            self.captorEnabled == other.captorEnabled;
    }
    return NO;
}

@end
