#import <Foundation/Foundation.h>
#import "AMAStartupCompletionObserving.h"

@class AMAMetricaConfiguration;

extern NSString *const kAMARequestIdentifiersOptionCallbackModeKey;
extern NSString *const kAMARequestIdentifiersOptionCallbackOnSuccess;
extern NSString *const kAMARequestIdentifiersOptionCallbackInAnyCase;

@interface AMAStartupItemsChangedNotifier : NSObject <AMAStartupCompletionObserving>

- (instancetype)init;
- (instancetype)initWithMetricaConfiguration:(AMAMetricaConfiguration *)metricaConfiguration NS_DESIGNATED_INITIALIZER;

+ (NSArray<NSString *> *)allIdentifiersKeys;

- (void)requestStartupItemsWithKeys:(NSArray<NSString *> *)keys
                            options:(NSDictionary *)options
                              queue:(dispatch_queue_t)queue
                         completion:(AMAIdentifiersCompletionBlock)block;

@end
