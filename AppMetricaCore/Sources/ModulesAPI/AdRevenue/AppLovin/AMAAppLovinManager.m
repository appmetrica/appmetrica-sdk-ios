
#import "AMAAppLovinManager.h"
#import "AMAAppLovinMaxIlrdObserver.h"
#import "AMAAppLovinLog.h"
#import "Startup/AMAAppLovinStartupConfiguration.h"
#import "Startup/AMAAppLovinStartupRequestParameters.h"
#import "Startup/AMAAppLovinStartupResponseParser.h"

@interface AMAAppLovinManager ()
@property (nonatomic, strong) AMAAppLovinMaxIlrdObserver *observer;
@property (nonatomic, strong) AMAAppLovinStartupConfiguration *startupConfig;
@property (nonatomic, strong) AMAAppLovinStartupResponseParser *responseParser;
@property (nonatomic, strong) id<AMAAsyncExecuting> executor;
@property (nonatomic, strong) id<AMAStartupStorageProviding> storageProvider;
@end

@implementation AMAAppLovinManager

+ (instancetype)sharedInstance
{
    static AMAAppLovinManager *instance = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    return [self initWithExecutor:[[AMAExecutor alloc] initWithIdentifier:self]
                   responseParser:[[AMAAppLovinStartupResponseParser alloc] init]];
}

- (instancetype)initWithExecutor:(id<AMAAsyncExecuting>)executor
                  responseParser:(AMAAppLovinStartupResponseParser *)responseParser
{
    self = [super init];
    if (self) {
        _executor = executor;
        _responseParser = responseParser;
    }
    return self;
}

- (void)setup
{
    @synchronized (self) {
        if (self.observer == nil) {
            AMAAppLovinLog(@"setup observer");
            self.observer = [[AMAAppLovinMaxIlrdObserver alloc] initWithExecutor:self.executor];
        }
    }
}

// MARK: - AMAModuleActivationDelegate

+ (void)willActivateWithConfiguration:(AMAModuleActivationConfiguration *)configuration
{
}

+ (void)didActivateWithConfiguration:(AMAModuleActivationConfiguration *)configuration
{
    AMAAppLovinManager *manager = [self sharedInstance];
    [manager.executor execute:^{
        AMAAppLovinStartupConfiguration *config = manager.startupConfig;
        BOOL enabled = config != nil ? config.aramEnabled : YES;
        AMAAppLovinLog(@"didActivate, aramEnabled=%@", enabled ? @"YES" : @"NO");
        [manager.observer activateAndSubscribe:enabled];
    }];
}

// MARK: - AMAExtendedStartupObserving

- (NSDictionary *)startupParameters
{
    return @{ @"request": [AMAAppLovinStartupRequestParameters parameters] };
}

- (void)setupStartupProvider:(id<AMAStartupStorageProviding>)startupStorageProvider
      cachingStorageProvider:(id<AMACachingStorageProviding>)cachingStorageProvider
{
    [self.executor execute:^{
        self.storageProvider = startupStorageProvider;
        [self initStartupConfiguration];
        AMAAppLovinLog(@"setupStartupProvider, aramEnabled=%@", self.startupConfig.aramEnabled ? @"YES" : @"NO");
    }];
}

- (void)startupUpdatedWithParameters:(NSDictionary *)parameters
{
    [self.executor execute:^{
        [self initStartupConfiguration];
        [self.responseParser parseResponse:parameters intoConfiguration:self.startupConfig];
        [self saveConfiguration];
        BOOL enabled = self.startupConfig != nil ? self.startupConfig.aramEnabled : YES;
        AMAAppLovinLog(@"startupUpdated, aramEnabled=%@", enabled ? @"YES" : @"NO");
        [self.observer activateAndSubscribe:enabled];
    }];
}

#pragma mark - Private

- (void)initStartupConfiguration
{
    id<AMAKeyValueStoring> storage = [self storage];
    if (storage != nil) {
        self.startupConfig = [[AMAAppLovinStartupConfiguration alloc] initWithStorage:storage];
    }
}

- (id<AMAKeyValueStoring>)storage
{
    if (self.storageProvider != nil) {
        return [self.storageProvider startupStorageForKeys:[AMAAppLovinStartupConfiguration allKeys]];
    }
    return nil;
}

- (void)saveConfiguration
{
    if (self.storageProvider != nil) {
        [self.storageProvider saveStorage:self.startupConfig.storage];
    }
}

@end
