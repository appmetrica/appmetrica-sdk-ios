#import <AppMetricaHostState/AppMetricaHostState.h>
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>
#import "AMAApplicationHostStateProvider.h"
#import "AMAHostStateControllerFactory.h"


@interface AMAHostStateProvider () <AMAHostStateProviderObserver>

@property (nonatomic, nullable, weak) id<AMAHostStateControlling> hostStateController;

@end

@implementation AMAHostStateProvider

@synthesize delegate = _delegate;

+ (id<AMAHostStateControlling>)sharedHostStateController
{
    static id<AMAHostStateControlling> controller = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        AMAHostStateControllerFactory *factory = [[AMAHostStateControllerFactory alloc] init];
        controller = [factory hostStateController];
    });
    return controller;
}

- (instancetype)init
{
    self = [super init];
    if (self != nil) {
        _hostStateController = [[self class] sharedHostStateController];
        
        [_hostStateController addAMAObserver:self];
    }

    return self;
}

- (AMAHostAppState)hostState
{
    return [self.hostStateController hostState];
}

- (void)forceUpdateToForeground
{
    [self.hostStateController forceUpdateToForeground];
}

- (void)hostStateProviderDidChangeHostState
{
    [self.delegate hostStateDidChange:[self hostState]];
}

- (void)dealloc
{
    [_hostStateController removeAMAObserver:self];
}

@end
