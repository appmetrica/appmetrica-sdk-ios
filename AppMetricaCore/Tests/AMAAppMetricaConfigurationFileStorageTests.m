#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "AMAAppMetricaConfigurationFileStorage.h"
#import "AMAAppMetricaConfiguration+JSONSerializable.h"
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

- (NSData *)jsonDataForConfiguration:(AMAAppMetricaConfiguration *)configuration
{
    NSDictionary *json = [configuration JSON];
    return [AMAJSONSerialization dataWithJSONObject:json error:nil];
}

#pragma mark - AMAAppMetricaConfigurationProvider Tests

- (void)testInitWithFileStorage
{
    // Given
    AMAStorageMock *storage = [AMAStorageMock new];
    
    // When
    AMAAppMetricaConfigurationFileStorage *provider = [[AMAAppMetricaConfigurationFileStorage alloc] initWithFileStorage:storage];
    
    // Then
    XCTAssertNotNil(provider, @"Provider should be initialized");
    XCTAssertEqual(provider.fileStorage, storage, @"File storage should be set correctly");
}

- (void)testConvenienceInitializer
{
    // Given
    AMAStorageMock *storage = [AMAStorageMock new];
    
    // When
    AMAAppMetricaConfigurationFileStorage *provider = [AMAAppMetricaConfigurationFileStorage appMetricaConfigurationFileStorageWithFileStorage:storage];
    
    // Then
    XCTAssertNotNil(provider, @"Provider should be initialized");
    XCTAssertEqual(provider.fileStorage, storage, @"File storage should be set correctly");
}

- (void)testLoadConfigurationReturnsNilWhenNoData
{
    // Given
    self.mockStorage.mockedData = nil;
    
    // When
    AMAAppMetricaConfiguration *config = [self.provider loadConfiguration];
    
    // Then
    XCTAssertNil(config, @"Should return nil when no data exists");
}

- (void)testLoadConfigurationReturnsNilWhenInvalidJSON
{
    // Given
    self.mockStorage.mockedData = [@"invalid json" dataUsingEncoding:NSUTF8StringEncoding];
    
    // When
    AMAAppMetricaConfiguration *config = [self.provider loadConfiguration];
    
    // Then
    XCTAssertNil(config, @"Should return nil when JSON is invalid");
}

- (void)testLoadConfigurationParsesJSONCorrectly
{
    // Given
    AMAAppMetricaConfiguration *originalConfig = [self createTestConfiguration];
    self.mockStorage.mockedData = [self jsonDataForConfiguration:originalConfig];
    
    // When
    AMAAppMetricaConfiguration *loadedConfig = [self.provider loadConfiguration];
    
    // Then
    XCTAssertNotNil(loadedConfig, @"Should load configuration");
    XCTAssertEqualObjects(loadedConfig.APIKey, originalConfig.APIKey, @"API key should match");
    XCTAssertEqual(loadedConfig.sessionTimeout, originalConfig.sessionTimeout, @"Session timeout should match");
    XCTAssertEqual(loadedConfig.maxReportsCount, originalConfig.maxReportsCount, @"Max reports count should match");
    XCTAssertEqual(loadedConfig.logsEnabled, originalConfig.logsEnabled, @"Logs enabled should match");
}

- (void)testLoadConfigurationCachesResult
{
    // Given
    AMAAppMetricaConfiguration *originalConfig = [self createTestConfiguration];
    self.mockStorage.mockedData = [self jsonDataForConfiguration:originalConfig];
    
    // When
    AMAAppMetricaConfiguration *firstLoad = [self.provider loadConfiguration];
    self.mockStorage.mockedData = nil; // Clear storage data
    AMAAppMetricaConfiguration *secondLoad = [self.provider loadConfiguration];
    
    // Then
    XCTAssertNotNil(firstLoad, @"First load should succeed");
    XCTAssertNotNil(secondLoad, @"Second load should return cached value");
    XCTAssertEqualObjects(firstLoad, secondLoad, @"Both loads should return same configuration");
}

- (void)testLoadConfigurationReturnsCopy
{
    // Given
    AMAAppMetricaConfiguration *originalConfig = [self createTestConfiguration];
    self.mockStorage.mockedData = [self jsonDataForConfiguration:originalConfig];
    
    // When
    AMAAppMetricaConfiguration *firstLoad = [self.provider loadConfiguration];
    AMAAppMetricaConfiguration *secondLoad = [self.provider loadConfiguration];
    
    // Then
    XCTAssertNotNil(firstLoad, @"First load should succeed");
    XCTAssertNotNil(secondLoad, @"Second load should succeed");
    XCTAssertNotEqual(firstLoad, secondLoad, @"Should return different instances (copies)");
    XCTAssertEqualObjects(firstLoad, secondLoad, @"But configurations should be equal");
}

- (void)testSaveConfigurationWritesToStorage
{
    // Given
    AMAAppMetricaConfiguration *config = [self createTestConfiguration];
    
    // When
    [self.provider saveConfiguration:config];
    
    // Then
    XCTAssertNil(self.mockStorage.mockedData, @"Should not write to storage due to executor");
    
    [self.executor execute];
    XCTAssertNotNil(self.mockStorage.mockedData, @"Should write data to storage");
    
    // Verify written data can be parsed back
    NSDictionary *writtenJSON = [AMAJSONSerialization dictionaryWithJSONData:self.mockStorage.mockedData error:nil];
    XCTAssertNotNil(writtenJSON, @"Written data should be valid JSON");
    XCTAssertEqualObjects(writtenJSON, [config JSON], @"Written API key should match");
}

- (void)testSaveConfigurationSkipsWhenEqual
{
    // Given
    AMAAppMetricaConfiguration *config = [self createTestConfiguration];
    self.mockStorage.mockedData = [self jsonDataForConfiguration:config];
    
    // Load to cache the configuration
    [self.provider loadConfiguration];
    
    // Clear written data
    self.mockStorage.mockedData = nil;
    
    // When - save the same configuration
    [self.provider saveConfiguration:config];
    [self.executor execute];
    
    // Then
    XCTAssertNil(self.mockStorage.mockedData, @"Should not write when configuration is equal");
}

- (void)testSaveConfigurationWritesWhenDifferent
{
    // Given
    AMAAppMetricaConfiguration *config1 = [self createTestConfiguration];
    self.mockStorage.mockedData = [self jsonDataForConfiguration:config1];
    
    // Load to cache the configuration
    [self.provider loadConfiguration];
    
    // Create a different configuration
    AMAAppMetricaConfiguration *config2 = [self createTestConfiguration];
    config2.sessionTimeout = 240; // Different value
    
    // Clear written data
    self.mockStorage.mockedData = nil;
    
    // When
    [self.provider saveConfiguration:config2];
    [self.executor execute];
    
    // Then
    XCTAssertNotNil(self.mockStorage.mockedData, @"Should write when configuration is different");
}

- (void)testSaveConfigurationUpdatesCache
{
    // Given
    AMAAppMetricaConfiguration *config = [self createTestConfiguration];
    
    // When
    [self.provider saveConfiguration:config];
    [self.executor execute];
    
    // Clear storage to ensure we're reading from cache
    self.mockStorage.mockedData = nil;
    AMAAppMetricaConfiguration *loadedConfig = [self.provider loadConfiguration];
    
    // Then
    XCTAssertNotNil(loadedConfig, @"Should load from cache");
    XCTAssertEqualObjects(loadedConfig, config, @"Cached configuration should match saved one");
}

- (void)testSaveConfigurationCreatesACopy
{
    // Given
    AMAAppMetricaConfiguration *config = [self createTestConfiguration];
    
    // When
    [self.provider saveConfiguration:config];
    [self.executor execute];
    
    // Modify original config
    config.sessionTimeout = 999;
    
    // Load from cache
    self.mockStorage.mockedData = nil;
    AMAAppMetricaConfiguration *loadedConfig = [self.provider loadConfiguration];
    
    // Then
    XCTAssertNotEqual(loadedConfig.sessionTimeout, 999, @"Cached configuration should not be affected by changes to original");
}

- (void)testThreadSafetyOfLoadConfiguration
{
    // Given
    AMAAppMetricaConfiguration *config = [self createTestConfiguration];
    self.mockStorage.mockedData = [self jsonDataForConfiguration:config];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Concurrent loads"];
    expectation.expectedFulfillmentCount = 10;
    
    // When - perform concurrent loads
    dispatch_queue_t queue = dispatch_queue_create("test.concurrent", DISPATCH_QUEUE_CONCURRENT);
    for (int i = 0; i < 10; i++) {
        dispatch_async(queue, ^{
            AMAAppMetricaConfiguration *loadedConfig = [self.provider loadConfiguration];
            XCTAssertNotNil(loadedConfig, @"Should load configuration");
            [expectation fulfill];
        });
    }
    
    // Then
    [self waitForExpectations:@[expectation] timeout:5.0];
}

@end
