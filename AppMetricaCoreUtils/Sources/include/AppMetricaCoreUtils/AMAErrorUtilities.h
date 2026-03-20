
#import <Foundation/Foundation.h>

extern NSErrorDomain const AMAAppMetricaEventErrorDomain NS_SWIFT_NAME(AppMetricaEventErrorDomain);

extern NSErrorDomain const AMAAppMetricaInternalErrorDomain NS_SWIFT_NAME(AppMetricaInternalErrorDomain);
extern NSErrorDomain const AMAAppMetricaDatabaseErrorDomain NS_SWIFT_NAME(AMAAppMetricaDatabaseErrorDomain);
extern NSString *const kAMAAppMetricaInternalErrorResultObjectKey NS_SWIFT_NAME(AppMetricaInternalErrorResultObjectKey);

typedef NS_ERROR_ENUM(AMAAppMetricaEventErrorDomain, AMAAppMetricaEventErrorCode) {
    AMAAppMetricaEventErrorCodeInitializationError = 1000,
    AMAAppMetricaEventErrorCodeInvalidName = 1001,
    AMAAppMetricaEventErrorCodeInvalidRevenueInfo = 1002,
    AMAAppMetricaEventErrorCodeEmptyUserProfile = 1003,
    AMAAppMetricaEventErrorCodeInvalidBacktrace = 1004,
    AMAAppMetricaEventErrorCodeInvalidAdRevenueInfo = 1005,
    AMAAppMetricaEventErrorCodeInvalidExternalAttributionContents = 1006,
} NS_SWIFT_NAME(AppMetricaEventError);

typedef NS_ERROR_ENUM(AMAAppMetricaInternalErrorDomain, AMAAppMetricaInternalEventErrorCode) {
    AMAAppMetricaInternalEventErrorCodeInvalidName = 1001,
    AMAAppMetricaInternalEventErrorCodeRecrash = 2000,
    AMAAppMetricaInternalEventErrorCodeUnexpectedDeserialization = 2001,
    AMAAppMetricaInternalEventErrorCodeUnsupportedReportVersion = 2002,
    AMAAppMetricaInternalEventErrorCodeInternalInconsistency = 2003,
    AMAAppMetricaInternalEventErrorCodeJsonSerialization = 2004,
    AMAAppMetricaInternalEventErrorCodeProbableUnhandledCrash = 2005,
    AMAAppMetricaInternalEventErrorCodeNamedError = 3000,
} NS_SWIFT_NAME(AppMetricaInternalEventError);

typedef NS_ERROR_ENUM(AMAAppMetricaDatabaseErrorDomain, AMAAppMetricaDatabaseEventErrorCode) {
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
