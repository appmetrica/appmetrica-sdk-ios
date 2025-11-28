
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMALocationRequestParameters.h"
#import "AMAMetricaConfigurationTestUtilities.h"
#import "AMAStartupClientIdentifierFactory.h"
#import "AMAStartupClientIdentifier.h"
#import "AMAIdentifiersTestUtilities.h"
#import <AppMetricaPlatform/AppMetricaPlatform.h>

SPEC_BEGIN(AMALocationRequestParametersTests)

describe(@"AMALocationRequestParameters", ^{

    NSNumber *const identifier = @42;
    NSString *const ifa = @"78753A44-4D6F-1226-9C60-0050E4C00067";

    beforeEach(^{
        AMAStartupClientIdentifier *startupClientIdentifier = [AMAStartupClientIdentifier nullMock];
        [startupClientIdentifier stub:@selector(IFV) andReturn:@"IFV"];
        [startupClientIdentifier stub:@selector(UUID) andReturn:@"UUID"];
        [startupClientIdentifier stub:@selector(deviceID) andReturn:@"DEVICE_ID"];
        [AMAStartupClientIdentifierFactory stub:@selector(startupClientIdentifier) andReturn:startupClientIdentifier];

        [AMAPlatformDescription stub:@selector(appFramework) andReturn:@"FRAMEWORK"];
        [AMAPlatformDescription stub:@selector(appID) andReturn:@"APP_ID"];
        [AMAPlatformDescription stub:@selector(OSVersion) andReturn:@"OS_VERSION"];
        [AMAPlatformDescription stub:@selector(OSAPILevel) andReturn:theValue(9)];
        [AMAPlatformDescription stub:@selector(deviceType) andReturn:@"DEVICE_TYPE"];
        [AMAPlatformDescription stub:@selector(isDeviceRooted) andReturn:theValue(NO)];
        [AMAPlatformDescription stub:@selector(SDKVersionName) andReturn:@"SDK_VERSION_NAME"];
        [AMAPlatformDescription stub:@selector(SDKBuildType) andReturn:@"SDK_BUILD_TYPE"];
        [AMAPlatformDescription stub:@selector(SDKBuildNumber) andReturn:theValue(16)];

        [AMAMetricaConfigurationTestUtilities stubConfigurationWithNullMock];
        AMAMetricaConfiguration *metricaConfiguration = [AMAMetricaConfiguration sharedInstance];
        [metricaConfiguration.inMemory stub:@selector(appVersion) andReturn:@"APP_VERSION"];
        [metricaConfiguration.inMemory stub:@selector(appBuildNumber) andReturn:theValue(23)];
        
        [AMAIdentifiersTestUtilities stubIdfaWithEnabled:YES value:ifa];
    });
    afterEach(^{
        [AMAPlatformDescription clearStubs];
        [AMAIdentifiersTestUtilities destubAll];
        [AMAMetricaConfigurationTestUtilities destubConfiguration];
        [AMAMetricaConfiguration clearStubs];
        [AMAMetricaConfiguration.sharedInstance clearStubs];
        [AMAMetricaConfiguration.sharedInstance.inMemory clearStubs];
    });

    it(@"Should return valid parameters", ^{
        NSDictionary *parameters = [AMALocationRequestParameters parametersWithRequestIdentifier:identifier];
        [[parameters should] equal:@{
            @"analytics_sdk_build_number": @"16",
            @"analytics_sdk_build_type": @"SDK_BUILD_TYPE",
            @"analytics_sdk_version_name": @"SDK_VERSION_NAME",
            @"app_build_number": @"23",
            @"app_framework": @"FRAMEWORK",
            @"app_id": @"APP_ID",
            @"app_platform": @"iOS",
            @"app_version_name": @"APP_VERSION",
            @"device_type": @"DEVICE_TYPE",
            @"deviceid": @"DEVICE_ID",
            @"encrypted_request": @"1",
            @"ifv": @"IFV",
            @"is_rooted": @"0",
            @"os_api_level": @"9",
            @"os_version": @"OS_VERSION",
            @"request_id": @"42",
            @"uuid": @"UUID",
        }];
    });
    it(@"Should handle rooted devices", ^{
        [AMAPlatformDescription stub:@selector(isDeviceRooted) andReturn:theValue(YES)];
        NSDictionary *parameters = [AMALocationRequestParameters parametersWithRequestIdentifier:identifier];
        [[parameters[@"is_rooted"] should] equal:@"1"];
    });

});

SPEC_END

