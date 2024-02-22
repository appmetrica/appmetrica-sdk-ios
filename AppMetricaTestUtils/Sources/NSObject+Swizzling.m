
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "objc/runtime.h"

@implementation NSObject (Swizzling)

+ (void)swizzleClassSelector:(nonnull SEL)originalSelector swizzledSelector:(nonnull SEL)swizzledSelector
{
    Class clazz = self;
        
    Method originalMethod = class_getClassMethod(clazz, originalSelector);
    Method swizzledMethod = class_getClassMethod(clazz, swizzledSelector);
        
    method_exchangeImplementations(originalMethod, swizzledMethod);
}

+ (void)swizzleInstaceSelector:(nonnull SEL)originalSelector swizzledSelector:(nonnull SEL)swizzledSelector
{
    Class clazz = self;
        
    Method originalMethod = class_getInstanceMethod(clazz, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(clazz, swizzledSelector);
        
    method_exchangeImplementations(originalMethod, swizzledMethod);
}

@end
