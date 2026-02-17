
#import <Foundation/Foundation.h>

@class AMACrashBacktrace;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(CrashThreadInfo)
@interface AMACrashThreadInfo : NSObject <NSCopying, NSMutableCopying>

@property (nonatomic, strong, readonly, nullable) AMACrashBacktrace *backtrace;
@property (nonatomic, assign, readonly) uint32_t index;
@property (nonatomic, assign, readonly) BOOL crashed;
@property (nonatomic, copy, readonly, nullable) NSString *threadName;
@property (nonatomic, copy, readonly, nullable) NSString *queueName;

- (instancetype)initWithBacktrace:(nullable AMACrashBacktrace *)backtrace
                          crashed:(BOOL)crashed;

@end

/** Mutable version of the `AMACrashThreadInfo` class. */
NS_SWIFT_NAME(MutableCrashThreadInfo)
@interface AMAMutableCrashThreadInfo : AMACrashThreadInfo

@property (nonatomic, assign) uint32_t index;
@property (nonatomic, assign) BOOL crashed;
@property (nonatomic, copy, nullable) NSString *threadName;
@property (nonatomic, copy, nullable) NSString *queueName;

@end

NS_ASSUME_NONNULL_END
