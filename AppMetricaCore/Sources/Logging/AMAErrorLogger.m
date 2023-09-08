
#import "AMACore.h"
#import "AMAErrorLogger.h"
#import "AMAErrorsFactory.h"

static NSString *const kAMAInternalInconsistencyErrorMsg = @"Internal inconsistency error";
static NSString *const kAMAInvalidApiKeyMsgFormat = @"Invalid apiKey \"%@\". ApiKey must be a hexadecimal string in format xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx. ApiKey can be requested or checked at https://appmetrica.io";
static NSString *const kAMAMetricaNotStartedMsg = @"activateWithApiKey: or activateWithConfiguration: aren't called";
static NSString *const kAMAMetricaAlreadyStartedMsg = @"Failed to activate AppMetrica; AppMetrica has already been started";
static NSString *const kAMAMetricaActivationWithPresentedKeyMsg = @"Failed to activate AppMetrica with provided apiKey. ApiKey has already been used by another reporter";
static NSString *const kAMAMetricaActivationWithSessionsAutoTrackingMsg = @"Failed to pause/resume session because AppMetrica has been activated with sessionsAutoTracking enabled";

static NSString *const kAMAInvalidTrackingUrlSchemeMsg = @"Failed to enable tracking. Invalid or unregistered url scheme";
static NSString *const kAMAInvalidParameterMessageForAppVersionMsg = @"appVersion can't be nil or an empty string";
static NSString *const kAMAInvalidParameterMessageForAppBuildNumberMsg = @"appBuildNumber must be a string containing a positive number";

@implementation AMAErrorLogger

+ (void)logAppMetricaNotStartedErrorWithOnFailure:(void (^)(NSError *error))failureCallback
{
    [AMAFailureDispatcher dispatchError:[AMAErrorsFactory appMetricaNotStartedError] withBlock:failureCallback];
    AMALogError(kAMAMetricaNotStartedMsg);
}

+ (void)logInvalidApiKeyError:(NSString *)apiKey
{
    AMALogError(kAMAInvalidApiKeyMsgFormat, apiKey);
    NSAssert(false, kAMAInvalidApiKeyMsgFormat, apiKey);
}

+ (void)logMetricaAlreadyStartedError
{
    AMALogError(kAMAMetricaAlreadyStartedMsg);
    NSAssert(false, kAMAMetricaAlreadyStartedMsg);
}

+ (void)logMetricaActivationWithAlreadyPresentedKeyError
{
    AMALogError(kAMAMetricaActivationWithPresentedKeyMsg);
    NSAssert(false, kAMAMetricaActivationWithPresentedKeyMsg);
}

+ (void)logMetricaActivationWithAutomaticSessionsTracking
{
    AMALogError(kAMAMetricaActivationWithSessionsAutoTrackingMsg);
    NSAssert(false, kAMAMetricaActivationWithSessionsAutoTrackingMsg);
}

+ (void)logMetricaInternalInconsistencyError
{
    AMALogError(kAMAInternalInconsistencyErrorMsg);
    NSAssert(false, kAMAInternalInconsistencyErrorMsg);
}

+ (void)logInvalidTrackUrlSchemeError
{
    AMALogError(kAMAInvalidTrackingUrlSchemeMsg);
    NSAssert(false, kAMAInvalidTrackingUrlSchemeMsg);
}

+ (void)logInvalidCustomAppVersionError
{
    AMALogError(kAMAInvalidParameterMessageForAppVersionMsg);
    NSAssert(false, kAMAInvalidParameterMessageForAppVersionMsg);
}

+ (void)logInvalidCustomAppBuildNumberError
{
    AMALogError(kAMAInvalidParameterMessageForAppBuildNumberMsg);
    NSAssert(false, kAMAInvalidParameterMessageForAppBuildNumberMsg);
}

@end
