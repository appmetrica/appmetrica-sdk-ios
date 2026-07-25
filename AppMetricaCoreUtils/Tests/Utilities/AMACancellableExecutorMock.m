
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

- (void)execute:(AMAExecutingBlock)block
{
    block();
}

- (void)executeAfterDelay:(NSTimeInterval)delay block:(AMAExecutingBlock)block
{
    [_receivedDelays addObject:@(delay)];
    block();
}

- (void)cancelDelayed {
    [self.cancelExpectation fulfill];
}

@end
