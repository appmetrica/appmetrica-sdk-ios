
#import "AMAAppLovinStartupConfiguration.h"
#import "AMAAppLovinStorageKeys.h"
#import <AppMetricaStorageUtils/AppMetricaStorageUtils.h>

@interface AMAAppLovinStartupConfiguration ()
@property (nonatomic, strong) id<AMAKeyValueStoring> storage;
@end

@implementation AMAAppLovinStartupConfiguration

- (instancetype)initWithStorage:(id<AMAKeyValueStoring>)storage
{
    self = [super init];
    if (self != nil) {
        _storage = storage;
    }
    return self;
}

+ (NSArray<NSString *> *)allKeys
{
    return @[ AMAAppLovinStorageKeyAramEnabled ];
}

- (BOOL)aramEnabled
{
    NSNumber *value = [self.storage boolNumberForKey:AMAAppLovinStorageKeyAramEnabled error:NULL];
    return value != nil ? value.boolValue : YES;
}

- (void)setAramEnabled:(BOOL)aramEnabled
{
    [self.storage saveBoolNumber:@(aramEnabled) forKey:AMAAppLovinStorageKeyAramEnabled error:NULL];
}

@end
