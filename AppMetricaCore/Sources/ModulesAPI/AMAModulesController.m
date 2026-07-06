
#import "AMAModulesController.h"
#import "AMAModuleContextImpl.h"
#import "AMACoreModuleComponentsInitializer.h"
#import "AMAReporter.h"
#import "AMACore.h"
#import "AMAStartupStorageProvider.h"
#import "AMACachingStorageProvider.h"

@interface AMAModulesController ()
@property (nonatomic, strong) NSMutableArray<id<AMAModuleEntryPoint>> *modules;
@property (nonatomic, strong) id<AMAAsyncExecuting, AMASyncExecuting> executor;
@property (nonatomic, assign) dispatch_once_t loadOnce;
@property (nonatomic, strong) AMAModuleContextImpl *context;
@end

@implementation AMAModulesController

- (instancetype)init
{
    id<AMAAsyncExecuting, AMASyncExecuting> executor = [[AMAExecutor alloc] initWithIdentifier:self];
    return [self initWithExecutor:executor startupParametersHandler:nil];
}

- (instancetype)initWithExecutor:(id<AMAAsyncExecuting, AMASyncExecuting>)executor
        startupParametersHandler:(AMAStartupParametersHandler)startupParametersHandler
{
    self = [super init];
    if (self) {
        _modules = [NSMutableArray array];
        _executor = executor;
        _context = [[AMAModuleContextImpl alloc] init];
        _startupParametersHandler = [startupParametersHandler copy];
    }
    return self;
}

- (void)ensureLoaded
{
    dispatch_once(&_loadOnce, ^{
        [self.executor execute:^{
            [AMACoreModuleComponentsInitializer discoverAndRegisterInController:self classLookup:nil];
            [self notifySetupStartupStorageProvider];
        }];
    });
}

- (void)registerModule:(id<AMAModuleEntryPoint>)module
{
    [self.modules addObject:module];
    [module initModuleWithContext:self.context];
}

// MARK: - Activation lifecycle

- (void)notifyWillActivateWithConfiguration:(AMAModuleActivationConfiguration *)configuration
{
    [self.executor execute:^{
        [self.context notifyWillActivateWithConfiguration:configuration];
    }];
}

- (void)notifyDidActivateWithConfiguration:(AMAModuleActivationConfiguration *)configuration
{
    [self.executor execute:^{
        [self.context notifyDidActivateWithConfiguration:configuration];
    }];
}

// MARK: - Startup observers

- (void)notifySetupStartupStorageProvider
{
    NSSet *observers = self.context.startupObservers;
    
    AMAStartupStorageProvider *startupStorageProvider = [[AMAStartupStorageProvider alloc] init];
    AMACachingStorageProvider *cachingStorageProvider = [[AMACachingStorageProvider alloc] init];
    
    AMALogInfo(@"Setup extended startup observers: %@", observers);
    for (id<AMAExtendedStartupObserving> observer in observers) {
        [observer setupStartupProvider:startupStorageProvider
                cachingStorageProvider:cachingStorageProvider];
        
        void(^handler)(NSDictionary *) = self.startupParametersHandler;
        if (handler != nil) {
            NSDictionary *params = [observer startupParameters];
            if (params.count > 0) {
                handler(params);
            }
        }
    }
}

- (void)notifyStartupUpdatedWithParameters:(NSDictionary *)parameters
{
    [self.executor execute:^{
        NSSet *observers = self.context.startupObservers;
        AMALogInfo(@"Notify about extended startup %lu observers", (unsigned long)observers.count);
        for (id<AMAExtendedStartupObserving> observer in observers) {
            [observer startupUpdatedWithParameters:parameters];
        }
    }];
}

- (void)notifyStartupFailedWithError:(NSError *)error
{
    [self.executor execute:^{
        NSSet *observers = self.context.startupObservers;
        AMALogInfo(@"Notify about extended startup failure %lu observers", (unsigned long)observers.count);
        for (id<AMAExtendedStartupObserving> observer in observers) {
            if ([observer respondsToSelector:@selector(startupUpdateFailedWithError:)]) {
                [observer startupUpdateFailedWithError:error];
            }
        }
    }];
}

// MARK: - Reporter storage

- (void)setupReporterStorageWithProvider:(id<AMAKeyValueStorageProviding>)provider
                                    main:(BOOL)main
                                  apiKey:(NSString *)apiKey
{
    [self.executor execute:^{
        NSSet *controllers = self.context.reporterStorageControllers;
        AMALogInfo(@"Setup main reporter for extended reporter storage %lu controllers",
                   (unsigned long)controllers.count);
        for (id<AMAReporterStorageControlling> controller in controllers) {
            [controller setupWithReporterStorage:provider main:main forAPIKey:apiKey];
        }
    }];
}

// MARK: - Event polling

- (void)addPollingEventsToReporter:(AMAReporter *)reporter
{
    NSArray<AMAEventPollingParameters *> *events =
        [AMACollectionUtilities flatMapArray:[self.context.eventPollingDelegates allObjects]
                                   withBlock:^NSArray *(Class<AMAEventPollingDelegate> delegate) {
            return [delegate pollingEvents];
        }];
    for (AMAEventPollingParameters *params in events) {
        [reporter reportPollingEvent:params onFailure:nil];
    }
}

- (void)setupAppEnvironmentWithContainer:(AMAEnvironmentContainer *)appEnvironment
{
    [self.executor execute:^{
        NSSet *delegates = self.context.eventPollingDelegates;
        AMALogInfo(@"Setup app environment for extended event polling %lu delegates",
                   (unsigned long)delegates.count);
        for (id<AMAEventPollingDelegate> delegate in delegates) {
            [delegate setupAppEnvironment:appEnvironment];
        }
    }];
}

// MARK: - Event flushing

- (void)notifySendEventsBuffer
{
    [self.executor execute:^{
        [self.context notifySendEventsBuffer];
    }];
}

// MARK: - Accessors

- (id<AMAAdProviding>)adProvider
{
    return self.context.adProvider;
}

@end
