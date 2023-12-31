
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(ModuleBundleProvider)
@interface AMAModuleBundleProvider : NSObject

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)new NS_UNAVAILABLE;

+ (NSBundle *)moduleBundle;

@end

NS_ASSUME_NONNULL_END
