
#import "AMACancellableExecutorMock.h"

@interface AMACancellableExecutorMock () {
    NSMutableArray<NSNumber *> *_receivedDelays;
}

@end

@implementation AMACancellableExecutorMock

- (instancetype)init
{
    self = [super init];
    if (self) {
        _receivedDelays = [NSMutableArray array];
    }
    return self;
}

- (NSArray<NSNumber *> *)receivedDelays
{
    return _receivedDelays.copy;
}

- (void)execute:(dispatch_block_t)block
{
    block();
}

- (void)executeAfterDelay:(NSTimeInterval)delay block:(dispatch_block_t)block
{
    [_receivedDelays addObject:@(delay)];
    block();
}

- (void)cancelDelayed {
    [self.cancelExpectation fulfill];
}

@end
