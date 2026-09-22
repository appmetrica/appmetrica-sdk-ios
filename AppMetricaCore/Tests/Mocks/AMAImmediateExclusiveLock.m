#import "AMAImmediateExclusiveLock.h"

@implementation AMAImmediateExclusiveLock

- (BOOL)performWithExclusiveLock:(void (^)(void))body
{
    body();
    return YES;
}

@end
