#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "AMAAppMetricaConfigurationFileStorage.h"
#import "AMAAppMetricaConfiguration+JSONSerializable.h"
#import "AMAAppMetricaConfigurationSnapshot.h"
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import <AppMetricaStorageUtils/AppMetricaStorageUtils.h>
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>
#import "AMAAppMetricaConfigurationProviderMock.h"

@interface AMAAppMetricaConfigurationFileStorageTests : XCTestCase

@property (nonatomic, strong) AMAStorageMock *mockStorage;
@property (nonatomic, strong) AMAManualCurrentQueueExecutor *executor;
@property (nonatomic, strong) AMAAppMetricaConfigurationFileStorage *provider;

@end

@implementation AMAAppMetricaConfigurationFileStorageTests

- (void)setUp
{
    [super setUp];
    self.mockStorage = [AMAStorageMock new];
    self.executor = [AMAManualCurrentQueueExecutor new];
    self.provider = [[AMAAppMetricaConfigurationFileStorage alloc] initWithFileStorage:self.mockStorage
                                                                              executor:self.executor];
}

- (void)tearDown
{
    self.mockStorage = nil;
    self.executor = nil;
    self.provider = nil;
    [super tearDown];
}

#pragma mark - Helper Methods

- (AMAAppMetricaConfiguration *)createTestConfiguration
{
    AMAAppMetricaConfiguration *config = [[AMAAppMetricaConfiguration alloc] initWithAPIKey:@"550e8400-e29b-41d4-a716-446655440000"];
    config.sessionTimeout = 120;
    config.maxReportsCount = 50;
    config.logsEnabled = YES;
    return config;
}

- (AMAAppMetricaConfigurationSnapshot *)privateSnapshotWithConfiguration:(AMAAppMetricaConfiguration *)configuration
                                                                 savedAt:(NSDate *)savedAt
{
    return [[AMAAppMetricaConfigurationSnapshot alloc] initWithConfiguration:configuration
                                                                     savedAt:savedAt
                                                                      source:AMAAppMetricaConfigurationSnapshotSourcePrivate];
}

- (NSData *)legacyJsonDataForConfiguration:(AMAAppMetricaConfiguration *)configuration
{
    NSDictionary *json = [configuration JSON];
    return [AMAJSONSerialization dataWithJSONObject:json error:nil];
}

#pragma mark - Init

- (void)testInitWithFileStorage
{
    AMAStorageMock *storage = [AMAStorageMock new];

    AMAAppMetricaConfigurationFileStorage *provider =
        [[AMAAppMetricaConfigurationFileStorage alloc] initWithFileStorage:storage];

    XCTAssertNotNil(provider);
    XCTAssertEqual(provider.fileStorage, storage);
}

- (void)testConvenienceInitializer
{
    AMAStorageMock *storage = [AMAStorageMock new];

    AMAAppMetricaConfigurationFileStorage *provider =
        [AMAAppMetricaConfigurationFileStorage appMetricaConfigurationFileStorageWithFileStorage:storage];

    XCTAssertNotNil(provider);
    XCTAssertEqual(provider.fileStorage, storage);
}

#pragma mark - Load Snapshot

- (void)testLoadSnapshotReturnsNilWhenNoData
{
    self.mockStorage.mockedData = nil;

    XCTAssertNil([self.provider loadSnapshot]);
}

- (void)testLoadSnapshotReturnsNilWhenInvalidJSON
{
    self.mockStorage.mockedData = [@"invalid json" dataUsingEncoding:NSUTF8StringEncoding];

    XCTAssertNil([self.provider loadSnapshot]);
}

- (void)testLoadSnapshotParsesLegacyJSONCorrectly
{
    AMAAppMetricaConfiguration *originalConfig = [self createTestConfiguration];
    self.mockStorage.mockedData = [self legacyJsonDataForConfiguration:originalConfig];

    AMAAppMetricaConfigurationSnapshot *loaded = [self.provider loadSnapshot];

    XCTAssertNotNil(loaded);
    XCTAssertEqualObjects(loaded.configuration.APIKey, originalConfig.APIKey);
    XCTAssertEqual(loaded.configuration.sessionTimeout, originalConfig.sessionTimeout);
    XCTAssertEqual(loaded.configuration.maxReportsCount, originalConfig.maxReportsCount);
    XCTAssertEqual(loaded.configuration.logsEnabled, originalConfig.logsEnabled);
    XCTAssertNil(loaded.savedAt);
    XCTAssertEqual(loaded.source, AMAAppMetricaConfigurationSnapshotSourcePrivate);
}

- (void)testLoadSnapshotCachesResult
{
    AMAAppMetricaConfiguration *originalConfig = [self createTestConfiguration];
    self.mockStorage.mockedData = [self legacyJsonDataForConfiguration:originalConfig];

    AMAAppMetricaConfigurationSnapshot *firstLoad = [self.provider loadSnapshot];
    self.mockStorage.mockedData = nil;
    AMAAppMetricaConfigurationSnapshot *secondLoad = [self.provider loadSnapshot];

    XCTAssertNotNil(firstLoad);
    XCTAssertNotNil(secondLoad);
    XCTAssertEqualObjects(firstLoad.configuration, secondLoad.configuration);
    XCTAssertEqualObjects(firstLoad.savedAt, secondLoad.savedAt);
}

- (void)testLoadSnapshotReturnsCopy
{
    AMAAppMetricaConfiguration *originalConfig = [self createTestConfiguration];
    self.mockStorage.mockedData = [self legacyJsonDataForConfiguration:originalConfig];

    AMAAppMetricaConfigurationSnapshot *firstLoad = [self.provider loadSnapshot];
    AMAAppMetricaConfigurationSnapshot *secondLoad = [self.provider loadSnapshot];

    XCTAssertNotNil(firstLoad);
    XCTAssertNotNil(secondLoad);
    XCTAssertNotEqual(firstLoad, secondLoad);
    XCTAssertNotEqual(firstLoad.configuration, secondLoad.configuration);
    XCTAssertEqualObjects(firstLoad.configuration, secondLoad.configuration);
}

#pragma mark - Save Snapshot

- (void)testSaveSnapshotWritesToStorage
{
    AMAAppMetricaConfiguration *config = [self createTestConfiguration];
    AMAAppMetricaConfigurationSnapshot *snapshot =
        [self privateSnapshotWithConfiguration:config savedAt:[NSDate dateWithTimeIntervalSince1970:7]];

    [self.provider saveSnapshot:snapshot];

    XCTAssertNil(self.mockStorage.mockedData);
    [self.executor execute];
    XCTAssertNotNil(self.mockStorage.mockedData);

    NSDictionary *writtenJSON = [AMAJSONSerialization dictionaryWithJSONData:self.mockStorage.mockedData error:nil];
    XCTAssertEqualObjects(writtenJSON[@"configuration"], [config JSON]);
    XCTAssertEqualObjects(writtenJSON[@"savedAt"], @7);
}

- (void)testSaveSnapshotSkipsWhenEqual
{
    AMAAppMetricaConfiguration *config = [self createTestConfiguration];
    self.mockStorage.mockedData = [self legacyJsonDataForConfiguration:config];
    [self.provider loadSnapshot];
    self.mockStorage.mockedData = nil;

    [self.provider saveSnapshot:[self privateSnapshotWithConfiguration:config savedAt:nil]];
    [self.executor execute];

    XCTAssertNil(self.mockStorage.mockedData);
}

- (void)testSaveSnapshotWritesWhenSavedAtChanges
{
    AMAAppMetricaConfiguration *config = [self createTestConfiguration];
    self.mockStorage.mockedData = [self legacyJsonDataForConfiguration:config];
    [self.provider loadSnapshot];
    self.mockStorage.mockedData = nil;

    AMAAppMetricaConfigurationSnapshot *snapshot =
        [self privateSnapshotWithConfiguration:config savedAt:[NSDate dateWithTimeIntervalSince1970:42]];

    [self.provider saveSnapshot:snapshot];
    [self.executor execute];

    XCTAssertNotNil(self.mockStorage.mockedData);
    NSDictionary *writtenJSON = [AMAJSONSerialization dictionaryWithJSONData:self.mockStorage.mockedData error:nil];
    XCTAssertEqualObjects(writtenJSON[@"savedAt"], @42);
}

- (void)testSaveSnapshotWritesWhenDifferent
{
    AMAAppMetricaConfiguration *config1 = [self createTestConfiguration];
    self.mockStorage.mockedData = [self legacyJsonDataForConfiguration:config1];
    [self.provider loadSnapshot];

    AMAAppMetricaConfiguration *config2 = [self createTestConfiguration];
    config2.sessionTimeout = 240;
    self.mockStorage.mockedData = nil;

    [self.provider saveSnapshot:[self privateSnapshotWithConfiguration:config2 savedAt:nil]];
    [self.executor execute];

    XCTAssertNotNil(self.mockStorage.mockedData);
}

- (void)testSaveSnapshotUpdatesCache
{
    AMAAppMetricaConfiguration *config = [self createTestConfiguration];
    NSDate *savedAt = [NSDate dateWithTimeIntervalSince1970:9];
    [self.provider saveSnapshot:[self privateSnapshotWithConfiguration:config savedAt:savedAt]];
    [self.executor execute];

    self.mockStorage.mockedData = nil;
    AMAAppMetricaConfigurationSnapshot *loaded = [self.provider loadSnapshot];

    XCTAssertNotNil(loaded);
    XCTAssertEqualObjects(loaded.configuration, config);
    XCTAssertEqualObjects(loaded.savedAt, savedAt);
}

- (void)testSaveSnapshotCreatesACopy
{
    AMAAppMetricaConfiguration *config = [self createTestConfiguration];
    [self.provider saveSnapshot:[self privateSnapshotWithConfiguration:config savedAt:nil]];
    [self.executor execute];

    config.sessionTimeout = 999;
    self.mockStorage.mockedData = nil;
    AMAAppMetricaConfigurationSnapshot *loaded = [self.provider loadSnapshot];

    XCTAssertNotEqual(loaded.configuration.sessionTimeout, 999);
}

- (void)testClearSnapshotRemovesCacheAndFile
{
    AMAAppMetricaConfiguration *config = [self createTestConfiguration];
    AMAAppMetricaConfigurationSnapshot *snapshot =
        [self privateSnapshotWithConfiguration:config savedAt:[NSDate date]];
    [self.provider saveSnapshot:snapshot];
    [self.executor execute];
    XCTAssertNotNil([self.provider loadSnapshot]);

    [self.provider clearSnapshot:snapshot];

    XCTAssertNil(self.mockStorage.mockedData);
    XCTAssertNil([self.provider loadSnapshot]);
}

- (void)testThreadSafetyOfLoadSnapshot
{
    AMAAppMetricaConfiguration *config = [self createTestConfiguration];
    self.mockStorage.mockedData = [self legacyJsonDataForConfiguration:config];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Concurrent loads"];
    expectation.expectedFulfillmentCount = 10;

    dispatch_queue_t queue = dispatch_queue_create("test.concurrent", DISPATCH_QUEUE_CONCURRENT);
    for (int i = 0; i < 10; i++) {
        dispatch_async(queue, ^{
            AMAAppMetricaConfigurationSnapshot *loaded = [self.provider loadSnapshot];
            XCTAssertNotNil(loaded);
            [expectation fulfill];
        });
    }

    [self waitForExpectations:@[expectation] timeout:5.0];
}

@end
