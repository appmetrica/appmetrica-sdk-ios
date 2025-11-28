
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMARequestParametersTestHelper.h"
#import "AMABundleInfoProviderMock.h"
#import <AppMetricaPlatform/AppMetricaPlatform.h>

@implementation AMARequestParametersTestHelper

- (id)init
{
    self = [super init];
    if (self != nil) {
        _deviceType = @"phone";
        _appPlatform = @"iOS";
        _manufacturer = @"Apple";
        _model = @"x86-64";
        _screenWidth = @"320";
        _screenHeight = @"480";
        _scalefactor = @"2";
        _screenDPI = @"326";
        _appID = @"io.appmetrica.tests";
        _mainAppID = @"io.appmetrica.tests";
        _extensionAppID = @"io.appmetrica.tests.extension";
        _version = @"1";
        _appFramework = @"native";
        
        _appInfoProvider = [[AMABundleInfoProviderMock alloc] initWithAppID:self.appID
                                                    copyOtherPropertiesFrom:[AMAPlatformDescription currentAppInfo]];
        _mainAppInfoProvider = [[AMABundleInfoProviderMock alloc] initWithAppID:self.mainAppID
                                                        copyOtherPropertiesFrom:[AMAPlatformDescription mainAppInfo]];
        _extensionAppInfoProvider = [[AMABundleInfoProviderMock alloc] initWithAppID:self.extensionAppID
                                                             copyOtherPropertiesFrom:[AMAPlatformDescription extensionAppInfo]];
    }
    return self;
}

- (void)configureStubs
{
    [AMAPlatformDescription stub:@selector(deviceType) andReturn:self.deviceType];
    [AMAPlatformDescription stub:@selector(OSName) andReturn:self.appPlatform];
    [AMAPlatformDescription stub:@selector(manufacturer) andReturn:self.manufacturer];
    [AMAPlatformDescription stub:@selector(model) andReturn:self.model];
    [AMAPlatformDescription stub:@selector(screenWidth) andReturn:self.screenWidth];
    [AMAPlatformDescription stub:@selector(screenHeight) andReturn:self.screenHeight];
    [AMAPlatformDescription stub:@selector(scalefactor) andReturn:self.scalefactor];
    [AMAPlatformDescription stub:@selector(screenDPI) andReturn:self.screenDPI];
    [AMAPlatformDescription stub:@selector(appFramework) andReturn:self.appFramework];
    [AMAPlatformDescription stub:@selector(currentAppInfo) andReturn:self.appInfoProvider];
    [AMAPlatformDescription stub:@selector(mainAppInfo) andReturn:self.appInfoProvider];
    [AMAPlatformDescription stub:@selector(extensionAppInfo) andReturn:self.extensionAppInfoProvider];
}

- (void)destubs
{
    [AMAPlatformDescription clearStubs];
}

@end
