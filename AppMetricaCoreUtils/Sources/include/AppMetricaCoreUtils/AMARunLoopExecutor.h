#import <Foundation/Foundation.h>

#if __has_include("AMAExecuting.h")
#import "AMAExecuting.h"
#else
#import <AppMetricaCoreUtils/AMAExecuting.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@interface AMARunLoopExecutor : NSObject<AMASyncExecuting, AMAAsyncExecuting, AMAThreadProviding>

- (instancetype)initWithName:(nullable NSString *)name;
- (instancetype)initWithName:(nullable NSString *)name
              qualityOfService:(NSQualityOfService)qualityOfService;

@end

NS_ASSUME_NONNULL_END
