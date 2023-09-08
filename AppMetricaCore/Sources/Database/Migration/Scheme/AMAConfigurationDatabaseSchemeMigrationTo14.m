
#import "AMACore.h"
#import "AMAConfigurationDatabaseSchemeMigrationTo14.h"
#import "AMAMigrationUtils.h"
#import "FMDB.h"

@implementation AMAConfigurationDatabaseSchemeMigrationTo14

- (NSUInteger)schemeVersion
{
    return 14;
}

- (BOOL)applyTransactionalMigrationToDatabase:(FMDatabase *)db
{
    return [AMAMigrationUtils addUserProfileIDInDatabase:db];
}

@end
