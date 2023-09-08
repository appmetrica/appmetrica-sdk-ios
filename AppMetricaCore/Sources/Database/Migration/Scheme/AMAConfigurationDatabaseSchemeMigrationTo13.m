
#import "AMACore.h"
#import "AMAConfigurationDatabaseSchemeMigrationTo13.h"
#import "AMAMigrationUtils.h"

@implementation AMAConfigurationDatabaseSchemeMigrationTo13

- (NSUInteger)schemeVersion
{
    return 13;
}

- (BOOL)applyTransactionalMigrationToDatabase:(FMDatabase *)db
{
    return [AMAMigrationUtils addLocationEnabledInDatabase:db];
}

@end
