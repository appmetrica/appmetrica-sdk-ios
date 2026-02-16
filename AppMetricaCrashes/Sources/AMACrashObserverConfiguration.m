#import "AMACrashObserverConfiguration.h"

@implementation AMACrashObserverConfiguration

- (instancetype)initWithDelegate:(id<AMACrashObserving>)delegate
                   callbackQueue:(dispatch_queue_t)callbackQueue
{
    self = [super init];
    if (self != nil) {
        _delegate = delegate;
        _callbackQueue = callbackQueue ?: dispatch_get_main_queue();
    }
    return self;
}

+ (instancetype)configurationWithDelegate:(id<AMACrashObserving>)delegate
{
    return [[AMACrashObserverConfiguration alloc] initWithDelegate:delegate
                                                     callbackQueue:dispatch_get_main_queue()];
}


#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

@end
