
#import <Foundation/Foundation.h>
#import "AMASystemInfoProviding.h"

@class AMAKSCrashReportDecoder;

NS_ASSUME_NONNULL_BEGIN

@interface AMAKSCrashSystemInfoProvider : NSObject <AMASystemInfoProviding>

- (instancetype)init;
- (instancetype)initWithDecoder:(AMAKSCrashReportDecoder *)decoder NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
