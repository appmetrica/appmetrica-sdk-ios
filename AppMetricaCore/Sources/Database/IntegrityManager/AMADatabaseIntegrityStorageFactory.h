
#import <Foundation/Foundation.h>

@class AMADatabaseIntegrityStorage;

@interface AMADatabaseIntegrityStorageFactory : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

+ (AMADatabaseIntegrityStorage *)storageForPath:(NSString *)path;

@end
