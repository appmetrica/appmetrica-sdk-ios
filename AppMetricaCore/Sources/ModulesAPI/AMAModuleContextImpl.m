
#import "AMAModuleContextImpl.h"
#import "AMACore.h"
#import "AMAAdProvider.h"

@interface AMAModuleContextImpl ()
@property (nonatomic, strong) NSMutableSet<Class<AMAModuleActivationDelegate>> *activationDelegates;
@property (nonatomic, strong) NSMutableSet<Class<AMAEventPollingDelegate>> *pollingDelegates;
@property (nonatomic, strong) NSMutableSet<Class<AMAEventFlushableDelegate>> *flushableDelegates;
@property (nonatomic, strong, nullable) id<AMAAdProviding> adProvider;
@property (nonatomic, strong) NSMutableSet<id<AMAExtendedStartupObserving>> *mutableStartupObservers;
@property (nonatomic, strong) NSMutableSet<id<AMAReporterStorageControlling>> *mutableStorageControllers;
@end

@implementation AMAModuleContextImpl

- (instancetype)init
{
    self = [super init];
    if (self) {
        _activationDelegates = [NSMutableSet set];
        _pollingDelegates = [NSMutableSet set];
        _flushableDelegates = [NSMutableSet set];
        _mutableStartupObservers = [NSMutableSet set];
        _mutableStorageControllers = [NSMutableSet set];
    }
    return self;
}

#pragma mark - AMAModuleContext

- (void)addActivationDelegate:(Class<AMAModuleActivationDelegate>)delegate
{
    @synchronized(self) {
        [self.activationDelegates addObject:delegate];
    }
}

- (void)addEventPollingDelegate:(Class<AMAEventPollingDelegate>)delegate
{
    @synchronized(self) {
        [self.pollingDelegates addObject:delegate];
    }
}

- (void)addEventFlushableDelegate:(Class<AMAEventFlushableDelegate>)delegate
{
    @synchronized(self) {
        [self.flushableDelegates addObject:delegate];
    }
}

- (void)registerAdProvider:(id<AMAAdProviding>)provider
{
    @synchronized(self) {
        if ([AMAAppMetrica isActivated] == NO) {
            self.adProvider = provider;
        } else {
            [[AMAAdProvider sharedInstance] setupAdProvider:provider];
        }
    }
}

- (void)registerExternalService:(AMAServiceConfiguration *)configuration
{
    @synchronized(self) {
        if (configuration.startupObserver != nil) {
            [self.mutableStartupObservers addObject:configuration.startupObserver];
        }
        if (configuration.reporterStorageController != nil) {
            [self.mutableStorageControllers addObject:configuration.reporterStorageController];
        }
    }
}

#pragma mark - Internal notify (called by AMAModulesController)

- (void)notifyWillActivateWithConfiguration:(AMAModuleActivationConfiguration *)configuration
{
    NSSet *snapshot;
    @synchronized(self) { snapshot = [self.activationDelegates copy]; }
    for (Class<AMAModuleActivationDelegate> delegate in snapshot) {
        [delegate willActivateWithConfiguration:configuration];
    }
}

- (void)notifyDidActivateWithConfiguration:(AMAModuleActivationConfiguration *)configuration
{
    NSSet *snapshot;
    @synchronized(self) { snapshot = [self.activationDelegates copy]; }
    for (Class<AMAModuleActivationDelegate> delegate in snapshot) {
        [delegate didActivateWithConfiguration:configuration];
    }
}

- (void)notifySendEventsBuffer
{
    NSSet *snapshot;
    @synchronized(self) { snapshot = [self.flushableDelegates copy]; }
    for (Class<AMAEventFlushableDelegate> delegate in snapshot) {
        [delegate sendEventsBuffer];
    }
}

#pragma mark - Accessors

- (NSSet<Class<AMAEventPollingDelegate>> *)eventPollingDelegates
{
    @synchronized(self) { return [self.pollingDelegates copy]; }
}


- (NSSet<id<AMAExtendedStartupObserving>> *)startupObservers
{
    @synchronized(self) { return [self.mutableStartupObservers copy]; }
}

- (NSSet<id<AMAReporterStorageControlling>> *)reporterStorageControllers
{
    @synchronized(self) { return [self.mutableStorageControllers copy]; }
}

@end
