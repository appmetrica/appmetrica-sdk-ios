
#import "AMACrashLogging.h"
#import "AMAKSCrash.h"
#import "AMAANRWatchdog.h"
#import <AppMetricaPlatform/AppMetricaPlatform.h>
#import <atomic>

static const useconds_t AMAANRSleepStartInterval = 50000;
static const useconds_t AMAANRMaxSleepInterval = 1000000;

enum class AMAANRState: int {
    initial,
    observed,
};

@interface AMAANRWatchdog () {
    std::atomic<AMAANRState> predicate;
}

@property (atomic, assign, getter = isOperating) BOOL operating;
@property (nonatomic, assign) NSTimeInterval ANRDuration;
@property (nonatomic, assign) NSTimeInterval checkPeriod;

@property (nonatomic, strong) id<AMAAsyncExecuting> watchingExecutor;
@property (nonatomic, strong) id<AMAAsyncExecuting> observedExecutor;

@end

@implementation AMAANRWatchdog

# pragma mark - Lifecycle

- (instancetype)initWithWatchdogInterval:(NSTimeInterval)watchdogInterval pingInterval:(NSTimeInterval)pingInterval
{
    dispatch_queue_t watchingQueue = [AMAQueuesFactory serialQueueForIdentifierObject:self
                                                                               domain:[AMAPlatformDescription SDKBundleName]];
    AMAExecutor *watchingExecutor = [[AMAExecutor alloc] initWithQueue:watchingQueue];
    AMAExecutor *observedExecutor = [[AMAExecutor alloc] initWithQueue:dispatch_get_main_queue()];

    return [self initWithWatchdogInterval:watchdogInterval
                             pingInterval:pingInterval
                         watchingExecutor:watchingExecutor
                         observedExecutor:observedExecutor];
}

- (instancetype)initWithWatchdogInterval:(NSTimeInterval)watchdogInterval
                            pingInterval:(NSTimeInterval)pingInterval
                        watchingExecutor:(id<AMAAsyncExecuting>)watchingExecutor
                        observedExecutor:(id<AMAAsyncExecuting>)observedExecutor
{
    self = [super init];
    if (self != nil) {
        if (predicate.is_lock_free() == false) {
            AMALogWarn(@"std::atomic<AMAANRState>predicate.is_lock_free() == false");
        }
        predicate.store(AMAANRState::initial);
        _watchingExecutor = watchingExecutor;
        _observedExecutor = observedExecutor;
        
        _operating = NO;
        _ANRDuration = watchdogInterval;
        _checkPeriod = pingInterval;
    }
    return self;
}

- (void)dealloc
{
    _operating = NO;
}

# pragma mark - Public

- (void)start
{
    @synchronized (self) {
        if (self.operating == NO) {
            self.operating = YES;
            __weak typeof(self) weakSelf = self;
            [self.watchingExecutor execute:^{
                [weakSelf startMonitoring];
            }];
        }
    }
}

- (void)cancel
{
    self.operating = NO;
}

# pragma mark - Private

- (void)startMonitoring
{
    int64_t inputMinSleepTime = (int64_t)(self.ANRDuration * USEC_PER_SEC);
    useconds_t maxSleepTime = (useconds_t)MIN(inputMinSleepTime, (int64_t)AMAANRMaxSleepInterval);
    
    while (self.isOperating) {
        useconds_t sleepTime = AMAANRSleepStartInterval;
        // predicate == AMAAnrState::initial
        
        __weak typeof(self) weakSelf = self;
        [self.observedExecutor execute:^{
            typeof(self) strongSelf = weakSelf;
            if (strongSelf != nil) {
                strongSelf->predicate.store(AMAANRState::observed, std::memory_order_release);
            }
        }];

        CFTimeInterval currentTime = CFAbsoluteTimeGetCurrent();
        CFTimeInterval untilTime = currentTime + (CFTimeInterval)self.ANRDuration;
        
        // wait until observedExecutor changes stored value
        while (currentTime <= untilTime && predicate.load(std::memory_order_acquire) == AMAANRState::initial) {
            sleepTime = MIN(sleepTime * 2, maxSleepTime);
            int64_t remainTime = ((int64_t)untilTime - (int64_t)currentTime) * USEC_PER_SEC;
            useconds_t usleepArg = (useconds_t)MIN(remainTime, (int64_t)sleepTime);
            usleep(usleepArg);
            
            currentTime = CFAbsoluteTimeGetCurrent();
        }
        // if observedExecutor is not finished yet notify ANR
        if (predicate.load(std::memory_order_acquire) == AMAANRState::initial) {
            if (self.isOperating) {
                [self notifyOfANR];
            }
            
            // Wait forever for observedExecutor
            // not to report the same suspension twice
            while (predicate.load(std::memory_order_acquire) != AMAANRState::observed) {
                usleep(sleepTime);
            }
        }

        predicate.store(AMAANRState::initial);

        [NSThread sleepForTimeInterval:self.checkPeriod];
    }
}

- (void)notifyOfANR
{
    AMALogInfo(@"ANR was detected. Trying to notify the delegate.");
    if ([self.delegate respondsToSelector:@selector(ANRWatchdogDidDetectANR:)]) {
        [self.delegate ANRWatchdogDidDetectANR:self];
    }
}

@end
