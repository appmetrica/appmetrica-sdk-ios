
#import "AMACrashMatchingRule.h"

@implementation AMACrashMatchingRule

- (instancetype)initWithClasses:(NSArray *)classes
                  classPrefixes:(NSArray *)classPrefixes
{
    return [self initWithClasses:classes classPrefixes:classPrefixes dynamicBinaryNames:nil];
}

- (instancetype)initWithClasses:(NSArray *)classes
                  classPrefixes:(NSArray *)classPrefixes
             dynamicBinaryNames:(nullable NSArray<NSString *> *)dynamicBinaryNames
{
    self = [super init];
    if (self != nil) {
        _classes = [classes copy];
        _classPrefixes = [classPrefixes copy];
        _dynamicBinaryNames = [dynamicBinaryNames copy];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

@end
