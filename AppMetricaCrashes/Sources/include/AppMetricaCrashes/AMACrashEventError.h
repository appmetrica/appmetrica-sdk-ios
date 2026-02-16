
#import <Foundation/Foundation.h>
#import <AppMetricaCrashes/AMACrashType.h>

@class AMACrashSignal;
@class AMACrashMach;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(CrashEventError)
@interface AMACrashEventError : NSObject <NSCopying, NSMutableCopying>

@property (nonatomic, assign, readonly) AMACrashType type;
@property (nonatomic, strong, readonly, nullable) AMACrashSignal *signal;
@property (nonatomic, strong, readonly, nullable) AMACrashMach *mach;
@property (nonatomic, copy, readonly, nullable) NSString *exceptionName;
@property (nonatomic, copy, readonly, nullable) NSString *exceptionReason;
@property (nonatomic, copy, readonly, nullable) NSString *cppExceptionName;

- (instancetype)initWithType:(AMACrashType)type;

@end

/** Mutable version of the `AMACrashEventError` class. */
NS_SWIFT_NAME(MutableCrashEventError)
@interface AMAMutableCrashEventError : AMACrashEventError

@property (nonatomic, strong, nullable) AMACrashSignal *signal;
@property (nonatomic, strong, nullable) AMACrashMach *mach;
@property (nonatomic, copy, nullable) NSString *exceptionName;
@property (nonatomic, copy, nullable) NSString *exceptionReason;
@property (nonatomic, copy, nullable) NSString *cppExceptionName;

@end

NS_ASSUME_NONNULL_END
