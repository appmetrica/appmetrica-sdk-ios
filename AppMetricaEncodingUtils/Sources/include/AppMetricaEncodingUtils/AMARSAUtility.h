
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AMARSAUtility : NSObject

+ (nullable NSData *)publicKeyFromPem:(NSString *)pemString;
+ (nullable NSData *)privateKeyFromPem:(NSString *)pemString;

@end

NS_ASSUME_NONNULL_END
