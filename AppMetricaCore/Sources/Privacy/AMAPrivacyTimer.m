
#import "AMAPrivacyTimer.h"
#import "AMAAdProviderProxy.h"
#import "AMAPrivacyTimerRetryPolicy.h"
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>

@interface AMAPrivacyTimer () <AMAMultiTimerDelegate>

@property (nonnull, readonly) id<AMACancelableExecuting> executor;
@property (nonnull, readonly) AMAAdProviderProxy *adProviderProxy;

@property (nonnull, readonly) id<AMAAsyncExecuting> delegateExecutor;

@property (nonatomic, nullable, strong) AMAMultiTimer *timer;
@property (nonatomic) BOOL isStarted;

- (void)createTimer;
- (void)invalidateTimer;
- (void)fireEvent;
- (BOOL)isResendPeriodOutdated;

@end

@implementation AMAPrivacyTimer

- (instancetype)initWithTimerRetryPolicy:(id<AMAPrivacyTimerRetryPolicy>)retryPolicy
                        delegateExecutor:(id<AMAAsyncExecuting>)delegateExecutor
                          adProviderProxy:(AMAAdProviderProxy *)adProviderProxy
{
    AMACancelableDelayedExecutor *executor = [[AMACancelableDelayedExecutor alloc] initWithIdentifier:self];
    return [self initWithTimerRetryPolicy:retryPolicy
                                 executor:executor
                         delegateExecutor:delegateExecutor
                          adProviderProxy:adProviderProxy];
}

- (instancetype)initWithTimerRetryPolicy:(id<AMAPrivacyTimerRetryPolicy>)retryPolicy
                                executor:(id<AMACancelableExecuting>)executor
                        delegateExecutor:(id<AMAAsyncExecuting>)delegateExecutor
                          adProviderProxy:(AMAAdProviderProxy *)adProviderProxy
{
    self = [super init];
    if (self) {
        _timerStorage = retryPolicy;
        _adProviderProxy = adProviderProxy;
        _executor = executor;
        _delegateExecutor = delegateExecutor;
    }
    return self;
}

- (void)start
{
    if (self.isStarted) {
        return;
    }
    [self invalidateTimer];
    
    if (![self isResendPeriodOutdated]) {
        return;
    }
    
    if (self.adProviderProxy.isAdvertisingTrackingEnabled) {
        [self fireEvent];
    }
    else {
        [self createTimer];
    }
}

- (void)stop
{
    if (!self.isStarted) {
        return;
    }
    [self invalidateTimer];
}

- (void)invalidateTimer
{
    AMAMultiTimer *timer;
    @synchronized (self) {
        timer = self.timer;
        self.timer = nil;
        self.isStarted = NO;
    }
    
    [timer invalidate];
}

- (void)createTimer
{
    NSArray<NSNumber *> *delays = [self.timerStorage retryPeriod] ?: @[];
    if (delays.count == 0) {
        return;
    }
    
    AMAMultiTimer *multitimer = [[AMAMultiTimer alloc] initWithDelays:delays
                                                             executor:self.executor
                                                             delegate:self];
    
    @synchronized (self) {
        if (self.isStarted) {
            return;
        }
        
        self.timer = multitimer;
        
        self.isStarted = YES;
    }
    [multitimer start];
}

- (BOOL)isResendPeriodOutdated
{
    return self.timerStorage.isResendPeriodOutdated;
}

- (void)fireEvent
{
    [self.delegateExecutor execute:^{
        [self.delegate privacyTimerDidFire:self];
    }];
}

- (void)multitimerDidFire:(AMAMultiTimer *)multitimer
{
    if (!self.isStarted) {
        return;
    }
    
    BOOL isNeedFire = [self.adProviderProxy isAdvertisingTrackingEnabled];
    
    if (isNeedFire) {
        [self invalidateTimer];
        [self fireEvent];
    }
}

@end
