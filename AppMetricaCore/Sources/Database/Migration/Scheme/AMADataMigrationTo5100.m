
#import "AMADataMigrationTo5100.h"
#import "AMADatabaseConstants.h"
#import "AMAStorageKeys.h"
#import "AMADatabaseProtocol.h"
#import "AMAMigrationUtils.h"

@implementation AMADataMigrationTo5100

- (NSString *)migrationKey
{
    return AMAStorageStringKeyDidApplyDataMigrationFor5100;
}

- (void)applyMigrationToDatabase:(id<AMADatabaseProtocol>)database
{
    // Reset startup update date
    [database inDatabase:^(AMAFMDatabase *db) {
        [AMAMigrationUtils resetStartupUpdatedAtToDistantPastInDatabase:database db:db];
    }];
}

@end
