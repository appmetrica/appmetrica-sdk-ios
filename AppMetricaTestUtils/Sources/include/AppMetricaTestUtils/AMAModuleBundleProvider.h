
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AMAModuleBundleProvider : NSObject

+ (NSBundle *)moduleBundle;
+ (NSBundle *)moduleBundleForResource:(NSString *)resource;

@end

NS_ASSUME_NONNULL_END
