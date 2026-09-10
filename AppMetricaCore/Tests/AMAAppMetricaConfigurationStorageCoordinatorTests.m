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
#import "AMAAppMetricaConfigurationSnapshot.h"

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

- (AMAAppMetricaConfigurationSnapshot *)privateSnapshotWithConfiguration:(AMAAppMetricaConfiguration *)configuration
                                                                 savedAt:(NSDate *)savedAt
{
    return [[AMAAppMetricaConfigurationSnapshot alloc] initWithConfiguration:configuration
                                                                     savedAt:savedAt
                                                                      source:AMAAppMetricaConfigurationSnapshotSourcePrivate];
}

#pragma mark - Load Snapshot Tests

- (void)testLoadReturnsFromPrivateWhenAvailable
{
    NSDate *savedAt = [NSDate dateWithTimeIntervalSince1970:10];
    self.privateProvider.configuration = [self createTestConfigurationWithAPIKey:apiKey1];
    self.privateProvider.savedAt = savedAt;
    self.groupProvider.configuration = [self createTestConfigurationWithAPIKey:apiKey2];
    self.groupProvider.savedAt = [NSDate dateWithTimeIntervalSince1970:20];

    AMAAppMetricaConfigurationSnapshot *loaded = [self.mainProvider loadSnapshot];

    XCTAssertEqualObjects(loaded.configuration.APIKey, apiKey1);
    XCTAssertEqualObjects(loaded.savedAt, savedAt);
    XCTAssertEqual(loaded.source, AMAAppMetricaConfigurationSnapshotSourcePrivate);
}

- (void)testLoadReturnsFromPrivateWhenAvailableInExtension
{
    [AMAPlatformDescription stub:@selector(runEnvronment) andReturn:theValue(AMARunEnvironmentExtension)];

    NSDate *savedAt = [NSDate dateWithTimeIntervalSince1970:11];
    self.privateProvider.configuration = [self createTestConfigurationWithAPIKey:apiKey1];
    self.privateProvider.savedAt = savedAt;
    self.groupProvider.configuration = [self createTestConfigurationWithAPIKey:apiKey2];

    AMAAppMetricaConfigurationSnapshot *loaded = [self.mainProvider loadSnapshot];

    XCTAssertEqualObjects(loaded.configuration.APIKey, apiKey1);
    XCTAssertEqualObjects(loaded.savedAt, savedAt);
    XCTAssertEqual(loaded.source, AMAAppMetricaConfigurationSnapshotSourcePrivate);
}

- (void)testLoadFallsBackToGroupWhenPrivateIsNil
{
    self.privateProvider.configuration = nil;
    NSDate *savedAt = [NSDate dateWithTimeIntervalSince1970:12];
    self.groupProvider.configuration = [self createTestConfigurationWithAPIKey:apiKey2];
    self.groupProvider.savedAt = savedAt;

    AMAAppMetricaConfigurationSnapshot *loaded = [self.mainProvider loadSnapshot];

    XCTAssertEqualObjects(loaded.configuration.APIKey, apiKey2);
    XCTAssertEqualObjects(loaded.savedAt, savedAt);
    XCTAssertEqual(loaded.source, AMAAppMetricaConfigurationSnapshotSourceGroup);
}

- (void)testLoadReturnsNilWhenBothStoragesAreNil
{
    self.privateProvider.configuration = nil;
    self.groupProvider.configuration = nil;

    XCTAssertNil([self.mainProvider loadSnapshot]);
}

- (void)testLoadReturnsNilWhenGroupIsNilAndPrivateIsNil
{
    AMAAppMetricaConfigurationStorageCoordinator *coordinator =
        [[AMAAppMetricaConfigurationStorageCoordinator alloc] initWithPrivateStorage:self.privateProvider
                                                                        groupStorage:nil];
    self.privateProvider.configuration = nil;

    XCTAssertNil([coordinator loadSnapshot]);
}

- (void)testLoadDoesNotCallGroupWhenPrivateSucceeds
{
    self.privateProvider.configuration = [self createTestConfigurationWithAPIKey:apiKey1];

    XCTestExpectation *groupNotCalled = [self expectationWithDescription:@"Group storage should not be called"];
    groupNotCalled.inverted = YES;
    self.groupProvider.loadSnapshotExpectation = groupNotCalled;

    [self.mainProvider loadSnapshot];

    [self waitForExpectations:@[groupNotCalled] timeout:1.0];
}

#pragma mark - Save Snapshot Tests (Main App Environment)

- (void)testSaveAlwaysSavesToPrivateStorage
{
    [AMAPlatformDescription stub:@selector(runEnvronment) andReturn:theValue(AMARunEnvironmentMainApp)];
    AMAAppMetricaConfigurationSnapshot *snapshot =
        [self privateSnapshotWithConfiguration:[self createTestConfiguration]
                                       savedAt:[NSDate dateWithTimeIntervalSince1970:1]];

    XCTestExpectation *privateSaved = [self expectationWithDescription:@"Private storage should be called"];
    self.privateProvider.saveSnapshotExpectation = privateSaved;

    [self.mainProvider saveSnapshot:snapshot];

    [self waitForExpectations:@[privateSaved] timeout:1.0];
}

- (void)testSaveSavesToGroupStorageInMainApp
{
    [AMAPlatformDescription stub:@selector(runEnvronment) andReturn:theValue(AMARunEnvironmentMainApp)];
    AMAAppMetricaConfigurationSnapshot *snapshot =
        [self privateSnapshotWithConfiguration:[self createTestConfiguration]
                                       savedAt:[NSDate dateWithTimeIntervalSince1970:2]];

    XCTestExpectation *groupSaved = [self expectationWithDescription:@"Group storage should be called in main app"];
    self.groupProvider.saveSnapshotExpectation = groupSaved;

    [self.mainProvider saveSnapshot:snapshot];

    [self waitForExpectations:@[groupSaved] timeout:1.0];
}

- (void)testSaveDoesNotSaveToGroupStorageInExtension
{
    [AMAPlatformDescription stub:@selector(runEnvronment) andReturn:theValue(AMARunEnvironmentExtension)];
    AMAAppMetricaConfigurationSnapshot *snapshot =
        [self privateSnapshotWithConfiguration:[self createTestConfiguration]
                                       savedAt:[NSDate dateWithTimeIntervalSince1970:3]];

    XCTestExpectation *groupNotCalled = [self expectationWithDescription:@"Group storage should not be called in extension"];
    groupNotCalled.inverted = YES;
    self.groupProvider.saveSnapshotExpectation = groupNotCalled;

    [self.mainProvider saveSnapshot:snapshot];

    [self waitForExpectations:@[groupNotCalled] timeout:1.0];
}

- (void)testSavePassesSameConfigToBothStorages
{
    [AMAPlatformDescription stub:@selector(runEnvronment) andReturn:theValue(AMARunEnvironmentMainApp)];
    NSDate *savedAt = [NSDate dateWithTimeIntervalSince1970:4];
    AMAAppMetricaConfigurationSnapshot *snapshot =
        [self privateSnapshotWithConfiguration:[self createTestConfigurationWithAPIKey:apiKey1]
                                       savedAt:savedAt];

    [self.mainProvider saveSnapshot:snapshot];

    XCTAssertEqualObjects(self.privateProvider.configuration.APIKey, apiKey1);
    XCTAssertEqualObjects(self.privateProvider.savedAt, savedAt);
    XCTAssertEqualObjects(self.groupProvider.configuration.APIKey, apiKey1);
    XCTAssertEqualObjects(self.groupProvider.savedAt, savedAt);
}

- (void)testSaveWithNilGroupStorageDoesNotCrash
{
    [AMAPlatformDescription stub:@selector(runEnvronment) andReturn:theValue(AMARunEnvironmentMainApp)];
    AMAAppMetricaConfigurationStorageCoordinator *coordinator =
        [[AMAAppMetricaConfigurationStorageCoordinator alloc] initWithPrivateStorage:self.privateProvider
                                                                        groupStorage:nil];
    AMAAppMetricaConfigurationSnapshot *snapshot =
        [self privateSnapshotWithConfiguration:[self createTestConfiguration]
                                       savedAt:[NSDate dateWithTimeIntervalSince1970:5]];

    XCTAssertNoThrow([coordinator saveSnapshot:snapshot]);
    XCTAssertEqualObjects(self.privateProvider.configuration.APIKey, snapshot.configuration.APIKey);
}

- (void)testSaveFulfillsPrivateExpectation
{
    [AMAPlatformDescription stub:@selector(runEnvronment) andReturn:theValue(AMARunEnvironmentExtension)];
    AMAAppMetricaConfigurationSnapshot *snapshot =
        [self privateSnapshotWithConfiguration:[self createTestConfiguration]
                                       savedAt:nil];

    XCTestExpectation *privateSaved = [self expectationWithDescription:@"Private storage save should be called"];
    self.privateProvider.saveSnapshotExpectation = privateSaved;

    [self.mainProvider saveSnapshot:snapshot];

    [self waitForExpectations:@[privateSaved] timeout:1.0];
}

- (void)testSaveFulfillsGroupExpectationInMainApp
{
    [AMAPlatformDescription stub:@selector(runEnvronment) andReturn:theValue(AMARunEnvironmentMainApp)];
    AMAAppMetricaConfigurationSnapshot *snapshot =
        [self privateSnapshotWithConfiguration:[self createTestConfiguration]
                                       savedAt:nil];

    XCTestExpectation *privateSaved = [self expectationWithDescription:@"Private storage save should be called"];
    XCTestExpectation *groupSaved = [self expectationWithDescription:@"Group storage save should be called"];
    self.privateProvider.saveSnapshotExpectation = privateSaved;
    self.groupProvider.saveSnapshotExpectation = groupSaved;

    [self.mainProvider saveSnapshot:snapshot];

    [self waitForExpectations:@[privateSaved, groupSaved] timeout:1.0];
}

#pragma mark - Clear Snapshot Tests

- (void)testClearSnapshotClearsOnlyPrivateSource
{
    self.privateProvider.configuration = [self createTestConfigurationWithAPIKey:apiKey1];
    self.groupProvider.configuration = [self createTestConfigurationWithAPIKey:apiKey2];
    AMAAppMetricaConfigurationSnapshot *snapshot =
        [self privateSnapshotWithConfiguration:self.privateProvider.configuration
                                       savedAt:[NSDate date]];

    [self.mainProvider clearSnapshot:snapshot];

    XCTAssertNil(self.privateProvider.configuration);
    XCTAssertEqualObjects(self.groupProvider.configuration.APIKey, apiKey2);
}

- (void)testClearSnapshotClearsOnlyGroupSource
{
    self.privateProvider.configuration = [self createTestConfigurationWithAPIKey:apiKey1];
    self.groupProvider.configuration = [self createTestConfigurationWithAPIKey:apiKey2];
    AMAAppMetricaConfigurationSnapshot *snapshot =
        [[AMAAppMetricaConfigurationSnapshot alloc] initWithConfiguration:self.groupProvider.configuration
                                                                  savedAt:[NSDate date]
                                                                   source:AMAAppMetricaConfigurationSnapshotSourceGroup];

    [self.mainProvider clearSnapshot:snapshot];

    XCTAssertEqualObjects(self.privateProvider.configuration.APIKey, apiKey1);
    XCTAssertNil(self.groupProvider.configuration);
}

- (void)testClearSnapshotWithNilGroupStorageDoesNotCrash
{
    AMAAppMetricaConfigurationStorageCoordinator *coordinator =
        [[AMAAppMetricaConfigurationStorageCoordinator alloc] initWithPrivateStorage:self.privateProvider
                                                                        groupStorage:nil];
    self.privateProvider.configuration = [self createTestConfiguration];
    AMAAppMetricaConfigurationSnapshot *snapshot =
        [self privateSnapshotWithConfiguration:self.privateProvider.configuration
                                       savedAt:nil];

    XCTAssertNoThrow([coordinator clearSnapshot:snapshot]);
    XCTAssertNil(self.privateProvider.configuration);
}

@end
