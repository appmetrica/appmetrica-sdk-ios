#import "AMAAppMetricaConfigurationStorageCoordinator.h"
#import "AMAAppMetricaConfigurationFileStorage.h"
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

- (AMAAppMetricaConfiguration *)loadConfiguration
{
    AMAAppMetricaConfiguration *configuration = [self.privateStorage loadConfiguration];
    if (configuration == nil) {
        configuration = [self.groupStorage loadConfiguration];
    }
    return configuration;
}

- (void)saveConfiguration:(nonnull AMAAppMetricaConfiguration *)configuration
{
    [self.privateStorage saveConfiguration:configuration];

    if ([AMAPlatformDescription runEnvronment] == AMARunEnvironmentMainApp) {
        [self.groupStorage saveConfiguration:configuration];
    }
}

@end
