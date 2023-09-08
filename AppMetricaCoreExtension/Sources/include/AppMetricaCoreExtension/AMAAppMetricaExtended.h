
#import <Foundation/Foundation.h>
#import <AppMetricaCore/AppMetricaCore.h>

NS_ASSUME_NONNULL_BEGIN

@class AMALogConfigurator;
@class AMACustomEventParameters;
@class AMAServiceConfiguration;

@protocol AMAModuleActivationDelegate;
@protocol AMAEventFlushableDelegate;
@protocol AMAAdProviding;

@interface AMAAppMetrica ()

+ (void)addActivationDelegate:(Class<AMAModuleActivationDelegate>)delegate;
+ (void)addEventFlushableDelegate:(Class<AMAEventFlushableDelegate>)delegate;

+ (void)registerAdProvider:(id<AMAAdProviding>)provider;

+ (void)registerExternalService:(AMAServiceConfiguration *)configuration;

+ (BOOL)isAppMetricaStarted;

+ (BOOL)isAPIKeyValid:(NSString *)apiKey;

+ (BOOL)isReporterCreatedForAPIKey:(NSString *)apiKey;

+ (AMALogConfigurator *)sharedLogConfigurator;

+ (void)setSessionExtras:(nullable NSData *)data
                  forKey:(NSString *)key NS_SWIFT_NAME(setSessionExtra(value:for:));

+ (void)clearSessionExtra;

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

/** Reports an event of a specified type to the server. This method is intended for reporting binary data.

 @param parameters The internal parameters to report event. See AMAEventInternalReportParameters.
 @param onFailure The block to be called when the operation fails, can be nil.
 */
+ (void)reportEventWithParameters:(AMACustomEventParameters *)parameters
                        onFailure:(nullable void (^)(NSError *error))onFailure;
@end

NS_ASSUME_NONNULL_END
