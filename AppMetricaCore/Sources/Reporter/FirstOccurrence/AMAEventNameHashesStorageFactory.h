
#import <Foundation/Foundation.h>

@class AMAEventNameHashesStorage;

@interface AMAEventNameHashesStorageFactory : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

+ (AMAEventNameHashesStorage *)storageForApiKey:(NSString *)apiKey;

@end
