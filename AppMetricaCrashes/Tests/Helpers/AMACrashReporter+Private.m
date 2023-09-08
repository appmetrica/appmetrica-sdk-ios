
#import "AMACrashReporter+Private.h"

@implementation AMACrashReporter (Test)

- (NSDictionary *)crashContext
{
    return [AMACrashLoader crashContext];
}

@end
