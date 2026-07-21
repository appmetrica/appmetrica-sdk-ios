#import "AMAModulesController.h"
#import "AMAModuleEntryPointDiscoverer.h"
#import "AMAModuleRegistrarImpl.h"
#import "AMAModuleRegistry.h"
#import "AMALegacyModuleRegistrationCoordinator.h"
#import "AMAReporter.h"
#import "AMACore.h"
#import "AMAStartupStorageProvider.h"
#import "AMACachingStorageProvider.h"

@interface AMAModulesController ()

@property (nonatomic, strong) NSMutableOrderedSet<id<AMAModuleEntryPoint>> *entryPoints;
@property (nonatomic, strong) id<AMAAsyncExecuting> executor;
@property (nonatomic, strong) id<AMAModuleEntryPointDiscovering> discoverer;
@property (nonatomic, strong) AMAModuleRegistrarImpl *registrar;
@property (nonatomic, strong, nullable) AMAModuleRegistry *registry;
@property (nonatomic, strong, nullable) AMALegacyModuleRegistrationCoordinator *registrationCoordinator;
@property (nonatomic) dispatch_once_t moduleLoadingOnce;

@end

@implementation AMAModulesController

- (instancetype)init
{
    id<AMAAsyncExecuting> executor = [[AMAExecutor alloc] initWithIdentifier:self];
    return [self initWithExecutor:executor
        registrationCoordinator:nil
        startupParametersHandler:nil];
}

- (instancetype)initWithExecutor:(id<AMAAsyncExecuting>)executor
        registrationCoordinator:(AMALegacyModuleRegistrationCoordinator *)registrationCoordinator
        startupParametersHandler:(AMAStartupParametersHandler)startupParametersHandler
{
    id<AMAModuleEntryPointDiscovering> discoverer =
        [[AMAModuleEntryPointDiscoverer alloc] initWithClassLookup:nil];
    return [self initWithExecutor:executor
                       discoverer:discoverer
           registrationCoordinator:registrationCoordinator
         startupParametersHandler:startupParametersHandler];
}

- (instancetype)initWithExecutor:(id<AMAAsyncExecuting>)executor
                       discoverer:(id<AMAModuleEntryPointDiscovering>)discoverer
           registrationCoordinator:(AMALegacyModuleRegistrationCoordinator *)registrationCoordinator
         startupParametersHandler:(AMAStartupParametersHandler)startupParametersHandler
{
    self = [super init];
    if (self != nil) {
        _entryPoints = [NSMutableOrderedSet orderedSet];
        _executor = executor;
        _discoverer = discoverer;
        _registrar = [[AMAModuleRegistrarImpl alloc] init];
        _registrationCoordinator = registrationCoordinator;
        _startupParametersHandler = [startupParametersHandler copy];
    }
    return self;
}

#pragma mark - Loading

- (void)startLoading
{
    dispatch_once(&_moduleLoadingOnce, ^{
        [self.executor execute:^{
            [self.registrationCoordinator beginRegistrationWithRegistrar:self.registrar];
            for (id<AMAModuleEntryPoint> entryPoint in [self.discoverer discoverEntryPoints]) {
                [self registerEntryPoint:entryPoint];
            }
            [self.registrationCoordinator completeRegistrationWithRegistrar:self.registrar];
            self.registry = [self.registrar publishRegistryWithEntryPoints:self.entryPoints.array];
            [self setupStartupObserversFromRegistry:self.registry];
        }];
    });
}

- (void)registerEntryPoint:(id<AMAModuleEntryPoint>)entryPoint
{
    if (entryPoint == nil || self.registry != nil) {
        AMALogError(@"Ignoring entry point registration after registry publication: %@", entryPoint);
        return;
    }
    if ([self.entryPoints containsObject:entryPoint]) {
        return;
    }

    [self.entryPoints addObject:entryPoint];
    @try {
        [entryPoint registerComponentsWithRegistrar:self.registrar];
    }
    @catch (NSException *exception) {
        AMALogError(@"Entry point %@ failed during component registration: %@", entryPoint, exception);
    }
}

#pragma mark - Activation lifecycle

- (void)performActivationWithAppMetricaConfiguration:(AMAAppMetricaConfiguration *)configuration
                                     activationBlock:(dispatch_block_t)activationBlock
{
    AMAModuleActivationConfiguration *moduleConfiguration =
        [[AMAModuleActivationConfiguration alloc] initWithApiKey:configuration.APIKey
                                                      appVersion:configuration.appVersion
                                                  appBuildNumber:configuration.appBuildNumber];
    [self.executor execute:^{
        for (id<AMAModulePreActivationHandler> handler in self.registry.preActivationHandlers) {
            [handler handlePreActivationWithConfiguration:moduleConfiguration];
        }
        for (Class<AMAModuleActivationDelegate> delegate in self.registry.activationDelegates) {
            [delegate willActivateWithConfiguration:moduleConfiguration];
        }
    }];

    @try {
        if (activationBlock != nil) {
            activationBlock();
        }
    }
    @finally {
        [self.executor execute:^{
            for (Class<AMAModuleActivationDelegate> delegate in self.registry.activationDelegates) {
                [delegate didActivateWithConfiguration:moduleConfiguration];
            }
        }];
    }
}

#pragma mark - Startup observers

- (void)setupStartupObserversFromRegistry:(AMAModuleRegistry *)registry
{
    AMAStartupStorageProvider *startupStorageProvider = [[AMAStartupStorageProvider alloc] init];
    AMACachingStorageProvider *cachingStorageProvider = [[AMACachingStorageProvider alloc] init];

    AMALogInfo(@"Setup extended startup observers: %@", registry.startupObservers);
    for (id<AMAExtendedStartupObserving> observer in registry.startupObservers) {
        [observer setupStartupProvider:startupStorageProvider
                cachingStorageProvider:cachingStorageProvider];

        if (self.startupParametersHandler != nil) {
            NSDictionary *params = [observer startupParameters];
            if (params.count > 0) {
                self.startupParametersHandler(params);
            }
        }
    }
}

- (void)notifyStartupUpdatedWithParameters:(NSDictionary *)parameters
{
    [self.executor execute:^{
        AMALogInfo(@"Notify about extended startup %lu observers", (unsigned long)self.registry.startupObservers.count);
        for (id<AMAExtendedStartupObserving> observer in self.registry.startupObservers) {
            [observer startupUpdatedWithParameters:parameters];
        }
    }];
}

- (void)notifyStartupFailedWithError:(NSError *)error
{
    [self.executor execute:^{
        AMALogInfo(@"Notify about extended startup failure %lu observers", (unsigned long)self.registry.startupObservers.count);
        for (id<AMAExtendedStartupObserving> observer in self.registry.startupObservers) {
            if ([observer respondsToSelector:@selector(startupUpdateFailedWithError:)]) {
                [observer startupUpdateFailedWithError:error];
            }
        }
    }];
}

#pragma mark - Reporter storage and polling

- (void)setupReporterStorageWithProvider:(id<AMAKeyValueStorageProviding>)provider
                                    main:(BOOL)main
                                  apiKey:(NSString *)apiKey
{
    [self.executor execute:^{
        AMALogInfo(@"Setup reporter for extended storage %lu controllers",
                   (unsigned long)self.registry.storageControllers.count);
        for (id<AMAReporterStorageControlling> controller in self.registry.storageControllers) {
            [controller setupWithReporterStorage:provider main:main forAPIKey:apiKey];
        }
    }];
}

- (void)addPollingEventsToReporter:(AMAReporter *)reporter
{
    [self.executor execute:^{
        NSArray<AMAEventPollingParameters *> *events =
            [AMACollectionUtilities flatMapArray:self.registry.pollingDelegates
                                       withBlock:^NSArray *(Class<AMAEventPollingDelegate> delegate) {
                return [delegate pollingEvents];
            }];
        for (AMAEventPollingParameters *params in events) {
            [reporter reportPollingEvent:params onFailure:nil];
        }
    }];
}

- (void)setupAppEnvironmentWithContainer:(AMAEnvironmentContainer *)appEnvironment
{
    [self.executor execute:^{
        AMALogInfo(@"Setup app environment for extended event polling %lu delegates",
                   (unsigned long)self.registry.pollingDelegates.count);
        for (Class<AMAEventPollingDelegate> delegate in self.registry.pollingDelegates) {
            [delegate setupAppEnvironment:appEnvironment];
        }
    }];
}

#pragma mark - Event flushing

- (void)notifySendEventsBuffer
{
    [self.executor execute:^{
        for (Class<AMAEventFlushableDelegate> delegate in self.registry.flushableDelegates) {
            [delegate sendEventsBuffer];
        }
    }];
}

#pragma mark - Ad provider

- (void)resolveModuleAdProviderWithHandler:(AMAModuleAdProviderHandler)handler
{
    [self.executor execute:^{
        if (handler != nil) {
            handler(self.registry.adProvider);
        }
    }];
}

@end
