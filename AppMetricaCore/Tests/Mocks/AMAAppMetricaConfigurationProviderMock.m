#import "AMAAppMetricaConfigurationProviderMock.h"

@implementation AMAAppMetricaConfigurationProviderMock

- (AMAAppMetricaConfiguration *)loadConfiguration
{
    [self.loadConfigurationExpectation fulfill];
    return self.configuration;
}

- (void)saveConfiguration:(AMAAppMetricaConfiguration *)configuration
{
    [self.saveConfigurationExpectation fulfill];
    self.configuration = configuration;
}

@end
