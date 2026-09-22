#import "AMAAppMetricaConfigurationStorageFactory.h"
#import "AMAAppGroupIdentifierProvider.h"
#import "AMAAppMetricaConfigurationFileStorage.h"
#import "AMAAppMetricaConfigurationStorageCoordinator.h"

#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>
#import <AppMetricaStorageUtils/AppMetricaStorageUtils.h>

@import AppMetricaSynchronization;

static NSString *const AMAConfigurationFileName = @"configuration.json";
static NSString *const AMAConfigurationLockFileName = @"configuration.lock";

@implementation AMAAppMetricaConfigurationStorageFactory

+ (id<AMAAppMetricaConfigurationStoring>)configurationStorage
{
    AMAAppGroupIdentifierProvider *appGroupIdentifierProvider = [AMAAppGroupIdentifierProvider sharedInstance];

    NSString *privateDirectory = AMAFileUtility.persistentPath;
    NSString *privateFilePath = [privateDirectory stringByAppendingPathComponent:AMAConfigurationFileName];
    AMADiskFileStorage *privateDiskStorage =
        [AMADiskFileStorage diskFileStorageWithPath:privateFilePath
                                            options:AMADiskFileStorageOptionNoBackup | AMADiskFileStorageOptionCreateDirectory];
    AMAAppMetricaConfigurationFileStorage *privateStorage =
        [AMAAppMetricaConfigurationFileStorage appMetricaConfigurationFileStorageWithFileStorage:privateDiskStorage];

    AMAAppMetricaConfigurationFileStorage *groupStorage = nil;
    NSString *lockDirectory = privateDirectory;

    NSString *appGroupIdentifier = appGroupIdentifierProvider.appGroupIdentifier;
    if (appGroupIdentifier != nil) {
        NSString *groupDirectory = [AMAFileUtility persistentPathForApplicationGroup:appGroupIdentifier];
        if (groupDirectory.length > 0) {
            NSString *groupFilePath = [groupDirectory stringByAppendingPathComponent:AMAConfigurationFileName];
            AMADiskFileStorage *groupDiskStorage =
                [AMADiskFileStorage diskFileStorageWithPath:groupFilePath
                                                    options:AMADiskFileStorageOptionNoBackup | AMADiskFileStorageOptionCreateDirectory];
            groupStorage =
                [AMAAppMetricaConfigurationFileStorage appMetricaConfigurationFileStorageWithFileStorage:groupDiskStorage];
            lockDirectory = groupDirectory;
        }
    }

    AMAFileLockExecutor *lock =
        [[AMAFileLockExecutor alloc] initWithFilePath:
            [lockDirectory stringByAppendingPathComponent:AMAConfigurationLockFileName]];

    return [[AMAAppMetricaConfigurationStorageCoordinator alloc] initWithPrivateStorage:privateStorage
                                                                           groupStorage:groupStorage
                                                                                   lock:lock];
}

@end
