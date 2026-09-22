#import "AMAAppMetricaConfigurationFileStorage.h"
#import "AMAAppMetricaConfigurationSnapshot.h"
#import "AMAAppMetricaConfiguration+JSONSerializable.h"
#import "AMAAppMetricaConfiguration+Internal.h"
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>
#import <AppMetricaStorageUtils/AppMetricaStorageUtils.h>

static NSString *const kAMAConfigurationSnapshotConfigurationKey = @"configuration";
static NSString *const kAMAConfigurationSnapshotSavedAtKey = @"savedAt";

@implementation AMAAppMetricaConfigurationFileStorage

- (instancetype)initWithFileStorage:(id<AMAFileStorage>)fileStorage
{
    self = [super init];
    if (self) {
        _fileStorage = fileStorage;
    }
    return self;
}

+ (instancetype)appMetricaConfigurationFileStorageWithFileStorage:(id<AMAFileStorage>)fileStorage
{
    return [[self alloc] initWithFileStorage:fileStorage];
}

- (AMAAppMetricaConfigurationSnapshot *)snapshotFromData:(NSData *)data
{
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

    return [[AMAAppMetricaConfigurationSnapshot alloc] initWithConfiguration:configuration
                                                                     savedAt:savedAt
                                                                      source:AMAAppMetricaConfigurationSnapshotSourcePrivate];
}

- (AMAAppMetricaConfigurationSnapshot *)loadSnapshot
{
    NSData *data = [self.fileStorage readDataWithError:nil];
    return [self snapshotFromData:data];
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
    NSDictionary *json = [self JSONDictionaryForSnapshot:snapshot];
    NSData *data = [AMAJSONSerialization dataWithJSONObject:json error:nil];
    if (data == nil) {
        return;
    }
    [self.fileStorage writeData:data error:nil];
}

- (void)deleteSnapshot
{
    [self.fileStorage deleteFileWithError:nil];
}

@end
