
#import "AMACore.h"
#import "AMAEventNameHashesStorageFactory.h"
#import "AMAEventNameHashesStorage.h"

static NSString *const kAMAFileName = @"event_hashes.bin";

@implementation AMAEventNameHashesStorageFactory

+ (AMAEventNameHashesStorage *)storageForApiKey:(NSString *)apiKey
{
    NSString *filePath = [[AMAFileUtility persistentPathForApiKey:apiKey] stringByAppendingPathComponent:kAMAFileName];
    AMADiskFileStorageOptions options = AMADiskFileStorageOptionNoBackup | AMADiskFileStorageOptionCreateDirectory;
    AMADiskFileStorage *fileStorage = [[AMADiskFileStorage alloc] initWithPath:filePath options:options];
    AMAEventNameHashesStorage *storage = [[AMAEventNameHashesStorage alloc] initWithFileStorage:fileStorage];
    return storage;
}

@end
