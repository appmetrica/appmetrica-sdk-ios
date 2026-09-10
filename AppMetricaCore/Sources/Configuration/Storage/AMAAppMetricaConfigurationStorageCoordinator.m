#import "AMAAppMetricaConfigurationStorageCoordinator.h"
#import "AMAAppMetricaConfigurationFileStorage.h"
#import "AMAAppMetricaConfigurationSnapshot.h"
#import "AMAAppGroupIdentifierProvider.h"
#import <AppMetricaPlatform/AppMetricaPlatform.h>
#import <AppMetricaStorageUtils/AppMetricaStorageUtils.h>


@interface AMAAppMetricaConfigurationStorageCoordinator ()

@property (nonatomic, strong, readonly, nonnull) id<AMAAppMetricaConfigurationStoring> privateStorage;
@property (nonatomic, strong, readonly, nullable) id<AMAAppMetricaConfigurationStoring> groupStorage;

@end

@implementation AMAAppMetricaConfigurationStorageCoordinator

- (instancetype)initWithPrivateStorage:(id<AMAAppMetricaConfigurationStoring>)privateStorage
                          groupStorage:(id<AMAAppMetricaConfigurationStoring>)groupStorage
{
    self = [super init];
    if (self) {
        _privateStorage = privateStorage;
        _groupStorage = groupStorage;
    }
    return self;
}

- (AMAAppMetricaConfigurationSnapshot *)loadSnapshot
{
    AMAAppMetricaConfigurationSnapshot *privateSnapshot = [self.privateStorage loadSnapshot];
    if (privateSnapshot.configuration != nil) {
        return [[AMAAppMetricaConfigurationSnapshot alloc] initWithConfiguration:privateSnapshot.configuration
                                                                         savedAt:privateSnapshot.savedAt
                                                                          source:AMAAppMetricaConfigurationSnapshotSourcePrivate];
    }

    AMAAppMetricaConfigurationSnapshot *groupSnapshot = [self.groupStorage loadSnapshot];
    if (groupSnapshot.configuration != nil) {
        return [[AMAAppMetricaConfigurationSnapshot alloc] initWithConfiguration:groupSnapshot.configuration
                                                                         savedAt:groupSnapshot.savedAt
                                                                          source:AMAAppMetricaConfigurationSnapshotSourceGroup];
    }
    return nil;
}

- (void)saveSnapshot:(AMAAppMetricaConfigurationSnapshot *)snapshot
{
    if (snapshot.source == AMAAppMetricaConfigurationSnapshotSourceGroup) {
        [self.groupStorage saveSnapshot:snapshot];
        return;
    }

    [self.privateStorage saveSnapshot:snapshot];

    if ([AMAPlatformDescription runEnvronment] == AMARunEnvironmentMainApp) {
        [self.groupStorage saveSnapshot:snapshot];
    }
}

- (void)clearSnapshot:(AMAAppMetricaConfigurationSnapshot *)snapshot
{
    if (snapshot.source == AMAAppMetricaConfigurationSnapshotSourceGroup) {
        [self.groupStorage clearSnapshot:snapshot];
        return;
    }
    [self.privateStorage clearSnapshot:snapshot];
}

@end
