
#import "AMAIronSourceImpressionDelegate.h"
#import "AMAIronSourceLog.h"
#import <objc/message.h>

static NSString *const kSourceIdentifier = @"ironsource";
static NSString *const kOriginalSourceV8  = @"ad-revenue-ironsource-v8";
static NSString *const kOriginalSourceV9  = @"ad-revenue-ironsource-v9";
static NSString *const kLayer    = @"native";
static NSString *const kCurrency = @"USD";

// V9 / LPMImpressionData adFormat strings
static NSString *const kV9FormatRewarded     = @"rewarded_video";
static NSString *const kV9FormatInterstitial = @"interstitial";
static NSString *const kV9FormatBanner       = @"banner";

typedef id        (*AMAISAdUnitClassMethodIMP)(Class, SEL);
typedef NSString *(*AMAISAdUnitValueIMP)(id, SEL);

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

// MARK: V8 — ISImpressionData (snake_case keys, ISAdUnit constants for adType)

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
    adRevenue.adType        = [self v8AdTypeForFormat:adFormat];
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

/// Builds the adFormat→AMAAdType map once from ISAdUnit class-method constants via runtime.
/// Falls back to an empty map (→ AMAAdTypeOther) if ISAdUnit is not present.
- (NSDictionary<NSString *, NSNumber *> *)v8AdUnitMap
{
    static NSDictionary *map = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        Class cls = NSClassFromString(@"ISAdUnit");
        if (cls == nil) {
            map = @{};
            return;
        }
        NSMutableDictionary *m = [NSMutableDictionary dictionary];
        void (^add)(NSString *, AMAAdType) = ^(NSString *selName, AMAAdType adType) {
            SEL sel = NSSelectorFromString(selName);
            if (![cls respondsToSelector:sel]) { return; }
            id unit = ((AMAISAdUnitClassMethodIMP)objc_msgSend)(cls, sel);
            if (unit == nil) { return; }
            SEL valueSel = NSSelectorFromString(@"value");
            if (![unit respondsToSelector:valueSel]) { return; }
            NSString *value = ((AMAISAdUnitValueIMP)objc_msgSend)(unit, valueSel);
            if (value.length > 0) { m[value] = @(adType); }
        };
        add(@"IS_AD_UNIT_REWARDED_VIDEO", AMAAdTypeRewarded);
        add(@"IS_AD_UNIT_INTERSTITIAL",   AMAAdTypeInterstitial);
        add(@"IS_AD_UNIT_BANNER",         AMAAdTypeBanner);
        add(@"IS_AD_UNIT_NATIVE_AD",      AMAAdTypeNative);
        map = [m copy];
    });
    return map;
}

- (AMAAdType)v8AdTypeForFormat:(nullable NSString *)adFormat
{
    if (adFormat == nil) { return AMAAdTypeUnknown; }
    NSNumber *mapped = [self v8AdUnitMap][adFormat];
    return mapped ? (AMAAdType)mapped.unsignedIntegerValue : AMAAdTypeOther;
}

// MARK: V9 — LPMImpressionData (camelCase keys, string adFormat mapping)

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
    adRevenue.adType          = [self v9AdTypeForFormat:adFormat];
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

- (AMAAdType)v9AdTypeForFormat:(nullable NSString *)adFormat
{
    if (adFormat == nil)                              { return AMAAdTypeUnknown; }
    if ([adFormat isEqualToString:kV9FormatRewarded]) { return AMAAdTypeRewarded; }
    if ([adFormat isEqualToString:kV9FormatInterstitial]) { return AMAAdTypeInterstitial; }
    if ([adFormat isEqualToString:kV9FormatBanner])   { return AMAAdTypeBanner; }
    return AMAAdTypeOther;
}

@end
