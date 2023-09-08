
#import "AMACore.h"
#import "AMAConfigurationDatabaseSchemeMigrationTo12.h"
#import "FMDB.h"
#import "AMAStorageKeys.h"

@implementation AMAConfigurationDatabaseSchemeMigrationTo12

- (NSUInteger)schemeVersion
{
    return 12;
}

- (BOOL)applyTransactionalMigrationToDatabase:(FMDatabase *)db
{
    NSString *legacyReportHost = [self stringForKey:AMAStorageStringKeyReportsURL db:db];
    if (legacyReportHost.length != 0) {
        NSArray *reportHosts = @[ legacyReportHost ];
        NSString *jsonString = [AMAJSONSerialization stringWithJSONObject:reportHosts error:NULL];
        if (jsonString != nil) {
            [self setString:jsonString forKey:AMAStorageStringKeyReportHosts db:db];
        }
        [self deleteValueForKey:AMAStorageStringKeyReportsURL db:db];
    }

    return YES;
}

- (NSString *)stringForKey:(NSString *)key db:(FMDatabase *)db
{
    NSString *result = nil;
    FMResultSet *resultSet = [db executeQuery:@"SELECT v FROM kv WHERE k = ?", key];
    if ([resultSet next]) {
        result = [resultSet stringForColumn:@"v"];
    }
    [resultSet close];
    return result;
}

- (void)setString:(NSString *)value forKey:(NSString *)key db:(FMDatabase *)db
{
    [db executeUpdate:@"INSERT OR REPLACE INTO kv (k, v) VALUES (?, ?)", key, value];
}

- (void)deleteValueForKey:(NSString *)key db:(FMDatabase *)db
{
    [db executeUpdate:@"DELETE FROM kv WHERE k = ?", key];
}

@end
