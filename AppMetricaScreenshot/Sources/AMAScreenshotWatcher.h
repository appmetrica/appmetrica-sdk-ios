#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol AMAScreenshotReporting;

@interface AMAScreenshotWatcher : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithReporter:(id<AMAScreenshotReporting>)reporter;
- (instancetype)initWithReporter:(id<AMAScreenshotReporting>)reporter
              notificationCenter:(NSNotificationCenter *)notificationCenter;

@property BOOL isStarted;

@end

NS_ASSUME_NONNULL_END
