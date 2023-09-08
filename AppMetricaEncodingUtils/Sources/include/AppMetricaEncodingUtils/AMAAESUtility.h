
#import <Foundation/Foundation.h>

@interface AMAAESUtility : NSObject

+ (NSData *)randomIv;
+ (NSData *)defaultIv;
+ (NSData *)randomKeyOfSize:(NSUInteger)size;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end
