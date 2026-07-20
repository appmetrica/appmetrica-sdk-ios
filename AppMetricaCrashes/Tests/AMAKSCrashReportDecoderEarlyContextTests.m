#import <XCTest/XCTest.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import <AppMetricaPlatform/AMAApplicationState.h>
#import <KSCrashReportFields.h>

#import "AMACrashContext.h"
#import "AMADecodedCrash.h"
#import "AMAKSCrashReportDecoder.h"

@interface AMAKSCrashReportDecoderEarlyContextDelegate : NSObject <AMAKSCrashReportDecoderDelegate>

@property (nonatomic, strong) AMADecodedCrash *decodedCrash;
@property (nonatomic, strong) NSError *error;

@end

@implementation AMAKSCrashReportDecoderEarlyContextDelegate

- (void)crashReportDecoder:(__unused AMAKSCrashReportDecoder *)decoder
            didDecodeCrash:(AMADecodedCrash *)decodedCrash
                 withError:(NSError *)error
{
    self.decodedCrash = decodedCrash;
    self.error = error;
}

- (void)crashReportDecoder:(__unused AMAKSCrashReportDecoder *)decoder
              didDecodeANR:(AMADecodedCrash *)decodedCrash
                 withError:(NSError *)error
{
    self.decodedCrash = decodedCrash;
    self.error = error;
}

@end

@interface AMAKSCrashReportDecoderEarlyContextTests : XCTestCase
@end

@implementation AMAKSCrashReportDecoderEarlyContextTests

- (void)testMinimalNestedApplicationStateDecodesVersionAndBuild
{
    NSString *path = [AMAModuleBundleProvider.moduleBundle
        pathForResource:@"8980AE83-1607-4566-BC5E-7D0DAF3414C9-SHORT"
        ofType:@"plist"];
    NSMutableDictionary *report = [[[NSDictionary alloc] initWithContentsOfFile:path] mutableCopy];
    NSMutableDictionary *userInfo = [report[KSCrashField_User] mutableCopy];
    [userInfo removeObjectForKey:kAMACrashContextAppVersionKey];
    [userInfo removeObjectForKey:kAMACrashContextAppBuildNumberKey];
    userInfo[kAMACrashContextAppStateKey] = @{
        kAMAAppVersionNameKey : @"1.2.3",
        kAMAAppBuildNumberKey : @"42",
    };
    report[KSCrashField_User] = userInfo;
    AMAKSCrashReportDecoderEarlyContextDelegate *delegate =
        [AMAKSCrashReportDecoderEarlyContextDelegate new];
    AMAKSCrashReportDecoder *decoder = [[AMAKSCrashReportDecoder alloc] initWithCrashID:@42];
    decoder.delegate = delegate;

    [decoder decode:report];

    XCTAssertNil(delegate.error);
    XCTAssertEqualObjects(delegate.decodedCrash.appState.appVersionName, @"1.2.3");
    XCTAssertEqualObjects(delegate.decodedCrash.appState.appBuildNumber, @"42");
}

@end
