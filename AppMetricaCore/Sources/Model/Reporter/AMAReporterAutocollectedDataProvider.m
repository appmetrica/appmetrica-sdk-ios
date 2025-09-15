
#import "AMAReporterAutocollectedDataProvider.h"
#import "AMACore.h"

static const NSTimeInterval kAMAAdditionalAPIKeyTTL = 7 * 24 * 60 * 60;

@interface AMAReporterAutocollectedDataProvider ()

@property (nonatomic, strong, readonly) AMAMetricaPersistentConfiguration *persistentConfiguration;
@property (nonatomic, strong, readonly) id<AMADateProviding> dateProvider;

@end

@implementation AMAReporterAutocollectedDataProvider

- (instancetype)initWithPersistentConfiguration:(AMAMetricaPersistentConfiguration *)persistentConfiguration
{
    return [self initWithPersistentConfiguration:persistentConfiguration dateProvider:[[AMADateProvider alloc] init]];
}

- (instancetype)initWithPersistentConfiguration:(AMAMetricaPersistentConfiguration *)persistentConfiguration
                                   dateProvider:(id<AMADateProviding>)dateProvider
{
    self = [super init];
    if (self != nil) {
        _persistentConfiguration = persistentConfiguration;
        _dateProvider = dateProvider;
    }
    return self;
}

- (void)addAutocollectedData:(NSString *)apiKey
{
    if (apiKey.length == 0) {
        return;
    }
    NSMutableDictionary<NSString *, NSNumber *> *autocollectedData =
        [self.persistentConfiguration.autocollectedData mutableCopy] ?: [NSMutableDictionary new];
    
    NSTimeInterval now = NSDate.date.timeIntervalSince1970;
    [autocollectedData setObject:@(now) forKey:apiKey];
    
    self.persistentConfiguration.autocollectedData = autocollectedData;
}

- (NSArray<NSString *> *)additionalAPIKeys
{
    NSDictionary<NSString *, NSNumber *> *autocollectedData = self.persistentConfiguration.autocollectedData;
    if (autocollectedData.count == 0) {
        return @[];
    }
    
    NSTimeInterval cutoff = self.dateProvider.currentDate.timeIntervalSince1970 - kAMAAdditionalAPIKeyTTL;
    
    NSMutableOrderedSet<NSString *> *result = [NSMutableOrderedSet orderedSet];
    [autocollectedData enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSNumber *ts, BOOL *stop) {
        if (ts.doubleValue >= cutoff && key.length > 0) {
            [result addObject:key];
        }
    }];
    return result.array ?: @[];
}

@end
