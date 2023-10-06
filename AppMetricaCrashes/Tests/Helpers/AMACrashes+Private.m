
#import "AMACrashes+Private.h"

@implementation AMACrashes (Test)

- (NSDictionary *)crashContext
{
    return [AMACrashLoader crashContext];
}

@end
