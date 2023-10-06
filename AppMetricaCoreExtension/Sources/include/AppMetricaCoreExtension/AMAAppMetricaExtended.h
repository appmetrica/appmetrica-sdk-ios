
#import <Foundation/Foundation.h>
#import <AppMetricaCore/AppMetricaCore.h>

NS_ASSUME_NONNULL_BEGIN

@class AMALogConfigurator;
@class AMACustomEventParameters;
@class AMAServiceConfiguration;
@class AMAInternalEventsReporter;

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
+ (void)registerAdProvider:(id<AMAAdProviding>)provider;
+ (void)registerExternalService:(AMAServiceConfiguration *)configuration;

// State Checks
+ (BOOL)isAppMetricaStarted;
+ (BOOL)isAPIKeyValid:(NSString *)apiKey;
+ (BOOL)isReporterCreatedForAPIKey:(NSString *)apiKey;

// Session Management
+ (void)setSessionExtras:(nullable NSData *)data
                  forKey:(NSString *)key NS_SWIFT_NAME(setSessionExtra(value:for:));
+ (void)clearSessionExtra;

// Reporting
+ (AMAInternalEventsReporter *)sharedInternalEventsReporter;
+ (nullable id<AMAAppMetricaExtendedReporting>)extendedReporterForApiKey:(NSString *)apiKey
NS_SWIFT_NAME(extendedReporter(for:));

// Logging Configuration
+ (AMALogConfigurator *)sharedLogConfigurator;

/** Reports an event of a specified type to the server. This method is intended for reporting string data.
 
 @param eventType The type of the event. See AMAEventTypes.h file for reserved event types.
 @param name The name of the event, can be nil.
 @param value The string value of the event, can be nil.
 @param environment The environment data, can be nil.
 @param extras The additional data for the event, can be nil.
 @param onFailure The block to be called when the operation fails, can be nil.
 */
+ (void)reportEventWithType:(NSUInteger)eventType
                       name:(nullable NSString *)name
                      value:(nullable NSString *)value
                environment:(nullable NSDictionary *)environment
                     extras:(nullable NSDictionary<NSString *, NSData *> *)extras
                  onFailure:(nullable void (^)(NSError *error))onFailure;

/** Reports a binary event of a specified type to the server. This method is intended for reporting binary data.
 
 @param eventType The type of the event. See AMAEventTypes.h file for reserved event types.
 @param data The data of the event, can be nil.
 @param gZipped The boolean value, determines whether data should be compressed using the gzip compression.
 @param environment The environment data, can be nil.
 @param extras The additional data for the event, can be nil.
 @param onFailure The block to be called when the operation fails, can be nil.
 */
+ (void)reportBinaryEventWithType:(NSUInteger)eventType
                             data:(NSData *)data
                          gZipped:(BOOL)gZipped
                      environment:(nullable NSDictionary *)environment
                           extras:(nullable NSDictionary<NSString *, NSData *> *)extras
                        onFailure:(nullable void (^)(NSError *error))onFailure;

/** Reports a file event of a specified type to the server. This method is intended for reporting file data.
 
 @param eventType The type of the event. See AMAEventTypes.h file for reserved event types.
 @param data The data of the event, can be nil.
 @param fileName The name of file, can be nil.
 @param gZipped The boolean value, determines whether data should be compressed using the gzip compression.
 @param encrypted The boolean value, determines whether data should be encrypted.
 @param truncated  The boolean value, determines whether data should be truncated partially or completely.
 @param environment The environment data, can be nil.
 @param extras The additional data for the event, can be nil.
 @param onFailure The block to be called when the operation fails, can be nil.
 */
+ (void)reportFileEventWithType:(NSUInteger)eventType
                           data:(NSData *)data
                       fileName:(NSString *)fileName
                        gZipped:(BOOL)gZipped
                      encrypted:(BOOL)encrypted
                      truncated:(BOOL)truncated
                    environment:(nullable NSDictionary *)environment
                         extras:(nullable NSDictionary<NSString *, NSData *> *)extras
                      onFailure:(nullable void (^)(NSError *error))onFailure;

/** Reports an event of a specified type to the server. This method is intended for reporting binary data.

 @param parameters The internal parameters to report event. See AMAEventInternalReportParameters.
 @param onFailure The block to be called when the operation fails, can be nil.
 */
+ (void)reportEventWithParameters:(AMACustomEventParameters *)parameters
                        onFailure:(nullable void (^)(NSError *error))onFailure;

@end

NS_ASSUME_NONNULL_END
