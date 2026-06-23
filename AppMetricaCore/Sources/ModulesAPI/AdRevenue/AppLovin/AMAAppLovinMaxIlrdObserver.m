
#import "AMAAppLovinMaxIlrdObserver.h"
#import "AMACore.h"
#import <objc/message.h>

static NSString *const kTopic = @"max_revenue_events";
static NSString *const kSourceIdentifier = @"applovin";
static NSString *const kOriginalSource = @"ad-revenue-applovin-v12-auto";
static NSString *const kLayer = @"native";
static NSString *const kCurrency = @"USD";
static NSString *const kCommunicatorId = @"AppMetrica";
static const NSUInteger kDeduplicationCacheSize = 10;

// Matches Java/Kotlin Double.toString() behavior: -1.0 → "-1.0" (not "-1")
static NSString *AMAAppLovinDoubleToString(double value) {
    NSString *s = [NSString stringWithFormat:@"%g", value];
    if ([s rangeOfString:@"."].location == NSNotFound) {
        s = [s stringByAppendingString:@".0"];
    }
    return s;
}

@interface AMAAppLovinMaxIlrdObserver ()
@property (nonatomic, strong) NSMutableArray<NSString *> *processedIds;
@property (nonatomic, assign) BOOL subscribed;
@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, strong) id communicator;
@property (nonatomic, strong) id<AMAAsyncExecuting> executor;
@end

@implementation AMAAppLovinMaxIlrdObserver

- (instancetype)init
{
    return [self initWithExecutor:[[AMAExecutor alloc] initWithIdentifier:self]];
}

- (instancetype)initWithExecutor:(id<AMAAsyncExecuting>)executor
{
    self = [super init];
    if (self) {
        self.processedIds = [NSMutableArray arrayWithCapacity:kDeduplicationCacheSize];
        self.subscribed = NO;
        self.enabled = NO;
        self.communicator = [self resolvedCommunicator];
        self.executor = executor;
    }
    return self;
}

// MARK: - Public

- (void)activateAndSubscribe:(BOOL)enabled
{
    [self.executor execute:^{
        self.enabled = enabled;
        if (enabled && self.communicator != nil && self.subscribed == NO) {
            [self subscribe];
        } else if (enabled == NO && self.subscribed) {
            [self unsubscribe];
        }
    }];
}

// MARK: - ALCCommunicator listener (selector matching, no formal conformance)

- (NSString *)communicatorIdentifier
{
    return kCommunicatorId;
}

- (void)didReceiveMessage:(id)message
{
    [self.executor execute:^{
        if (self.enabled == NO) {
            return;
        }
        SEL topicSel = NSSelectorFromString(@"topic");
        NSString *topic = [message respondsToSelector:topicSel]
            ? ((NSString *(*)(id, SEL))objc_msgSend)(message, topicSel) : nil;
        if ([topic isEqualToString:kTopic] == NO) {
            return;
        }

        SEL dataSel = NSSelectorFromString(@"data");
        if ([message respondsToSelector:dataSel] == NO) {
            return;
        }
        NSDictionary *data = ((id (*)(id, SEL))objc_msgSend)(message, dataSel);
        if (![data isKindOfClass:[NSDictionary class]]) {
            return;
        }

        [self processMessageData:data];
    }];
}

// MARK: - Private

- (nullable id)resolvedCommunicator
{
    Class cls = NSClassFromString(@"ALCCommunicator");
    if (cls == nil) {
        return nil;
    }
    SEL defaultSel = NSSelectorFromString(@"defaultCommunicator");
    if (![cls respondsToSelector:defaultSel]) {
        return nil;
    }
    return ((id (*)(Class, SEL))objc_msgSend)(cls, defaultSel);
}

- (void)subscribe
{
    SEL sel = NSSelectorFromString(@"subscribe:forTopic:");
    if ([self.communicator respondsToSelector:sel]) {
        ((void (*)(id, SEL, id, NSString *))objc_msgSend)(self.communicator, sel, self, kTopic);
        self.subscribed = YES;
    }
}

- (void)unsubscribe
{
    SEL sel = NSSelectorFromString(@"unsubscribe:forTopic:");
    if ([self.communicator respondsToSelector:sel]) {
        ((void (*)(id, SEL, id, NSString *))objc_msgSend)(self.communicator, sel, self, kTopic);
        self.subscribed = NO;
    }
}

- (void)processMessageData:(NSDictionary *)data
{
    NSString *eventId = data[@"id"];
    if (eventId.length == 0) {
        return;
    }

    BOOL alreadySeen = [self.processedIds containsObject:eventId];
    if (!alreadySeen) {
        if (self.processedIds.count >= kDeduplicationCacheSize) {
            [self.processedIds removeObjectAtIndex:0];
        }
        [self.processedIds addObject:eventId];
    }

    if (alreadySeen) {
        return;
    }

    NSNumber *revenueNumber = data[@"revenue"];
    if (revenueNumber == nil) {
        return;
    }
    double revenueValue = [revenueNumber doubleValue];
    if (revenueValue == 0.0) {
        return;
    }

    // Negative values are AppLovin's sentinel for "no revenue data".
    // Report as 0 and preserve the original value in payload.
    BOOL isNegativeRevenue = (revenueValue < 0.0);
    double reportedRevenue = isNegativeRevenue ? 0.0 : revenueValue;

    NSString *adFormat = isNegativeRevenue ? nil : data[@"ad_format"];

    AMAMutableAdRevenueInfo *adRevenue = [[AMAMutableAdRevenueInfo alloc]
        initWithAdRevenue:[NSDecimalNumber decimalNumberWithDecimal:[@(reportedRevenue) decimalValue]]
                 currency:kCurrency];

    adRevenue.adType = [self adTypeForFormat:adFormat];
    adRevenue.adNetwork = isNegativeRevenue ? nil : data[@"network_name"];
    adRevenue.adUnitID = isNegativeRevenue ? nil : data[@"max_ad_unit_id"];
    adRevenue.adPlacementID = isNegativeRevenue ? nil : data[@"third_party_ad_placement_id"];
    adRevenue.precision = isNegativeRevenue ? nil : data[@"precision"];

    NSMutableDictionary *payload = [@{
        @"layer": kLayer,
        @"source": kSourceIdentifier,
        @"original_source": kOriginalSource,
        @"original_ad_type": adFormat ?: @"null",
    } mutableCopy];
    if (isNegativeRevenue) {
        payload[@"original_ad_revenue"] = AMAAppLovinDoubleToString(revenueValue);
    }
    adRevenue.payload = [payload copy];

    if (self.enabled == YES) {
        [AMAAppMetrica reportAdRevenue:adRevenue isAutocollected:YES onFailure:nil];
    }
}

- (AMAAdType)adTypeForFormat:(nullable NSString *)adFormat
{
    if (adFormat == nil) {
        return AMAAdTypeUnknown;
    }
    static NSDictionary<NSString *, NSNumber *> *mapping;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        mapping = @{
            @"BANNER":   @(AMAAdTypeBanner),
            @"MREC":     @(AMAAdTypeMrec),
            @"NATIVE":   @(AMAAdTypeNative),
            @"INTER":    @(AMAAdTypeInterstitial),
            @"REWARDED": @(AMAAdTypeRewarded),
            @"APPOPEN":  @(AMAAdTypeAppOpen),
        };
    });
    NSNumber *mapped = mapping[adFormat];
    return mapped ? (AMAAdType)[mapped unsignedIntegerValue] : AMAAdTypeOther;
}

@end
