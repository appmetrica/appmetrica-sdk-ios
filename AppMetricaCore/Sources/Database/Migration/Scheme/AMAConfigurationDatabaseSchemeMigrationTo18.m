
#import "AMACore.h"
#import "AMAConfigurationDatabaseSchemeMigrationTo18.h"
#import "AMAMigrationUtils.h"
#import "FMDB.h"

@implementation AMAConfigurationDatabaseSchemeMigrationTo18

- (NSUInteger)schemeVersion
{
    return 18;
}

- (BOOL)applyTransactionalMigrationToDatabase:(FMDatabase *)db
{
    BOOL success = YES;
    success = success && [AMAMigrationUtils addGlobalEventNumberInDatabase:db];
    success = success && [AMAMigrationUtils addEventNumberOfTypeInDatabase:db];
    return success;
}

@end
