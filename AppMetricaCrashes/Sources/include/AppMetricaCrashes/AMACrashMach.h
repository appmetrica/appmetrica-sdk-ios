
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(CrashMach)
@interface AMACrashMach : NSObject <NSCopying>

@property (nonatomic, assign, readonly) int32_t exceptionType;
@property (nonatomic, assign, readonly) int64_t code;
@property (nonatomic, assign, readonly) int64_t subcode;

- (instancetype)initWithExceptionType:(int32_t)exceptionType code:(int64_t)code subcode:(int64_t)subcode;

@end

NS_ASSUME_NONNULL_END
