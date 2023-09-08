
#import <Foundation/Foundation.h>
#import "AMAMetricaConfiguration.h"
#import "AMAMetricaInMemoryConfiguration.h"
#import "AMAMetricaPersistentConfiguration.h"
#import "AMAStartupParametersConfiguration.h"

@interface AMAMetricaConfigurationTestUtilities : NSObject

+ (void)stubConfigurationWithAppVersion:(NSString *)appVersion buildNumber:(uint32_t)buildNumber;
+ (void)stubConfiguration;
+ (void)stubConfigurationWithNullMock;

@end
