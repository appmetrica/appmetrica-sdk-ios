
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**  AMACrash contains crash description.
 */
@interface AMACrash : NSObject

/** Full crash report to be reported.
 */
@property (nonatomic, copy, nullable, readonly) NSData *rawData;

/** Timestamp of crash to be reported.
 */
@property (nonatomic, strong, nullable, readonly) NSDate *date;

/** Additional information, associated with crash.
 */
@property (nonatomic, copy, nullable, readonly) NSDictionary *errorEnvironment;

/** Full crash report to be reported.
 */
@property (nonatomic, copy, nullable, readonly) NSString *rawContent DEPRECATED_ATTRIBUTE;

/** Initialize crash with specified raw report binary data, date and error environment.

    @param rawData Full crash report encoded with protobuf.
    @param date Date and time of crash.
    @param errorEnvironment Additional information, associated with crash.
 */
- (instancetype)initWithRawData:(nullable NSData *)rawData
                           date:(nullable NSDate *)date
               errorEnvironment:(nullable NSDictionary *)errorEnvironment;

/** Create crash object with specified raw report content, date and error environment.

    @param rawData Full crash report encoded with protobuf.
    @param date Date and time of crash.
    @param errorEnvironment Additional information, associated with crash.
 */
+ (instancetype)crashWithRawData:(nullable NSData *)rawData
                            date:(nullable NSDate *)date
                errorEnvironment:(nullable NSDictionary *)errorEnvironment;

/** Initialize crash with specified raw report content, date and error environment.

    @param rawContent Full crash report in standard Apple format.
    @param date Date and time of crash.
    @param errorEnvironment Additional information, associated with crash.
 */
- (instancetype)initWithRawContent:(nullable NSString *)rawContent
                              date:(nullable NSDate *)date
                  errorEnvironment:(nullable NSDictionary *)errorEnvironment
DEPRECATED_MSG_ATTRIBUTE("initWithRawContent:date:errorEnvironment: has been deprecated. "
                         "Use initWithRawData:date:errorEnvironment: instead");

/** Create crash object with specified raw report content, date and error environment.

    @param rawContent Full crash report in standard Apple format.
    @param date Date and time of crash.
    @param errorEnvironment Additional information, associated with crash.
 */
+ (instancetype)crashWithRawContent:(nullable NSString *)rawContent
                               date:(nullable NSDate *)date
                   errorEnvironment:(nullable NSDictionary *)errorEnvironment
DEPRECATED_MSG_ATTRIBUTE("crashWithRawContent:date:errorEnvironment: has been deprecated. "
                         "Use crashWithRawData:date:errorEnvironment: instead");

@end

NS_ASSUME_NONNULL_END
