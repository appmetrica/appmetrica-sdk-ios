
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol AMAAttributeValueNormalizer <NSObject>

- (nullable NSString *)normalizeValue:(nullable NSString *)value;

@end

NS_ASSUME_NONNULL_END
