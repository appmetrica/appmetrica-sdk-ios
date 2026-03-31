#import "AMAAppMetricaConfigurationFileStorage.h"
#import "AMAAppMetricaConfiguration+JSONSerializable.h"
#import "AMAAppMetricaConfiguration+Internal.h"
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>
#import <AppMetricaStorageUtils/AppMetricaStorageUtils.h>

@interface AMAAppMetricaConfigurationFileStorage ()

@property (atomic, nullable, strong) AMAAppMetricaConfiguration *cachedConfiguration;

@end

@implementation AMAAppMetricaConfigurationFileStorage

- (instancetype)initWithFileStorage:(id<AMAFileStorage>)fileStorage
{
    self = [super init];
    if (self) {
        _fileStorage = fileStorage;
        _executor = [[AMAExecutor alloc] initWithIdentifier:self];
    }
    return self;
}

- (instancetype)initWithFileStorage:(id<AMAFileStorage>)fileStorage
                           executor:(id<AMAAsyncExecuting>)executor
{
    self = [super init];
    if (self) {
        _fileStorage = fileStorage;
        _executor = executor;
    }
    return self;
}

+ (instancetype)appMetricaConfigurationFileStorageWithFileStorage:(id<AMAFileStorage>)fileStorage
{
    return [[self alloc] initWithFileStorage:fileStorage];
}

- (AMAAppMetricaConfiguration *)loadConfigurationFromFile
{
    AMAAppMetricaConfiguration *configuration = self.cachedConfiguration;
    if (configuration == nil) {
        NSData *data = [self.fileStorage readDataWithError:nil];
        if ([data length] == 0) {
            return nil;
        }
        
        NSDictionary *jsonData = [AMAJSONSerialization dictionaryWithJSONData:data error:nil];
        if ([jsonData count] == 0) {
            return nil;
        }
        
        configuration = [[AMAAppMetricaConfiguration alloc] initWithJSON:jsonData];
        self.cachedConfiguration = configuration;
    }
    return configuration;
}

- (AMAAppMetricaConfiguration *)loadConfiguration
{
    AMAAppMetricaConfiguration *configuration = self.cachedConfiguration;

    if (configuration == nil) {
        @synchronized (self) {
            configuration = [self loadConfigurationFromFile];
        }
    }
    return [configuration copy];
}

- (void)saveConfiguration:(AMAAppMetricaConfiguration *)configuration
{
    AMAAppMetricaConfiguration *config = [configuration copy];

    @synchronized (self) {
        AMAAppMetricaConfiguration *currentConfiguration = [self loadConfigurationFromFile];
        if ([config isEqualToConfiguration:currentConfiguration]) {
            return;
        }
        self.cachedConfiguration = config;
    }

    [self.executor execute:^{
        NSDictionary *jsonData = [config JSON];
        NSData *data = [AMAJSONSerialization dataWithJSONObject:jsonData error:nil];
        [self.fileStorage writeData:data error:nil];
    }];
}

@end
