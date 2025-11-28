
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMAExtensionReportProvider.h"
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>

SPEC_BEGIN(AMAExtensionReportProviderTests)

describe(@"AMAExtensionReportProvider", ^{

    NSString *const appBundlePath = @"/path/to/app";
    NSString *const extensionsPath = [appBundlePath stringByAppendingPathComponent:@"PlugIns"];
    NSString *const extensionFileName = @"today.appex";
    NSString *const extensionBundlePath = [extensionsPath stringByAppendingPathComponent:extensionFileName];
    NSString *const appBundleID = @"app.bundle.id";
    NSString *const extensionBundleID = @"extension.bundle.id";
    NSString *const extensionType = @"extension.type";

    NSBundle *__block appBundle = nil;
    NSBundle *__block extensionBundle = nil;
    NSFileManager *__block fileManager = nil;
    AMAExtensionReportProvider *__block provider = nil;

    beforeEach(^{
        [NSBundle stub:@selector(bundleWithPath:) withBlock:^id(NSArray *params) {
            NSString *path = params[0];
            if ([path isEqualToString:appBundlePath]) {
                return appBundle;
            }
            else if ([path isEqualToString:extensionBundlePath]) {
                return extensionBundle;
            }
            return nil;
        }];

        provider = [[AMAExtensionReportProvider alloc] init];
    });
    afterEach(^{
        [NSBundle clearStubs];
    });

    context(@"Application", ^{
        beforeEach(^{
            appBundle = [NSBundle nullMock];
            [appBundle stub:@selector(bundlePath) andReturn:appBundlePath];
            [appBundle stub:@selector(bundleIdentifier) andReturn:appBundleID];
            [appBundle stub:@selector(infoDictionary) andReturn:@{}];
            [NSBundle stub:@selector(mainBundle) andReturn:appBundle];

            extensionBundle = [NSBundle nullMock];
            [extensionBundle stub:@selector(bundlePath) andReturn:extensionBundleID];
            [extensionBundle stub:@selector(bundleIdentifier) andReturn:extensionBundleID];
            [extensionBundle stub:@selector(infoDictionary) andReturn:@{
                @"NSExtension": @{
                    @"NSExtensionPointIdentifier": extensionType,
                },
            }];

            fileManager = [NSFileManager nullMock];
            [fileManager stub:@selector(contentsOfDirectoryAtPath:error:) andReturn:@[ extensionFileName ]];
            [NSFileManager stub:@selector(defaultManager) andReturn:fileManager];
        });
        afterEach(^{
            [NSBundle clearStubs];
            [NSFileManager clearStubs];
        });

        it(@"Should return valid type", ^{
            [[[provider report][@"own_type"] should] equal:@{ @"app": @"" }];
        });
        it(@"Should return valid app bundle ID", ^{
            [[[provider report][@"app_bundle_id"] should] equal:appBundleID];
        });
        it(@"Should return valid extensions list", ^{
            [[[provider report][@"extensions"] should] equal:@{ extensionType: @[ extensionBundleID ] }];
        });
        it(@"Should not request app bundle with path", ^{
            [[NSBundle shouldNot] receive:@selector(bundleWithPath:) withArguments:appBundlePath];
            [provider report];
        });
        it(@"Should request extension bundle with valid path", ^{
            [[NSBundle should] receive:@selector(bundleWithPath:) withArguments:extensionBundlePath];
            [provider report];
        });
        it(@"Should return extension with unknown bundle ID if not available", ^{
            [extensionBundle stub:@selector(bundleIdentifier) andReturn:nil];
            [[[provider report][@"extensions"] should] equal:@{ extensionType: @[ @"unknown" ] }];
        });
        it(@"Should return unknown app bundle ID if not available", ^{
            [appBundle stub:@selector(bundleIdentifier) andReturn:nil];
            [[[provider report][@"app_bundle_id"] should] equal:@"unknown"];
        });
        it(@"Should return no extensions if failed to get directory content", ^{
            [fileManager stub:@selector(contentsOfDirectoryAtPath:error:) withBlock:^id(NSArray *params) {
                NSError *error = [NSError errorWithDomain:@"" code:0 userInfo:nil];
                [AMATestUtilities fillObjectPointerParameter:params[1] withValue:error];
                return nil;
            }];
            [[[provider report][@"extensions"] should] beEmpty];
        });
    });

    context(@"Extension", ^{
        beforeEach(^{
            appBundle = [NSBundle nullMock];
            [appBundle stub:@selector(bundlePath) andReturn:appBundlePath];
            [appBundle stub:@selector(bundleIdentifier) andReturn:appBundleID];
            [appBundle stub:@selector(infoDictionary) andReturn:@{}];

            extensionBundle = [NSBundle nullMock];
            [extensionBundle stub:@selector(bundlePath) andReturn:extensionBundlePath];
            [extensionBundle stub:@selector(bundleIdentifier) andReturn:extensionBundleID];
            [extensionBundle stub:@selector(infoDictionary) andReturn:@{
                @"NSExtension": @{
                    @"NSExtensionPointIdentifier": extensionType,
                },
            }];
            [NSBundle stub:@selector(mainBundle) andReturn:extensionBundle];

            fileManager = [NSFileManager nullMock];
            [fileManager stub:@selector(contentsOfDirectoryAtPath:error:) andReturn:@[ extensionFileName ]];
            [NSFileManager stub:@selector(defaultManager) andReturn:fileManager];
        });
        afterEach(^{
            [NSBundle clearStubs];
            [NSFileManager clearStubs];
        });

        it(@"Should return valid type", ^{
            [[[provider report][@"own_type"] should] equal:@{ @"extension": extensionType }];
        });
        it(@"Should return valid app bundle ID", ^{
            [[[provider report][@"app_bundle_id"] should] equal:appBundleID];
        });
        it(@"Should return valid extensions list", ^{
            [[[provider report][@"extensions"] should] equal:@{ extensionType: @[ extensionBundleID ] }];
        });
        it(@"Should request app bundle with valid path", ^{
            [[NSBundle should] receive:@selector(bundleWithPath:) withArguments:appBundlePath];
            [provider report];
        });
        it(@"Should return extension with unknown bundle ID if not available", ^{
            [extensionBundle stub:@selector(bundleIdentifier) andReturn:nil];
            [[[provider report][@"extensions"] should] equal:@{ extensionType: @[ @"unknown" ] }];
        });
        it(@"Should return unknown app bundle ID if not available", ^{
            [appBundle stub:@selector(bundleIdentifier) andReturn:nil];
            [[[provider report][@"app_bundle_id"] should] equal:@"unknown"];
        });
        it(@"Should return no extensions if failed to get directory content", ^{
            [fileManager stub:@selector(contentsOfDirectoryAtPath:error:) withBlock:^id(NSArray *params) {
                NSError *error = [NSError errorWithDomain:@"" code:0 userInfo:nil];
                [AMATestUtilities fillObjectPointerParameter:params[1] withValue:error];
                return nil;
            }];
            [[[provider report][@"extensions"] should] beEmpty];
        });
    });

});

SPEC_END
