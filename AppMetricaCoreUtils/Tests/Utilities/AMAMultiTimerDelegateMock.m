#import "AMAMultiTimerDelegateMock.h"

@implementation AMAMultiTimerDelegateMock

- (void)multitimerDidFire:(AMAMultiTimer *)multitimer
{
    [self.fireCalledExpectation fulfill];
    if (self.invalidateTimer) {
        [multitimer invalidate];
    }
}

@end
