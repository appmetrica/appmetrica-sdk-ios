#import "AMAEventPollingDelegateMock.h"

@implementation AMAEventPollingDelegateMock

static NSArray<AMAEventPollingParameters *> *_mockedEvents = nil;

+ (NSArray<AMAEventPollingParameters *> *)mockedEvents
{
    return _mockedEvents;
}

+ (void)setMockedEvents:(NSArray<AMAEventPollingParameters *> *)mockedEvents
{
    _mockedEvents = mockedEvents;
}

+ (NSArray<AMAEventPollingParameters *> *)eventsForPreviousSession 
{
    return _mockedEvents ?: @[];
}

+ (void)setupAppEnvironment:(nonnull AMAEnvironmentContainer *)appEnvironment
{
}

@end
