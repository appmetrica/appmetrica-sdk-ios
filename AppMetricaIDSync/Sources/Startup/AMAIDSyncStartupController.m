
#import "AMAIDSyncStartupController.h"
#import "AMAIDSyncLoader.h"
#import "AMAIDSyncStartupConfiguration.h"
#import "AMAIDSyncStartupRequestParameters.h"
#import "AMAIDSyncStartupResponseParser.h"
#import "AMAIDSyncStartupResponse.h"
#import "AMAIDSyncCore.h"

@interface AMAIDSyncStartupController ()

@property (nonatomic, strong, readwrite) AMAIDSyncStartupConfiguration *startup;

@property (nonatomic, strong) id<AMAStartupStorageProviding> storageProvider;

@property (nonatomic, strong) AMAIDSyncStartupResponseParser *responseParser;

@property (nonatomic, strong, readonly) NSObject *startupConfigurationLock;

@end

@implementation AMAIDSyncStartupController

- (instancetype)init
{
    self = [super init];
    if (self) {
        _startupConfigurationLock = [[NSObject alloc] init];
        _responseParser = [[AMAIDSyncStartupResponseParser alloc] init];
    }
    return self;
}

// TODO: Workaround to remove later
+ (instancetype)sharedInstance
{
    static AMAIDSyncStartupController *startupController;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        startupController = [AMAIDSyncStartupController new];
    });
    return startupController;
}

#pragma mark - Public -

- (id<AMAKeyValueStoring>)storage
{
    @synchronized (self) {
        if (self.storageProvider != nil) {
            return [self.storageProvider startupStorageForKeys:[AMAIDSyncStartupConfiguration allKeys]];
        }
        return nil;
    }
}

- (void)saveStorage
{
    @synchronized (self) {
        if (self.storageProvider != nil) {
            [self.storageProvider saveStorage:self.startup.storage];
        }
    }
}

#pragma mark - Startup configuration -

- (AMAIDSyncStartupConfiguration *)startup
{
    if (_startup == nil) {
        @synchronized (self.startupConfigurationLock) {
            if (_startup == nil) {
                id<AMAKeyValueStoring> storage = [self storage];
                if (storage != nil) {
                    _startup = [[AMAIDSyncStartupConfiguration alloc] initWithStorage:storage];
                }
                else {
                    AMALogError(@"Failed to load id sync startup parameters");
                }
            }
        }
    }
    return _startup;
}

- (void)updateStartupConfiguration:(AMAIDSyncStartupConfiguration *)startup
{
    @synchronized(self.startupConfigurationLock) {
        self.startup = startup;
    }
}

- (void)synchronizeStartup
{
    @synchronized(self.startupConfigurationLock) {
        [self saveStorage];
    }
}

#pragma mark - AMAExtendedStartupObserving -

- (void)setupWithReporterStorage:(id<AMAKeyValueStorageProviding>)stateStorageProvider
                            main:(BOOL)main
                       forAPIKey:(NSString *)apiKey
{
}

- (NSDictionary *)startupParameters
{
    return @{
        @"request": [AMAIDSyncStartupRequestParameters parameters]
    };
}

- (void)setupStartupProvider:(id<AMAStartupStorageProviding>)startupStorageProvider
      cachingStorageProvider:(id<AMACachingStorageProviding>)cachingStorageProvider
{
    @synchronized (self) {
        self.storageProvider = startupStorageProvider;
        
        [[AMAIDSyncLoader sharedInstance] start];
    }
}

- (void)startupUpdatedWithParameters:(NSDictionary *)parameters
{
    @synchronized (self) {
        AMAIDSyncStartupResponse *response = [self.responseParser parseStartupResponse:parameters];
        
        [self updateStartupConfiguration:response.configuration];
        [self synchronizeStartup];
        
        [[AMAIDSyncLoader sharedInstance] start];
    }
}

@end
