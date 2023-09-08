
#import <AppMetricaStorageUtils/AppMetricaStorageUtils.h>

NS_ASSUME_NONNULL_BEGIN

@interface AMAUserDefaultsKVSDataProvider : NSObject <AMAKeyValueStorageDataProviding>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithUserDefaults:(NSUserDefaults *)userDefaults;

@end

NS_ASSUME_NONNULL_END
