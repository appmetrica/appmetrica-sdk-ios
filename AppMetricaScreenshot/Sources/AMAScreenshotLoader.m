
#import "AMAScreenshotLoader.h"
#import <AppMetricaCore/AppMetricaCore.h>
#import <AppMetricaCoreExtension/AppMetricaCoreExtension.h>
#import "AMAScreenshotWatcher.h"
#import "AMAScreenshotMainReporter.h"
#import "AMAScreenshotConfiguration.h"
#import "AMAScreenshotStartupParser.h"

static NSString *const kAMAStartupRequestParametersKey = @"request";
static NSString *const AMAScreenshotObfuscatedName = @"scr";
static NSString *const AMAScreenshotVersion = @"1";


@interface AMAScreenshotLoader()

@property (atomic, strong, nullable) AMAScreenshotWatcher *screenshotWatcher;

@property (nonatomic, strong, nullable) AMAScreenshotConfiguration *screenshotConfiguration;

@property (nonatomic, strong, nullable) id<AMAStartupStorageProviding> storageProvider;
@property (nonatomic, strong, nullable) id<AMACachingStorageProviding> cachingStorageProvider;

@end

@implementation AMAScreenshotLoader

+ (instancetype)sharedInstance
{
    static AMAScreenshotLoader *loader;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        loader = [AMAScreenshotLoader new];
    });
    return loader;
}

+ (void)load
{
    AMAServiceConfiguration *config = [[AMAServiceConfiguration alloc]
                                       initWithStartupObserver:[self sharedInstance]
                                       reporterStorageController:[self sharedInstance]
    ];
    [AMAAppMetrica registerExternalService:config];
}

- (void)setupWithReporterStorage:(id<AMAKeyValueStorageProviding>)stateStorageProvider
                            main:(BOOL)main
                       forAPIKey:(NSString *)apiKey
{
}

- (NSDictionary *)startupParameters
{
    return @{
        kAMAStartupRequestParametersKey: [self startupParametersRequestParameters]
    };
}

- (NSDictionary *)startupParametersRequestParameters
{
    return @{
        @"features": AMAScreenshotObfuscatedName,
        AMAScreenshotObfuscatedName: AMAScreenshotVersion,
    };
}

- (void)setupStartupProvider:(id<AMAStartupStorageProviding>)startupStorageProvider
      cachingStorageProvider:(id<AMACachingStorageProviding>)cachingStorageProvider
{
    @synchronized (self) {
        self.storageProvider = startupStorageProvider;
        self.cachingStorageProvider = cachingStorageProvider;
        
        [self createConfigWithStartupProvider];
        [self updateWatcherStatus];
    }
}

- (void)startupUpdatedWithParameters:(NSDictionary *)parameters
{
    @synchronized (self) {
        AMAScreenshotStartupResponse *response = [AMAScreenshotStartupParser parse:parameters];
        [self.screenshotConfiguration updateStartupConfiguration:response];
        
        [self.storageProvider saveStorage:self.screenshotConfiguration.storage];
        [self updateWatcherStatus];
    }
}

- (void)updateWatcherStatus
{
    BOOL isEnabled = self.screenshotConfiguration.screenshotEnabled && self.screenshotConfiguration.captorEnabled;
    if (isEnabled) {
        [self createWatcherIfNeeded];
    }
    self.screenshotWatcher.isStarted = isEnabled;
}

- (void)createConfigWithStartupProvider
{
    id<AMAKeyValueStoring> storage = [self.storageProvider startupStorageForKeys:[AMAScreenshotConfiguration allKeys]];
    AMAScreenshotConfiguration *config = [[AMAScreenshotConfiguration alloc] initWithStorage:storage];
    self.screenshotConfiguration = config;
}

- (void)createWatcherIfNeeded
{
    if (self.screenshotWatcher == nil) {
        AMAScreenshotMainReporter *reporter = [AMAScreenshotMainReporter new];
        AMAScreenshotWatcher *watcher = [[AMAScreenshotWatcher alloc] initWithReporter:reporter
                                                                    notificationCenter:[NSNotificationCenter defaultCenter]];
        
        self.screenshotWatcher = watcher;
    }
}

@end
