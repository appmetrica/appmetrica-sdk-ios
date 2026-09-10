
#import <Foundation/Foundation.h>

@class AMADefaultAnonymousConfigProvider;
@class AMAMetricaPersistentConfiguration;
@class AMAAppMetricaConfiguration;
@class AMAFirstActivationDetector;
@class AMAAppMetricaLibraryAdapterConfiguration;
@class AMASavedAppMetricaConfigRepository;

NS_ASSUME_NONNULL_BEGIN

@interface AMAConfigForAnonymousActivationProvider : NSObject

@property (nonatomic, strong, readonly) AMASavedAppMetricaConfigRepository *repository;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithStorage:(AMAMetricaPersistentConfiguration *)persistent;
- (instancetype)initWithStorage:(AMAMetricaPersistentConfiguration *)persistent
                defaultProvider:(AMADefaultAnonymousConfigProvider *)defaultProvider
        firstActivationDetector:(AMAFirstActivationDetector *)firstActivationDetector;
- (instancetype)initWithStorage:(AMAMetricaPersistentConfiguration *)persistent
                defaultProvider:(AMADefaultAnonymousConfigProvider *)defaultProvider
        firstActivationDetector:(AMAFirstActivationDetector *)firstActivationDetector
                     repository:(AMASavedAppMetricaConfigRepository *)repository;

- (AMAAppMetricaConfiguration *)configuration;

@end

NS_ASSUME_NONNULL_END
