
#import <AppMetricaCoreExtension/AppMetricaCoreExtension.h>
#import "AMAErrorRepresentable.h"

NS_ASSUME_NONNULL_BEGIN


//TODO: (glinnik) Need for facade(requestCrashReportingStateWithCompletionQueue). Public?
/** Crash reporting state callback block

 @param state Contains any combination of following identifiers on success:
 kAMACrashReportingStateEnabledKey - (NSNumber with bool) Is crash reporting enabled?
 kAMACrashReportingStateCrashedLastLaunchKey - (NSNumber with bool) Has application crashed last launch?
 */
typedef void(^AMACrashReportingStateCompletionBlock)(NSDictionary * _Nullable state);

@protocol AMAErrorRepresentable;

@interface AMACrashes : NSObject

/** Reports custom error messages.

 @param message Short name or description of the error
 @param exception Exception contains an NSException object that must be passed to the server. It can take the nil value.
 @param onFailure Block to be executed if an error occurs while reporting, the error is passed as block argument.
 */
+ (void)reportError:(NSString *)message
          exception:(nullable NSException *)exception
          onFailure:(nullable void (^)(NSError *error))onFailure
DEPRECATED_MSG_ATTRIBUTE("Use reportError:options:onFailure: or reportNSError:options:onFailure:");

/** Reports an error of the `NSError` type.
 AppMetrica uses domain and code for grouping errors.
 
 Limits for `NSError`:
 - 200 characters for `domain`;
 - 50 key-value pairs for `userInfo`. 100 characters for a key length, 2000 for a value length;
 - 10 underlying errors using `NSUnderlyingErrorKey` as a key in `userInfo`;
 - 200 stack frames in a backtrace using `AMABacktraceErrorKey` as a key in `userInfo`.
 If the value exceeds the limit, AppMetrica truncates it.
 
 @note You can also report custom backtrace in `NSError`, see the `AMABacktraceErrorKey` constant.

 @param error The error to report.
 @param onFailure Block to be executed if an error occurres while reporting, the error is passed as block argument.
 */
+ (void)reportNSError:(NSError *)error
            onFailure:(nullable void (^)(NSError *error))onFailure NS_SWIFT_NAME(report(nserror:onFailure:));

/** Reports an error of the `NSError` type.
 AppMetrica uses domain and code for grouping errors.
 Use this method to set the reporting options.
 
 Limits for `NSError`:
 - 200 characters for `domain`;
 - 50 key-value pairs for `userInfo`. 100 characters for a key length, 2000 for a value length;
 - 10 underlying errors using `NSUnderlyingErrorKey` as a key in `userInfo`;
 - 200 stack frames in a backtrace using `AMABacktraceErrorKey` as a key in `userInfo`.
 If the value exceeds the limit, AppMetrica truncates it.
 
 @note You can also report custom backtrace in `NSError`, see the `AMABacktraceErrorKey` constant.
 
 @param error The error to report.
 @param options The options of error reporting.
 @param onFailure Block to be executed if an error occurres while reporting, the error is passed as block argument.
 */
+ (void)reportNSError:(NSError *)error
              options:(AMAErrorReportingOptions)options
            onFailure:(nullable void (^)(NSError *error))onFailure NS_SWIFT_NAME(report(nserror:options:onFailure:));

/** Reports a custom error.
 @note See `AMAErrorRepresentable` for more information.

 @param error The error to report.
 @param onFailure Block to be executed if an error occurres while reporting, the error is passed as block argument.
 */
+ (void)reportError:(id<AMAErrorRepresentable>)error
          onFailure:(nullable void (^)(NSError *error))onFailure NS_SWIFT_NAME(report(error:onFailure:));

/** Reports a custom error.
 Use this method to set the reporting options.
 @note See `AMAErrorRepresentable` for more information.

 @param error The error to report.
 @param options The options of error reporting.
 @param onFailure Block to be executed if an error occurres while reporting, the error is passed as block argument.
 */
+ (void)reportError:(id<AMAErrorRepresentable>)error
            options:(AMAErrorReportingOptions)options
          onFailure:(nullable void (^)(NSError *error))onFailure NS_SWIFT_NAME(report(error:options:onFailure:));

@end

NS_ASSUME_NONNULL_END
