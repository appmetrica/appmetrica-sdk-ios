
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol AMAAllocationsTracking;

@interface AMAAllocationsTrackerProvider : NSObject

+ (void)track:(void (^)(id<AMAAllocationsTracking> tracker))block;
+ (id<AMAAllocationsTracking>)manuallyHandledTracker;

@end

NS_ASSUME_NONNULL_END
