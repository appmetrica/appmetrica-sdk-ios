
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(CrashSignal)
@interface AMACrashSignal : NSObject <NSCopying>

@property (nonatomic, assign, readonly) int32_t signal;
@property (nonatomic, assign, readonly) int32_t code;

- (instancetype)initWithSignal:(int32_t)signal code:(int32_t)code;

@end

NS_ASSUME_NONNULL_END
