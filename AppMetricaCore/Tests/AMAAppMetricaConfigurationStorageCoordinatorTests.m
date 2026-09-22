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
#import "AMAImmediateExclusiveLock.h"
#import "AMAAppMetricaConfigurationSnapshot.h"

@import AppMetricaSynchronization;

static NSString *const apiKey1 = @"8E5F3255-86F3-49B8-B338-5761C3215094";
static NSString *const apiKey2 = @"20D87C88-07D0-42E2-9C86-28A067B657BA";

@interface AMARejectingExclusiveLock : NSObject <AMAExclusiveLocking>
@end

@implementation AMARejectingExclusiveLock

- (BOOL)performWithExclusiveLock:(void (^)(void))body
{
    return NO;
}

@end

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
                  groupStorage:self.groupProvider
                          lock:[AMAImmediateExclusiveLock new]];
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

- (AMAAppMetricaConfigurationSnapshot *)updateIdentityReturningSnapshot
{
    __block AMAAppMetricaConfigurationSnapshot *loaded = nil;
    BOOL locked = [self.mainProvider updateLoadedSnapshot:^AMAAppMetricaConfigurationSnapshot *(AMAAppMetricaConfigurationSnapshot *current) {
        return current;
    } result:&loaded];
    XCTAssertTrue(locked);
    return loaded;
}

#pragma mark - Load via update

- (void)testUpdateReturnsFromPrivateWhenAvailable
{
    NSDate *savedAt = [NSDate dateWithTimeIntervalSince1970:10];
    self.privateProvider.configuration = [self createTestConfigurationWithAPIKey:apiKey1];
    self.privateProvider.savedAt = savedAt;
    self.groupProvider.configuration = [self createTestConfigurationWithAPIKey:apiKey2];
    self.groupProvider.savedAt = [NSDate dateWithTimeIntervalSince1970:20];

    AMAAppMetricaConfigurationSnapshot *loaded = [self updateIdentityReturningSnapshot];

    XCTAssertEqualObjects(loaded.configuration.APIKey, apiKey1);
    XCTAssertEqualObjects(loaded.savedAt, savedAt);
    XCTAssertEqual(loaded.source, AMAAppMetricaConfigurationSnapshotSourcePrivate);
}

- (void)testUpdateReturnsFromPrivateWhenAvailableInExtension
{
    [AMAPlatformDescription stub:@selector(runEnvronment) andReturn:theValue(AMARunEnvironmentExtension)];

    NSDate *savedAt = [NSDate dateWithTimeIntervalSince1970:11];
    self.privateProvider.configuration = [self createTestConfigurationWithAPIKey:apiKey1];
    self.privateProvider.savedAt = savedAt;
    self.groupProvider.configuration = [self createTestConfigurationWithAPIKey:apiKey2];

    AMAAppMetricaConfigurationSnapshot *loaded = [self updateIdentityReturningSnapshot];

    XCTAssertEqualObjects(loaded.configuration.APIKey, apiKey1);
    XCTAssertEqualObjects(loaded.savedAt, savedAt);
    XCTAssertEqual(loaded.source, AMAAppMetricaConfigurationSnapshotSourcePrivate);
}

- (void)testUpdateFallsBackToGroupWhenPrivateIsNil
{
    self.privateProvider.configuration = nil;
    NSDate *savedAt = [NSDate dateWithTimeIntervalSince1970:12];
    self.groupProvider.configuration = [self createTestConfigurationWithAPIKey:apiKey2];
    self.groupProvider.savedAt = savedAt;

    AMAAppMetricaConfigurationSnapshot *loaded = [self updateIdentityReturningSnapshot];

    XCTAssertEqualObjects(loaded.configuration.APIKey, apiKey2);
    XCTAssertEqualObjects(loaded.savedAt, savedAt);
    XCTAssertEqual(loaded.source, AMAAppMetricaConfigurationSnapshotSourceGroup);
}

- (void)testUpdateReturnsNilWhenBothStoragesAreNil
{
    self.privateProvider.configuration = nil;
    self.groupProvider.configuration = nil;

    AMAAppMetricaConfigurationSnapshot *loaded = nil;
    BOOL locked = [self.mainProvider updateLoadedSnapshot:^AMAAppMetricaConfigurationSnapshot *(AMAAppMetricaConfigurationSnapshot *current) {
        XCTFail(@"Update must not run when snapshot is absent");
        return current;
    } result:&loaded];

    XCTAssertTrue(locked);
    XCTAssertNil(loaded);
}

- (void)testUpdateReturnsNilWhenGroupIsNilAndPrivateIsNil
{
    AMAAppMetricaConfigurationStorageCoordinator *coordinator =
        [[AMAAppMetricaConfigurationStorageCoordinator alloc] initWithPrivateStorage:self.privateProvider
                                                                        groupStorage:nil
                                                                                lock:[AMAImmediateExclusiveLock new]];
    self.privateProvider.configuration = nil;

    AMAAppMetricaConfigurationSnapshot *loaded = nil;
    BOOL locked = [coordinator updateLoadedSnapshot:^AMAAppMetricaConfigurationSnapshot *(AMAAppMetricaConfigurationSnapshot *current) {
        XCTFail(@"Update must not run when snapshot is absent");
        return current;
    } result:&loaded];

    XCTAssertTrue(locked);
    XCTAssertNil(loaded);
}

- (void)testUpdateDoesNotCallGroupWhenPrivateSucceeds
{
    self.privateProvider.configuration = [self createTestConfigurationWithAPIKey:apiKey1];

    XCTestExpectation *groupNotCalled = [self expectationWithDescription:@"Group storage should not be called"];
    groupNotCalled.inverted = YES;
    self.groupProvider.loadSnapshotExpectation = groupNotCalled;

    [self updateIdentityReturningSnapshot];

    [self waitForExpectations:@[groupNotCalled] timeout:1.0];
}

- (void)testUpdateReturnsNOWhenLockFails
{
    AMAAppMetricaConfigurationStorageCoordinator *coordinator =
        [[AMAAppMetricaConfigurationStorageCoordinator alloc] initWithPrivateStorage:self.privateProvider
                                                                        groupStorage:self.groupProvider
                                                                                lock:[AMARejectingExclusiveLock new]];
    self.privateProvider.configuration = [self createTestConfigurationWithAPIKey:apiKey1];

    __block BOOL updateCalled = NO;
    AMAAppMetricaConfigurationSnapshot *loaded = (id)[NSNull null];
    BOOL locked = [coordinator updateLoadedSnapshot:^AMAAppMetricaConfigurationSnapshot *(AMAAppMetricaConfigurationSnapshot *current) {
        updateCalled = YES;
        return current;
    } result:&loaded];

    XCTAssertFalse(locked);
    XCTAssertFalse(updateCalled);
    XCTAssertNil(loaded);
}

- (void)testUpdateClearsOnlyPrivateSourceWhenReturningNil
{
    self.privateProvider.configuration = [self createTestConfigurationWithAPIKey:apiKey1];
    self.groupProvider.configuration = [self createTestConfigurationWithAPIKey:apiKey2];

    AMAAppMetricaConfigurationSnapshot *loaded = nil;
    BOOL locked = [self.mainProvider updateLoadedSnapshot:^AMAAppMetricaConfigurationSnapshot *(AMAAppMetricaConfigurationSnapshot *current) {
        return nil;
    } result:&loaded];

    XCTAssertTrue(locked);
    XCTAssertNil(loaded);
    XCTAssertNil(self.privateProvider.configuration);
    XCTAssertEqualObjects(self.groupProvider.configuration.APIKey, apiKey2);
}

- (void)testUpdateClearsOnlyGroupSourceWhenReturningNil
{
    self.privateProvider.configuration = nil;
    self.groupProvider.configuration = [self createTestConfigurationWithAPIKey:apiKey2];
    self.groupProvider.savedAt = [NSDate date];

    AMAAppMetricaConfigurationSnapshot *loaded = nil;
    BOOL locked = [self.mainProvider updateLoadedSnapshot:^AMAAppMetricaConfigurationSnapshot *(AMAAppMetricaConfigurationSnapshot *current) {
        return nil;
    } result:&loaded];

    XCTAssertTrue(locked);
    XCTAssertNil(loaded);
    XCTAssertNil(self.privateProvider.configuration);
    XCTAssertNil(self.groupProvider.configuration);
}

- (void)testUpdateSavesChangedSnapshot
{
    self.privateProvider.configuration = [self createTestConfigurationWithAPIKey:apiKey1];
    self.privateProvider.savedAt = [NSDate dateWithTimeIntervalSince1970:1];
    NSDate *newSavedAt = [NSDate dateWithTimeIntervalSince1970:2];

    AMAAppMetricaConfigurationSnapshot *loaded = nil;
    BOOL locked = [self.mainProvider updateLoadedSnapshot:^AMAAppMetricaConfigurationSnapshot *(AMAAppMetricaConfigurationSnapshot *current) {
        return [current snapshotByUpdatingSavedAt:newSavedAt];
    } result:&loaded];

    XCTAssertTrue(locked);
    XCTAssertEqualObjects(loaded.savedAt, newSavedAt);
    XCTAssertEqualObjects(self.privateProvider.savedAt, newSavedAt);
}

- (void)testUpdateDoesNotSaveEqualSnapshot
{
    NSDate *savedAt = [NSDate dateWithTimeIntervalSince1970:3];
    self.privateProvider.configuration = [self createTestConfigurationWithAPIKey:apiKey1];
    self.privateProvider.savedAt = savedAt;

    XCTestExpectation *saveNotCalled = [self expectationWithDescription:@"Equal snapshot should not save"];
    saveNotCalled.inverted = YES;
    self.privateProvider.saveSnapshotExpectation = saveNotCalled;

    AMAAppMetricaConfigurationSnapshot *loaded = nil;
    BOOL locked = [self.mainProvider updateLoadedSnapshot:^AMAAppMetricaConfigurationSnapshot *(AMAAppMetricaConfigurationSnapshot *current) {
        return current;
    } result:&loaded];

    XCTAssertTrue(locked);
    XCTAssertEqualObjects(loaded.savedAt, savedAt);
    [self waitForExpectations:@[saveNotCalled] timeout:1.0];
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
                                                                        groupStorage:nil
                                                                                lock:[AMAImmediateExclusiveLock new]];
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

@end
