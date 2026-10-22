#import "AMADataMigrationTo620.h"
#import "AMAStorageKeys.h"
#import "AMADatabaseProtocol.h"
#import "AMADatabase.h"
#import <AppMetricaFMDB/AppMetricaFMDB.h>
#import "AMAMetricaConfiguration.h"
#import "AMAMetricaPersistentConfiguration.h"
#import "AMAAppMetricaConfigurationFileStorage.h"
#import "AMAAppMetricaConfigurationSnapshot.h"
#import "AMAAppMetricaConfiguration+JSONSerializable.h"

@implementation AMADataMigrationTo620

- (NSString *)migrationKey
{
    return AMAStorageStringKeyDidApplyDataMigrationFor620;
}

- (void)applyMigrationToDatabase:(id<AMADatabaseProtocol>)database
{
    AMAMetricaPersistentConfiguration *persistent = [AMAMetricaConfiguration sharedInstance].persistent;
    
    // Migrations hold the database lock; a concurrent cache reader may be waiting for this database.
    id<AMAKeyValueStoring> kvStorage = database.storageProvider.syncStorage;
    
    NSDictionary *dictionary = [kvStorage jsonDictionaryForKey:AMAStorageStringKeyAppMetricaClientConfiguration error:nil];
    AMAAppMetricaConfiguration *configuration = [[AMAAppMetricaConfiguration alloc] initWithJSON:dictionary];
    
    if (configuration != nil) {
        [persistent saveAppMetricaClientConfigurationSnapshotUsingCurrent:
            ^AMAAppMetricaConfigurationSnapshot *(AMAAppMetricaConfigurationSnapshot *current) {
                return [[AMAAppMetricaConfigurationSnapshot alloc]
                    initWithConfiguration:configuration
                                  savedAt:current.savedAt
                                   source:AMAAppMetricaConfigurationSnapshotSourcePrivate];
            }];
    }
}

@end
