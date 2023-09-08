
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>

NS_ASSUME_NONNULL_BEGIN

@interface AMATruncatorsFactory : NSObject

+ (id<AMAStringTruncating>)eventNameTruncator;
+ (id<AMAStringTruncating>)eventStringValueTruncator;
+ (id<AMADataTruncating>)eventBinaryValueTruncator;
+ (id<AMADataTruncating>)fullValueTruncator;
+ (id<AMAStringTruncating>)userInfoTruncator;
+ (id<AMAStringTruncating>)profileIDTruncator;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
