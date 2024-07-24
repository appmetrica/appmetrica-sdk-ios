
#import "AMAUrgentEventCountDispatchStrategy.h"
#import "AMAEventTypes.h"

@implementation AMAUrgentEventCountDispatchStrategy

- (NSUInteger)eventsNumberNeededForDispatch
{
    return 1;
}

- (NSArray *)includedEventTypes
{
    return @[
        @(AMAEventTypeFirst),
        @(AMAEventTypeInit),
        @(AMAEventTypeUpdate),
        @(AMAEventTypeStart),
    ];
}

@end
