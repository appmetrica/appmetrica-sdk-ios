#import "AMAAdRevenueSourceContainer.h"
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>
#import "AMACore.h"

static NSString *const kAdRevenuePluginSourcesKey = @"io.appmetrica.analytics.plugin_supported_ad_revenue_sources";
static NSArray<NSString *> *kAdRevenueDefaultValues;

@interface AMAAdRevenueSourceContainer ()

@property (nonatomic, strong, readonly) NSBundle *pluginSourceBundle;

@end

@implementation AMAAdRevenueSourceContainer

@synthesize pluginSupportedSources = _pluginSupportedSources;
@synthesize nativeSupportedSources = _nativeSupportedSources;

+ (void)load
{
    kAdRevenueDefaultValues = @[
        @"yandex"
    ];
}

- (instancetype)initWithPluginSourceBundle:(NSBundle*)pluginSourceBundle
{
    self = [super init];
    if (self) {
        _nativeSupportedSources = [kAdRevenueDefaultValues copy];
        _pluginSourceBundle = pluginSourceBundle;
    }
    return self;
}

- (void)addNativeSupportedSource:(NSString *)source
{
    @synchronized (self) {
        NSMutableArray<NSString *> *result = [self.nativeSupportedSources mutableCopy];
        [result addObject:source];
        _nativeSupportedSources = [result copy];
    }
}

- (NSArray<NSString *> *)pluginSupportedSources
{
    if (_pluginSupportedSources == nil) {
        @synchronized (self) {
            if (_pluginSupportedSources == nil) {
                
                NSArray<NSString *> *result = @[];
                id infoPListSources = [self.pluginSourceBundle objectForInfoDictionaryKey:kAdRevenuePluginSourcesKey];
                if ([infoPListSources isKindOfClass:[NSString class]]) {
                    NSArray *infoPlistArray = [AMAJSONSerialization arrayWithJSONString:infoPListSources error:nil];
                    if ([AMAValidationUtilities validateJSONArray:infoPlistArray valueClass:[NSString class]]) {
                        result = infoPlistArray;
                    } else {
                        AMALogError(@"%@ must containts json string array", kAdRevenuePluginSourcesKey);
                    }
                } else {
                    AMALogInfo(@"%@ not found. No AdRevenue plugins will be sent", kAdRevenuePluginSourcesKey);
                }
                
                _pluginSupportedSources = result;
            }
        }
    }
    return _pluginSupportedSources;
}

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    static AMAAdRevenueSourceContainer *result;
    dispatch_once(&onceToken, ^{
        result = [[AMAAdRevenueSourceContainer alloc] initWithPluginSourceBundle:[NSBundle mainBundle]];
    });
    return result;
}

@end
