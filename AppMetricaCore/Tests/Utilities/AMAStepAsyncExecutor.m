#import "AMAStepAsyncExecutor.h"

@interface AMAStepAsyncExecutor ()

@property (nonatomic, strong) NSCondition *condition;
@property (nonatomic, strong) NSMutableArray<dispatch_block_t> *pendingBlocks;
@property (nonatomic) BOOL running;

@end


@implementation AMAStepAsyncExecutor

- (instancetype)init
{
    self = [super init];
    if (self != nil) {
        _condition = [[NSCondition alloc] init];
        _pendingBlocks = [NSMutableArray array];
    }
    return self;
}

- (void)execute:(dispatch_block_t)block
{
    if (block == nil) {
        return;
    }
    [self.condition lock];
    [self.pendingBlocks addObject:[block copy]];
    [self.condition broadcast];
    [self.condition unlock];
}

- (NSUInteger)pendingBlockCount
{
    [self.condition lock];
    NSUInteger count = self.pendingBlocks.count;
    [self.condition unlock];
    return count;
}

- (BOOL)runNext
{
    [self.condition lock];
    if (self.running || self.pendingBlocks.count == 0) {
        [self.condition unlock];
        return NO;
    }
    self.running = YES;
    dispatch_block_t block = self.pendingBlocks.firstObject;
    [self.pendingBlocks removeObjectAtIndex:0];
    [self.condition unlock];

    @try {
        block();
    }
    @finally {
        [self.condition lock];
        self.running = NO;
        [self.condition broadcast];
        [self.condition unlock];
    }
    return YES;
}

- (void)runUntilIdle
{
    while ([self runNext]) {
    }
}

- (BOOL)waitForPendingBlockCount:(NSUInteger)pendingBlockCount timeout:(NSTimeInterval)timeout
{
    NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:timeout];
    [self.condition lock];
    while (self.pendingBlocks.count < pendingBlockCount) {
        if ([self.condition waitUntilDate:deadline] == NO) {
            [self.condition unlock];
            return NO;
        }
    }
    [self.condition unlock];
    return YES;
}

@end
