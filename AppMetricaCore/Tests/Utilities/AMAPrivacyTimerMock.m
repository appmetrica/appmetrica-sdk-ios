#import "AMAPrivacyTimerMock.h"

@class AMAMultitimer;

@interface AMAPrivacyTimer (Private)

- (void)multitimerDidFire:(AMAMultitimer *)multitimer;

@end


@implementation AMAPrivacyTimerMock

- (void)multitimerDidFire:(AMAMultitimer *)multitimer
{
    [self.onTimerLock lock];
    [super multitimerDidFire:multitimer];
    [self.onTimerExpectation fulfill];
    // exception should not happen, just unlock without catching
    [self.onTimerLock unlock];
}

@end
