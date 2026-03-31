#import "AMAAppMetricaConfigurationStorageFactory.h"
#import "AMAAppGroupIdentifierProvider.h"
#import "AMAAppMetricaConfigurationFileStorage.h"
#import "AMAAppMetricaConfigurationStorageCoordinator.h"

#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>
#import <AppMetricaStorageUtils/AppMetricaStorageUtils.h>

static NSString *const AMAConfigurationFileName = @"configuration.json";

@implementation AMAAppMetricaConfigurationStorageFactory

+ (id<AMAAppMetricaConfigurationStoring>)configurationStorage
{
    AMAAppGroupIdentifierProvider *appGroupIdentifierProvider = [AMAAppGroupIdentifierProvider sharedInstance];

    NSString *privateFilePath = [NSString stringWithFormat:@"%@/%@",
                                 AMAFileUtility.persistentPath,
                                 AMAConfigurationFileName];
    AMADiskFileStorage *privateDiskStorage = [AMADiskFileStorage diskFileStorageWithPath:privateFilePath
                                                                                 options:AMADiskFileStorageOptionNoBackup];
    AMAAppMetricaConfigurationFileStorage *privateStorage =
        [AMAAppMetricaConfigurationFileStorage appMetricaConfigurationFileStorageWithFileStorage:privateDiskStorage];

    AMAAppMetricaConfigurationFileStorage *groupStorage = nil;
    NSString *appGroupIdentifier = appGroupIdentifierProvider.appGroupIdentifier;
    if (appGroupIdentifier != nil) {
        NSString *groupFilePath = [NSString stringWithFormat:@"%@/%@",
                                   [AMAFileUtility persistentPathForApplicationGroup:appGroupIdentifier],
                                   AMAConfigurationFileName];
        AMADiskFileStorage *groupDiskStorage = [AMADiskFileStorage diskFileStorageWithPath:groupFilePath
                                                                                   options:AMADiskFileStorageOptionNoBackup];
        groupStorage = [AMAAppMetricaConfigurationFileStorage appMetricaConfigurationFileStorageWithFileStorage:groupDiskStorage];
    }

    return [[AMAAppMetricaConfigurationStorageCoordinator alloc] initWithPrivateStorage:privateStorage
                                                                           groupStorage:groupStorage];
}

@end
