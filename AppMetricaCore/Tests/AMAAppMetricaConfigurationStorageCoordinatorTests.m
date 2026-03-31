#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaPlatform/AppMetricaPlatform.h>
#import "AMAAppMetricaConfigurationFileStorage.h"
#import "AMAAppMetricaConfiguration+JSONSerializable.h"
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>
#import "AMAAppMetricaConfigurationStorageCoordinator.h"
#import "AMAAppMetricaConfigurationProviderMock.h"

static NSString *const apiKey1 = @"8E5F3255-86F3-49B8-B338-5761C3215094";
static NSString *const apiKey2 = @"20D87C88-07D0-42E2-9C86-28A067B657BA";

@interface AMAAppMetricaConfigurationStorageCoordinatorTests: XCTestCase

@property (nonatomic, strong) AMAAppMetricaConfigurationProviderMock *privateProvider;
@property (nonatomic, strong) AMAAppMetricaConfigurationProviderMock *groupProvider;
@property (nonatomic, strong) AMAAppMetricaConfigurationStorageCoordinator *mainProvider;

@end

@implementation AMAAppMetricaConfigurationStorageCoordinatorTests

- (void)setUp
{
    [super setUp];
    self.privateProvider = [AMAAppMetricaConfigurationProviderMock new];
    self.groupProvider = [AMAAppMetricaConfigurationProviderMock new];
    self.mainProvider = [[AMAAppMetricaConfigurationStorageCoordinator alloc]
        initWithPrivateStorage:self.privateProvider
        groupStorage:self.groupProvider];
}

- (void)tearDown
{
    [AMAPlatformDescription clearStubs];
    self.privateProvider = nil;
    self.groupProvider = nil;
    self.mainProvider = nil;
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

- (AMAAppMetricaConfiguration *)createTestConfigurationWithAPIKey:(NSString *)apiKey
{
    AMAAppMetricaConfiguration *config = [[AMAAppMetricaConfiguration alloc] initWithAPIKey:apiKey];
    config.sessionTimeout = 180;
    config.maxReportsCount = 100;
    config.logsEnabled = NO;
    return config;
}

#pragma mark - Load Configuration Tests

- (void)testLoadReturnsFromPrivateWhenAvailable
{
    // Given
    AMAAppMetricaConfiguration *config = [self createTestConfigurationWithAPIKey:apiKey1];
    self.privateProvider.configuration = config;
    self.groupProvider.configuration = [self createTestConfigurationWithAPIKey:apiKey2];

    // When
    AMAAppMetricaConfiguration *loaded = [self.mainProvider loadConfiguration];

    // Then
    XCTAssertEqualObjects(loaded.APIKey, apiKey1, @"Should return private storage configuration");
}

- (void)testLoadReturnsFromPrivateWhenAvailableInExtension
{
    [AMAPlatformDescription stub:@selector(runEnvronment) andReturn:theValue(AMARunEnvironmentExtension)];
    
    // Given
    AMAAppMetricaConfiguration *config = [self createTestConfigurationWithAPIKey:apiKey1];
    self.privateProvider.configuration = config;
    self.groupProvider.configuration = [self createTestConfigurationWithAPIKey:apiKey2];

    // When
    AMAAppMetricaConfiguration *loaded = [self.mainProvider loadConfiguration];

    // Then
    XCTAssertEqualObjects(loaded.APIKey, apiKey1, @"Should return private storage configuration");
}

- (void)testLoadFallsBackToGroupWhenPrivateIsNil
{
    // Given
    self.privateProvider.configuration = nil;
    AMAAppMetricaConfiguration *groupConfig = [self createTestConfigurationWithAPIKey:apiKey2];
    self.groupProvider.configuration = groupConfig;

    // When
    AMAAppMetricaConfiguration *loaded = [self.mainProvider loadConfiguration];

    // Then
    XCTAssertEqualObjects(loaded.APIKey, apiKey2, @"Should fall back to group storage when private returns nil");
}

- (void)testLoadReturnsNilWhenBothStoragesAreNil
{
    // Given
    self.privateProvider.configuration = nil;
    self.groupProvider.configuration = nil;

    // When
    AMAAppMetricaConfiguration *loaded = [self.mainProvider loadConfiguration];

    // Then
    XCTAssertNil(loaded, @"Should return nil when both storages return nil");
}

- (void)testLoadReturnsNilWhenGroupIsNilAndPrivateIsNil
{
    // Given
    AMAAppMetricaConfigurationStorageCoordinator *coordinator =
        [[AMAAppMetricaConfigurationStorageCoordinator alloc] initWithPrivateStorage:self.privateProvider
                                                                        groupStorage:nil];
    self.privateProvider.configuration = nil;

    // When
    AMAAppMetricaConfiguration *loaded = [coordinator loadConfiguration];

    // Then
    XCTAssertNil(loaded, @"Should return nil when group storage is nil and private returns nil");
}

- (void)testLoadDoesNotCallGroupWhenPrivateSucceeds
{
    // Given
    AMAAppMetricaConfiguration *privateConfig = [self createTestConfigurationWithAPIKey:apiKey1];
    self.privateProvider.configuration = privateConfig;

    XCTestExpectation *groupNotCalled = [self expectationWithDescription:@"Group storage should not be called"];
    groupNotCalled.inverted = YES;
    self.groupProvider.loadConfigurationExpectation = groupNotCalled;

    // When
    [self.mainProvider loadConfiguration];

    // Then
    [self waitForExpectations:@[groupNotCalled] timeout:1.0];
}

#pragma mark - Save Configuration Tests (Main App Environment)

- (void)testSaveAlwaysSavesToPrivateStorage
{
    // Given
    [AMAPlatformDescription stub:@selector(runEnvronment) andReturn:theValue(AMARunEnvironmentMainApp)];
    AMAAppMetricaConfiguration *config = [self createTestConfiguration];

    XCTestExpectation *privateSaved = [self expectationWithDescription:@"Private storage should be called"];
    self.privateProvider.saveConfigurationExpectation = privateSaved;

    // When
    [self.mainProvider saveConfiguration:config];

    // Then
    [self waitForExpectations:@[privateSaved] timeout:1.0];
}

- (void)testSaveSavesToGroupStorageInMainApp
{
    // Given
    [AMAPlatformDescription stub:@selector(runEnvronment) andReturn:theValue(AMARunEnvironmentMainApp)];
    AMAAppMetricaConfiguration *config = [self createTestConfiguration];

    XCTestExpectation *groupSaved = [self expectationWithDescription:@"Group storage should be called in main app"];
    self.groupProvider.saveConfigurationExpectation = groupSaved;

    // When
    [self.mainProvider saveConfiguration:config];

    // Then
    [self waitForExpectations:@[groupSaved] timeout:1.0];
}

- (void)testSaveDoesNotSaveToGroupStorageInExtension
{
    // Given
    [AMAPlatformDescription stub:@selector(runEnvronment) andReturn:theValue(AMARunEnvironmentExtension)];
    AMAAppMetricaConfiguration *config = [self createTestConfiguration];

    XCTestExpectation *groupNotCalled = [self expectationWithDescription:@"Group storage should not be called in extension"];
    groupNotCalled.inverted = YES;
    self.groupProvider.saveConfigurationExpectation = groupNotCalled;

    // When
    [self.mainProvider saveConfiguration:config];

    // Then
    [self waitForExpectations:@[groupNotCalled] timeout:1.0];
}

- (void)testSavePassesSameConfigToBothStorages
{
    // Given
    [AMAPlatformDescription stub:@selector(runEnvronment) andReturn:theValue(AMARunEnvironmentMainApp)];
    AMAAppMetricaConfiguration *config = [self createTestConfigurationWithAPIKey:apiKey1];

    // When
    [self.mainProvider saveConfiguration:config];

    // Then
    XCTAssertEqualObjects(self.privateProvider.configuration.APIKey, apiKey1,
                          @"Private storage should receive the same configuration");
    XCTAssertEqualObjects(self.groupProvider.configuration.APIKey, apiKey1,
                          @"Group storage should receive the same configuration");
}

#pragma mark - Save Configuration Tests (Nil Group Storage)

- (void)testSaveWithNilGroupStorageDoesNotCrash
{
    // Given
    [AMAPlatformDescription stub:@selector(runEnvronment) andReturn:theValue(AMARunEnvironmentMainApp)];
    AMAAppMetricaConfigurationStorageCoordinator *coordinator =
        [[AMAAppMetricaConfigurationStorageCoordinator alloc] initWithPrivateStorage:self.privateProvider
                                                                        groupStorage:nil];
    AMAAppMetricaConfiguration *config = [self createTestConfiguration];

    // When / Then — should not crash
    XCTAssertNoThrow([coordinator saveConfiguration:config],
                     @"Saving with nil group storage should not crash");
    XCTAssertEqualObjects(self.privateProvider.configuration.APIKey, config.APIKey,
                          @"Private storage should still receive the configuration");
}

#pragma mark - Save Configuration Expectation Tests

- (void)testSaveFulfillsPrivateExpectation
{
    // Given
    [AMAPlatformDescription stub:@selector(runEnvronment) andReturn:theValue(AMARunEnvironmentExtension)];
    AMAAppMetricaConfiguration *config = [self createTestConfiguration];

    XCTestExpectation *privateSaved = [self expectationWithDescription:@"Private storage save should be called"];
    self.privateProvider.saveConfigurationExpectation = privateSaved;

    // When
    [self.mainProvider saveConfiguration:config];

    // Then
    [self waitForExpectations:@[privateSaved] timeout:1.0];
}

- (void)testSaveFulfillsGroupExpectationInMainApp
{
    // Given
    [AMAPlatformDescription stub:@selector(runEnvronment) andReturn:theValue(AMARunEnvironmentMainApp)];
    AMAAppMetricaConfiguration *config = [self createTestConfiguration];

    XCTestExpectation *privateSaved = [self expectationWithDescription:@"Private storage save should be called"];
    XCTestExpectation *groupSaved = [self expectationWithDescription:@"Group storage save should be called"];
    self.privateProvider.saveConfigurationExpectation = privateSaved;
    self.groupProvider.saveConfigurationExpectation = groupSaved;

    // When
    [self.mainProvider saveConfiguration:config];

    // Then
    [self waitForExpectations:@[privateSaved, groupSaved] timeout:1.0];
}

@end
