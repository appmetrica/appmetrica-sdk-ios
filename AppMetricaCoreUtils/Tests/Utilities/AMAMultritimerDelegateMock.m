#import "AMAMultritimerDelegateMock.h"

@implementation AMAMultritimerDelegateMock

- (void)multitimerDidFire:(AMAMultiTimer *)multitimer
{
    [self.fireCalledExpectation fulfill];
    if (self.invalidateTimer) {
        [multitimer invalidate];
    }
}

@end
