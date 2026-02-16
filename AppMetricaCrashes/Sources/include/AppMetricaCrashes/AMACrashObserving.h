#import <Foundation/Foundation.h>

@class AMACrashEvent;

NS_ASSUME_NONNULL_BEGIN

/// Protocol for crash observation callbacks
/// Implement this protocol to receive notifications about crashes
NS_SWIFT_NAME(CrashObserving)
@protocol AMACrashObserving <NSObject>

@required

/// Called when a crash is detected and processed
/// @param crashEvent Information about the crash event
- (void)didDetectCrash:(AMACrashEvent *)crashEvent;

@optional

/// Called when an ANR (Application Not Responding) is detected
/// @param crashEvent Information about the ANR event
- (void)didDetectANR:(AMACrashEvent *)crashEvent;

/// Called when a probably unhandled crash is detected
/// @param errorMessage Description of the probable unhandled crash
- (void)didDetectProbableUnhandledCrash:(NSString *)errorMessage;

@end

NS_ASSUME_NONNULL_END
