
#import "AMAConfigurationDatabaseSchemeMigrationTo14.h"
#import "AMAMigrationUtils.h"
#import <AppMetrica_FMDB/AppMetrica_FMDB.h>

@implementation AMAConfigurationDatabaseSchemeMigrationTo14

- (NSUInteger)schemeVersion
{
    return 14;
}

- (BOOL)applyTransactionalMigrationToDatabase:(AMAFMDatabase *)db
{
    return [AMAMigrationUtils addUserProfileIDInDatabase:db];
}

@end
