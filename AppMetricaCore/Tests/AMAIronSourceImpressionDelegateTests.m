
#import <XCTest/XCTest.h>
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMAIronSourceImpressionDelegate.h"
#import "Mocks/AMAAppMetricaMock.h"

// MARK: - Fake impression data (V9 — camelCase keys)

@interface AMAFakeV9ImpressionData : NSObject
@property (nonatomic, strong) NSNumber *revenue;
@property (nonatomic, copy)   NSString *adFormat;
@property (nonatomic, copy)   NSString *adNetwork;
@property (nonatomic, copy)   NSString *placement;
@property (nonatomic, copy)   NSString *precision;
@property (nonatomic, copy)   NSString *mediationAdUnitId;
@property (nonatomic, copy)   NSString *mediationAdUnitName;
@end
@implementation AMAFakeV9ImpressionData
@end

// MARK: - Fake impression data (V8 — snake_case keys)

@interface AMAFakeV8ImpressionData : NSObject
@property (nonatomic, strong) NSNumber *revenue;
@property (nonatomic, copy)   NSString *ad_format;
@property (nonatomic, copy)   NSString *ad_network;
@property (nonatomic, copy)   NSString *placement;
@property (nonatomic, copy)   NSString *precision;
@property (nonatomic, copy)   NSString *mediation_ad_unit_id;
@property (nonatomic, copy)   NSString *mediation_ad_unit_name;
@end
@implementation AMAFakeV8ImpressionData
@end

// MARK: - Tests

@interface AMAIronSourceImpressionDelegateTests : XCTestCase
@property (nonatomic, strong) AMAIronSourceImpressionDelegate *v9Delegate;
@property (nonatomic, strong) AMAIronSourceImpressionDelegate *v8Delegate;
@end

@implementation AMAIronSourceImpressionDelegateTests

- (void)setUp
{
    [AMAAppMetricaMock resetCaptures];
    [AMAAppMetrica stub:@selector(reportAdRevenue:isAutocollected:onFailure:)
             withBlock:^id(NSArray *params) {
        [AMAAppMetricaMock.capturedAdRevenues addObject:params[0]];
        [AMAAppMetricaMock.capturedIsAutocollected addObject:params[1]];
        return nil;
    }];
    self.v9Delegate = [[AMAIronSourceImpressionDelegate alloc] initWithMajorVersion:9];
    self.v8Delegate = [[AMAIronSourceImpressionDelegate alloc] initWithMajorVersion:8];
}

- (void)tearDown
{
    [AMAAppMetrica clearStubs];
}

// MARK: - V9 queuing behaviour

- (void)testV9_impressionAfterActivation_reportedImmediately
{
    [self.v9Delegate processQueuedImpressionData];
    AMAFakeV9ImpressionData *d = [AMAFakeV9ImpressionData new];
    d.revenue = @0.5;
    [self.v9Delegate impressionDataDidSucceed:d];

    XCTAssertEqual(AMAAppMetricaMock.capturedAdRevenues.count, 1u);
}

- (void)testV9_impressionsBeforeActivation_queuedThenFlushed
{
    AMAFakeV9ImpressionData *d1 = [AMAFakeV9ImpressionData new]; d1.revenue = @0.1;
    AMAFakeV9ImpressionData *d2 = [AMAFakeV9ImpressionData new]; d2.revenue = @0.2;
    [self.v9Delegate impressionDataDidSucceed:d1];
    [self.v9Delegate impressionDataDidSucceed:d2];
    XCTAssertEqual(AMAAppMetricaMock.capturedAdRevenues.count, 0u, @"must not report before activation");

    [self.v9Delegate processQueuedImpressionData];
    XCTAssertEqual(AMAAppMetricaMock.capturedAdRevenues.count, 2u);
}

- (void)testV9_queueClearedAfterFlush_secondFlushReportsNothing
{
    AMAFakeV9ImpressionData *d = [AMAFakeV9ImpressionData new]; d.revenue = @1.0;
    [self.v9Delegate impressionDataDidSucceed:d];
    [self.v9Delegate processQueuedImpressionData];
    [AMAAppMetricaMock resetCaptures];

    [self.v9Delegate processQueuedImpressionData];
    XCTAssertEqual(AMAAppMetricaMock.capturedAdRevenues.count, 0u);
}

// MARK: - V9 field mapping

- (void)testV9_allFieldsMappedCorrectly
{
    [self.v9Delegate processQueuedImpressionData];

    AMAFakeV9ImpressionData *d = [AMAFakeV9ImpressionData new];
    d.revenue             = @0.75;
    d.adFormat            = @"rewarded_video";
    d.adNetwork           = @"admob";
    d.placement           = @"main_screen";
    d.precision           = @"exact";
    d.mediationAdUnitId   = @"unit_id_123";
    d.mediationAdUnitName = @"unit_name_456";
    [self.v9Delegate impressionDataDidSucceed:d];

    AMAAdRevenueInfo *info = AMAAppMetricaMock.capturedAdRevenues.firstObject;
    XCTAssertEqualObjects(info.adRevenue, [NSDecimalNumber decimalNumberWithDecimal:[@(0.75) decimalValue]]);
    XCTAssertEqualObjects(info.currency, @"USD");
    XCTAssertEqual(info.adType, AMAAdTypeRewarded);
    XCTAssertEqualObjects(info.adNetwork, @"admob");
    XCTAssertEqualObjects(info.adPlacementName, @"main_screen");
    XCTAssertEqualObjects(info.precision, @"exact");
    XCTAssertEqualObjects(info.adUnitID, @"unit_id_123");
    XCTAssertEqualObjects(info.adUnitName, @"unit_name_456");
    XCTAssertEqualObjects(info.payload[@"layer"], @"native");
    XCTAssertEqualObjects(info.payload[@"source"], @"ironsource");
    XCTAssertEqualObjects(info.payload[@"original_source"], @"ad-revenue-ironsource-v9");
    XCTAssertEqualObjects(info.payload[@"original_ad_type"], @"rewarded_video");
    XCTAssertEqualObjects(AMAAppMetricaMock.capturedIsAutocollected.firstObject, @YES);
}

- (void)testV9_adTypeMapping
{
    [self.v9Delegate processQueuedImpressionData];
    NSDictionary<NSString *, NSNumber *> *cases = @{
        @"rewarded_video": @(AMAAdTypeRewarded),
        @"rewardedVideo":  @(AMAAdTypeRewarded),
        @"nativeAd":       @(AMAAdTypeNative),
        @"interstitial":   @(AMAAdTypeInterstitial),
        @"banner":         @(AMAAdTypeBanner),
        @"unknown_format": @(AMAAdTypeOther),
    };
    [cases enumerateKeysAndObjectsUsingBlock:^(NSString *format, NSNumber *expected, BOOL *stop) {
        [AMAAppMetricaMock resetCaptures];
        AMAFakeV9ImpressionData *d = [AMAFakeV9ImpressionData new];
        d.revenue = @1.0; d.adFormat = format;
        [self.v9Delegate impressionDataDidSucceed:d];
        XCTAssertEqual(((AMAAdRevenueInfo *)AMAAppMetricaMock.capturedAdRevenues.firstObject).adType,
                       (AMAAdType)expected.unsignedIntegerValue, @"adFormat=%@", format);
    }];
}

- (void)testV8_adTypeMapping
{
    [self.v8Delegate processQueuedImpressionData];
    NSDictionary<NSString *, NSNumber *> *cases = @{
        @"rewarded_video": @(AMAAdTypeRewarded),
        @"rewardedVideo":  @(AMAAdTypeRewarded),
        @"nativeAd":       @(AMAAdTypeNative),
        @"interstitial":   @(AMAAdTypeInterstitial),
        @"banner":         @(AMAAdTypeBanner),
        @"unknown_format": @(AMAAdTypeOther),
    };
    [cases enumerateKeysAndObjectsUsingBlock:^(NSString *format, NSNumber *expected, BOOL *stop) {
        [AMAAppMetricaMock resetCaptures];
        AMAFakeV8ImpressionData *d = [AMAFakeV8ImpressionData new];
        d.revenue = @1.0; d.ad_format = format;
        [self.v8Delegate impressionDataDidSucceed:d];
        XCTAssertEqual(((AMAAdRevenueInfo *)AMAAppMetricaMock.capturedAdRevenues.firstObject).adType,
                       (AMAAdType)expected.unsignedIntegerValue, @"ad_format=%@", format);
    }];
}

- (void)testV9_nilAdFormat_unknownAdTypeAndNullInPayload
{
    [self.v9Delegate processQueuedImpressionData];
    AMAFakeV9ImpressionData *d = [AMAFakeV9ImpressionData new]; d.revenue = @1.0;
    [self.v9Delegate impressionDataDidSucceed:d];
    AMAAdRevenueInfo *info = AMAAppMetricaMock.capturedAdRevenues.firstObject;
    XCTAssertEqual(info.adType, AMAAdTypeUnknown);
    XCTAssertEqualObjects(info.payload[@"original_ad_type"], @"null");
}

// MARK: - V8 field mapping

- (void)testV8_allFieldsMappedCorrectly
{
    [self.v8Delegate processQueuedImpressionData];

    AMAFakeV8ImpressionData *d = [AMAFakeV8ImpressionData new];
    d.revenue                = @1.25;
    d.ad_format              = @"unknown_format";
    d.ad_network             = @"ironnet";
    d.placement              = @"video_end";
    d.precision              = @"estimated";
    d.mediation_ad_unit_id   = @"vid_id";
    d.mediation_ad_unit_name = @"vid_name";
    [self.v8Delegate impressionDataDidSucceed:d];

    AMAAdRevenueInfo *info = AMAAppMetricaMock.capturedAdRevenues.firstObject;
    XCTAssertEqualObjects(info.adRevenue, [NSDecimalNumber decimalNumberWithDecimal:[@(1.25) decimalValue]]);
    XCTAssertEqualObjects(info.currency, @"USD");
    XCTAssertEqual(info.adType, AMAAdTypeOther);
    XCTAssertEqualObjects(info.adNetwork, @"ironnet");
    XCTAssertEqualObjects(info.adPlacementName, @"video_end");
    XCTAssertEqualObjects(info.precision, @"estimated");
    XCTAssertEqualObjects(info.adUnitID, @"vid_id");
    XCTAssertEqualObjects(info.adUnitName, @"vid_name");
    XCTAssertEqualObjects(info.payload[@"original_source"], @"ad-revenue-ironsource-v8");
    XCTAssertEqualObjects(info.payload[@"original_ad_type"], @"unknown_format");
}

- (void)testV8_nilAdFormat_unknownAdType
{
    [self.v8Delegate processQueuedImpressionData];
    AMAFakeV8ImpressionData *d = [AMAFakeV8ImpressionData new]; d.revenue = @1.0;
    [self.v8Delegate impressionDataDidSucceed:d];
    XCTAssertEqual(((AMAAdRevenueInfo *)AMAAppMetricaMock.capturedAdRevenues.firstObject).adType, AMAAdTypeUnknown);
}

- (void)testV8_nilRevenue_doesNotReport
{
    [self.v8Delegate processQueuedImpressionData];
    AMAFakeV8ImpressionData *d = [AMAFakeV8ImpressionData new];
    [self.v8Delegate impressionDataDidSucceed:d];
    XCTAssertEqual(AMAAppMetricaMock.capturedAdRevenues.count, 0u);
}

- (void)testV9_nilRevenue_doesNotReport
{
    [self.v9Delegate processQueuedImpressionData];
    AMAFakeV9ImpressionData *d = [AMAFakeV9ImpressionData new];
    [self.v9Delegate impressionDataDidSucceed:d];
    XCTAssertEqual(AMAAppMetricaMock.capturedAdRevenues.count, 0u);
}

@end
