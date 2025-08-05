
#import <Foundation/Foundation.h>
#import <AppMetricaCore/AppMetricaCore.h>

NS_ASSUME_NONNULL_BEGIN

@class AMALogConfigurator;
@class AMAEventPollingParameters;
@class AMAServiceConfiguration;
@class AMAApplicationState;

@protocol AMAModuleActivationDelegate;
@protocol AMAEventFlushableDelegate;
@protocol AMAEventPollingDelegate;
@protocol AMAAdProviding;
@protocol AMAAppMetricaExtendedReporting;

@interface AMAAppMetrica ()

// Activation and Event Delegates
+ (void)addActivationDelegate:(Class<AMAModuleActivationDelegate>)delegate;
+ (void)addEventFlushableDelegate:(Class<AMAEventFlushableDelegate>)delegate;
+ (void)addEventPollingDelegate:(Class<AMAEventPollingDelegate>)delegate;

// Registration Methods
+ (void)registerExternalService:(AMAServiceConfiguration *)configuration;

// Ad related methods
+ (void)registerAdProvider:(id<AMAAdProviding>)provider;
+ (void)setAdProviderEnabled:(BOOL)newValue;

// AdRevenue methods
+ (void)registerAdRevenueNativeSource:(NSString *)source;
+ (void)reportLibraryAdapterAdRevenueRelatedEvent:(NSString *)name
                                       parameters:(nullable NSDictionary *)params
                                        onFailure:(nullable void (^)(NSError *error))onFailure
NS_SWIFT_NAME(reportLibraryAdapterAdRevenueRelatedEvent(name:parameters:onFailure:));


// State Checks
+ (BOOL)isAPIKeyValid:(NSString *)apiKey;
+ (BOOL)isReporterCreatedForAPIKey:(NSString *)apiKey;
+ (BOOL)shouldReportToApiKey:(NSString *)apiKey;

// Session Management
+ (void)setSessionExtras:(nullable NSData *)data
                  forKey:(NSString *)key NS_SWIFT_NAME(setSessionExtra(value:for:));
+ (void)clearSessionExtras;

// Logging Configuration
+ (AMALogConfigurator *)sharedLogConfigurator;

// Anonymous activation
+ (void)activate;
+ (void)activateWithAdIdentifierTrackingEnabled:(BOOL)adIdentifierTrackingEnabled NS_SWIFT_NAME(activate(adIdentifierTrackingEnabled:));

// Reporting
+ (nullable id<AMAAppMetricaExtendedReporting>)extendedReporterForApiKey:(NSString *)apiKey
NS_SWIFT_NAME(extendedReporter(for:));

/** Reports an event of a specified type to the server. This method is intended for reporting string data.

 @param eventType The type of the event. See AMAEventTypes.h file for reserved event types.
 @param name The name of the event, can be nil.
 @param value The string value of the event, can be nil.
 @param eventEnvironment The event environment data, can be nil.
 @param appEnvironment  The app environment data, can be nil.
 @param extras The additional data for the event, can be nil.
 @param onFailure The block to be called when the operation fails, can be nil.
 */
+ (void)reportEventWithType:(NSUInteger)eventType
                       name:(nullable NSString *)name
                      value:(nullable NSString *)value
           eventEnvironment:(nullable NSDictionary *)eventEnvironment
             appEnvironment:(nullable NSDictionary *)appEnvironment
                     extras:(nullable NSDictionary<NSString *, NSData *> *)extras
                  onFailure:(nullable void (^)(NSError *error))onFailure;

/** Reports a binary event of a specified type to the server. This method is intended for reporting binary data.

 @param eventType The type of the event. See AMAEventTypes.h file for reserved event types.
 @param data The data of the event, cannot be nil.
 @param name The name of the event, can be nil.
 @param gZipped The boolean value, determines whether data should be compressed using the gzip compression.
 @param eventEnvironment The event environment data, can be nil.
 @param appEnvironment  The app environment data, can be nil.
 @param extras The additional data for the event, can be nil.
 @param bytesTruncated The number of bytes that have been truncated.
 @param onFailure The block to be called when the operation fails, can be nil.
 */
+ (void)reportBinaryEventWithType:(NSUInteger)eventType
                             data:(NSData *)data
                             name:(nullable NSString *)name
                          gZipped:(BOOL)gZipped
                 eventEnvironment:(nullable NSDictionary *)eventEnvironment
                   appEnvironment:(nullable NSDictionary *)appEnvironment
                           extras:(nullable NSDictionary<NSString *, NSData *> *)extras
                   bytesTruncated:(NSUInteger)bytesTruncated
                        onFailure:(nullable void (^)(NSError *error))onFailure;

/** Reports a file event of a specified type to the server. This method is intended for reporting file data.
 
 @param eventType The type of the event. See AMAEventTypes.h file for reserved event types.
 @param data The data of the event, cannot be nil.
 @param fileName The name of file, cannot be nil.
 @param date The creation date of the event, can be nil.
 @param gZipped The boolean value, determines whether data should be compressed using the gzip compression. If true, encryption is ignored.
 @param encrypted The boolean value, determines whether data should be encrypted.
 @param truncated  The boolean value, determines whether data should be truncated partially or completely.
 @param eventEnvironment The event environment data, can be nil.
 @param appEnvironment  The app environment data, can be nil.
 @param appState  The application state, can be nil.
 @param extras The additional data for the event, can be nil.
 @param onFailure The block to be called when the operation fails, can be nil.
 */
+ (void)reportFileEventWithType:(NSUInteger)eventType
                           data:(NSData *)data
                       fileName:(NSString *)fileName
                           date:(nullable NSDate *)date
                        gZipped:(BOOL)gZipped
                      encrypted:(BOOL)encrypted
                      truncated:(BOOL)truncated
               eventEnvironment:(nullable NSDictionary *)eventEnvironment
                 appEnvironment:(nullable NSDictionary *)appEnvironment
                       appState:(nullable AMAApplicationState *)appState
                         extras:(nullable NSDictionary<NSString *, NSData *> *)extras
                      onFailure:(nullable void (^)(NSError *error))onFailure;

/** Reports an SDK system event.

 @param name Short name or description of the event.
 @param onFailure Block to be executed if an error occurs while reporting, the error is passed as block argument.
 */
+ (void)reportSystemEvent:(NSString *)name
                onFailure:(nullable void (^)(NSError *error))onFailure
NS_SWIFT_NAME(reportSystemEvent(name:onFailure:));

/**
 * Sends information about ad revenue.
 * @note See `AMAAdRevenueInfo` for more info.
 *
 * @param adRevenue Object containing the information about ad revenue.
 * @param onFailure Block to be executed if an error occurs while sending ad revenue,
 *                  the error is passed as block argument.
 */
+ (void)reportAdRevenue:(AMAAdRevenueInfo *)adRevenue
        isAutocollected:(BOOL)isAutocollected
              onFailure:(nullable void (^)(NSError *error))onFailure
NS_SWIFT_NAME(reportAdRevenue(_:isAutocollected:onFailure:));


@end

NS_ASSUME_NONNULL_END
