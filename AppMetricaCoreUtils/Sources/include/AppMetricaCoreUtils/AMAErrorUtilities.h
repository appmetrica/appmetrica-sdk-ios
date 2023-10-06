
#import <Foundation/Foundation.h>

extern NSErrorDomain const kAMAAppMetricaErrorDomain;

extern NSErrorDomain const kAMAAppMetricaInternalErrorDomain;
extern NSString *const kAMAAppMetricaInternalErrorResultObjectKey;

typedef NS_ERROR_ENUM(kAMAAppMetricaErrorDomain, AMAAppMetricaEventErrorCode) {
    AMAAppMetricaEventErrorCodeInitializationError = 1000,
    AMAAppMetricaEventErrorCodeInvalidName = 1001,
    AMAAppMetricaEventErrorCodeInvalidRevenueInfo = 1002,
    AMAAppMetricaEventErrorCodeEmptyUserProfile = 1003,
    AMAAppMetricaEventErrorCodeInvalidBacktrace = 1004,
    AMAAppMetricaEventErrorCodeInvalidAdRevenueInfo = 1005,
};

typedef NS_ERROR_ENUM(kAMAAppMetricaInternalErrorDomain, AMAAppMetricaInternalEventErrorCode) {
    AMAAppMetricaInternalEventErrorCodeRecrash = 2000,
    AMAAppMetricaInternalEventErrorCodeUnexpectedDeserialization = 2001,
    AMAAppMetricaInternalEventErrorCodeUnsupportedReportVersion = 2002,
    AMAAppMetricaInternalEventErrorCodeInternalInconsistency = 2003,
    AMAAppMetricaInternalEventJsonSerializationError = 2004,
    AMAAppMetricaInternalEventErrorCodeProbableUnhandledCrash = 2005,
    AMAAppMetricaInternalEventErrorCodeNamedError = 3000,
};

@interface AMAErrorUtilities : NSObject

+ (void)fillError:(NSError **)placeholderError withError:(NSError *)error;
+ (void)fillError:(NSError **)placeholderError withInternalErrorName:(NSString *)errorName;
+ (NSError *)errorWithDomain:(NSString *)domain code:(NSInteger)code description:(NSString *)description;
+ (NSError *)errorByAddingUnderlyingError:(NSError *)underlyingError toError:(NSError *)error;

+ (NSError *)errorWithCode:(NSInteger)code description:(NSString *)description;
+ (NSError *)internalErrorWithCode:(NSInteger)code description:(NSString *)description;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end
