
#import "AMACrashMach.h"

@implementation AMACrashMach

- (instancetype)initWithExceptionType:(int32_t)exceptionType code:(int64_t)code subcode:(int64_t)subcode
{
    self = [super init];
    if (self != nil) {
        _exceptionType = exceptionType;
        _code = code;
        _subcode = subcode;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

@end
