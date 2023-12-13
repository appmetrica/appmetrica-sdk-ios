
#import "AMACore.h"
#import "AMAEventNameHashesStorageFactory.h"
#import "AMAEventNameHashesStorage.h"

static NSString *const kAMAFileName = @"event_hashes.bin";

@implementation AMAEventNameHashesStorageFactory

+ (AMAEventNameHashesStorage *)storageForApiKey:(NSString *)apiKey
{
    NSString *filePath = [[AMAFileUtility persistentPathForApiKey:apiKey] stringByAppendingPathComponent:kAMAFileName];
    return [self storageForPath:filePath];
}

+ (AMAEventNameHashesStorage *)migrationStorageForPath:(NSString *)path
{
    NSString *filePath = [path stringByAppendingPathComponent:kAMAFileName];
    return [self storageForPath:filePath];
}

#pragma mark - Private -
+ (AMAEventNameHashesStorage *)storageForPath:(NSString *)filePath
{
    AMADiskFileStorageOptions options = AMADiskFileStorageOptionNoBackup | AMADiskFileStorageOptionCreateDirectory;
    AMADiskFileStorage *fileStorage = [[AMADiskFileStorage alloc] initWithPath:filePath options:options];
    AMAEventNameHashesStorage *storage = [[AMAEventNameHashesStorage alloc] initWithFileStorage:fileStorage];
    return storage;
}

@end
