
#import "AMADataMigrationTo590.h"
#import "AMADatabaseConstants.h"
#import "AMAStorageKeys.h"
#import "AMADatabaseProtocol.h"
#import "AMAMigrationUtils.h"
#import "AMAAppMetricaUUIDMigrator.h"
#import "AMAMetricaConfiguration.h"
#import "AMAMetricaConfiguration+MigrationTo590.h"
#import <AppMetricaPlatform/AppMetricaPlatform.h>

@import AppMetricaIdentifiers;

@implementation AMADataMigrationTo590

- (NSString *)migrationKey
{
    return AMAStorageStringKeyDidApplyDataMigrationFor590;
}

- (void)applyMigrationToDatabase:(id<AMADatabaseProtocol>)database
{
    if ([AMAPlatformDescription isExtension] == NO) {
        id<AMAIdentifierProviding> identifierProvider = [AMAMetricaConfiguration sharedInstance].identifierProvider;
        [self migrateUUID:identifierProvider];
        [self migrateDeviceID:database identifierProvider:identifierProvider];
    }
}

- (void)migrateUUID:(id<AMAIdentifierProviding>)identifierProvider
{
    AMAAppMetricaUUIDMigrator *uuidMigrator = [[AMAAppMetricaUUIDMigrator alloc] init];
    NSString *uuid = [uuidMigrator migrateAppMetricaUUID];
    
    if ([uuid length] > 0) {
        [identifierProvider updateAppMigrationDataWithUuid:uuid];
    }
}

- (void)migrateDeviceID:(id<AMADatabaseProtocol>)database
     identifierProvider:(id<AMAIdentifierProviding>)identifierProvider
{
    id<AMAKeyValueStoring> storage = database.storageProvider.cachingStorage;
    
    NSString *(^dbStorageKey)(NSString *) = ^NSString *(NSString *key) {
        return [NSString stringWithFormat:@"fallback-keychain-%@", key];
    };
    
    NSString *deviceID = [storage stringForKey:dbStorageKey(AMAAppMetricaIdentifiersKeys.deviceID) error:nil];
    NSString *deviceIDHash = [storage stringForKey:dbStorageKey(AMAAppMetricaIdentifiersKeys.deviceIDHash) error:nil];
    
    if ([deviceID length] > 0) {
        [identifierProvider updateAppMigrationDataWithDeviceID:deviceID deviceIDHash:deviceIDHash];
    }
}

@end
