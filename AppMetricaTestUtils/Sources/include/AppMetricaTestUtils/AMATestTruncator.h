
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(TestTruncator)
@interface AMATestTruncator : NSObject <AMAStringTruncating, AMADataTruncating, AMADictionaryTruncating>

- (void)enableTruncationWithResult:(id)truncationResult bytesTruncated:(NSUInteger)bytesTruncated;
- (void)enableTruncationWithResult:(id)truncationResult forArgument:(nullable id)argument bytesTruncated:(NSUInteger)bytesTruncated;

@end

NS_ASSUME_NONNULL_END
