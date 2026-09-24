
#import <Foundation/Foundation.h>

extern NSErrorDomain const AMAAppMetricaEventErrorDomain NS_SWIFT_NAME(AppMetricaEventErrorDomain);

extern NSErrorDomain const AMAAppMetricaInternalErrorDomain NS_SWIFT_NAME(AppMetricaInternalErrorDomain);
extern NSErrorDomain const AMAAppMetricaDatabaseErrorDomain NS_SWIFT_NAME(AMAAppMetricaDatabaseErrorDomain);
extern NSString *const kAMAAppMetricaInternalErrorResultObjectKey NS_SWIFT_NAME(AppMetricaInternalErrorResultObjectKey);

typedef NS_ERROR_ENUM(AMAAppMetricaEventErrorDomain, AMAAppMetricaEventError) {
    /** activateWithApiKey: or activateWithConfiguration: has not been called yet. */
    AMAAppMetricaEventErrorCodeIsNotActivated NS_SWIFT_NAME(isNotActivated) = 1000,
    /** Event name, error message, deep link URL, or event type is invalid or empty. */
    AMAAppMetricaEventErrorCodeInvalidName NS_SWIFT_NAME(invalidName) = 1001,
    /** Revenue info contains invalid data (e.g. non-ISO 4217 currency code or zero quantity). */
    AMAAppMetricaEventErrorCodeInvalidRevenueInfo NS_SWIFT_NAME(invalidRevenueInfo) = 1002,
    /** User profile update is empty; all attributes may have been ignored. */
    AMAAppMetricaEventErrorCodeEmptyUserProfile NS_SWIFT_NAME(emptyUserProfile) = 1003,
    /** Backtrace provided for a crash or error report is null or empty. */
    AMAAppMetricaEventErrorCodeInvalidBacktrace NS_SWIFT_NAME(invalidBacktrace) = 1004,
    /** Ad revenue info contains invalid data (e.g. non-ISO 4217 currency code). */
    AMAAppMetricaEventErrorCodeInvalidAdRevenueInfo NS_SWIFT_NAME(invalidAdRevenueInfo) = 1005,
    /** External attribution data has invalid contents and cannot be converted to JSON. */
    AMAAppMetricaEventErrorCodeInvalidExternalAttributionContents NS_SWIFT_NAME(invalidExternalAttributionContents) = 1006,
    /** AppMetrica activation was called, but the main reporter is not ready yet. */
    AMAAppMetricaEventErrorCodeMainReporterNotReady NS_SWIFT_NAME(mainReporterNotReady) = 1007,
    /** Session failed to load from the database. */
    AMAAppMetricaEventErrorCodeSessionNotLoad NS_SWIFT_NAME(sessionNotLoad) = 1008,
} NS_SWIFT_NAME(AppMetricaEventError);

typedef NS_ERROR_ENUM(AMAAppMetricaInternalErrorDomain, AMAAppMetricaInternalEventErrorCode) {
    /** Event name, error message, deep link URL, or event type is invalid or empty. */
    AMAAppMetricaInternalEventErrorCodeInvalidName = 1001,

    /** A recrash (secondary crash) was detected while processing a crash report. */
    AMAAppMetricaInternalEventErrorCodeRecrash = 2000,
    /** JSON deserialization produced an object of an unexpected type (e.g. array instead of dictionary). */
    AMAAppMetricaInternalEventErrorCodeUnexpectedDeserialization = 2001,
    /** Crash report version is not supported by the current SDK. */
    AMAAppMetricaInternalEventErrorCodeUnsupportedReportVersion = 2002,
    /** Internal state inconsistency detected (e.g. a required component is not configured). */
    AMAAppMetricaInternalEventErrorCodeInternalInconsistency = 2003,
    /** Failed to serialize a dictionary into JSON (the object is not valid JSON). */
    AMAAppMetricaInternalEventErrorCodeJsonSerialization = 2004,
    /** The previous app session likely ended with an unhandled crash (foreground or background). */
    AMAAppMetricaInternalEventErrorCodeProbableUnhandledCrash = 2005,
    
    /** A named internal error propagated via fillError:withInternalErrorName:. */
    AMAAppMetricaInternalEventErrorCodeNamedError = 3000,
} NS_SWIFT_NAME(AppMetricaInternalEventError);

typedef NS_ERROR_ENUM(AMAAppMetricaDatabaseErrorDomain, AMAAppMetricaDatabaseEventErrorCode) {
    /** A database operation (read, write, or query) failed due to an internal database error. */
    AMAAppMetricaDatabaseEventErrorCodeOperationFailed = 3000,
} NS_SWIFT_NAME(AppMetricaDatabaseEventError);

NS_SWIFT_NAME(ErrorUtilities)
@interface AMAErrorUtilities : NSObject

+ (void)fillError:(NSError **)placeholderError withError:(NSError *)error;
+ (void)fillError:(NSError **)placeholderError withInternalErrorName:(NSString *)errorName;
+ (NSError *)errorWithDomain:(NSString *)domain code:(NSInteger)code description:(NSString *)description;
+ (NSError *)errorByAddingUnderlyingError:(NSError *)underlyingError toError:(NSError *)error;

+ (NSError *)errorWithCode:(NSInteger)code description:(NSString *)description;
+ (NSError *)internalErrorWithCode:(NSInteger)code description:(NSString *)description;
+ (NSError *)databaseErrorWithCode:(NSInteger)code description:(NSString *)description;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end
