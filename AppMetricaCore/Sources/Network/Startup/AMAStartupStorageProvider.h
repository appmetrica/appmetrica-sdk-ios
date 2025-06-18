
#import <Foundation/Foundation.h>
#import "AMACore.h"

@class AMAMetricaConfiguration;

@interface AMAStartupStorageProvider : NSObject<AMAStartupStorageProviding>

- (instancetype)initWithConfiguration:(AMAMetricaConfiguration *)configuration;

@end
