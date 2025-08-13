#import <Foundation/Foundation.h>

@class AMAAppMetricaConfiguration;

NS_ASSUME_NONNULL_BEGIN

@interface AMAActivationTypeResolver : NSObject

+ (BOOL)isAnonymousConfiguration:(AMAAppMetricaConfiguration *)configuration;

@end

NS_ASSUME_NONNULL_END
