
#import "AMAEventStorage.h"
#import "AMAEventTypes.h"

@class AMAReportEventsBatch;
@class AMASession;

@interface AMAEventStorage (TestUtilities)

- (AMAEvent *)amatest_savedEventWithOID:(NSNumber *)eventOID;
- (AMAEvent *)amatest_savedEventWithType:(AMAEventType)eventType;
- (AMAEvent *)amatest_savedEventWithType:(AMAEventType)eventType name:(NSString *)name;
- (NSArray *)amatest_allSavedEvents;
- (NSArray *)amatest_allSavedEventsWithType:(AMAEventType)eventType name:(NSString *)name;
- (NSArray *)amatest_eventsForSessionOid:(NSNumber *)oid;

@end
