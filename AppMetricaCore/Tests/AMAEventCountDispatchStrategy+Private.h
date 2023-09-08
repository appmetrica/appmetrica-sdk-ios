
#import "AMAEventCountDispatchStrategy.h"
#import "AMADispatchStrategy+Private.h"

@interface AMAEventCountDispatchStrategy ()

- (void)updateEventsCount;
- (void)handleSessionDidAddEventNotification:(NSNotification *)notif;
- (NSUInteger)eventsNumberNeededForDispatch;

- (NSArray *)includedEventTypes;
- (NSArray *)excludedEventTypes;

@end
