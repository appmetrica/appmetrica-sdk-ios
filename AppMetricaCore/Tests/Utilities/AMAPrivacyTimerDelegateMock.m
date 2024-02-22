
#import "AMAPrivacyTimerDelegateMock.h"

@implementation AMAPrivacyTimerDelegateMock

- (void)privacyTimerDidFire:(AMAPrivacyTimer *)privacyTimer
{
    [self.fireExpectation fulfill];
}

@end
