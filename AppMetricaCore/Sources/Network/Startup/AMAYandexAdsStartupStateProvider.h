#import <Foundation/Foundation.h>
#import "AMAStartupStateProviding.h"

@class AMASavedAppMetricaConfigRepository;
@class AMAYandexAdsSDKDetector;
@class AMAMetricaPersistentConfiguration;

NS_ASSUME_NONNULL_BEGIN

@interface AMAYandexAdsStartupStateProvider : NSObject <AMAStartupStateProviding>

@property (nonatomic, assign, readonly) BOOL isYandexAdsOnly;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)initWithRepository:(AMASavedAppMetricaConfigRepository *)repository
                          detector:(AMAYandexAdsSDKDetector *)detector
           persistentConfiguration:(AMAMetricaPersistentConfiguration *)persistentConfiguration;

@end

NS_ASSUME_NONNULL_END
