
#import <Foundation/Foundation.h>
#import "AMACore.h"

NS_ASSUME_NONNULL_BEGIN

@interface AMAIronSourceManager : NSObject <AMAModuleActivationDelegate>

+ (instancetype)sharedInstance;

- (void)setupWithMajorVersion:(NSInteger)majorVersion;

@end

NS_ASSUME_NONNULL_END
