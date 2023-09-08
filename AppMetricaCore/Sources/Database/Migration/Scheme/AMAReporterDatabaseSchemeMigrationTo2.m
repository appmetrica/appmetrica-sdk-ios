
#import "AMACore.h"
#import "AMAReporterDatabaseSchemeMigrationTo2.h"
#import "AMAMigrationUtils.h"
#import "FMDB.h"

@implementation AMAReporterDatabaseSchemeMigrationTo2

- (NSUInteger)schemeVersion
{
    return 2;
}

- (BOOL)applyTransactionalMigrationToDatabase:(FMDatabase *)db
{
    BOOL result = YES;

    result = result && [AMAMigrationUtils updateColumnTypes:@"k TEXT NOT NULL PRIMARY KEY, v BLOB"
                                            ofKeyValueTable:@"kv"
                                                         db:db];

    return result;
}

@end
