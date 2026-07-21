#import "AMAModuleRegistry.h"

@implementation AMAModuleRegistry

- (instancetype)initWithEntryPoints:(NSArray<id<AMAModuleEntryPoint>> *)entryPoints
            preActivationHandlers:(NSArray<id<AMAModulePreActivationHandler>> *)preActivationHandlers
              activationDelegates:(NSArray<Class<AMAModuleActivationDelegate>> *)activationDelegates
                 pollingDelegates:(NSArray<Class<AMAEventPollingDelegate>> *)pollingDelegates
                flushableDelegates:(NSArray<Class<AMAEventFlushableDelegate>> *)flushableDelegates
                 startupObservers:(NSArray<id<AMAExtendedStartupObserving>> *)startupObservers
               storageControllers:(NSArray<id<AMAReporterStorageControlling>> *)storageControllers
                       adProvider:(id<AMAAdProviding>)adProvider
{
    self = [super init];
    if (self != nil) {
        _entryPoints = [entryPoints copy];
        _preActivationHandlers = [preActivationHandlers copy];
        _activationDelegates = [activationDelegates copy];
        _pollingDelegates = [pollingDelegates copy];
        _flushableDelegates = [flushableDelegates copy];
        _startupObservers = [startupObservers copy];
        _storageControllers = [storageControllers copy];
        _adProvider = adProvider;
    }
    return self;
}

@end
