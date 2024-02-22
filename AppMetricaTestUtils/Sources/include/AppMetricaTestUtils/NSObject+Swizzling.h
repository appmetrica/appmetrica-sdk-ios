#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (Swizzling)
+ (void)swizzleClassSelector:(SEL)originalSelector swizzledSelector:(SEL)swizzledSelector;
+ (void)swizzleInstaceSelector:(SEL)originalSelector swizzledSelector:(SEL)swizzledSelector;
@end

NS_ASSUME_NONNULL_END
