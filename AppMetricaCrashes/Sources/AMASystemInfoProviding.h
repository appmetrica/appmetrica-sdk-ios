
#import <Foundation/Foundation.h>

@class AMASystemInfo;

NS_ASSUME_NONNULL_BEGIN

@protocol AMASystemInfoProviding <NSObject>

- (nullable AMASystemInfo *)currentSystemInfo;

@end

NS_ASSUME_NONNULL_END
