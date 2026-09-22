#import <XCTest/XCTest.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMAYandexAdsStartupStateProvider.h"
#import "AMAYandexAdsSDKDetector.h"
#import "AMASavedAppMetricaConfigRepository.h"
#import "AMAMetricaPersistentConfiguration.h"
#import "AMAMetricaInMemoryConfiguration.h"
#import "AMAMockDatabase.h"
#import "AMAAppMetricaConfigurationProviderMock.h"
#import "AMAAppMetricaConfigurationStorageCoordinator.h"
#import "AMAImmediateExclusiveLock.h"
#import "AMAAppMetricaConfiguration.h"
#import "AMADefaultAnonymousConfigProvider.h"

@interface AMAYandexAdsStartupStateProviderTests : XCTestCase
@property (nonatomic, strong) id<AMADatabaseProtocol> database;
@property (nonatomic, strong) AMAAppMetricaConfigurationProviderMock *configStorage;
@property (nonatomic, strong) AMAMetricaPersistentConfiguration *persistent;
@property (nonatomic, strong) AMADateProviderMock *dateProvider;
@property (nonatomic, strong) AMASavedAppMetricaConfigRepository *repository;
@end

@implementation AMAYandexAdsStartupStateProviderTests

- (void)setUp
{
    [super setUp];
    self.database = [AMAMockDatabase configurationDatabase];
    self.configStorage = [[AMAAppMetricaConfigurationProviderMock alloc] init];
    id<AMAAppMetricaConfigurationStoring> storing =
        [[AMAAppMetricaConfigurationStorageCoordinator alloc] initWithPrivateStorage:self.configStorage
                                                                        groupStorage:nil
                                                                                lock:[AMAImmediateExclusiveLock new]];
    self.persistent = [[AMAMetricaPersistentConfiguration alloc]
        initWithStorage:self.database.storageProvider.syncStorage
        inMemoryConfiguration:[[AMAMetricaInMemoryConfiguration alloc] init]
        appMetricaConfigurationStorage:storing];
    self.dateProvider = [[AMADateProviderMock alloc] init];
    [self.dateProvider freezeWithDate:[NSDate dateWithTimeIntervalSince1970:1700000000]];
    self.repository = [[AMASavedAppMetricaConfigRepository alloc]
        initWithPersistentConfiguration:self.persistent dateProvider:self.dateProvider];
}

- (AMAYandexAdsStartupStateProvider *)providerWithMarker:(BOOL)present
{
    AMAYandexAdsSDKDetector *detector = [[AMAYandexAdsSDKDetector alloc]
        initWithClassResolver:^Class(NSString *name) { return present ? NSObject.class : Nil; }];
    return [[AMAYandexAdsStartupStateProvider alloc] initWithRepository:self.repository
                                                             detector:detector
                                              persistentConfiguration:self.persistent];
}

- (void)testAbsentOrdinaryAndAnonymousConfigurationsWithAndWithoutMarker
{
    AMAAppMetricaConfiguration *ordinary = [[AMAAppMetricaConfiguration alloc]
        initWithAPIKey:@"550e8400-e29b-41d4-a716-446655440000"];
    AMAAppMetricaConfiguration *anonymous = [[AMAAppMetricaConfiguration alloc]
        initWithAPIKey:AMADefaultAnonymousConfigProvider.anonymousAPIKey];
    for (id configuration in @[NSNull.null, ordinary, anonymous]) {
        for (NSNumber *marker in @[@NO, @YES]) {
            self.configStorage.configuration = configuration == NSNull.null ? nil : configuration;
            self.configStorage.savedAt = self.dateProvider.currentDate;
            BOOL expected = marker.boolValue && configuration != ordinary;
            AMAYandexAdsStartupStateProvider *provider = [self providerWithMarker:marker.boolValue];
            XCTAssertEqual(provider.isYandexAdsOnly, expected);
            XCTAssertEqualObjects(provider.startupParameters, (@{@"hoyas": expected ? @"1" : @"0"}));
            XCTAssertEqualObjects(provider.reservedParameterKeys, [NSSet setWithObject:@"hoyas"]);
        }
    }
}

- (void)testStateIsRecomputedAfterOrdinaryActivationAndExpiration
{
    AMAYandexAdsStartupStateProvider *provider = [self providerWithMarker:YES];
    XCTAssertTrue(provider.isYandexAdsOnly);
    AMAAppMetricaConfiguration *ordinary = [[AMAAppMetricaConfiguration alloc]
        initWithAPIKey:@"550e8400-e29b-41d4-a716-446655440000"];
    [self.repository saveConfiguration:ordinary refreshTTL:YES];
    XCTAssertFalse(provider.isYandexAdsOnly);
    NSDate *savedAt = self.configStorage.savedAt;
    [self.dateProvider freezeWithDate:[savedAt dateByAddingTimeInterval:30 * 24 * 60 * 60 - 1]];
    XCTAssertFalse(provider.isYandexAdsOnly);
    XCTAssertEqualObjects(self.configStorage.configuration, ordinary);
    [self.dateProvider freezeWithDate:[savedAt dateByAddingTimeInterval:30 * 24 * 60 * 60]];
    XCTAssertTrue(provider.isYandexAdsOnly);
    XCTAssertNil(self.configStorage.configuration);
    XCTAssertNil(self.configStorage.savedAt);
    XCTAssertTrue(provider.isYandexAdsOnly);
}

- (void)testLegacyConfigurationGetsFullTTLAndBackwardClockRemainsValid
{
    self.configStorage.configuration = [[AMAAppMetricaConfiguration alloc]
        initWithAPIKey:@"550e8400-e29b-41d4-a716-446655440000"];
    self.persistent.libraryAdapterCustomHosts = @[@"https://ads.example"];
    AMAYandexAdsStartupStateProvider *provider = [self providerWithMarker:YES];
    NSDate *now = self.dateProvider.currentDate;
    XCTAssertFalse(provider.isYandexAdsOnly);
    XCTAssertEqualObjects(self.configStorage.savedAt, now);
    [self.dateProvider freezeWithDate:[now dateByAddingTimeInterval:-1]];
    XCTAssertFalse(provider.isYandexAdsOnly);
    [self.dateProvider freezeWithDate:[now dateByAddingTimeInterval:30 * 24 * 60 * 60 + 1]];
    XCTAssertTrue(provider.isYandexAdsOnly);
    XCTAssertEqualObjects(self.persistent.libraryAdapterCustomHosts, (@[@"https://ads.example"]));
}

- (void)testRefreshDecisionsUseProvidedParametersAndPreserveMigrationBehavior
{
    AMAYandexAdsStartupStateProvider *provider = [self providerWithMarker:YES];
    for (id previous in @[NSNull.null, @NO, @YES]) {
        for (NSNumber *current in @[@NO, @YES]) {
            self.persistent.lastStartupYandexAdsOnlyState = previous == NSNull.null ? nil : previous;
            NSDictionary *parameters = @{@"hoyas": current.boolValue ? @"1" : @"0"};
            BOOL expected = previous == NSNull.null ? current.boolValue : [previous boolValue] != current.boolValue;
            XCTAssertEqual([provider requiresUpdateForParameters:parameters], expected);
            XCTAssertEqualObjects(self.persistent.lastStartupYandexAdsOnlyState,
                                  previous == NSNull.null ? nil : previous);
        }
    }
}

- (void)testSuccessfulStartupPersistsSentParametersAcrossStateChangesAndProviderRecreation
{
    AMAYandexAdsStartupStateProvider *provider = [self providerWithMarker:YES];
    NSDictionary *sentParameters = provider.startupParameters;
    AMAAppMetricaConfiguration *ordinary = [[AMAAppMetricaConfiguration alloc]
        initWithAPIKey:@"550e8400-e29b-41d4-a716-446655440000"];
    [self.repository saveConfiguration:ordinary refreshTTL:YES];
    XCTAssertEqualObjects(provider.startupParameters[@"hoyas"], @"0");
    [provider startupDidSucceedWithParameters:sentParameters];
    XCTAssertEqualObjects(self.persistent.lastStartupYandexAdsOnlyState, @YES);

    provider = [self providerWithMarker:YES];
    XCTAssertTrue([provider requiresUpdateForParameters:provider.startupParameters]);
    [provider startupDidSucceedWithParameters:provider.startupParameters];
    XCTAssertEqualObjects(self.persistent.lastStartupYandexAdsOnlyState, @NO);
    XCTAssertFalse([provider requiresUpdateForParameters:provider.startupParameters]);
}

@end

@interface AMAYandexAdsSDKDetectorTests : XCTestCase
@end

@implementation AMAYandexAdsSDKDetectorTests

- (void)testLazyLookupCachesBothPresenceAndAbsence
{
    for (NSNumber *present in @[@NO, @YES]) {
        __block NSUInteger lookups = 0;
        AMAYandexAdsSDKDetector *detector = [[AMAYandexAdsSDKDetector alloc]
            initWithClassResolver:^Class(NSString *name) {
                ++lookups;
                XCTAssertEqualObjects(name, @"AnalyticsAdsMarker");
                return present.boolValue ? NSObject.class : Nil;
            }];
        XCTAssertEqual(lookups, 0u);
        for (NSUInteger index = 0; index < 10; ++index) {
            XCTAssertEqual(detector.isPresent, present.boolValue);
        }
        XCTAssertEqual(lookups, 1u);
    }
}

- (void)testConcurrentLookupRunsOnce
{
    __block NSUInteger lookups = 0;
    AMAYandexAdsSDKDetector *detector = [[AMAYandexAdsSDKDetector alloc]
        initWithClassResolver:^Class(NSString *name) {
            ++lookups;
            return NSObject.class;
        }];
    dispatch_apply(20, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^(size_t index) {
        XCTAssertTrue(detector.isPresent);
    });
    XCTAssertEqual(lookups, 1u);
    XCTAssertEqual(AMAYandexAdsSDKDetector.sharedInstance, AMAYandexAdsSDKDetector.sharedInstance);
}

@end
