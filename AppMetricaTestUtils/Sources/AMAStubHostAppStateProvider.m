
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>

@interface AMAStubHostAppStateProvider ()

@property (nonatomic, strong) NSHashTable *hostStateDelegates;

@end

@implementation AMAStubHostAppStateProvider

@synthesize delegate = _delegate;

- (instancetype)init
{
    self = [super init];
    if (self) {
        _hostState = AMAHostAppStateBackground;
        _hostStateDelegates = [NSHashTable weakObjectsHashTable];
    }

    return self;
}

- (void)setHostState:(AMAHostAppState)hostState
{
    _hostState = hostState;
    
    NSHashTable *delegates;
    @synchronized (self.delegate) {
        delegates = [self.hostStateDelegates copy];
    }
    
    for (id<AMAHostStateProviderDelegate> delegate in delegates) {
        [delegate hostStateDidChange:self.hostState];
    }
}

- (void)setDelegate:(id<AMAHostStateProviderDelegate>)delegate
{
    @synchronized (self) {
        [self.hostStateDelegates addObject:delegate];
    }
}

- (void)forceUpdateToForeground
{
}

@end
