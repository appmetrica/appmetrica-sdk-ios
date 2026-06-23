
#import <XCTest/XCTest.h>
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMAAppLovinMaxIlrdObserver.h"
#import "AMAAppLovinTestSDKStubs.h"
#import "AMAAppMetricaMock.h"
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>

@interface AMAAppLovinIlrdObserverTests : XCTestCase
@property (nonatomic, strong) AMAAppLovinMaxIlrdObserver *observer;
@end

@implementation AMAAppLovinIlrdObserverTests

- (void)setUp
{
    AMAAppLovinTestSDKStubsReset();
    gALCCommunicatorAvailable = YES;
    [AMAAppMetricaMock resetCaptures];
    [AMAAppMetrica stub:@selector(reportAdRevenue:isAutocollected:onFailure:)
             withBlock:^id(NSArray *params) {
        [AMAAppMetricaMock.capturedAdRevenues addObject:params[0]];
        [AMAAppMetricaMock.capturedIsAutocollected addObject:params[1]];
        return nil;
    }];
    self.observer = [[AMAAppLovinMaxIlrdObserver alloc] initWithExecutor:[[AMACurrentQueueExecutor alloc] init]];
    [self.observer activateAndSubscribe:YES];
}

- (void)tearDown
{
    [AMAAppMetrica clearStubs];
}

- (void)sendData:(NSDictionary *)data
{
    AMAAppLovinSimulateMessage(data, @"max_revenue_events");
}

// MARK: - Filtering

- (void)testMissingId_dropped
{
    [self sendData:@{ @"revenue": @1.0, @"ad_format": @"BANNER" }];
    XCTAssertEqual(AMAAppMetricaMock.capturedAdRevenues.count, 0u);
}

- (void)testZeroRevenue_dropped
{
    [self sendData:@{ @"id": @"e1", @"revenue": @0.0, @"ad_format": @"BANNER" }];
    XCTAssertEqual(AMAAppMetricaMock.capturedAdRevenues.count, 0u);
}

- (void)testWrongTopic_ignored
{
    AMAAppLovinSimulateMessage(@{ @"id": @"e1", @"revenue": @1.0 }, @"other_topic");
    XCTAssertEqual(AMAAppMetricaMock.capturedAdRevenues.count, 0u);
}

// MARK: - Deduplication

- (void)testDeduplication_sameId_reportedOnce
{
    [self sendData:@{ @"id": @"dup", @"revenue": @1.0, @"ad_format": @"BANNER" }];
    [self sendData:@{ @"id": @"dup", @"revenue": @1.0, @"ad_format": @"BANNER" }];
    XCTAssertEqual(AMAAppMetricaMock.capturedAdRevenues.count, 1u);
}

- (void)testDeduplication_differentIds_bothReported
{
    [self sendData:@{ @"id": @"e1", @"revenue": @1.0, @"ad_format": @"BANNER" }];
    [self sendData:@{ @"id": @"e2", @"revenue": @1.0, @"ad_format": @"BANNER" }];
    XCTAssertEqual(AMAAppMetricaMock.capturedAdRevenues.count, 2u);
}

// MARK: - Field mapping

- (void)testAllFieldsMappedCorrectly
{
    [self sendData:@{
        @"id": @"ev1",
        @"revenue": @2.5,
        @"ad_format": @"REWARDED",
        @"network_name": @"admob",
        @"max_ad_unit_id": @"unit_id",
        @"third_party_ad_placement_id": @"placement_id",
        @"precision": @"exact",
    }];

    AMAAdRevenueInfo *info = AMAAppMetricaMock.capturedAdRevenues.firstObject;
    XCTAssertEqualObjects(info.adRevenue, [NSDecimalNumber decimalNumberWithDecimal:[@(2.5) decimalValue]]);
    XCTAssertEqualObjects(info.currency, @"USD");
    XCTAssertEqual(info.adType, AMAAdTypeRewarded);
    XCTAssertEqualObjects(info.adNetwork, @"admob");
    XCTAssertEqualObjects(info.adUnitID, @"unit_id");
    XCTAssertEqualObjects(info.adPlacementID, @"placement_id");
    XCTAssertEqualObjects(info.precision, @"exact");
    XCTAssertEqualObjects(info.payload[@"source"], @"applovin");
    XCTAssertEqualObjects(info.payload[@"layer"], @"native");
    XCTAssertEqualObjects(info.payload[@"original_source"], @"ad-revenue-applovin-v12-auto");
    XCTAssertEqualObjects(info.payload[@"original_ad_type"], @"REWARDED");
    XCTAssertEqualObjects(AMAAppMetricaMock.capturedIsAutocollected.firstObject, @YES);
}

// MARK: - Ad type mapping

- (void)testAdTypeMapping
{
    NSDictionary<NSString *, NSNumber *> *cases = @{
        @"BANNER":   @(AMAAdTypeBanner),
        @"MREC":     @(AMAAdTypeMrec),
        @"NATIVE":   @(AMAAdTypeNative),
        @"INTER":    @(AMAAdTypeInterstitial),
        @"REWARDED": @(AMAAdTypeRewarded),
        @"APPOPEN":  @(AMAAdTypeAppOpen),
        @"LEADER":   @(AMAAdTypeOther),
    };
    [cases enumerateKeysAndObjectsUsingBlock:^(NSString *format, NSNumber *expected, BOOL *stop) {
        [AMAAppMetricaMock resetCaptures];
        [self sendData:@{ @"id": format, @"revenue": @1.0, @"ad_format": format }];
        XCTAssertEqual(((AMAAdRevenueInfo *)AMAAppMetricaMock.capturedAdRevenues.firstObject).adType,
                       (AMAAdType)expected.unsignedIntegerValue, @"ad_format=%@", format);
    }];
}

// MARK: - Negative revenue sentinel

- (void)testNegativeRevenue_reportedAsZeroWithOriginalInPayload
{
    // AppLovin sentinel: -1.0 means "no revenue data"; must be reported as 0 with original value in payload
    [self sendData:@{ @"id": @"neg1", @"revenue": @(-1.0) }];

    AMAAdRevenueInfo *info = AMAAppMetricaMock.capturedAdRevenues.firstObject;
    XCTAssertEqualObjects(info.adRevenue, [NSDecimalNumber zero]);
    XCTAssertEqual(info.adType, AMAAdTypeUnknown);
    XCTAssertNil(info.adNetwork);
    XCTAssertNil(info.adUnitID);
    XCTAssertEqualObjects(info.payload[@"original_ad_revenue"], @"-1.0");
    XCTAssertEqualObjects(info.payload[@"original_ad_type"], @"null");
}

// MARK: - activateAndSubscribe

- (void)testActivateAndSubscribeNO_doesNotSubscribe
{
    AMAAppLovinTestSDKStubsReset();
    gALCCommunicatorAvailable = YES;
    AMAAppLovinMaxIlrdObserver *observer = [[AMAAppLovinMaxIlrdObserver alloc] initWithExecutor:[[AMACurrentQueueExecutor alloc] init]];
    [observer activateAndSubscribe:NO];
    XCTAssertEqual(gALCSubscribedListeners.count, 0u);
}

- (void)testActivateAndSubscribeNO_afterSubscribed_unsubscribes
{
    [self.observer activateAndSubscribe:NO];
    XCTAssertEqual(gALCUnsubscribedListeners.count, 1u);
}

- (void)testActivateAndSubscribeYES_afterSubscribed_doesNotDuplicate
{
    [self.observer activateAndSubscribe:YES];
    XCTAssertEqual(gALCSubscribedListeners.count, 1u);
}

- (void)testDisabled_dropsMessage
{
    [self.observer activateAndSubscribe:NO];
    [self sendData:@{ @"id": @"e1", @"revenue": @1.0, @"ad_format": @"BANNER" }];
    XCTAssertEqual(AMAAppMetricaMock.capturedAdRevenues.count, 0u);
}

// MARK: - missing revenue

- (void)testMissingRevenue_dropped
{
    [self sendData:@{ @"id": @"e1", @"ad_format": @"BANNER" }];
    XCTAssertEqual(AMAAppMetricaMock.capturedAdRevenues.count, 0u);
}

@end
