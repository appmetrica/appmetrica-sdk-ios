
#import "AMACrashBacktrace.h"

@implementation AMACrashBacktrace

- (instancetype)initWithFrames:(NSArray<AMACrashBacktraceFrame *> *)frames
{
    self = [super init];
    if (self != nil) {
        _frames = [frames copy];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

@end
