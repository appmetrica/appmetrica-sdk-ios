
#import <AppMetricaHostState/AppMetricaHostState.h>
#import "AMAExtensionHostStateProvider.h"

@interface AMAExtensionHostStateProvider ()

@property (atomic) AMAHostAppState internalHostState;
@property (nonatomic, strong) NSNotificationCenter *notificationCenter;

@end

@implementation AMAExtensionHostStateProvider

- (instancetype)init
{
    return [self initWithNotificationCenter:[NSNotificationCenter defaultCenter]];
}

- (instancetype)initWithNotificationCenter:(NSNotificationCenter *)center
{
    self = [super init];
    if (self) {
        _internalHostState = AMAHostAppStateUnknown;
        _notificationCenter = center;

        [self subscribeToNotifications];
    }

    return self;
}

- (void)dealloc
{
    [self.notificationCenter removeObserver:self];
}

- (void)subscribeToNotifications
{
    [self.notificationCenter addObserver:self
                                selector:@selector(extensionDidBecomeActive)
                                    name:NSExtensionHostDidBecomeActiveNotification
                                  object:nil];
    [self.notificationCenter addObserver:self
                                selector:@selector(extensionWillResignActive)
                                    name:NSExtensionHostWillResignActiveNotification
                                  object:nil];
}

- (void)forceUpdateToForeground
{
    [self maybeChangeStateTo:AMAHostAppStateForeground];
}

- (AMAHostAppState)hostState
{
    @synchronized (self) {
        return self.internalHostState == AMAHostAppStateUnknown ? AMAHostAppStateForeground : self.internalHostState;
    }
}

- (void)extensionDidBecomeActive
{
    [self maybeChangeStateTo:AMAHostAppStateForeground];
}

- (void)extensionWillResignActive
{
    [self maybeChangeStateTo:AMAHostAppStateTerminated];
}

#pragma mark - Private

- (void)maybeChangeStateTo:(AMAHostAppState)newState
{
    BOOL stateChanged = NO;
    if (self.internalHostState != newState) {
        @synchronized (self) {
            if (self.internalHostState != newState) {
                self.internalHostState = newState;
                stateChanged = YES;
            }
        }
    }
    if (stateChanged) {
        [self hostStateDidChange];
    }
}

@end
