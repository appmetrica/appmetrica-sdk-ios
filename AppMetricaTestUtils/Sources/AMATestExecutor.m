
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>

@interface AMATestDelayedManualExecutor ()

@property (nonatomic, copy) AMAExecutingBlock executionBlock;
@property (nonatomic, assign) NSTimeInterval delayInterval;

@end

@implementation AMATestDelayedManualExecutor

- (void)executeAfterDelay:(NSTimeInterval)delay block:(AMAExecutingBlock)block
{
    self.delayInterval = delay;
    self.executionBlock = block;
}

- (void)cancelDelayed
{
    self.executionBlock = nil;
    self.delayInterval = 0;
}

- (void)execute:(AMAExecutingBlock)block
{
    if (block != nil) {
        block();
    }
    else if (self.executionBlock != nil) {
        self.executionBlock();
    }
}

- (nullable id)syncExecute:(nonnull id  _Nullable (^)(void))block
{
    return block();
}

@end

#pragma mark - current queue

@implementation AMACurrentQueueExecutor

- (void)execute:(AMAExecutingBlock)block
{
    block();
}

- (void)executeAfterDelay:(NSTimeInterval)delay block:(AMAExecutingBlock)block
{
    [self execute:block];
}

- (void)cancelDelayed
{
}

- (nullable id)syncExecute:(id _Nullable (^)(void))block 
{
    return block();
}

- (NSThread *)thread
{
    return NSThread.currentThread;
}

@end

#pragma mark - manual

@interface AMAManualCurrentQueueExecutor ()

@property (nonatomic, strong) NSMutableArray *blocks;

@end

@implementation AMAManualCurrentQueueExecutor

- (instancetype)init
{
    self = [super init];
    if (self != nil) {
        _blocks = [NSMutableArray array];
    }
    return self;
}

- (void)execute:(AMAExecutingBlock)block
{
    @synchronized (self) {
        if (block != nil) {
            if (self.executeNonDelayedBlocksImmediately) {
                block();
            }
            else {
                [self.blocks addObject:block];
            }
        }
    }
}

- (nullable id)syncExecute:(nonnull id  _Nullable (^)(void))block 
{
    return block();
}

- (void)execute
{
    @synchronized (self) {
        NSArray *blocks = [self.blocks copy];
        [self.blocks removeAllObjects];
        for (AMAExecutingBlock block in blocks) {
            block();
        }
    }
}

- (void)executeAfterDelay:(NSTimeInterval)delay block:(AMAExecutingBlock)block
{
    [self execute:block];
}

- (void)cancelDelayed
{
}

@end
