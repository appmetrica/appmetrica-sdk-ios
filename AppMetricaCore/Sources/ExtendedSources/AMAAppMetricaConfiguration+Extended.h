
#import <Foundation/Foundation.h>

#if __has_include("AppMetricaCore.h")
    #import "AMAAppMetricaConfiguration.h"
#else
    #import <AppMetricaCore/AMAAppMetricaConfiguration.h>
#endif

@interface AMAAppMetricaConfiguration ()

/** Enable/disable probably unhandled crashes (like Out Of Memory) tracking.

 Disabled by default.
 To enable probably unhandled crash tracking, set the property value to YES.
 */
@property (nonatomic, assign) BOOL probablyUnhandledCrashReporting;

/** Crash reports will not be sent if crash is caused by signal from ignoredCrashSignals array.
 Array should contain NSNumber objects configured with signal values defined in <sys/signal.h>.
 */
@property (nonatomic, copy, nullable) NSArray<NSNumber *> *ignoredCrashSignals;

/** Crashes will be reported as errors if crash is caused by signal from errorSignals array.
 Array should contain NSNumber objects configured with signal values defined in <sys/signal.h>.
 This parameter is not processed since 3.7.0
 */
@property (nonatomic, copy, nullable) NSArray<NSNumber *> *errorSignals DEPRECATED_ATTRIBUTE;

/** Enable/disable ANR detection.
 Detects blocked the main thread and reports it. Tries to submit block on the main queue and waits for the response.
 ANR detection automatically paused as the application enters background mode and vice versa.
 
 @note Disabled by default.
 To enable ANR detection, set the property value to YES.
 */
@property (nonatomic, assign) BOOL applicationNotRespondingDetection;

/** Sets/gets time interval the watchdog queue would wait for the main queue response before report ANR.
 
 @note The default value is 4 seconds.
 Takes effect only after the activation and enabling `allowsBackgroundLocationUpdates` flag.
 */
@property (nonatomic, assign) NSTimeInterval applicationNotRespondingWatchdogInterval;

/** Sets/gets time interval the watchdog queue would ping the main queue.
 
 @note The default value is 0.1 second.
 Takes effect only after activation and enabling allowsBackgroundLocationUpdates flag.
 @warning A small value can lead to poor performance.
 */
@property (nonatomic, assign) NSTimeInterval applicationNotRespondingPingInterval;

@end
