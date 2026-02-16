
#import "AMACrashEventError.h"

@interface AMACrashEventError ()

@property (nonatomic, strong, readwrite, nullable) AMACrashSignal *signal;
@property (nonatomic, strong, readwrite, nullable) AMACrashMach *mach;
@property (nonatomic, copy, readwrite, nullable) NSString *exceptionName;
@property (nonatomic, copy, readwrite, nullable) NSString *exceptionReason;
@property (nonatomic, copy, readwrite, nullable) NSString *cppExceptionName;

@end

@implementation AMACrashEventError

- (instancetype)initWithType:(AMACrashType)type
{
    self = [super init];
    if (self != nil) {
        _type = type;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
    AMAMutableCrashEventError *copy = [[AMAMutableCrashEventError alloc] initWithType:self.type];
    copy.signal = self.signal;
    copy.mach = self.mach;
    copy.exceptionName = self.exceptionName;
    copy.exceptionReason = self.exceptionReason;
    copy.cppExceptionName = self.cppExceptionName;
    return copy;
}

@end

@implementation AMAMutableCrashEventError

@dynamic signal;
@dynamic mach;
@dynamic exceptionName;
@dynamic exceptionReason;
@dynamic cppExceptionName;

- (id)copyWithZone:(NSZone *)zone
{
    AMACrashEventError *copy = [[AMACrashEventError alloc] initWithType:self.type];
    copy.signal = self.signal;
    copy.mach = self.mach;
    copy.exceptionName = self.exceptionName;
    copy.exceptionReason = self.exceptionReason;
    copy.cppExceptionName = self.cppExceptionName;
    return copy;
}

@end
