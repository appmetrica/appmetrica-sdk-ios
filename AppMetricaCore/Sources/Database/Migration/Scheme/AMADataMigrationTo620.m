#import "AMADataMigrationTo620.h"
#import "AMAStorageKeys.h"
#import "AMADatabaseProtocol.h"
#import "AMADatabase.h"
#import <AppMetricaFMDB/AppMetricaFMDB.h>
#import "AMAMetricaConfiguration.h"
#import "AMAMetricaPersistentConfiguration.h"
#import "AMAAppMetricaConfigurationFileStorage.h"
#import "AMAAppMetricaConfiguration+JSONSerializable.h"

@implementation AMADataMigrationTo620

- (NSString *)migrationKey
{
    return AMAStorageStringKeyDidApplyDataMigrationFor620;
}

- (void)applyMigrationToDatabase:(id<AMADatabaseProtocol>)database
{
    AMAMetricaPersistentConfiguration *persistent = [AMAMetricaConfiguration sharedInstance].persistent;
    
    id<AMAKeyValueStoring> kvStorage = database.storageProvider.cachingStorage;
    
    NSDictionary *dictionary = [kvStorage jsonDictionaryForKey:AMAStorageStringKeyAppMetricaClientConfiguration error:nil];
    AMAAppMetricaConfiguration *configuration = [[AMAAppMetricaConfiguration alloc] initWithJSON:dictionary];
    
    if (configuration != nil) {
        persistent.appMetricaClientConfiguration = configuration;
    }
}

@end
