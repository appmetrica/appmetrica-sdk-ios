
#import <Kiwi/Kiwi.h>
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>

SPEC_BEGIN(AMAVersionUtilsTests)

describe(@"AMAVersionUtils", ^{

    NSOperatingSystemVersion __block currentVersion;

    beforeEach(^{
        [NSProcessInfo.processInfo stub:@selector(isOperatingSystemAtLeastVersion:) withBlock:^id(NSArray *params) {
            NSOperatingSystemVersion version;
            [params[0] getValue:&version];
            BOOL result = NO;
            result = result || (version.majorVersion < currentVersion.majorVersion);
            result = result || (version.majorVersion == currentVersion.majorVersion
                                && version.minorVersion < currentVersion.minorVersion);
            result = result || (version.majorVersion == currentVersion.majorVersion
                                && version.minorVersion == currentVersion.minorVersion
                                && version.patchVersion <= currentVersion.patchVersion);
            return theValue(result);
        }];
    });

    describe(@"iOS 10", ^{

        beforeEach(^{
            currentVersion = (NSOperatingSystemVersion){10, 1, 0};
        });

        describe(@"test version major check", ^{

            it(@"iOS version is at least 9", ^{
                [[theValue([AMAVersionUtils isOSVersionMajorAtLeast:9]) should] beYes];
            });
            it(@"iOS version is at least 10", ^{
                [[theValue([AMAVersionUtils isOSVersionMajorAtLeast:10]) should] beYes];
            });
            it(@"iOS version is not at least 11", ^{
                [[theValue([AMAVersionUtils isOSVersionMajorAtLeast:11]) should] beNo];
            });
        });

        describe(@"test version check", ^{

            it(@"iOS version is at least 9", ^{
                NSOperatingSystemVersion version = (NSOperatingSystemVersion){9, 0, 0};
                [[theValue([AMAVersionUtils isOSVersionAtLeast:version]) should] beYes];
            });
            it(@"iOS version is at least 10", ^{
                NSOperatingSystemVersion version = (NSOperatingSystemVersion){10, 0, 0};
                [[theValue([AMAVersionUtils isOSVersionAtLeast:version]) should] beYes];
            });
            it(@"iOS version is at exact 10.1", ^{
                NSOperatingSystemVersion version = (NSOperatingSystemVersion){10, 1, 0};
                [[theValue([AMAVersionUtils isOSVersionAtLeast:version]) should] beYes];
            });
            it(@"iOS version is at least 10.3", ^{
                NSOperatingSystemVersion version = (NSOperatingSystemVersion){10, 2, 0};
                [[theValue([AMAVersionUtils isOSVersionAtLeast:version]) should] beNo];
            });
            it(@"iOS version is not at least 11", ^{
                NSOperatingSystemVersion version = (NSOperatingSystemVersion){11, 0, 0};
                [[theValue([AMAVersionUtils isOSVersionAtLeast:version]) should] beNo];
            });
        });
    });
});

SPEC_END
