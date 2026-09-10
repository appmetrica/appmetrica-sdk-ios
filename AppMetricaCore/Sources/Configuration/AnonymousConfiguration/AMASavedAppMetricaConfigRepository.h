#import <Foundation/Foundation.h>

@class AMAAppMetricaConfiguration;
@class AMAMetricaPersistentConfiguration;
@protocol AMADateProviding;

NS_ASSUME_NONNULL_BEGIN

@interface AMASavedAppMetricaConfigRepository : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithPersistentConfiguration:(AMAMetricaPersistentConfiguration *)persistent;
- (instancetype)initWithPersistentConfiguration:(AMAMetricaPersistentConfiguration *)persistent
                                   dateProvider:(id<AMADateProviding>)dateProvider NS_DESIGNATED_INITIALIZER;

- (nullable AMAAppMetricaConfiguration *)validSavedConfig;
- (void)saveConfiguration:(AMAAppMetricaConfiguration *)configuration
               refreshTTL:(BOOL)refreshTTL;

@end

NS_ASSUME_NONNULL_END
