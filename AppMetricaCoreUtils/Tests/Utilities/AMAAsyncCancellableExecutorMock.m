
#import "AMAAsyncCancellableExecutorMock.h"

@interface AMAAsyncCancellableExecutorMock ()

@end

@implementation AMAAsyncCancellableExecutorMock

- (void)execute:(AMAExecutingBlock)block
{
    block();
}

- (void)executeAfterDelay:(NSTimeInterval)delay block:(AMAExecutingBlock)block
{
    [self.executeExpectation fulfill];
    dispatch_async(dispatch_get_main_queue(), ^{
        block();
    });
}

- (void)cancelDelayed 
{
    [self.cancelExpectation fulfill];
}

@end
