
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMAStartupParameters.h"
#import "AMAStartupClientIdentifier.h"
#import "AMAStartupClientIdentifierFactory.h"
#import "AMAMetricaConfigurationTestUtilities.h"
#import <AppMetricaPlatform/AppMetricaPlatform.h>

SPEC_BEGIN(AMAStartupParametersTests)

describe(@"AMAStartupParameters", ^{

    NSMutableDictionary *__block expectedParameters = nil;
    AMAStartupClientIdentifier *__block startupIdentifier = nil;

    beforeEach(^{
        [AMAPlatformDescription stub:@selector(appID)];
        [AMAPlatformDescription stub:@selector(appDebuggable) andReturn:theValue(NO)];
        [AMAPlatformDescription stub:@selector(manufacturer)];
        [AMAPlatformDescription stub:@selector(model)];
        [AMAPlatformDescription stub:@selector(OSVersion)];
        [AMAPlatformDescription stub:@selector(screenWidth)];
        [AMAPlatformDescription stub:@selector(screenHeight)];
        [AMAPlatformDescription stub:@selector(screenDPI)];
        [AMAPlatformDescription stub:@selector(scalefactor)];
        [AMAPlatformDescription stub:@selector(SDKVersionName)];

        [AMAPlatformLocaleState stub:@selector(fullLocaleIdentifier)];

        startupIdentifier = [AMAStartupClientIdentifier nullMock];
        [AMAStartupClientIdentifierFactory stub:@selector(startupClientIdentifier) andReturn:startupIdentifier];

        [AMAMetricaConfigurationTestUtilities stubConfigurationWithNullMock];
        
        NSString *appPlatform = @"iphone";
        NSString *deviceType = @"phone";
#if TARGET_OS_TV
        appPlatform = @"iphone";
        deviceType = @"tv";
#endif

        expectedParameters = [@{
            @"app_debuggable": @"0",
            @"app_platform": appPlatform,
            @"atc": @"1",
            @"b": @"1",
            @"device_type": deviceType,
            @"deviceid": @"",
            @"features": @"ea,exc,pc,vc,dlch",
            @"protocol_version": @"2",
            @"queries": @"1",
            @"query_hosts": @"2",
            @"permissions": @"1",
            @"detect_locale": @"1",
            @"stat_sending": @"1",
            @"exc": @"1",
            @"flc": @"1",
            @"slc" : @"1",
            @"rp" : @"1",
            @"pc" : @"1",
            @"asa" : @"1",
            @"at" : @"1",
            @"scv" :@"1",
            @"scm": @"1",
            @"srm": @"1",
            @"senm": @"1",
            @"su": @"1",
            @"exta" : @"1",
        } mutableCopy];
    });
    afterEach(^{
        [AMAPlatformDescription clearStubs];
        [AMAMetricaConfigurationTestUtilities destubConfiguration];
        [AMAStartupClientIdentifierFactory clearStubs];
        [AMAMetricaConfiguration.sharedInstance clearStubs];
        [AMAMetricaConfiguration.sharedInstance.startup clearStubs];
    });

    it(@"Should return minimal parameters", ^{
        [[[AMAStartupParameters parameters] should] equal:expectedParameters];
    });
    it(@"Should fill app_debuggable with 1", ^{
        [AMAPlatformDescription stub:@selector(appDebuggable) andReturn:theValue(YES)];
        expectedParameters[@"app_debuggable"] = @"1";
        [[[AMAStartupParameters parameters] should] equal:expectedParameters];
    });
    it(@"Should fill appID", ^{
        NSString *appID = @"com.app.id";
        [AMAPlatformDescription stub:@selector(appID) andReturn:appID];
        expectedParameters[@"app_id"] = appID;
        [[[AMAStartupParameters parameters] should] equal:expectedParameters];
    });
    it(@"Should fill locale", ^{
        NSString *locale = @"ru_BY";
        [AMAPlatformLocaleState stub:@selector(fullLocaleIdentifier) andReturn:locale];
        expectedParameters[@"locale"] = locale;
        [[[AMAStartupParameters parameters] should] equal:expectedParameters];
    });
    it(@"Should fill manufacturer", ^{
        NSString *manufacturer = @"Company";
        [AMAPlatformDescription stub:@selector(manufacturer) andReturn:manufacturer];
        expectedParameters[@"manufacturer"] = manufacturer;
        [[[AMAStartupParameters parameters] should] equal:expectedParameters];
    });
    it(@"Should fill model", ^{
        NSString *model = @"Phone 3";
        [AMAPlatformDescription stub:@selector(model) andReturn:model];
        expectedParameters[@"model"] = model;
        [[[AMAStartupParameters parameters] should] equal:expectedParameters];
    });
    it(@"Should fill os_version", ^{
        NSString *osVersion = @"4.2.0";
        [AMAPlatformDescription stub:@selector(OSVersion) andReturn:osVersion];
        expectedParameters[@"os_version"] = osVersion;
        [[[AMAStartupParameters parameters] should] equal:expectedParameters];
    });
    it(@"Should fill screen_width", ^{
        NSNumber *screenWidth = @23;
        [AMAPlatformDescription stub:@selector(screenWidth) andReturn:screenWidth];
        expectedParameters[@"screen_width"] = screenWidth;
        [[[AMAStartupParameters parameters] should] equal:expectedParameters];
    });
    it(@"Should fill screen_height", ^{
        NSNumber *screenHeight = @42;
        [AMAPlatformDescription stub:@selector(screenHeight) andReturn:screenHeight];
        expectedParameters[@"screen_height"] = screenHeight;
        [[[AMAStartupParameters parameters] should] equal:expectedParameters];
    });
    it(@"Should fill screen_dpi", ^{
        NSNumber *screenDPI = @1.6;
        [AMAPlatformDescription stub:@selector(screenDPI) andReturn:screenDPI];
        expectedParameters[@"screen_dpi"] = screenDPI;
        [[[AMAStartupParameters parameters] should] equal:expectedParameters];
    });
    it(@"Should fill scalefactor", ^{
        NSNumber *scaleFactor = @3.2;
        [AMAPlatformDescription stub:@selector(scalefactor) andReturn:scaleFactor];
        expectedParameters[@"scalefactor"] = scaleFactor;
        [[[AMAStartupParameters parameters] should] equal:expectedParameters];
    });
    it(@"Should fill identifiers", ^{
        NSString *deviceIDHash = @"deviceidhash";
        NSDictionary *parameters = @{
                                     @"deviceid": @"deviceid",
                                     deviceIDHash: deviceIDHash,
                                     @"uuid": @"uuid",
                                     };
        [startupIdentifier stub:@selector(startupParameters) andReturn:parameters];
        [expectedParameters addEntriesFromDictionary:parameters];
        expectedParameters[deviceIDHash] = nil;
        [[[AMAStartupParameters parameters] should] equal:expectedParameters];
    });
    it(@"Should fill analytics_sdk_version_name", ^{
        NSString *sdkVersion = @"4.2.0";
        [AMAPlatformDescription stub:@selector(SDKVersionName) andReturn:sdkVersion];
        expectedParameters[@"analytics_sdk_version_name"] = sdkVersion;
        [[[AMAStartupParameters parameters] should] equal:expectedParameters];
    });
    it(@"Should fill country_init", ^{
        NSString *initialCountry = @"by";
        [[AMAMetricaConfiguration sharedInstance].startup stub:@selector(initialCountry) andReturn:initialCountry];
        expectedParameters[@"country_init"] = initialCountry;
        [[[AMAStartupParameters parameters] should] equal:expectedParameters];
    });
    it(@"Should not send detect_locale in second request", ^{
        [[AMAMetricaConfiguration sharedInstance].persistent stub:@selector(hadFirstStartup) andReturn:theValue(YES)];
        expectedParameters[@"detect_locale"] = nil;
        [[[AMAStartupParameters parameters] should] equal:expectedParameters];
    });
});

SPEC_END
