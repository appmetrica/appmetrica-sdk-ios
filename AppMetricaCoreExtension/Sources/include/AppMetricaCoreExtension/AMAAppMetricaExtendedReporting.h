
#import <Foundation/Foundation.h>
#import <AppMetricaCore/AppMetricaCore.h>

NS_ASSUME_NONNULL_BEGIN

@protocol AMAAppMetricaExtendedReporting  <AMAAppMetricaReporting>

/** Reports an event of a specified type to the server. This method is intended for reporting string data.
 
 @param eventType The type of the event. See AMAEventTypes.h file for reserved event types.
 @param name The name of the event, can be nil.
 @param value The string value of the event, can be nil.
 @param environment The environment data, can be nil.
 @param extras The additional data for the event, can be nil.
 @param onFailure The block to be called when the operation fails, can be nil.
 */
- (void)reportEventWithType:(NSUInteger)eventType
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
- (void)reportBinaryEventWithType:(NSUInteger)eventType
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
- (void)reportFileEventWithType:(NSUInteger)eventType
                           data:(NSData *)data
                       fileName:(NSString *)fileName
                        gZipped:(BOOL)gZipped
                      encrypted:(BOOL)encrypted
                      truncated:(BOOL)truncated
                    environment:(nullable NSDictionary *)environment
                         extras:(nullable NSDictionary<NSString *, NSData *> *)extras
                      onFailure:(nullable void (^)(NSError *error))onFailure;

@end

NS_ASSUME_NONNULL_END
