
#import "AMASessionStorage+AMATestUtilities.h"
#import "AMADatabaseProtocol.h"
#import "AMADatabaseConstants.h"
#import "AMASession.h"
#import "AMASessionSerializer.h"
#import <AppMetricaFMDB/AppMetricaFMDB.h>

@interface AMASessionStorage ()

@property (nonatomic, strong, readonly) id<AMADatabaseProtocol> database;
@property (nonatomic, strong, readonly) AMASessionSerializer *serializer;

@end

@implementation AMASessionStorage (AMATestUtilities)

- (AMASession *)amatest_backgroundSession
{
    return [self amatest_lastSessionWithType:AMASessionTypeBackground];
}

- (AMASession *)amatest_existingOrNewBackgroundSessionCreatedAt:(NSDate *)date;
{
    AMASession *session = [self amatest_backgroundSession];
    if (session == nil) {
        session = [self newBackgroundSessionCreatedAt:date error:nil];
    }
    return session;
}

- (AMASession *)amatest_lastSessionWithType:(AMASessionType)type
{
    return [self lastSessionWithType:type error:nil];
}

- (AMASession *)amatest_sessionWithOid:(NSNumber *)sessionOid
{
    __block AMASession *session = nil;
    [self.database inDatabase:^(AMAFMDatabase *db) {
        NSString *query = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ? LIMIT 1",
                           kAMASessionTableName, kAMACommonTableFieldOID];
        AMAFMResultSet *rs = [db executeQuery:query, sessionOid];
        if ([rs next]) {
            session = [self.serializer sessionForDictionary:rs.resultDictionary error:nil];
        }
        [rs close];
    }];
    return session;
}

- (NSArray *)amatest_allSessionsWithType:(AMASessionType)type
{
    __block NSMutableArray *sessions = [NSMutableArray array];
    [self.database inDatabase:^(AMAFMDatabase *db) {
        NSString *query = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = ? ORDER BY %@ DESC",
                           kAMASessionTableName, kAMACommonTableFieldType, kAMASessionTableFieldStartTime];
        AMAFMResultSet *rs = [db executeQuery:query, @(type)];
        while ([rs next]) {
            AMASession *session = [self.serializer sessionForDictionary:rs.resultDictionary error:nil];
            if (session != nil) {
                [sessions addObject:session];
            }
        }
        [rs close];
    }];
    return [sessions copy];
}

@end
