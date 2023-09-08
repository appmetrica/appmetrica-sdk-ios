
#import "AMACore.h"
#import "AMAConfigurationDatabaseSchemeMigrationTo15.h"
#import "AMAMigrationUtils.h"
#import "AMAEventTypes.h"
#import "FMDB.h"

//TODO: Remove identity migration
static NSString *const kAMAIdentityFilePathPrefix = @"/Library/Caches/io.appmetrica/";

@implementation AMAConfigurationDatabaseSchemeMigrationTo15

- (NSUInteger)schemeVersion
{
    return 15;
}

- (BOOL)applyTransactionalMigrationToDatabase:(FMDatabase *)db
{
    BOOL result = [AMAMigrationUtils addEncryptionTypeInDatabase:db];
    result = result && [self fixIdentityFilePathInDatabase:db];
    return result;
}

- (BOOL)fixIdentityFilePathInDatabase:(FMDatabase *)db
{
    FMResultSet *identityEventsSet = [db executeQuery:@"SELECT id, value FROM events WHERE type = ?"
                                 withArgumentsInArray:@[ @(28) ]];
    while ([identityEventsSet next]) {
        NSString *eventValue = [identityEventsSet stringForColumn:@"value"];
        NSRange prefixRange = [eventValue rangeOfString:kAMAIdentityFilePathPrefix];
        if (prefixRange.length != 0) {
            NSInteger eventID = [identityEventsSet intForColumn:@"id"];
            NSString *trimmedEventValue = [eventValue substringFromIndex:NSMaxRange(prefixRange)];
            BOOL updateIsOK = [db executeUpdate:@"UPDATE events SET value = ? WHERE id = ?"
                           withArgumentsInArray:@[ trimmedEventValue, @(eventID) ]];
            if (updateIsOK == NO) {
                AMALogError(@"Identity migration failed: %@", [db lastError]);
            }
        }
    }
    return YES;
}

@end
