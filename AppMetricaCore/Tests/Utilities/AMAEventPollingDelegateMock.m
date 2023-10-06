#import "AMAEventPollingDelegateMock.h"

@implementation AMAEventPollingDelegateMock

static NSArray<AMACustomEventParameters *> *_mockedEvents = nil;

+ (NSArray<AMACustomEventParameters *> *)mockedEvents
{
    return _mockedEvents;
}

+ (void)setMockedEvents:(NSArray<AMACustomEventParameters *> *)mockedEvents 
{
    _mockedEvents = mockedEvents;
}

+ (NSArray<AMACustomEventParameters *> *)eventsForPreviousSession 
{
    return _mockedEvents ?: @[];
}

@end
