
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef struct AMAAppMetricaCrashErrorEnvironmentWriter AMAAppMetricaCrashErrorEnvironmentWriter;

/// Callback called while KSCrash is writing the crash report `user` section.
///
/// This callback can be called from a crash/signal handler. The implementation must be async-signal-safe:
/// do not call Objective-C, Swift, Foundation, dispatch, logging, allocation, locks, or C++ runtime APIs.
/// Prepare any strings in advance and keep them in static/preallocated storage.
///
/// Swift can assign a C/C++ callback to this property, but implementing the callback in Swift is not supported.
/// C++ callbacks must have C ABI, for example by using `extern "C"`.
typedef void (*AMAAppMetricaCrashErrorEnvironmentCallback)(
    const AMAAppMetricaCrashErrorEnvironmentWriter *writer
);

/// Adds a string key-value pair to the crash-time error environment.
///
/// This function is async-signal-safe when `writer`, `key`, and `value` point to valid preallocated data.
/// `key` and `value` must be NUL-terminated C strings. Invalid input is ignored.
FOUNDATION_EXPORT void AMAAppMetricaCrashErrorEnvironmentWriterAddStringValue(
    const AMAAppMetricaCrashErrorEnvironmentWriter *writer,
    const char *key,
    const char *value
) NS_SWIFT_UNAVAILABLE("Crash-time writing must be implemented in async-signal-safe C/C++ code with C ABI.");

/// `AMAAppMetricaCrashesConfiguration` provides a customizable interface for controlling how your application
/// deals with various types of crashes and issues.
///
/// This class allows you to enable or disable specific types of crash reporting and to customize the behavior
/// of the reporting mechanism.
NS_SWIFT_NAME(AppMetricaCrashesConfiguration)
@interface AMAAppMetricaCrashesConfiguration : NSObject <NSCopying>

/// Controls the automated tracking of application crashes.
///
/// If enabled, the crash reporter will automatically report application crashes.
/// During early crash monitoring initialization, this selects all supported native monitors when enabled and only
/// the monitors required by the SDK when disabled.
/// - Note: This is enabled by default.
/// - To disable: Set this property to `NO`.
@property (nonatomic, assign) BOOL autoCrashTracking;

/// Controls the reporting of probably unhandled crashes like 'Out Of Memory'.
///
/// Use this to enable or disable the tracking of crashes that are probably unhandled by the application.
/// Detection starts only after normal AppMetrica activation, including when native crash monitoring was initialized early.
/// - Note: This is disabled by default.
/// - To enable: Set this property to `YES`.
@property (nonatomic, assign) BOOL probablyUnhandledCrashReporting;

/// Specifies an array of signal values to be ignored by the crash reporter.
///
/// The array should contain `NSNumber` objects configured with signal values as defined in `<sys/signal.h>`.
/// - Note: By default, no signals are ignored.
@property (nonatomic, copy, nullable) NSArray<NSNumber *> *ignoredCrashSignals;

/// Controls the detection of Application Not Responding (ANR) states.
///
/// If enabled, it will detect if the main thread is blocked and report it accordingly.
/// The detection automatically pauses when the application enters the background.
/// Detection starts only after normal AppMetrica activation, including when native crash monitoring was initialized early.
/// - Note: This is disabled by default.
/// - To enable: Set this property to `YES`.
@property (nonatomic, assign) BOOL applicationNotRespondingDetection;

/// Sets the time interval the watchdog will wait before reporting an Application Not Responding (ANR) state.
///
/// - Note: The default value is 4 seconds.
/// - Important: Takes effect only after activation and enabling `allowsBackgroundLocationUpdates`.
@property (nonatomic, assign) NSTimeInterval applicationNotRespondingWatchdogInterval;

/// Sets the frequency with which the watchdog will check for an Application Not Responding (ANR) state.
///
/// - Note: The default value is 0.1 second.
/// - Warning: Setting this to a small value can lead to poor performance.
/// - Important: Takes effect only after activation and enabling `allowsBackgroundLocationUpdates`.
@property (nonatomic, assign) NSTimeInterval applicationNotRespondingPingInterval;

/// Callback that can add key-value pairs to `errorEnvironment` while KSCrash writes a crash report.
///
/// The callback is optional and is not set by default. If set, it must remain valid for the lifetime of the process.
/// It is applied when KSCrash is first installed and must be present in the first configuration frozen by early crash
/// monitoring initialization or normal activation.
/// Values written from the callback are merged into `errorEnvironment`; on key conflict, callback values win.
/// The same limits as `-setErrorEnvironmentValue:forKey:` apply after merging.
///
/// - Important: The callback can be called from a crash/signal handler and must be async-signal-safe.
/// Swift code may configure a C/C++ callback, but the callback implementation itself must not use Swift.
/// C++ callbacks must have C ABI, for example by using `extern "C"`.
@property (nonatomic, assign, nullable) AMAAppMetricaCrashErrorEnvironmentCallback crashErrorEnvironmentCallback;

@end

NS_ASSUME_NONNULL_END
