
#import <Foundation/Foundation.h>

@class AMAAppLovinStartupConfiguration;

NS_ASSUME_NONNULL_BEGIN

@interface AMAAppLovinStartupResponseParser : NSObject

- (void)parseResponse:(NSDictionary *)parameters
    intoConfiguration:(AMAAppLovinStartupConfiguration *)configuration;

@end

NS_ASSUME_NONNULL_END
