
#import <Foundation/Foundation.h>
#import <AppMetricaPlatform/AppMetricaPlatform.h>

@class AMAApplicationState;
@class AMACrashInfo;
@class AMACrashEventError;
@class AMACrashThreadInfo;

NS_ASSUME_NONNULL_BEGIN

/** The class to store crash event data.

 @note This interface has the mutable version `AMAMutableCrashEvent`.
 */
NS_SWIFT_NAME(CrashEvent)
@interface AMACrashEvent : NSObject <NSCopying, NSMutableCopying>

@property (nonatomic, copy, readonly, nullable) AMAApplicationState *appState;

@property (nonatomic, copy, readonly, nullable) NSDictionary<NSString *, NSString *> *errorEnvironment;
@property (nonatomic, copy, readonly, nullable) NSDictionary<NSString *, NSString *> *appEnvironment;

@property (nonatomic, copy, readonly, nullable) AMACrashInfo *info;
@property (nonatomic, copy, readonly, nullable) AMACrashEventError *error;

@property (nonatomic, readonly, nullable) AMACrashThreadInfo *crashedThread;
@property (nonatomic, copy, readonly, nullable) NSArray<AMACrashThreadInfo *> *threads;

@end

/** Mutable version of the `AMACrashEvent` class. */
NS_SWIFT_NAME(MutableCrashEvent)
@interface AMAMutableCrashEvent : AMACrashEvent

@property (nonatomic, copy, nullable) AMAApplicationState *appState;

@property (nonatomic, copy, nullable) NSDictionary<NSString *, NSString *> *errorEnvironment;
@property (nonatomic, copy, nullable) NSDictionary<NSString *, NSString *> *appEnvironment;

@property (nonatomic, copy, nullable) AMACrashInfo *info;
@property (nonatomic, copy, nullable) AMACrashEventError *error;

@property (nonatomic, copy, nullable) NSArray<AMACrashThreadInfo *> *threads;

@end

NS_ASSUME_NONNULL_END
