
#import "AMATruncating.h"

NS_ASSUME_NONNULL_BEGIN

@interface AMABytesStringTruncator : NSObject <AMAStringTruncating>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithMaxBytesLength:(NSUInteger)maxBytesLength;

@end

NS_ASSUME_NONNULL_END
