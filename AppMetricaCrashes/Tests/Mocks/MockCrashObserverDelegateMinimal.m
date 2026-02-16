
#import "MockCrashObserverDelegateMinimal.h"

@implementation MockCrashObserverDelegateMinimal

- (void)didDetectCrash:(AMACrashEvent *)crashEvent
{
    self.lastCrashEvent = crashEvent;
    [self.didDetectCrashExpectation fulfill];
}

@end
