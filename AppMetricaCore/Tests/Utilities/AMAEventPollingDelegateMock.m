#import "AMAEventPollingDelegateMock.h"
#import "AMAModuleInvocationRecorder.h"

@implementation AMAEventPollingDelegateMock

static NSArray<AMAEventPollingParameters *> *_mockedEvents = nil;
static __weak AMAModuleInvocationRecorder *_invocationRecorder = nil;

+ (NSArray<AMAEventPollingParameters *> *)mockedEvents
{
    return _mockedEvents;
}

+ (void)setMockedEvents:(NSArray<AMAEventPollingParameters *> *)mockedEvents
{
    _mockedEvents = mockedEvents;
}

+ (AMAModuleInvocationRecorder *)invocationRecorder
{
    return _invocationRecorder;
}

+ (void)setInvocationRecorder:(AMAModuleInvocationRecorder *)invocationRecorder
{
    _invocationRecorder = invocationRecorder;
}

+ (void)reset
{
    _mockedEvents = nil;
    _invocationRecorder = nil;
}

+ (NSArray<AMAEventPollingParameters *> *)pollingEvents
{
    [_invocationRecorder recordInvocationFromClass:self selector:_cmd];
    return _mockedEvents ?: @[];
}

+ (void)setupAppEnvironment:(nonnull AMAEnvironmentContainer *)appEnvironment
{
    [_invocationRecorder recordInvocationFromClass:self selector:_cmd];
}

@end
