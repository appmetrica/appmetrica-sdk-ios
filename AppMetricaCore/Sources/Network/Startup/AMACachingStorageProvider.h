
#import <Foundation/Foundation.h>
#import "AMACore.h"

@class AMAMetricaConfiguration;

@interface AMACachingStorageProvider : NSObject<AMACachingStorageProviding>

- (instancetype)initWithConfiguration:(AMAMetricaConfiguration *)configuration;

@end
