
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(BundleInfoProvider)
@protocol AMABundleInfoProvider

@property (readonly) NSString *appID;
@property (readonly) NSString *appBuildNumber;
@property (readonly) NSString *appVersion;
@property (readonly) NSString *appVersionName;

@end

NS_ASSUME_NONNULL_END
