
#import "AMACrashThreadInfo.h"

@interface AMACrashThreadInfo ()

@property (nonatomic, assign, readwrite) uint32_t index;
@property (nonatomic, copy, readwrite, nullable) NSString *threadName;
@property (nonatomic, copy, readwrite, nullable) NSString *queueName;

@end

@implementation AMACrashThreadInfo

- (instancetype)initWithBacktrace:(AMACrashBacktrace *)backtrace
                          crashed:(BOOL)crashed
{
    self = [super init];
    if (self != nil) {
        _backtrace = backtrace;
        _crashed = crashed;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
    AMAMutableCrashThreadInfo *copy = [[AMAMutableCrashThreadInfo alloc] initWithBacktrace:self.backtrace
                                                                                   crashed:self.crashed];
    copy.index = self.index;
    copy.threadName = self.threadName;
    copy.queueName = self.queueName;
    return copy;
}

@end

@implementation AMAMutableCrashThreadInfo

@dynamic index;
@dynamic crashed;
@dynamic threadName;
@dynamic queueName;

- (id)copyWithZone:(NSZone *)zone
{
    AMACrashThreadInfo *copy = [[AMACrashThreadInfo alloc] initWithBacktrace:self.backtrace
                                                                     crashed:self.crashed];
    copy.index = self.index;
    copy.threadName = self.threadName;
    copy.queueName = self.queueName;
    return copy;
}

@end
