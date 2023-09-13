
#import "AMAMetricaConfigurationTestUtilities.h"
#import "AMAMockDatabase.h"
#import "AMAKeychainBridgeMock.h"
#import <Kiwi/Kiwi.h>
#import "AMAInstantFeaturesConfiguration.h"
#import <AppMetricaPlatform/AppMetricaPlatform.h>

@implementation AMAMetricaConfigurationTestUtilities

+ (void)stubConfigurationWithAppVersion:(NSString *)appVersion buildNumber:(uint32_t)buildNumber
{
    [AMAPlatformDescription stub:@selector(appVersion) andReturn:appVersion];
    [AMAPlatformDescription stub:@selector(appBuildNumber) andReturn:[@(buildNumber) stringValue]];
    [self stubConfiguration];
}

+ (void)stubConfiguration
{
    AMAKeychainBridge *keychainBridge = [[AMAKeychainBridgeMock alloc] init];
    id<AMADatabaseProtocol> database = [AMAMockDatabase configurationDatabase];
    AMAMetricaConfiguration *config = [[AMAMetricaConfiguration alloc] initWithKeychainBridge:keychainBridge
                                                                                     database:database];
    [AMAMetricaConfiguration stub:@selector(sharedInstance) andReturn:config];
}

+ (void)stubConfigurationWithNullMock
{
    AMAMetricaConfiguration *configuration = [AMAMetricaConfiguration nullMock];
    [configuration stub:@selector(inMemory) andReturn:[[AMAMetricaInMemoryConfiguration alloc] init]];
    [configuration stub:@selector(persistent) andReturn:[AMAMetricaPersistentConfiguration nullMock]];
    [configuration stub:@selector(startup) andReturn:[AMAStartupParametersConfiguration nullMock]];
    [configuration stub:@selector(instant) andReturn:[AMAInstantFeaturesConfiguration nullMock]];
    
    [AMAMetricaConfiguration stub:@selector(sharedInstance) andReturn:configuration];
}

@end
