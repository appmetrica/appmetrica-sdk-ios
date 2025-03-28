#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMAScreenshotConfiguration.h"

static NSString *const kScreenshotEnabledKey = @"screenshot.enabled";
static NSString *const kApiCaptorEnabledKey = @"api_captor_config.enabled";

@interface AMAScreenshotConfigurationTests : XCTestCase

@property (nonatomic, strong) AMAKeyValueStorageMock *storage;
@property (nonatomic, strong) AMAScreenshotConfiguration *configuration;

@end

@implementation AMAScreenshotConfigurationTests

- (void)setUp
{
    self.storage = [AMAKeyValueStorageMock new];
    self.configuration = [[AMAScreenshotConfiguration alloc] initWithStorage:self.storage];
}

- (void)testAllKeys
{
    NSArray *expected = @[kScreenshotEnabledKey, kApiCaptorEnabledKey];
    XCTAssertEqualObjects([AMAScreenshotConfiguration allKeys], expected);
}

- (void)testReadingDefault
{
    XCTAssertFalse(self.configuration.screenshotEnabled);
    XCTAssertFalse(self.configuration.captorEnabled);
}

- (void)testReadingError
{
    self.storage.error = [NSError errorWithDomain:@"io.appmetrica.screenshot.test" code:0 userInfo:nil];
    XCTAssertFalse(self.configuration.screenshotEnabled);
    XCTAssertFalse(self.configuration.captorEnabled);
}

- (void)testReading
{
    [self.storage saveBoolNumber:@(YES) forKey:kScreenshotEnabledKey error:nil];
    [self.storage saveBoolNumber:@(YES) forKey:kApiCaptorEnabledKey error:nil];
    XCTAssertTrue(self.configuration.screenshotEnabled);
    XCTAssertTrue(self.configuration.captorEnabled);
}

- (void)testWritingNo
{
    self.configuration.screenshotEnabled = NO;
    self.configuration.captorEnabled = NO;
    XCTAssertEqualObjects(self.storage.storage[kScreenshotEnabledKey], @(NO));
    XCTAssertEqualObjects(self.storage.storage[kApiCaptorEnabledKey], @(NO));
}

- (void)testWritingYes
{
    self.configuration.screenshotEnabled = YES;
    self.configuration.captorEnabled = YES;
    XCTAssertEqualObjects(self.storage.storage[kScreenshotEnabledKey], @(YES));
    XCTAssertEqualObjects(self.storage.storage[kApiCaptorEnabledKey], @(YES));
}

- (void)testWritingReading
{
    self.configuration.screenshotEnabled = YES;
    self.configuration.captorEnabled = YES;
    XCTAssertTrue(self.configuration.screenshotEnabled);
    XCTAssertTrue(self.configuration.captorEnabled);
}

@end
