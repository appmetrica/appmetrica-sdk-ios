
#import "AMAAppStateManagerTestHelper.h"
#import <Kiwi/Kiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMACore.h"
#import "AMAMetricaConfigurationTestUtilities.h"
#import "AMAIdentifiersTestUtilities.h"
#import <AppMetricaPlatform/AppMetricaPlatform.h>

@implementation AMAAppStateManagerTestHelper

- (id)init
{
    self = [super init];
    if (self != nil) {
        _appVersionName = @"1.00";
        _kitVersionName = @"1.0.0";
        _kitBuildNumber = 627;
        _kitBuildType = @"source";
        _OSVersion = @"7.0";
        _OSAPILevel = 7;
        _locale = @"en_US";
        _isRooted = NO;
        _UUID = @"a1234567890123456789012345678901";
        _deviceID = @"E621E1F8-C36C-495A-93FC-0C247A3E6E5F";
        _IFV = @"A1112222-C36C-495A-93FC-0C247A3E6B21";
        _IFA = @"B2223333-C36C-495A-93FC-0C247A3E6B22";
        _LAT = NO;
        _appBuildNumber = 55;
        _appDebuggable = YES;
    }
    return self;
}

- (void)stubApplicationState
{
    [AMAMetricaConfiguration sharedInstance].inMemory.appVersion = self.appVersionName;
    [AMAMetricaConfiguration sharedInstance].inMemory.appBuildNumber = self.appBuildNumber;
    [AMAPlatformDescription stub:@selector(SDKVersionName) andReturn:self.kitVersionName];
    [AMAPlatformDescription stub:@selector(SDKBuildNumber) andReturn:theValue(self.kitBuildNumber)];
    [AMAPlatformDescription stub:@selector(SDKBuildType) andReturn:self.kitBuildType];
    [AMAPlatformDescription stub:@selector(OSVersion) andReturn:self.OSVersion];
    [AMAPlatformDescription stub:@selector(appDebuggable) andReturn:theValue(self.appDebuggable)];
    [AMAPlatformDescription stub:@selector(OSAPILevel) andReturn:theValue(self.OSAPILevel)];
    [AMAPlatformLocaleState stub:@selector(fullLocaleIdentifier) andReturn:self.locale];
    [AMAPlatformDescription stub:@selector(isDeviceRooted) andReturn:theValue(self.isRooted)];
    [AMAIdentifiersTestUtilities stubIFV:self.IFV];
    [[AMAMetricaConfiguration sharedInstance].persistent stub:@selector(deviceID) andReturn:self.deviceID];
    [AMAIdentifiersTestUtilities stubIdfaWithEnabled:(self.LAT == NO) value:self.IFA];
    [AMAIdentifiersTestUtilities stubUUID:self.UUID];
}

@end
