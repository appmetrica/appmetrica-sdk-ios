
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>

@interface AMATestDelayedManualExecutor ()

@property (nonatomic, copy) dispatch_block_t executionBlock;
@property (nonatomic, assign) NSTimeInterval delayInterval;

@end

@implementation AMATestDelayedManualExecutor

- (void)executeAfterDelay:(NSTimeInterval)delay block:(dispatch_block_t)block
{
    self.delayInterval = delay;
    self.executionBlock = block;
}

- (void)cancelDelayed
{
    self.executionBlock = nil;
    self.delayInterval = 0;
}

- (void)execute:(dispatch_block_t)block
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

- (void)execute:(dispatch_block_t)block
{
    block();
}

- (void)executeAfterDelay:(NSTimeInterval)delay block:(dispatch_block_t)block
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

- (void)execute:(dispatch_block_t)block
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
        for (dispatch_block_t block in blocks) {
            block();
        }
    }
}

- (void)executeAfterDelay:(NSTimeInterval)delay block:(dispatch_block_t)block
{
    [self execute:block];
}

- (void)cancelDelayed
{
}

@end
