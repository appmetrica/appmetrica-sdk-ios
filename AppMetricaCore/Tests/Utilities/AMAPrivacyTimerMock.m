#import "AMAPrivacyTimerMock.h"

@class AMAMultitimer;

@interface AMAPrivacyTimer (Private)

- (void)multitimerDidFire:(AMAMultitimer *)multitimer;
- (void)fireEvent;

@end


@implementation AMAPrivacyTimerMock

- (void)fireEvent
{
    if (self.disableFire) {
        return;
    }
    [super fireEvent];
}

- (void)multitimerDidFire:(AMAMultitimer *)multitimer
{
    [self.onTimerLock lock];
    [super multitimerDidFire:multitimer];
    [self.onTimerExpectation fulfill];
    // exception should not happen, just unlock without catching
    [self.onTimerLock unlock];
}

@end
