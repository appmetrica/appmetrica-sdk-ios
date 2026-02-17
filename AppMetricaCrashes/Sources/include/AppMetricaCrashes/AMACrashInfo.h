
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(CrashInfo)
@interface AMACrashInfo : NSObject <NSCopying, NSMutableCopying>

/** Version of the KSCrash report format. */
@property (nonatomic, copy, readonly, nullable) NSString *crashReportVersion;
@property (nonatomic, copy, readonly, nullable) NSString *identifier;
@property (nonatomic, strong, readonly, nullable) NSDate *timestamp;

- (instancetype)initWithCrashReportVersion:(nullable NSString *)crashReportVersion;

@end

/** Mutable version of the `AMACrashInfo` class. */
NS_SWIFT_NAME(MutableCrashInfo)
@interface AMAMutableCrashInfo : AMACrashInfo

@property (nonatomic, copy, nullable) NSString *identifier;
@property (nonatomic, strong, nullable) NSDate *timestamp;

@end

NS_ASSUME_NONNULL_END
