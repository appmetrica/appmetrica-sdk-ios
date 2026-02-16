
#import "MockCrashHandler.h"
#import "AMACrashEvent.h"

@implementation MockCrashHandler

- (BOOL)shouldReportCrash:(AMACrashEvent *)crashEvent
{
    self.crashCallCount++;
    self.lastCrashEvent = crashEvent;
    return self.crashResult;
}

- (BOOL)shouldReportANR:(AMACrashEvent *)crashEvent
{
    self.anrCallCount++;
    self.lastCrashEvent = crashEvent;
    return self.anrResult;
}

@end
