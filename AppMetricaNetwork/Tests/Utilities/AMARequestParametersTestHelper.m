
#import <Kiwi/Kiwi.h>
#import "AMARequestParametersTestHelper.h"
#import <AppMetricaPlatform/AppMetricaPlatform.h>

@implementation AMARequestParametersTestHelper

- (id)init
{
    self = [super init];
    if (self != nil) {
        _isIPad = NO;
        _appPlatform = @"iOS";
        _manufacturer = @"Apple";
        _model = @"x86-64";
        _screenWidth = @"320";
        _screenHeight = @"480";
        _scalefactor = @"2";
        _screenDPI = @"326";
        _appID = @"io.appmetrica.tests";
        _version = @"1";
        _appFramework = @"native";
    }
    return self;
}

- (void)configureStubs
{
    [AMAPlatformDescription stub:@selector(deviceTypeIsIPad) andReturn:theValue(self.isIPad)];
    [AMAPlatformDescription stub:@selector(OSName) andReturn:self.appPlatform];
    [AMAPlatformDescription stub:@selector(manufacturer) andReturn:self.manufacturer];
    [AMAPlatformDescription stub:@selector(model) andReturn:self.model];
    [AMAPlatformDescription stub:@selector(screenWidth) andReturn:self.screenWidth];
    [AMAPlatformDescription stub:@selector(screenHeight) andReturn:self.screenHeight];
    [AMAPlatformDescription stub:@selector(scalefactor) andReturn:self.scalefactor];
    [AMAPlatformDescription stub:@selector(screenDPI) andReturn:self.screenDPI];
    [AMAPlatformDescription stub:@selector(appID) andReturn:self.appID];
    [AMAPlatformDescription stub:@selector(appFramework) andReturn:self.appFramework];
}

@end
