
#import "AMAAsyncCancellableExecutorMock.h"

@interface AMAAsyncCancellableExecutorMock ()

@end

@implementation AMAAsyncCancellableExecutorMock

- (void)execute:(dispatch_block_t)block
{
    block();
}

- (void)executeAfterDelay:(NSTimeInterval)delay block:(dispatch_block_t)block 
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
