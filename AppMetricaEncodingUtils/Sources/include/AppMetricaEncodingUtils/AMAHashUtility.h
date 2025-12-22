
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(HashUtility)
@interface AMAHashUtility : NSObject

+ (NSString *)sha256HashForData:(NSData *)jsonData;
+ (NSString *)sha256HashForString:(NSString *)string;
+ (NSData *)sha256DataForString:(NSString *)string;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
