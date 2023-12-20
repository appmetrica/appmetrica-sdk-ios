
#import <Foundation/Foundation.h>

#if __has_include("AMACompletionBlocks.h")
    #import "AMACompletionBlocks.h"
#else
    #import <AppMetricaCore/AMACompletionBlocks.h>
#endif

@class CLLocation;
@class AMAAppMetricaConfiguration;
@class AMAReporterConfiguration;
@class AMAUserProfile;
@class AMARevenueInfo;
@class AMAECommerce;
@class AMAAdRevenueInfo;
@protocol AMAAppMetricaReporting;
@protocol AMAAppMetricaPlugins;

#if !TARGET_OS_TV
@protocol AMAJSControlling;
#endif

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(AppMetrica)
@interface AMAAppMetrica : NSObject

/** Retrieves current UUID.

 Synchronous interface.
 */
@property (class, nonatomic, readonly) NSString *uuid;

/** Starts the statistics collection process.

 @param configuration Configuration combines all AppMetrica settings in one place.
 Configuration initialized with unique application key that is issued during application registration in AppMetrica.
 Application key must be a hexadecimal string in format xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx.
 The key can be requested or checked at https://appmetrica.io
 */
+ (void)activateWithConfiguration:(AMAAppMetricaConfiguration *)configuration;

/** Retrieves current device ID hash.

 Synchronous interface. If it is not available at the moment of call nil is returned.
 */
@property (class, nonatomic, nullable, readonly) NSString *deviceIDHash;

/** Retrieves current device ID.

 @return Device ID string. If it is not available at the moment of call nil is returned.
 */
+ (nullable NSString *)deviceID;

/** Enabling/disabling accurate location retrieval for internal location manager.

 @param accurateLocationEnabled Indicates whether accurate location retrieval should be enabled.
 Has effect only when locationTrackingEnabled is 'YES', and location is not set manually.
 */
+ (void)setAccurateLocationTracking:(BOOL)accurateLocationEnabled;

/** Enable/disable background location updates tracking.

 Disabled by default.
 @param allowsBackgroundLocationUpdates Indicates whether background location updating should be enabled.
 @see https://developer.apple.com/reference/corelocation/cllocationmanager/1620568-allowsbackgroundlocationupdates
 */
+ (void)setAllowsBackgroundLocationUpdates:(BOOL)allowsBackgroundLocationUpdates;

/** Reports a custom event.

 @param message Short name or description of the event.
 @param onFailure Block to be executed if an error occurs while reporting, the error is passed as block argument.
 */
+ (void)reportEvent:(NSString *)message
          onFailure:(nullable void (^)(NSError *error))onFailure
NS_SWIFT_NAME(reportEvent(name:onFailure:));

/** Reports a custom event with additional parameters.

 @param message Short name or description of the event.
 @param params Dictionary of name/value pairs that should be sent to the server.
 @param onFailure Block to be executed if an error occurs while reporting, the error is passed as block argument.
 */
+ (void)reportEvent:(NSString *)message
         parameters:(nullable NSDictionary *)params
          onFailure:(nullable void (^)(NSError *error))onFailure
NS_SWIFT_NAME(reportEvent(name:parameters:onFailure:));

/** Sends information about the user profile.

 @param userProfile The `AMAUserProfile` object. Contains user profile information.
 @param onFailure Block to be executed if an error occurs while reporting, the error is passed as block argument.
 */
+ (void)reportUserProfile:(AMAUserProfile *)userProfile
                onFailure:(nullable void (^)(NSError *error))onFailure NS_SWIFT_NAME(report(userProfile:onFailure:));

/** Sends information about the purchase.

 @param revenueInfo The `AMARevenueInfo` object. Contains purchase information
 @param onFailure Block to be executed if an error occurs while reporting, the error is passed as block argument.
 */
+ (void)reportRevenue:(AMARevenueInfo *)revenueInfo
            onFailure:(nullable void (^)(NSError *error))onFailure NS_SWIFT_NAME(report(revenue:onFailure:));

/** Sets the ID of the user profile.

 @warning The value can contain up to 200 characters
 @param userProfileID The custom user profile ID
 */
+ (void)setUserProfileID:(nullable NSString *)userProfileID;

/** Enables/disables data sending to the AppMetrica server.

 @note Disabling this option also turns off data sending from the reporters that initialized for different apiKey.

 @param enabled Flag indicating whether the data sending is enabled. By default, the sending is enabled.
 */
+ (void)setDataSendingEnabled:(BOOL)enabled;

/** Enables/disables location reporting to AppMetrica.
 If enabled and location set via setLocation: method - that location would be used.
 If enabled and location is not set via setLocation,
 but application has appropriate permission - CLLocationManager would be used to acquire location data.

 @param enabled Flag indicating if reporting location to AppMetrica enabled
 Enabled by default.
 */
+ (void)setLocationTracking:(BOOL)enabled;

/** Sets location to AppMetrica.
 To enable AppMetrica to use this location trackLocationEnabled should be 'YES'

 @param location Custom device location to be reported.
 */
+ (void)setLocation:(nullable CLLocation *)location;

/** Retrieves current version of library.
 */
+ (NSString *)libraryVersion;

/** Getting all predefined identifiers

 @param queue Queue for the block to be dispatched to. If nil, main queue is used.
 @param block Block will be dispatched upon identifiers becoming available or in a case of error.
 Predefined identifiers are:
    kAMAUUIDKey
    kAMADeviceIDKey
    kAMADeviceIDHashKey
 If they are available at the moment of call - block is dispatched immediately. See definition
 of AMAIdentifiersCompletionBlock for more detailed information on returned types.
 */
+ (void)requestStartupIdentifiersWithCompletionQueue:(nullable dispatch_queue_t)queue
                                     completionBlock:(AMAIdentifiersCompletionBlock)block
NS_SWIFT_NAME(requestStartupIdentifiers(completionQueue:completionBlock:));

/** Getting identifiers for specific keys

 @param keys Array of identifier keys to request. See AMACompletionBlocks.h.
 @param queue Queue for the block to be dispatched to. If nil, main queue is used.
 @param block Block will be dispatched upon identifiers becoming available or in a case of error.
 If they are available at the moment of call - block is dispatched immediately. Some keys may require
 a network request to startup. See definition of AMAIdentifiersCompletionBlock for more detailed
 information on returned types.
 */
+ (void)requestStartupIdentifiersWithKeys:(NSArray<NSString *> *)keys
                          completionQueue:(nullable dispatch_queue_t)queue
                          completionBlock:(AMAIdentifiersCompletionBlock)block
NS_SWIFT_NAME(requestStartupIdentifiers(keys:completionQueue:completionBlock:));

/** Handles the URL that has opened the application.
 Reports the URL for deep links tracking.

 @param url URL that has opened the application.
 */
+ (void)handleOpenURL:(NSURL *)url;

/** Activates reporter with specific configuration.

 @param configuration Configuration combines all reporter settings in one place.
 Configuration initialized with unique application key that is issued during application registration in AppMetrica.
 Application key must be a hexadecimal string in format xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx.
 The key can be requested or checked at https://appmetrica.io
 */
+ (void)activateReporterWithConfiguration:(AMAReporterConfiguration *)configuration;

/** Returns id<AMAAppMetricaReporting> that can send events to specific API key.
 To customize configuration of reporter activate with 'activateReporterWithConfiguration:' method first.

 @param apiKey Api key to send events to.
 @return id<AMAAppMetricaReporting> that conforms to AMAAppMetricaReporting and handles
 sending events to specified apikey
 */
+ (nullable id<AMAAppMetricaReporting>)reporterForApiKey:(NSString *)apiKey NS_SWIFT_NAME(reporter(for:));

/**
 * Sets referral URL for this installation. This might be required to track some specific traffic sources like Facebook.
 * @param url referral URL value.
 */
+ (void)reportReferralUrl:(NSURL *)url NS_SWIFT_NAME(report(referralUrl:));

/** Sends all stored events from the buffer.

 AppMetrica SDK doesn't send events immediately after they occurred. It stores events data in the buffer.
 This method sends all the data from the buffer and flushes it.
 Use the method to force stored events sending after important checkpoints of user scenarios.

 @warning Frequent use of the method can lead to increasing outgoing internet traffic and energy consumption.
 */
+ (void)sendEventsBuffer;

/** Resumes the last session or creates a new one if it has been expired.

 @warning You should disable the automatic tracking before using this method.
 See the sessionsAutoTracking property of AMAAppMetricaConfiguration.
 */
+ (void)resumeSession;

/** Pauses the current session.
 All events reported after calling this method and till the session timeout will still join this session.

 @warning You should disable the automatic tracking before using this method.
 See the sessionsAutoTracking property of AMAAppMetricaConfiguration.
 */
+ (void)pauseSession;

/** Sends information about the E-commerce event.

 @note See `AMAEcommerce` for all possible E-commerce events.

 @param eCommerce The object of `AMAECommerce` class.
 @param onFailure Block to be executed if an error occurs while reporting, the error is passed as block argument.
 */
+ (void)reportECommerce:(AMAECommerce *)eCommerce
              onFailure:(nullable void (^)(NSError *error))onFailure NS_SWIFT_NAME(report(eCommerce:onFailure:));

#if !TARGET_OS_TV
/**
 * Adds interface named "AppMetrica" to WKWebView's JavaScript.
 * It enabled you to report events to AppMetrica from JavaScript code.
 * For use you need an explicit import of AMAWebKit:
 * ```
 * #import <AppMetricaWebKit/AppMetricaWebKit.h>
 * ```
 * @note
 * This method must be called before adding any WKUserScript that uses AppMetrica interface or creating WKWebView.
 * Example:
 * ```
 * WKWebViewConfiguration *webConfiguration = [WKWebViewConfiguration new];
 * WKUserContentController *userContentController = [WKUserContentController new];
 * AMAJSController *jsController = [[AMAJSController alloc] initWithUserContentController:userContentController];
 * [AMAAppMetrica setupWebViewReporting:jsController
                                 onFailure:nil];
 * [userContentController addUserScript:self.scriptWithAppMetrica];
 * webConfiguration.userContentController = userContentController;
 * self.webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:webConfiguration];
 * ```
 * After web view reporting is initialized you can report event to AppMetrica from your JavaScript code the following way:
 * ```
 * function reportToAppMetrica(eventName, eventValue) {
 *     AppMetrica.reportEvent(eventName, eventValue);
 * }
 * ```
 * Here eventName is any non-empty String, eventValue is a JSON String, may be null or empty.
 *
 * @param controller AMAJSController object from AMAWebKit
 * @param onFailure Block to be executed if an error occurs while initializing web view reporting,
 *                  the error is passed as block argument.
 */
+ (void)setupWebViewReporting:(id<AMAJSControlling>)controller
                    onFailure:(nullable void (^)(NSError *error))onFailure;
#endif

/**
 * Sends information about ad revenue.
 * @note See `AMAAdRevenueInfo` for more info.
 *
 * @param adRevenue Object containing the information about ad revenue.
 * @param onFailure Block to be executed if an error occurs while sending ad revenue,
 *                  the error is passed as block argument.
 */
+ (void)reportAdRevenue:(AMAAdRevenueInfo *)adRevenue
              onFailure:(nullable void (^)(NSError *error))onFailure NS_SWIFT_NAME(report(adRevenue:onFailure:));

/** Setting key - value data to be used as additional information, associated with all future events.
 If value is nil, previously set key-value is removed. Does nothing if key hasn't been added.

 @param value The app environment value.
 @param key The app environment key.
 */
+ (void)setAppEnvironmentValue:(nullable NSString *)value
                        forKey:(NSString *)key NS_SWIFT_NAME(setAppEnvironment(value:for:));

/** Clearing app environment, e.g. removes all key - value data associated with all future events.
 */
+ (void)clearAppEnvironment;

@end

NS_ASSUME_NONNULL_END
