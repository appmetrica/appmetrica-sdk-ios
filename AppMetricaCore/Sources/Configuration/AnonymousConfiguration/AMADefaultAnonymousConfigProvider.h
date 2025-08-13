
#import <Foundation/Foundation.h>
#import "AMACore.h"

NS_ASSUME_NONNULL_BEGIN

@interface AMADefaultAnonymousConfigProvider : NSObject

- (AMAAppMetricaConfiguration *)configuration;

@property (nonatomic, class, readonly) NSString *anonymousAPIKey;

@end

NS_ASSUME_NONNULL_END
