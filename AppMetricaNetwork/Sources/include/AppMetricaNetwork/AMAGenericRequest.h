
#import "AMARequest.h"

NS_ASSUME_NONNULL_BEGIN

@interface AMAGenericRequest : NSObject<AMARequest>

@property (nonatomic, strong, readonly) NSString *method;
@property (nonatomic, assign, readonly) NSTimeInterval timeout;
@property (nonatomic, assign, readonly) NSURLRequestCachePolicy cachePolicy;

@end

NS_ASSUME_NONNULL_END
