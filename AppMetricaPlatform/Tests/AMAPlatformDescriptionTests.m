
#import <Kiwi/Kiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import <AppMetricaPlatform/AppMetricaPlatform.h>
#import "AMAAppVersionProvider.h"
#import "Mocks/AMAAppVersionProviderMock.h"
#import "AMADeviceDescription.h"

@interface AMAPlatformDescription (Tests)

+ (AMAAppBuildType)currentAppBuildType;

@end

SPEC_BEGIN(AMAPlatformDescriptionTests)

describe(@"AMAPlatformDescription", ^{
    
    context(@"Build type", ^{
        void (^stubAppStoreReceiptURL)(NSString *path, BOOL exists) = ^(NSString *path, BOOL exists) {
            NSURL *appStoreReceiptURL = [NSURL URLWithString:path];
            NSBundle *mainBundleMock = [NSBundle nullMock];
            [NSBundle stub:@selector(mainBundle) andReturn:mainBundleMock];
            [mainBundleMock stub:@selector(appStoreReceiptURL) andReturn:appStoreReceiptURL];
            NSFileManager *fileManagerMock = [NSFileManager nullMock];
            [NSFileManager stub:@selector(defaultManager) andReturn:fileManagerMock];
            [fileManagerMock stub:@selector(fileExistsAtPath:) andReturn:theValue(exists)];
        };
        void (^stubIsDebuggerAttached)(BOOL attached) = ^(BOOL attached) {
            [AMAPlatformDescription stub:@selector(isDebuggerAttached) andReturn:theValue(attached)];
        };
        void (^stubEmbeddedProvisioningProfile)(NSDictionary *profile) = ^(NSDictionary *profile) {
            [AMAPlatformDescription stub:@selector(embeddedMobileProvisioning) andReturn:profile];
        };
        context(@"AppStore", ^{
            it(@"Should return this build type for valid AppStore receipt URL", ^{
                stubAppStoreReceiptURL(@"/some/path/ends/with/receipt", YES);
                [[theValue([AMAPlatformDescription currentAppBuildType]) should] equal:theValue(AMAAppBuildTypeAppStore)];
            });
            it(@"Should not return this build type if AppStore receipt file dosen't exist", ^{
                stubAppStoreReceiptURL(@"/some/path/ends/with/receipt", NO);
                [[theValue([AMAPlatformDescription currentAppBuildType]) shouldNot] equal:theValue(AMAAppBuildTypeAppStore)];
            });
        });
        context(@"Debug", ^{
            beforeEach(^{
                stubAppStoreReceiptURL(@"/invalid/path", NO);
            });
            it(@"Should return this build type if debugger attached", ^{
                stubIsDebuggerAttached(YES);
                [[theValue([AMAPlatformDescription currentAppBuildType]) should] equal:theValue(AMAAppBuildTypeDebug)];
            });
            it(@"Should return this build type if get-task-allow is YES", ^{
                stubIsDebuggerAttached(NO);
                stubEmbeddedProvisioningProfile(@{ @"Entitlements" : @{ @"get-task-allow" : @YES } });
                [[theValue([AMAPlatformDescription currentAppBuildType]) should] equal:theValue(AMAAppBuildTypeDebug)];
            });
            it(@"Should not return this build type if debugger not attached and get-task-allow is NO", ^{
                stubIsDebuggerAttached(NO);
                stubEmbeddedProvisioningProfile(@{ @"Entitlements" : @{ @"get-task-allow" : @NO } });
                [[theValue([AMAPlatformDescription currentAppBuildType]) shouldNot] equal:theValue(AMAAppBuildTypeDebug)];
            });
            it(@"Should not return this build type if AppStore receipt URL valid", ^{
                stubAppStoreReceiptURL(@"/some/path/ends/with/receipt", YES);
                stubIsDebuggerAttached(YES);
                [[theValue([AMAPlatformDescription currentAppBuildType]) shouldNot] equal:theValue(AMAAppBuildTypeDebug)];
            });
        });
        context(@"AdHoc", ^{
            beforeEach(^{
                stubAppStoreReceiptURL(@"/invalid/path", NO);
                stubIsDebuggerAttached(NO);
            });
            it(@"Should return this buld type if get-task-allow is NO", ^{
                stubEmbeddedProvisioningProfile(@{ @"Entitlements" : @{ @"get-task-allow" : @NO } });
                [[theValue([AMAPlatformDescription currentAppBuildType]) should] equal:theValue(AMAAppBuildTypeAdHoc)];
            });
            it(@"Should not return this buld type if embedded mobileprovision absent", ^{
                stubEmbeddedProvisioningProfile(nil);
                [[theValue([AMAPlatformDescription currentAppBuildType]) shouldNot] equal:theValue(AMAAppBuildTypeAdHoc)];
            });
        });
        context(@"TestFlight", ^{
            it(@"Should return this build type for sandbox AppStore receipt URL without debugger and embedded mobileprovision", ^{
                stubAppStoreReceiptURL(@"/some/path/ends/with/sandboxReceipt", NO);
                stubIsDebuggerAttached(NO);
                stubEmbeddedProvisioningProfile(nil);
                [[theValue([AMAPlatformDescription currentAppBuildType]) should] equal:theValue(AMAAppBuildTypeTestFlight)];
            });
        });
        context(@"Broken embedded mobileprovision", ^{
            beforeEach(^{
                stubAppStoreReceiptURL(@"/invalid/path", NO);
                stubIsDebuggerAttached(NO);
            });
            it(@"Should not raise if provision absent", ^{
                stubEmbeddedProvisioningProfile(nil);
                [[theBlock(^{
                    [AMAPlatformDescription currentAppBuildType];
                }) shouldNot] raise];
            });
            it(@"Should not raise if provision doesn't contain Entitlements key", ^{
                stubEmbeddedProvisioningProfile(@{});
                [[theBlock(^{
                    [AMAPlatformDescription currentAppBuildType];
                }) shouldNot] raise];
            });
            it(@"Should not raise if Entitlements key doesn't holds dictionary", ^{
                stubEmbeddedProvisioningProfile(@{ @"Entitlements" : @0 });
                [[theBlock(^{
                    [AMAPlatformDescription currentAppBuildType];
                }) shouldNot] raise];
            });
            it(@"Should not raise if Entitlements doesn't contains get-task-allow key", ^{
                stubEmbeddedProvisioningProfile(@{ @"Entitlements" : @{} });
                [[theBlock(^{
                    [AMAPlatformDescription currentAppBuildType];
                }) shouldNot] raise];
            });
            it(@"Should not raise if get-task-allow key doesn't holds number", ^{
                stubEmbeddedProvisioningProfile(@{ @"Entitlements" : @{ @"get-task-allow" : @[] } });
                [[theBlock(^{
                    [AMAPlatformDescription currentAppBuildType];
                }) shouldNot] raise];
            });
        });
        it(@"Should not raise on isDebuggerAttached call", ^{
            [[theBlock(^{
                [AMAPlatformDescription isDebuggerAttached];
            }) shouldNot] raise];
        });
    });

    context(@"App Debuggable", ^{
        void (^stubAppBuildType)(AMAAppBuildType appBuildType) = ^(AMAAppBuildType appBuildType) {
            [AMAPlatformDescription stub:@selector(appBuildType) andReturn:theValue(appBuildType)];
        };
        it(@"Should return YES for Debug app build type", ^{
            stubAppBuildType(AMAAppBuildTypeDebug);
            [[theValue([AMAPlatformDescription appDebuggable]) should] beYes];
        });
        it(@"Should return NO for AdHoc app build type", ^{
            stubAppBuildType(AMAAppBuildTypeAdHoc);
            [[theValue([AMAPlatformDescription appDebuggable]) should] beNo];
        });
        it(@"Should return NO for AppStore app build type", ^{
            stubAppBuildType(AMAAppBuildTypeAppStore);
            [[theValue([AMAPlatformDescription appDebuggable]) should] beNo];
        });
        it(@"Should return NO for TestFlight app build type", ^{
            stubAppBuildType(AMAAppBuildTypeTestFlight);
            [[theValue([AMAPlatformDescription appDebuggable]) should] beNo];
        });
        it(@"Should return NO for unknown app build type", ^{
            stubAppBuildType(AMAAppBuildTypeUnknown);
            [[theValue([AMAPlatformDescription appDebuggable]) should] beNo];
        });
    });
    
    context(@"SDK", ^{
        it(@"Should return version name", ^{
#ifdef AMA_VERSION_PRERELEASE_ID
            NSString *expected = [NSString stringWithFormat:@"%d.%d.%d-%s",
                                  AMA_VERSION_MAJOR, AMA_VERSION_MINOR, AMA_VERSION_PATCH, AMA_VERSION_PRERELEASE_ID];
#else
            NSString *expected = [NSString stringWithFormat:@"%d.%d.%d", AMA_VERSION_MAJOR, AMA_VERSION_MINOR, AMA_VERSION_PATCH];
#endif
            [[[AMAPlatformDescription SDKVersionName] should] equal:expected];
        });
        it(@"Should return build number", ^{
            [[theValue([AMAPlatformDescription SDKBuildNumber]) should] equal:theValue(AMA_BUILD_NUMBER)];
        });
        it(@"Should return undefined build type when use SPM", ^{
            [[[AMAPlatformDescription SDKBuildType] should] equal:@"undefined"];
        });
        it(@"Should return bundle name", ^{
            [[[AMAPlatformDescription SDKBundleName] should] equal:@"io.appmetrica"];
        });
        it(@"Should return user agent", ^{
            NSString *SDKName = @"io.appmetrica.analytics";
            NSString *versionName = [AMAPlatformDescription SDKVersionName];
            NSUInteger buildNumber = [AMAPlatformDescription SDKBuildNumber];
            
            NSString *userAgent = [AMAPlatformDescription SDKUserAgent];
            
            [[userAgent should] containString:[NSString stringWithFormat:@"%@/%@.%lu", SDKName, versionName, (unsigned long)buildNumber]];
        });
    });
    
    context(@"Application", ^{
        context(@"AppVersion provider", ^{
            AMAAppVersionProviderMock *__block provider = [[AMAAppVersionProviderMock alloc] init];
            AMAAppVersionProviderMock *__block allocedProvider = [AMAAppVersionProviderMock nullMock];
            beforeEach(^{
                [AMAAppVersionProvider stub:@selector(alloc) andReturn:allocedProvider];
                [allocedProvider stub:@selector(init) andReturn:provider];
            });
            
            it(@"Should return app version", ^{
                [[[AMAPlatformDescription appVersion] should] equal:[provider appVersion]];
            });
            it(@"Should return app version name", ^{
                [[[AMAPlatformDescription appVersionName] should] equal:[provider appVersionName]];
            });
            it(@"Should return app build number", ^{
                [[[AMAPlatformDescription appBuildNumber] should] equal:[provider appBuildNumber]];
            });
            it(@"Should return app id", ^{
                [[[AMAPlatformDescription appID] should] equal:[provider appID]];
            });
        });
        it(@"Should return app framework", ^{
            [[[AMAPlatformDescription appFramework] should] equal:@"native"];
        });
        
        context(@"isExtension", ^{
            it(@"Should return true if extension", ^{
                [[NSBundle mainBundle] stub:@selector(executablePath) andReturn:@".appex"];
                
                [[theValue([AMAPlatformDescription isExtension]) should] beYes];
            });
            
            it(@"Should return false if not extension", ^{
                [[NSBundle mainBundle] stub:@selector(executablePath) andReturn:@".app"];
                
                [[theValue([AMAPlatformDescription isExtension]) should] beNo];
            });
        });
        
        context(@"DeviceDescription", ^{
            it(@"Should return DeviceDescription appIdentifierPrefix", ^{
                NSString *prefix = @"prefix";
                [AMADeviceDescription stub:@selector(appIdentifierPrefix) andReturn:prefix];
                
                [[[AMAPlatformDescription appIdentifierPrefix] should] equal:prefix];
            });
            
            it(@"Should return DeviceDescription appPlatformIsIPad", ^{
                [AMADeviceDescription stub:@selector(appPlatformIsIPad) andReturn:theValue(YES)];
                
                [[theValue([AMAPlatformDescription appPlatformIsIPad]) should] beYes];
                
                [AMADeviceDescription stub:@selector(appPlatformIsIPad) andReturn:theValue(NO)];
                
                [[theValue([AMAPlatformDescription appPlatformIsIPad]) should] beNo];
            });
        });
    });
    
    context(@"OS", ^{
        it(@"Should return OS name", ^{
            [[[AMAPlatformDescription OSName] should] equal:@"iOS"];
        });
        
        it(@"Should return OS version", ^{
            NSString *OSVersion = @"13.37";
            [AMADeviceDescription stub:@selector(OSVersion) andReturn:OSVersion];
            
            [[[AMAPlatformDescription OSVersion] should] equal:OSVersion];
        });
        
        it(@"Should return OS APILevel", ^{
            NSString *OSVersion = @"14.48";
            [AMADeviceDescription stub:@selector(OSVersion) andReturn:OSVersion];
            NSString *apiLevel = [OSVersion componentsSeparatedByString:@"."].firstObject;

            [[theValue([AMAPlatformDescription OSAPILevel]) should] equal:theValue([apiLevel integerValue])];
        });
        
        it(@"Should return DeviceDescription jail status", ^{
            [AMADeviceDescription stub:@selector(isDeviceRooted) andReturn:theValue(YES)];

            [[theValue([AMAPlatformDescription isDeviceRooted]) should] beYes];
            
            [AMADeviceDescription stub:@selector(isDeviceRooted) andReturn:theValue(NO)];

            [[theValue([AMAPlatformDescription isDeviceRooted]) should] beNo];
        });
    });
    
    context(@"Device", ^{
        it(@"Should return DeviceDescription manufacturer", ^{
            NSString *manufacturer = @"Lockheed Martin";
            [AMADeviceDescription stub:@selector(manufacturer) andReturn:manufacturer];
            
            [[[AMAPlatformDescription manufacturer] should] equal:manufacturer];
        });
        
        it(@"Should return DeviceDescription screenDPI", ^{
            NSString *screenDPI = @"117";
            [AMADeviceDescription stub:@selector(screenDPI) andReturn:screenDPI];
            
            [[[AMAPlatformDescription screenDPI] should] equal:screenDPI];
        });
        
        it(@"Should return DeviceDescription screenWidth", ^{
            NSString *screenWidth = @"118";
            [AMADeviceDescription stub:@selector(screenWidth) andReturn:screenWidth];
            
            [[[AMAPlatformDescription screenWidth] should] equal:screenWidth];
        });
        
        it(@"Should return DeviceDescription screenHeight", ^{
            NSString *screenHeight = @"119";
            [AMADeviceDescription stub:@selector(screenHeight) andReturn:screenHeight];
            
            [[[AMAPlatformDescription screenHeight] should] equal:screenHeight];
        });
        
        it(@"Should return DeviceDescription scalefactor", ^{
            NSString *scalefactor = @"120";
            [AMADeviceDescription stub:@selector(scalefactor) andReturn:scalefactor];
            
            [[[AMAPlatformDescription scalefactor] should] equal:scalefactor];
        });
        
        it(@"Should return DeviceDescription is Ipad status", ^{
            [AMADeviceDescription stub:@selector(deviceTypeIsIPad) andReturn:theValue(YES)];

            [[theValue([AMAPlatformDescription deviceTypeIsIPad]) should] beYes];
            
            [AMADeviceDescription stub:@selector(deviceTypeIsIPad) andReturn:theValue(NO)];

            [[theValue([AMAPlatformDescription deviceTypeIsIPad]) should] beNo];
        });
        
        it(@"Should return tablet if device type is ipad", ^{
            [AMAPlatformDescription stub:@selector(deviceTypeIsIPad) andReturn:theValue(YES)];
            
            [[[AMAPlatformDescription deviceType] should] equal:@"tablet"];
        });
        
        it(@"Should return phone if device type is ipad", ^{
            [AMAPlatformDescription stub:@selector(deviceTypeIsIPad) andReturn:theValue(NO)];
            
            [[[AMAPlatformDescription deviceType] should] equal:@"phone"];
        });
    });
});

SPEC_END
