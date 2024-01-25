
#import "AMAMultiTimer.h"
#import "AMAExecuting.h"
#import "AMAIterable.h"
#import "AMAArrayIterator.h"

@interface AMAMultiTimer () {
    AMAMultitimerStatus _status;
}

@property (nonatomic, nullable) id<AMAResettableIterable> iterator;
@property (nonatomic, readonly) id<AMACancelableExecuting> executor;

- (void)scheduleNextDelay;

@end

@implementation AMAMultiTimer

- (instancetype)initWithDelays:(NSArray<NSNumber *> *)delays
                      executor:(id<AMACancelableExecuting>)executor
                      delegate:(nullable id<AMAMultitimerDelegate>)delegate
{
    self = [super init];
    if (self) {
        _executor = executor;
        _iterator = [[AMAArrayIterator alloc] initWithArray:delays];
        _delegate = delegate;
    }
    return self;
}

- (AMAMultitimerStatus)status
{
    @synchronized (self) {
        return _status;
    }
}

- (void)start
{
    @synchronized (self) {
        if (_status == AMAMultitimerStatusStarted) {
            return;
        }
        [self.executor cancelDelayed];
        [self.iterator reset];
        [self scheduleNextDelay];
    }
}

- (void)invalidate
{
    @synchronized (self) {
        [self.executor cancelDelayed];
        [self.iterator reset];
        _status = AMAMultitimerStatusNotStarted;
    }
}

- (void)onTimerFired
{
    // self.status use @synchronized(self)
    if (self.status != AMAMultitimerStatusStarted) {
        return;
    }
    
    [self.delegate multitimerDidFire:self];
    @synchronized (self) {
        if (_status == AMAMultitimerStatusStarted) {
            [self scheduleNextDelay];
        }
    }
}

- (void)scheduleNextDelay
{
    NSNumber *internal = [self.iterator current];
    if (internal != nil) {
        _status = AMAMultitimerStatusStarted;
        __weak typeof(self) weakSelf = self;
        [self.iterator next];
        [self.executor executeAfterDelay:internal.doubleValue block:^{
            [weakSelf onTimerFired];
        }];
    }
    else {
        _status = AMAMultitimerStatusNotStarted;
    }
}


@end
