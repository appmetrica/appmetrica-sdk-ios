
#import <AppMetricaLog/AppMetricaLog.h>
#import "AMALocationDataMigrationTo5100.h"
#import "AMADatabaseConstants.h"
#import "AMAStorageKeys.h"
#import <AppMetricaFMDB/AppMetricaFMDB.h>
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>
#import "AMAMigrationTo5100Utils.h"
#import "AMADatabaseProtocol.h"
#import "AMATableDescriptionProvider.h"

@implementation AMALocationDataMigrationTo5100

- (NSString *)migrationKey
{
    return AMAStorageStringKeyDidApplyDataMigrationFor5100;
}

- (void)applyMigrationToDatabase:(id<AMADatabaseProtocol>)database
{
    @synchronized (self) {
        [self migrateTablesInDatabase:database];
    }
}

- (void)migrateTablesInDatabase:(id<AMADatabaseProtocol>)database
{
    NSDictionary *tables = @{
        kAMALocationsTableName : [AMATableDescriptionProvider locationsTableMetaInfo],
        kAMALocationsVisitsTableName : [AMATableDescriptionProvider visitsTableMetaInfo],
    };
    [database inDatabase:^(AMAFMDatabase *db) {
        for (NSString *table in tables) {
            [AMAMigrationTo5100Utils migrateLocationTable:table
                                              tableScheme:[tables objectForKey:table]
                                                       db:db];
        }
        [db close];
    }];
}

@end
