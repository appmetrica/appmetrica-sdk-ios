
#import <XCTest/XCTest.h>
#import "AMAAppVersionProvider.h"

@interface AMAAppVersionProviderTests : XCTestCase

@property (nonatomic, strong) NSBundle *bundle;
@property (nonatomic, strong) AMAAppVersionProvider *versionProvider;

@end

@implementation AMAAppVersionProviderTests

- (void)setUp
{
    _bundle = [NSBundle mainBundle];
    _versionProvider = [[AMAAppVersionProvider alloc] initWithBundle:_bundle];
}

- (void)testAppID
{
    NSString *appID = [self.versionProvider appID];
    
    XCTAssertEqualObjects(appID, [self.bundle bundleIdentifier], @"Should return bundle identifier");
}

- (void)testAppBuildNumber
{
    NSString *appBuildNumber = [self.versionProvider appBuildNumber];
    
    XCTAssertEqualObjects(appBuildNumber, [self.bundle objectForInfoDictionaryKey:@"CFBundleVersion"], @"Should return CFBundleVersion");
}

- (void)testAppVersion
{
    NSString *appVersion = [self.versionProvider appVersion];
    
    XCTAssertEqualObjects(appVersion, [self.bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"], @"Should return CFBundleShortVersionString");
}

- (void)testAppVersionName
{
    NSString *appVersionName = [self.versionProvider appVersionName];
    
    NSUInteger appVersion = [[self.versionProvider appVersion] integerValue];
    NSString *expected = [NSString stringWithFormat:@"%u.%02u",
                          (unsigned)appVersion / 100,
                          (unsigned)appVersion % 100];
    
    XCTAssertEqualObjects(appVersionName, expected, @"Should return app version name");
}

@end
