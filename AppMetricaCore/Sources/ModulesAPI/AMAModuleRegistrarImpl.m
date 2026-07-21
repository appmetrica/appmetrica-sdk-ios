#import "AMAModuleRegistrarImpl.h"
#import "AMAModuleRegistry.h"

@interface AMAModuleRegistrarImpl ()

@property (nonatomic, strong) NSMutableOrderedSet<id<AMAModulePreActivationHandler>> *preActivationHandlers;
@property (nonatomic, strong) NSMutableOrderedSet<Class<AMAModuleActivationDelegate>> *activationDelegates;
@property (nonatomic, strong) NSMutableOrderedSet<Class<AMAEventPollingDelegate>> *pollingDelegates;
@property (nonatomic, strong) NSMutableOrderedSet<Class<AMAEventFlushableDelegate>> *flushableDelegates;
@property (nonatomic, strong) NSMutableOrderedSet<id<AMAExtendedStartupObserving>> *startupObservers;
@property (nonatomic, strong) NSMutableOrderedSet<id<AMAReporterStorageControlling>> *storageControllers;
@property (nonatomic, strong, nullable) id<AMAAdProviding> adProvider;
@property (nonatomic, strong, nullable) AMAModuleRegistry *publishedRegistry;

@end

@implementation AMAModuleRegistrarImpl

- (instancetype)init
{
    self = [super init];
    if (self != nil) {
        _preActivationHandlers = [NSMutableOrderedSet orderedSet];
        _activationDelegates = [NSMutableOrderedSet orderedSet];
        _pollingDelegates = [NSMutableOrderedSet orderedSet];
        _flushableDelegates = [NSMutableOrderedSet orderedSet];
        _startupObservers = [NSMutableOrderedSet orderedSet];
        _storageControllers = [NSMutableOrderedSet orderedSet];
    }
    return self;
}

#pragma mark - AMAModuleRegistrar

- (BOOL)canRegisterComponentNamed:(NSString *)componentName
{
    if (self.publishedRegistry != nil) {
        AMALogError(@"Ignoring late module registration for %@ after registry publication", componentName);
        return NO;
    }
    return YES;
}

- (void)registerPreActivationHandler:(id<AMAModulePreActivationHandler>)handler
{
    @synchronized (self) {
        if ([self canRegisterComponentNamed:@"pre-activation handler"]) {
            [self.preActivationHandlers addObject:handler];
        }
    }
}

- (void)registerActivationDelegate:(Class<AMAModuleActivationDelegate>)delegate
{
    @synchronized (self) {
        if ([self canRegisterComponentNamed:@"activation delegate"]) {
            [self.activationDelegates addObject:delegate];
        }
    }
}

- (void)registerEventPollingDelegate:(Class<AMAEventPollingDelegate>)delegate
{
    @synchronized (self) {
        if ([self canRegisterComponentNamed:@"polling delegate"]) {
            [self.pollingDelegates addObject:delegate];
        }
    }
}

- (void)registerEventFlushableDelegate:(Class<AMAEventFlushableDelegate>)delegate
{
    @synchronized (self) {
        if ([self canRegisterComponentNamed:@"flushable delegate"]) {
            [self.flushableDelegates addObject:delegate];
        }
    }
}

- (void)registerAdProvider:(id<AMAAdProviding>)provider
{
    @synchronized (self) {
        if ([self canRegisterComponentNamed:@"ad provider"]) {
            self.adProvider = provider;
        }
    }
}

- (void)registerServiceConfiguration:(AMAServiceConfiguration *)configuration
{
    @synchronized (self) {
        if ([self canRegisterComponentNamed:@"service configuration"] == NO) {
            return;
        }
        if (configuration.startupObserver != nil) {
            [self.startupObservers addObject:configuration.startupObserver];
        }
        if (configuration.reporterStorageController != nil) {
            [self.storageControllers addObject:configuration.reporterStorageController];
        }
    }
}

#pragma mark - Registry

- (AMAModuleRegistry *)publishRegistryWithEntryPoints:(NSArray<id<AMAModuleEntryPoint>> *)entryPoints
{
    @synchronized (self) {
        if (self.publishedRegistry == nil) {
            self.publishedRegistry = [[AMAModuleRegistry alloc]
                initWithEntryPoints:entryPoints
                preActivationHandlers:self.preActivationHandlers.array
                activationDelegates:self.activationDelegates.array
                pollingDelegates:self.pollingDelegates.array
                flushableDelegates:self.flushableDelegates.array
                startupObservers:self.startupObservers.array
                storageControllers:self.storageControllers.array
                adProvider:self.adProvider];
        }
        return self.publishedRegistry;
    }
}

@end
