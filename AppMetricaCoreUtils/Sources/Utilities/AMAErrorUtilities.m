
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>
#import "AMACoreUtilsLogging.h"

NSErrorDomain const kAMAAppMetricaErrorDomain = @"io.appmetrica";
NSErrorDomain const kAMAAppMetricaInternalErrorDomain = @"AppMetricaInternalErrorDomain";
NSErrorDomain const kAMAAppMetricaDatabaseErrorDomain = @"AppMetricaDatabaseErrorDomain";

NSErrorDomain const AMAAppMetricaEventErrorDomain = @"io.appmetrica";
NSErrorDomain const AMAAppMetricaInternalErrorDomain = @"AppMetricaInternalErrorDomain";
NSErrorDomain const AMAAppMetricaDatabaseErrorDomain = @"AppMetricaDatabaseErrorDomain";

NSString *const kAMAAppMetricaInternalErrorResultObjectKey = @"kAppMetricaInternalErrorResultObjectKey";

@implementation AMAErrorUtilities

+ (void)fillError:(NSError **)placeholderError withError:(NSError *)error
{
    if (placeholderError != NULL) {
        *placeholderError = error;
    }
    else if (error != nil) {
        AMALogError(@"%@", error);
    }
}

+ (void)fillError:(NSError *__autoreleasing *)placeholderError withInternalErrorName:(NSString *)errorName
{
    NSError *internalError = [NSError errorWithDomain:AMAAppMetricaInternalErrorDomain
                                                 code:AMAAppMetricaInternalEventErrorCodeNamedError
                                             userInfo:@{ NSLocalizedDescriptionKey: errorName ?: @"" }];
    [self fillError:placeholderError withError:internalError];
}

+ (NSError *)errorByAddingUnderlyingError:(NSError *)underlyingError toError:(NSError *)initialError
{
    NSError *newError = initialError != nil ? initialError : underlyingError;
    if (underlyingError != nil && initialError != nil) {
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:initialError.userInfo];
        userInfo[NSUnderlyingErrorKey] = underlyingError;
        newError = [NSError errorWithDomain:initialError.domain code:initialError.code userInfo:userInfo];
    }
    return newError;
}

+ (NSError *)errorWithDomain:(NSString *)domain code:(NSInteger)code description:(NSString *)description
{
    NSDictionary *userInfo = nil;
    if (description != nil) {
        userInfo = @{ NSLocalizedDescriptionKey : description };
    }
    return [NSError errorWithDomain:domain code:code userInfo:userInfo];
}

+ (NSError *)errorWithCode:(NSInteger)code description:(NSString *)description
{
    return [[self class] errorWithDomain:AMAAppMetricaEventErrorDomain
                                    code:code
                             description:description];
}

+ (NSError *)internalErrorWithCode:(NSInteger)code description:(NSString *)description
{
    return [[self class] errorWithDomain:AMAAppMetricaInternalErrorDomain
                                    code:code
                             description:description];
}

+ (NSError *)databaseErrorWithCode:(NSInteger)code description:(NSString *)description
{
    return [[self class] errorWithDomain:AMAAppMetricaDatabaseErrorDomain
                                    code:code
                             description:description];
}

@end
