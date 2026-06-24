
#import "AMAIronSourceImpressionDelegate.h"
#import "AMAIronSourceLog.h"

static NSString *const kSourceIdentifier = @"ironsource";
static NSString *const kOriginalSourceV8  = @"ad-revenue-ironsource-v8";
static NSString *const kOriginalSourceV9  = @"ad-revenue-ironsource-v9";
static NSString *const kLayer    = @"native";
static NSString *const kCurrency = @"USD";

// Unified IronSource adFormat strings (impression data), v8 + v9.
static NSString *const kFormatRewardedVideo    = @"rewarded_video";
static NSString *const kFormatRewardedVideoAlt = @"rewardedVideo";
static NSString *const kFormatNativeAd         = @"nativeAd";
static NSString *const kFormatInterstitial     = @"interstitial";
static NSString *const kFormatBanner           = @"banner";

@interface AMAIronSourceImpressionDelegate ()
{
    NSInteger _majorVersion;
    NSMutableArray *_pendingImpressions;
    NSLock *_lock;
    BOOL _activated;
}
@end

@implementation AMAIronSourceImpressionDelegate

- (instancetype)initWithMajorVersion:(NSInteger)majorVersion
{
    self = [super init];
    if (self) {
        _majorVersion = majorVersion;
        _pendingImpressions = [NSMutableArray array];
        _lock = [[NSLock alloc] init];
        _activated = NO;
        AMAIronSourceLog(@"delegate initialized for v%ld", (long)majorVersion);
    }
    return self;
}

- (void)processQueuedImpressionData
{
    NSArray *pending;
    [_lock lock];
    _activated = YES;
    pending = [_pendingImpressions copy];
    [_pendingImpressions removeAllObjects];
    [_lock unlock];

    AMAIronSourceLog(@"activated, flushing %lu queued impressions", (unsigned long)pending.count);
    for (id impression in pending) {
        [self processImpressionData:impression];
    }
}

// MARK: - ISImpressionDataDelegate / LPMImpressionDataDelegate (selector matching, no formal conformance)

- (void)impressionDataDidSucceed:(id)impressionData
{
    [_lock lock];
    BOOL activated = _activated;
    if (!activated) {
        [_pendingImpressions addObject:impressionData];
    }
    [_lock unlock];

    if (activated) {
        [self processImpressionData:impressionData];
    } else {
        AMAIronSourceLog(@"impression queued before activation (total: %lu)",
                         (unsigned long)_pendingImpressions.count);
    }
}

// MARK: - Private

- (void)processImpressionData:(id)impressionData
{
    if (_majorVersion == 8) {
        [self processV8ImpressionData:impressionData];
    } else {
        [self processV9ImpressionData:impressionData];
    }
}

// MARK: V8 — ISImpressionData (snake_case keys)

- (void)processV8ImpressionData:(id)impressionData
{
    NSNumber *revenueNumber = [impressionData valueForKey:@"revenue"];
    if (revenueNumber == nil) {
        return;
    }
    double revenueValue = [revenueNumber doubleValue];

    AMAMutableAdRevenueInfo *adRevenue = [[AMAMutableAdRevenueInfo alloc]
        initWithAdRevenue:[NSDecimalNumber decimalNumberWithDecimal:[@(revenueValue) decimalValue]]
                 currency:kCurrency];

    NSString *adFormat = [impressionData valueForKey:@"ad_format"];
    adRevenue.adType        = [self adTypeForFormat:adFormat];
    adRevenue.adNetwork     = [impressionData valueForKey:@"ad_network"];
    adRevenue.adPlacementName = [impressionData valueForKey:@"placement"];
    adRevenue.precision     = [impressionData valueForKey:@"precision"];
    adRevenue.adUnitID      = [impressionData valueForKey:@"mediation_ad_unit_id"];
    adRevenue.adUnitName    = [impressionData valueForKey:@"mediation_ad_unit_name"];
    adRevenue.payload = @{
        @"layer":           kLayer,
        @"source":          kSourceIdentifier,
        @"original_source": kOriginalSourceV8,
        @"original_ad_type": adFormat ?: @"null",
    };

    AMAIronSourceLog(@"v8: revenue=%g adFormat=%@ adNetwork=%@",
                     revenueValue, adFormat, adRevenue.adNetwork);
    [AMAAppMetrica reportAdRevenue:adRevenue isAutocollected:YES onFailure:nil];
}

// MARK: V9 — LPMImpressionData (camelCase keys)

- (void)processV9ImpressionData:(id)impressionData
{
    NSNumber *revenueNumber = [impressionData valueForKey:@"revenue"];
    if (revenueNumber == nil) {
        return;
    }
    double revenueValue = [revenueNumber doubleValue];

    AMAMutableAdRevenueInfo *adRevenue = [[AMAMutableAdRevenueInfo alloc]
        initWithAdRevenue:[NSDecimalNumber decimalNumberWithDecimal:[@(revenueValue) decimalValue]]
                 currency:kCurrency];

    NSString *adFormat = [impressionData valueForKey:@"adFormat"];
    adRevenue.adType          = [self adTypeForFormat:adFormat];
    adRevenue.adNetwork       = [impressionData valueForKey:@"adNetwork"];
    adRevenue.adPlacementName = [impressionData valueForKey:@"placement"];
    adRevenue.precision       = [impressionData valueForKey:@"precision"];
    adRevenue.adUnitID        = [impressionData valueForKey:@"mediationAdUnitId"];
    adRevenue.adUnitName      = [impressionData valueForKey:@"mediationAdUnitName"];
    adRevenue.payload = @{
        @"layer":           kLayer,
        @"source":          kSourceIdentifier,
        @"original_source": kOriginalSourceV9,
        @"original_ad_type": adFormat ?: @"null",
    };

    AMAIronSourceLog(@"v9: revenue=%g adFormat=%@ adNetwork=%@",
                     revenueValue, adFormat, adRevenue.adNetwork);
    [AMAAppMetrica reportAdRevenue:adRevenue isAutocollected:YES onFailure:nil];
}

- (AMAAdType)adTypeForFormat:(nullable NSString *)adFormat
{
    if (adFormat == nil) {
        return AMAAdTypeUnknown;
    }
    if ([adFormat isEqualToString:kFormatRewardedVideo] ||
        [adFormat isEqualToString:kFormatRewardedVideoAlt]) {
        return AMAAdTypeRewarded;
    }
    if ([adFormat isEqualToString:kFormatInterstitial]) {
        return AMAAdTypeInterstitial;
    }
    if ([adFormat isEqualToString:kFormatBanner]) {
        return AMAAdTypeBanner;
    }
    if ([adFormat isEqualToString:kFormatNativeAd]) {
        return AMAAdTypeNative;
    }
    return AMAAdTypeOther;
}

@end
