
#import <Foundation/Foundation.h>
#import "AMAReporterAutocollectedDataProviding.h"
#import "AMAMetricaPersistentConfiguration.h"

@protocol AMADateProviding;

@interface AMAReporterAutocollectedDataProvider : NSObject<AMAReporterAutocollectedDataProviding>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithPersistentConfiguration:(AMAMetricaPersistentConfiguration *)persistentConfiguration;
- (instancetype)initWithPersistentConfiguration:(AMAMetricaPersistentConfiguration *)persistentConfiguration
                                   dateProvider:(id<AMADateProviding>)dateProvider;

- (void)addAutocollectedData:(NSString *)apiKey;

@end
