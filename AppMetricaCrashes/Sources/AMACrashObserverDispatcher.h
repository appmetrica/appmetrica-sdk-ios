#import <Foundation/Foundation.h>

@class AMACrashObserverConfiguration;
@class AMACrashEvent;
@class AMADecodedCrash;

NS_ASSUME_NONNULL_BEGIN

/// Internal manager for crash observer configurations
/// Handles observer configurations and callback dispatching
@interface AMACrashObserverDispatcher : NSObject

- (instancetype)init NS_DESIGNATED_INITIALIZER;

/// Register an observer configuration
/// @param configuration The observer configuration to register
- (void)registerObserverConfiguration:(AMACrashObserverConfiguration *)configuration;

/// Unregister observer configuration
/// @param configuration The observer configuration to unregister
- (void)unregisterObserverConfiguration:(AMACrashObserverConfiguration *)configuration;

/// Get all registered configurations
/// @return Array of registered configurations
- (NSArray<AMACrashObserverConfiguration *> *)registeredConfigurations;

/// Notify all observers about a crash
/// @param decodedCrash The decoded crash information
- (void)notifyCrash:(AMADecodedCrash *)decodedCrash;

/// Notify all observers about an ANR event
/// @param decodedCrash The decoded crash information
- (void)notifyANR:(AMADecodedCrash *)decodedCrash;

/// Notify all observers about a probable unhandled crash
/// @param errorMessage The error message describing the crash
- (void)notifyProbableUnhandledCrash:(NSString *)errorMessage;

@end

NS_ASSUME_NONNULL_END
