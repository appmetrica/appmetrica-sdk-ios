
#import <Foundation/Foundation.h>

@class AMADefaultAnonymousConfigProvider;
@class AMAMetricaPersistentConfiguration;
@class AMAAppMetricaConfiguration;
@class AMAFirstActivationDetector;

@interface AMAConfigForAnonymousActivationProvider : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithStorage:(AMAMetricaPersistentConfiguration *)persistent;
- (instancetype)initWithStorage:(AMAMetricaPersistentConfiguration *)persistent
                defaultProvider:(AMADefaultAnonymousConfigProvider *)defaultProvider
        firstActivationDetector:(AMAFirstActivationDetector *)firstActivationDetector;

- (AMAAppMetricaConfiguration *)configuration;

@end
