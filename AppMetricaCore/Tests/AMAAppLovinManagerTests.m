
#import <XCTest/XCTest.h>
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMAAppLovinManager.h"
#import "AMAAppLovinMaxIlrdObserver.h"
#import "AMAAppLovinStartupResponseParser.h"
#import "AMAAppLovinTestSDKStubs.h"
#import "AMAAppMetricaMock.h"
#import "Mocks/AMATestStartupStorageProvider.h"
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>

// MARK: - Test helpers

@interface AMAAppLovinManager (Testing)
@property (nonatomic, strong) AMAAppLovinMaxIlrdObserver *observer;
@property (nonatomic, strong) id<AMAAsyncExecuting> executor;
@end

// MARK: - Tests

@interface AMAAppLovinManagerTests : XCTestCase
@property (nonatomic, strong) AMAAppLovinManager *manager;
@property (nonatomic, strong) AMATestStartupStorageProvider *storageProvider;
@property (nonatomic, strong) AMATestCachingStorageProvider *cachingProvider;
@end

@implementation AMAAppLovinManagerTests

- (void)setUp
{
    AMAAppLovinTestSDKStubsReset();
    gALCCommunicatorAvailable = YES;
    [AMAAppMetricaMock resetCaptures];
    [AMAAppMetrica stub:@selector(reportAdRevenue:isAutocollected:onFailure:)
             withBlock:^id(NSArray *params) {
        [AMAAppMetricaMock.capturedAdRevenues addObject:params[0]];
        return nil;
    }];

    AMACurrentQueueExecutor *syncExecutor = [[AMACurrentQueueExecutor alloc] init];
    AMAAppLovinMaxIlrdObserver *syncObserver = [[AMAAppLovinMaxIlrdObserver alloc] initWithExecutor:syncExecutor];

    self.manager = [[AMAAppLovinManager alloc]
        initWithExecutor:syncExecutor
          responseParser:[[AMAAppLovinStartupResponseParser alloc] init]];
    self.manager.observer = syncObserver;

    self.storageProvider = [[AMATestStartupStorageProvider alloc] init];
    self.storageProvider.storage = [[AMAKeyValueStorageMock alloc] init];
    self.cachingProvider = [[AMATestCachingStorageProvider alloc] init];

    AMACurrentQueueExecutor *sharedSyncExecutor = [[AMACurrentQueueExecutor alloc] init];
    [AMAAppLovinManager sharedInstance].executor = sharedSyncExecutor;
    [AMAAppLovinManager sharedInstance].observer = [[AMAAppLovinMaxIlrdObserver alloc] initWithExecutor:sharedSyncExecutor];
}

- (void)tearDown
{
    [AMAAppMetrica clearStubs];
}

// MARK: - setup

- (void)testSetup_createsObserver
{
    AMAAppLovinManager *m = [[AMAAppLovinManager alloc]
        initWithExecutor:[[AMACurrentQueueExecutor alloc] init]
          responseParser:[[AMAAppLovinStartupResponseParser alloc] init]];
    XCTAssertNil(m.observer);
    [m setup];
    XCTAssertNotNil(m.observer);
}

- (void)testSetup_reusesObserver
{
    AMAAppLovinManager *manager = [[AMAAppLovinManager alloc]
        initWithExecutor:[[AMACurrentQueueExecutor alloc] init]
          responseParser:[[AMAAppLovinStartupResponseParser alloc] init]];

    [manager setup];
    AMAAppLovinMaxIlrdObserver *observer = manager.observer;
    [manager setup];

    XCTAssertTrue(manager.observer == observer);
}

// MARK: - didActivateWithConfiguration

- (void)testDidActivate_subscribesObserver
{
    [AMAAppLovinManager didActivateWithConfiguration:nil];
    XCTAssertEqual(gALCSubscribedListeners.count, 1u);
}

- (void)testWillActivate_doesNotSubscribe
{
    [AMAAppLovinManager willActivateWithConfiguration:nil];
    XCTAssertEqual(gALCSubscribedListeners.count, 0u);
}

// MARK: - setupStartupProvider

- (void)testSetupStartupProvider_withDefaultAramEnabled_doesNotSubscribeBeforeActivation
{
    [self.manager setupStartupProvider:self.storageProvider
                cachingStorageProvider:self.cachingProvider];
    XCTAssertEqual(gALCSubscribedListeners.count, 0u);
}

- (void)testSetupStartupProvider_withStoredAramDisabled_doesNotSubscribe
{
    AMAKeyValueStorageMock *storage = (AMAKeyValueStorageMock *)self.storageProvider.storage;
    storage.storage = @{ @"io.appmetrica.applovin.aram_enabled": @NO };

    [self.manager setupStartupProvider:self.storageProvider
                cachingStorageProvider:self.cachingProvider];
    XCTAssertEqual(gALCSubscribedListeners.count, 0u);
}

// MARK: - startupUpdatedWithParameters

- (void)testStartupUpdated_withAramDisabled_unsubscribes
{
    [self.manager setupStartupProvider:self.storageProvider
                cachingStorageProvider:self.cachingProvider];
    [self.manager.observer activateAndSubscribe:YES];

    NSDictionary *response = @{ @"features": @{ @"list": @{ @"ad_revenue_applovin_max": @{ @"enabled": @0 } } } };
    [self.manager startupUpdatedWithParameters:response];

    XCTAssertEqual(gALCUnsubscribedListeners.count, 1u);
}

- (void)testStartupUpdated_withAramEnabled_keepsSubscription
{
    [self.manager setupStartupProvider:self.storageProvider
                cachingStorageProvider:self.cachingProvider];
    [self.manager.observer activateAndSubscribe:YES];

    NSDictionary *response = @{ @"features": @{ @"list": @{ @"ad_revenue_applovin_max": @{ @"enabled": @1 } } } };
    [self.manager startupUpdatedWithParameters:response];

    XCTAssertEqual(gALCUnsubscribedListeners.count, 0u);
}

- (void)testStartupUpdated_savesStorage
{
    [self.manager setupStartupProvider:self.storageProvider
                cachingStorageProvider:self.cachingProvider];

    NSDictionary *response = @{ @"features": @{ @"list": @{ @"ad_revenue_applovin_max": @{ @"enabled": @0 } } } };
    [self.manager startupUpdatedWithParameters:response];

    XCTAssertEqual(self.storageProvider.savedStorages.count, 1u);
}

// MARK: - startupParameters

- (void)testStartupParameters_containsAramFeature
{
    NSDictionary *params = [self.manager startupParameters];
    XCTAssertEqualObjects(params[@"request"][@"features"], @"aram");
}

// MARK: - message forwarding

- (void)testDidActivate_thenMessage_reportsAdRevenue
{
    [AMAAppLovinManager didActivateWithConfiguration:nil];

    AMAAppLovinSimulateMessage(@{
        @"id": @"evt1",
        @"revenue": @0.5,
        @"ad_format": @"BANNER",
    }, @"max_revenue_events");

    XCTAssertEqual(AMAAppMetricaMock.capturedAdRevenues.count, 1u);
}

@end
