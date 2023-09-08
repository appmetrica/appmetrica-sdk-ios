
#import <Foundation/Foundation.h>

extern NSErrorDomain const kAMAAppMetricaErrorDomain;

extern NSErrorDomain const kAMAAppMetricaInternalErrorDomain;
extern NSString *const kAMAAppMetricaInternalErrorResultObjectKey;

typedef NS_ERROR_ENUM(kAMAAppMetricaErrorDomain, AMAAppMetricaEventErrorCode) {
    AMAAppMetricaEventErrorCodeInitializationError = 1000,
    AMAAppMetricaEventErrorCodeInvalidName = 1001,
    AMAAppMetricaEventErrorCodeJsonSerializationError = 1002,
    AMAAppMetricaEventErrorCodeInvalidRevenueInfo = 1003,
    AMAAppMetricaEventErrorCodeEmptyUserProfile = 1004,
    AMAAppMetricaEventErrorCodeInternalInconsistency = 1005,
    AMAAppMetricaEventErrorCodeInvalidBacktrace = 1006,
    AMAAppMetricaEventErrorCodeInvalidAdRevenueInfo = 1007,
};

typedef NS_ERROR_ENUM(kAMAAppMetricaInternalErrorDomain, AMAAppMetricaInternalEventErrorCode) {
    AMAAppMetricaInternalEventErrorCodeRecrash = 2000,
    AMAAppMetricaInternalEventErrorCodeUnexpectedDeserialization = 2001,
    AMAAppMetricaInternalEventErrorCodeUnsupportedReportVersion = 2002,
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
