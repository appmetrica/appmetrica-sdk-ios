
#import <XCTest/XCTest.h>
#import "AMAAppLovinStartupConfiguration.h"
#import "AMAAppLovinStorageKeys.h"
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>

@interface AMAAppLovinStartupConfigurationTests : XCTestCase
@property (nonatomic, strong) AMAKeyValueStorageMock *storage;
@property (nonatomic, strong) AMAAppLovinStartupConfiguration *config;
@end

@implementation AMAAppLovinStartupConfigurationTests

- (void)setUp
{
    self.storage = [[AMAKeyValueStorageMock alloc] init];
    self.config = [[AMAAppLovinStartupConfiguration alloc] initWithStorage:self.storage];
}

- (void)testDefaultAramEnabled_isYES_whenStorageEmpty
{
    XCTAssertTrue(self.config.aramEnabled);
}

- (void)testSetAramEnabledNO_persistsToStorage
{
    self.config.aramEnabled = NO;
    AMAAppLovinStartupConfiguration *reloaded = [[AMAAppLovinStartupConfiguration alloc] initWithStorage:self.storage];
    XCTAssertFalse(reloaded.aramEnabled);
}

- (void)testSetAramEnabledYES_persistsToStorage
{
    self.config.aramEnabled = NO;
    self.config.aramEnabled = YES;
    AMAAppLovinStartupConfiguration *reloaded = [[AMAAppLovinStartupConfiguration alloc] initWithStorage:self.storage];
    XCTAssertTrue(reloaded.aramEnabled);
}

- (void)testAllKeys_containsAramKey
{
    XCTAssertTrue([[AMAAppLovinStartupConfiguration allKeys] containsObject:AMAAppLovinStorageKeyAramEnabled]);
}

- (void)testAllKeys_hasExactlyOneKey
{
    XCTAssertEqual([AMAAppLovinStartupConfiguration allKeys].count, 1u);
}

@end
