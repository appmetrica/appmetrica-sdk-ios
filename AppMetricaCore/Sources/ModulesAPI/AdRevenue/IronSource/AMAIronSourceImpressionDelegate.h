
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Handles impressionDataDidSucceed: for both ISImpressionData (v8) and LPMImpressionData (v9+).
@interface AMAIronSourceImpressionDelegate : NSObject

- (instancetype)initWithMajorVersion:(NSInteger)majorVersion NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (void)impressionDataDidSucceed:(id)impressionData;

/// Flush queued impressions after AppMetrica activates.
- (void)processQueuedImpressionData;

@end

NS_ASSUME_NONNULL_END
