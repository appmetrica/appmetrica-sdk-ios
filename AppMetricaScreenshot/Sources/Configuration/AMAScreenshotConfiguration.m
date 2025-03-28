#import "AMAScreenshotConfiguration.h"
#import <AppMetricaStorageUtils/AppMetricaStorageUtils.h>
#import "AMAScreenshotStartupResponse.h"

static NSString *AMAScreenshotEnabledKey = @"screenshot.enabled";
static NSString *AMAScreenshotApiCaptorEnabledKey = @"api_captor_config.enabled";

@implementation AMAScreenshotConfiguration

- (instancetype)initWithStorage:(id<AMAKeyValueStoring>)storage
{
    self = [super init];
    if (self) {
        _storage = storage;
    }
    return self;
}

+ (NSArray<NSString *> *)allKeys
{
    return @[
        AMAScreenshotEnabledKey,
        AMAScreenshotApiCaptorEnabledKey,
    ];
}

#define PROPERTY_FOR_TYPE(returnType, getter, setter, key, storageGetter, storageSetter, setOnce) \
- (returnType *)getter { \
    return [self.storage storageGetter:key error:NULL]; \
} \
- (void)setter:(returnType *)value { \
    if (setOnce && self.getter != nil) return; \
    [self.storage storageSetter:value forKey:key error:NULL]; \
}

#define BOOL_PROPERTY(getter, setter, key) \
- (BOOL)getter { \
    return [[self.storage boolNumberForKey:key error:NULL] boolValue]; \
} \
- (void)setter:(BOOL)value { \
    [self.storage saveBoolNumber:@(value) forKey:key error:nil]; \
}

BOOL_PROPERTY(screenshotEnabled, setScreenshotEnabled, AMAScreenshotEnabledKey);
BOOL_PROPERTY(captorEnabled, setCaptorEnabled, AMAScreenshotApiCaptorEnabledKey);

- (void)updateStartupConfiguration:(AMAScreenshotStartupResponse*)response
{
    self.screenshotEnabled = response.featureEnabled;
    self.captorEnabled = response.captorEnabled;
}

#if AMA_ALLOW_DESCRIPTIONS

- (NSString *)description
{
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", super.description];
    [description appendFormat:@", self.screenshot.enabled=%@", @(self.screenshotEnabled)];
    [description appendFormat:@", self.captor.enabled=%@", @(self.captorEnabled)];
    [description appendString:@">"];
    return description;
}
#endif

@end
