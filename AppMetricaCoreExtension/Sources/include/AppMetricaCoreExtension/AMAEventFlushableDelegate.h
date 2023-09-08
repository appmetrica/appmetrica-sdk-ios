
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol AMAEventFlushableDelegate <NSObject>

+ (void)sendEventsBuffer;

@end

NS_ASSUME_NONNULL_END
