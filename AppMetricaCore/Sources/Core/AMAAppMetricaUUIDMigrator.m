#import "AMAAppMetricaUUIDMigrator.h"
#import <AppMetricaStorageUtils/AppMetricaStorageUtils.h>
#import "AMAMetricaConfiguration.h"
#import "AMAStorageKeys.h"
#import "AMAInstantFeaturesConfiguration.h"
#import "AMADatabaseFactory.h"
#import "AMACore.h"
#import "AMAInstantFeaturesConfiguration+Migration.h"

@implementation AMAAppMetricaUUIDMigrator


- (nullable NSString *)migrateAppMetricaUUID
{
    NSString *UUID = nil;
    AMALogInfo(@"No cached uuid");

    AMAInstantFeaturesConfiguration *instantFeaturesConfiguration = [AMAInstantFeaturesConfiguration sharedInstance];
    UUID = instantFeaturesConfiguration.UUID;
    AMALogInfo(@"Uuid from instant features: %@", UUID);
    
    if (UUID.length > 0) {
        return UUID;
    }
    
    if (UUID.length == 0) {
        UUID = [self uuidFromOldStorage];
        AMALogInfo(@"Uuid from old storage: %@", UUID);
    }
    
    if (UUID.length == 0) {
        UUID = [self uuidFromMigrationStorage];
        AMALogInfo(@"Uuid from old instant features: %@", UUID);
    }

    return UUID;
}

#pragma mark - Private -

- (NSString *)uuidFromOldStorage
{
    NSString *oldUUID = nil;
    NSString *oldUUIDDatabasePath = [AMADatabaseFactory configurationDatabasePath];
    if ([AMAFileUtility fileExistsAtPath:oldUUIDDatabasePath] == YES) {
        id<AMAKeyValueStoring> uuidOldStorage = [[AMAMetricaConfiguration sharedInstance] UUIDOldStorage];
        NSError *error = nil;
        oldUUID = [uuidOldStorage stringForKey:AMAStorageStringKeyUUID error:&error];
        if (error != nil) {
            AMALogInfo(@"Failed to read uuid from old storage. Error: %@", error);
        }
    } else {
        AMALogInfo(@"No old uuid database");
    }
    return oldUUID;
}

- (NSString *)uuidFromMigrationStorage
{
    AMAInstantFeaturesConfiguration *migrationConfiguration = [AMAInstantFeaturesConfiguration migrationInstance];
    return migrationConfiguration.UUID;
}


@end
