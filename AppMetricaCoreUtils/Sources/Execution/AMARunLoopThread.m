#import "AMARunLoopThread.h"

@implementation AMARunLoopThread

- (void)main
{
    @autoreleasepool {
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        
        while (!self.isCancelled) {
            [runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        }
    }
}

@end
