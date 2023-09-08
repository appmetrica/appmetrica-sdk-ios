
#import "AMAFileStorage.h"

typedef NS_OPTIONS(NSUInteger, AMADiskFileStorageOptions) {
    AMADiskFileStorageOptionNoBackup = 1 << 0,
    AMADiskFileStorageOptionCreateDirectory = 1 << 1,
};

@interface AMADiskFileStorage : NSObject <AMAFileStorage>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithPath:(NSString *)path options:(AMADiskFileStorageOptions)options;

@end
