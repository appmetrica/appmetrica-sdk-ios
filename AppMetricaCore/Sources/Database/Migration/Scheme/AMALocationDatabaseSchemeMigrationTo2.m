
#import "AMALocationDatabaseSchemeMigrationTo2.h"
#import "AMAMigrationUtils.h"
#import <AppMetrica_FMDB/AppMetrica_FMDB.h>

@implementation AMALocationDatabaseSchemeMigrationTo2

- (NSUInteger)schemeVersion
{
    return 2;
}

- (BOOL)applyTransactionalMigrationToDatabase:(AMAFMDatabase *)db
{
    BOOL result = YES;

    result = result && [AMAMigrationUtils updateColumnTypes:@"k TEXT NOT NULL PRIMARY KEY, v TEXT NOT NULL DEFAULT ''"
                                            ofKeyValueTable:@"kv"
                                                         db:db];

    return result;
}

@end
