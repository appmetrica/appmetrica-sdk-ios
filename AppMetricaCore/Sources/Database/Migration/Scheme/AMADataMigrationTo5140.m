#import "AMADataMigrationTo5140.h"
#import "AMADatabaseProtocol.h"
#import "AMAStorageKeys.h"
#import <AppMetricaFMDB/AppMetricaFMDB.h>

@implementation AMADataMigrationTo5140

- (NSString *)migrationKey
{
    return AMAStorageStringKeyDidApplyDataMigrationFor5140;
}

- (void)applyMigrationToDatabase:(id<AMADatabaseProtocol>)database
{
    [database inDatabase:^(AMAFMDatabase *db) {
        [db executeStatements:@"PRAGMA auto_vacuum=FULL; PRAGMA journal_mode=WAL; PRAGMA synchronous=NORMAL; VACUUM;"];
    }];
}

@end
