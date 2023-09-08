
#import "AMAIterable.h"

NS_ASSUME_NONNULL_BEGIN

@interface AMAArrayIterator : NSObject <AMAIterable>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithArray:(NSArray *)array;

@end

NS_ASSUME_NONNULL_END
