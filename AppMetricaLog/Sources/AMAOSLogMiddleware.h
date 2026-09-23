
#import "AMALogMiddleware.h"

@interface AMAOSLogMiddleware : NSObject <AMALogMiddleware>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithCategory:(const char *)category;

@end
