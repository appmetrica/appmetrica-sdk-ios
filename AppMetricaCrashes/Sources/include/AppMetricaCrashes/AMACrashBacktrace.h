
#import <Foundation/Foundation.h>

@class AMACrashBacktraceFrame;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(CrashBacktrace)
@interface AMACrashBacktrace : NSObject <NSCopying>

@property (nonatomic, copy, readonly, nullable) NSArray<AMACrashBacktraceFrame *> *frames;

- (instancetype)initWithFrames:(nullable NSArray<AMACrashBacktraceFrame *> *)frames;

@end

NS_ASSUME_NONNULL_END
