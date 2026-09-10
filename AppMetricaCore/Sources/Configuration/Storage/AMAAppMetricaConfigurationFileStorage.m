#import "AMAAppMetricaConfigurationFileStorage.h"
#import "AMAAppMetricaConfigurationSnapshot.h"
#import "AMAAppMetricaConfiguration+JSONSerializable.h"
#import "AMAAppMetricaConfiguration+Internal.h"
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>
#import <AppMetricaStorageUtils/AppMetricaStorageUtils.h>

static NSString *const kAMAConfigurationSnapshotConfigurationKey = @"configuration";
static NSString *const kAMAConfigurationSnapshotSavedAtKey = @"savedAt";

@interface AMAAppMetricaConfigurationFileStorage ()

@property (atomic, nullable, strong) AMAAppMetricaConfigurationSnapshot *cachedSnapshot;

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

- (AMAAppMetricaConfigurationSnapshot *)loadSnapshotFromFile
{
    AMAAppMetricaConfigurationSnapshot *snapshot = self.cachedSnapshot;
    if (snapshot != nil) {
        return snapshot;
    }

    NSData *data = [self.fileStorage readDataWithError:nil];
    if ([data length] == 0) {
        return nil;
    }

    NSDictionary *jsonData = [AMAJSONSerialization dictionaryWithJSONData:data error:nil];
    if ([jsonData count] == 0) {
        return nil;
    }

    AMAAppMetricaConfiguration *configuration = nil;
    NSDate *savedAt = nil;
    id nestedConfiguration = jsonData[kAMAConfigurationSnapshotConfigurationKey];
    if ([nestedConfiguration isKindOfClass:[NSDictionary class]]) {
        configuration = [[AMAAppMetricaConfiguration alloc] initWithJSON:nestedConfiguration];
        id savedAtValue = jsonData[kAMAConfigurationSnapshotSavedAtKey];
        if ([savedAtValue isKindOfClass:[NSNumber class]]) {
            savedAt = [NSDate dateWithTimeIntervalSince1970:[(NSNumber *)savedAtValue doubleValue]];
        }
    }
    else {
        // Legacy format: top-level configuration JSON without wrapper.
        configuration = [[AMAAppMetricaConfiguration alloc] initWithJSON:jsonData];
    }

    if (configuration == nil) {
        return nil;
    }

    snapshot = [[AMAAppMetricaConfigurationSnapshot alloc] initWithConfiguration:configuration
                                                                         savedAt:savedAt
                                                                          source:AMAAppMetricaConfigurationSnapshotSourcePrivate];
    self.cachedSnapshot = snapshot;
    return snapshot;
}

- (AMAAppMetricaConfigurationSnapshot *)loadSnapshot
{
    AMAAppMetricaConfigurationSnapshot *snapshot = self.cachedSnapshot;
    if (snapshot == nil) {
        @synchronized (self) {
            snapshot = [self loadSnapshotFromFile];
        }
    }
    if (snapshot == nil) {
        return nil;
    }
    return [[AMAAppMetricaConfigurationSnapshot alloc] initWithConfiguration:snapshot.configuration
                                                                     savedAt:snapshot.savedAt
                                                                      source:snapshot.source];
}

- (NSDictionary *)JSONDictionaryForSnapshot:(AMAAppMetricaConfigurationSnapshot *)snapshot
{
    NSMutableDictionary *json = [NSMutableDictionary dictionary];
    NSDictionary *configurationJSON = [snapshot.configuration JSON];
    if (configurationJSON != nil) {
        json[kAMAConfigurationSnapshotConfigurationKey] = configurationJSON;
    }
    if (snapshot.savedAt != nil) {
        json[kAMAConfigurationSnapshotSavedAtKey] = @([snapshot.savedAt timeIntervalSince1970]);
    }
    return [json copy];
}

- (void)saveSnapshot:(AMAAppMetricaConfigurationSnapshot *)snapshot
{
    AMAAppMetricaConfigurationSnapshot *toSave =
        [[AMAAppMetricaConfigurationSnapshot alloc] initWithConfiguration:snapshot.configuration
                                                                  savedAt:snapshot.savedAt
                                                                   source:AMAAppMetricaConfigurationSnapshotSourcePrivate];

    @synchronized (self) {
        AMAAppMetricaConfigurationSnapshot *currentSnapshot = [self loadSnapshotFromFile];
        if ([toSave isEqualToSnapshot:currentSnapshot]) {
            return;
        }
        self.cachedSnapshot = toSave;
    }

    [self.executor execute:^{
        NSDictionary *jsonData = [self JSONDictionaryForSnapshot:toSave];
        NSData *data = [AMAJSONSerialization dataWithJSONObject:jsonData error:nil];
        [self.fileStorage writeData:data error:nil];
    }];
}

- (void)clearSnapshot:(AMAAppMetricaConfigurationSnapshot *)snapshot
{
    @synchronized (self) {
        self.cachedSnapshot = nil;
    }
    [self.fileStorage deleteFileWithError:nil];
}

@end
