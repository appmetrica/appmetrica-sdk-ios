
#import "AMAEventStorage+TestUtilities.h"
#import "AMASession.h"
#import "AMAReportEventsBatch.h"
#import "AMADatabaseProtocol.h"
#import "AMADatabaseConstants.h"
#import "AMAEventSerializer.h"
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>
#import "AMAEvent.h"
@import FMDB;

@implementation AMAEventStorage (TestUtilities)

- (AMAEvent *)amatest_savedEventWithOID:(NSNumber *)eventOID
{
    NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ? LIMIT 1",
                     kAMAEventTableName, kAMACommonTableFieldOID];
    return [self amatest_allSavedEventsForQuery:sql arguments:@[ eventOID ]].firstObject;
}

- (AMAEvent *)amatest_savedEventWithType:(AMAEventType)eventType
{
    return [self amatest_savedEventWithType:eventType name:nil];
}

- (AMAEvent *)amatest_savedEventWithType:(AMAEventType)eventType name:(NSString *)name
{
    NSArray *result = [self amatest_allSavedEventsWithType:eventType name:name];
    AMAEvent *event = result.firstObject;
    return event;
}

- (NSArray *)amatest_allSavedEvents
{
    NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@ ORDER BY %@ DESC",
                     kAMAEventTableName, kAMACommonTableFieldOID];
    return [self amatest_allSavedEventsForQuery:sql arguments:@[]];
}

- (NSArray *)amatest_allSavedEventsWithType:(AMAEventType)eventType name:(NSString *)name
{
    NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ? ORDER BY %@ DESC",
                     kAMAEventTableName, kAMACommonTableFieldType, kAMACommonTableFieldOID];
    NSArray *allEvents = [self amatest_allSavedEventsForQuery:sql arguments:@[ @(eventType) ]];
    NSArray *filteredEvents = allEvents;
    if (name != nil) {
        filteredEvents = [AMACollectionUtilities mapArray:allEvents withBlock:^id(AMAEvent *event) {
            return [name isEqual:event.name] ? event : nil;
        }];
    }
    return filteredEvents;
}

- (NSArray *)amatest_eventsForSessionOid:(NSNumber *)oid
{
    NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ? ORDER BY %@ DESC",
                     kAMAEventTableName, kAMAEventTableFieldSessionOID, kAMACommonTableFieldOID];
    return [self amatest_allSavedEventsForQuery:sql arguments:@[ oid ]];
}

- (NSArray *)amatest_allSavedEventsForQuery:(NSString *)query arguments:(NSArray *)arguments
{
    NSMutableArray *result = [NSMutableArray array];
    [self.database inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:query withArgumentsInArray:arguments];
        while ([rs next]) {
            AMAEvent *event = [self.eventSerializer eventForDictionary:rs.resultDictionary error:nil];
            if (event != nil) {
                [result addObject:event];
            }
        }
        [rs close];
    }];
    return [result copy];
}

@end
