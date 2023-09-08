
#import "AMACore.h"
#import "AMAAppMetricaPluginsImpl.h"
#import "AMAPluginErrorDetails.h"
#import "AMAAppMetrica+Internal.h"
#import "AMAErrorLogger.h"
#import "AMAAppMetricaImpl.h"

// FIXME: Come up with where to move plugins
@implementation AMAAppMetricaPluginsImpl

- (void)reportUnhandledException:(AMAPluginErrorDetails *)errorDetails
                       onFailure:(nullable void (^)(NSError *error))onFailure
{
    if ([AMAAppMetrica isAppMetricaStarted] == NO) {
        [AMAErrorLogger logAppMetricaNotStartedErrorWithOnFailure:onFailure];
        return;
    }
//    [[AMAAppMetrica sharedImpl] reportPluginCrash:errorDetails onFailure:onFailure];
}

- (void)reportError:(AMAPluginErrorDetails *)errorDetails
            message:(NSString *)message
          onFailure:(nullable void (^)(NSError *error))onFailure
{
    if ([AMAAppMetrica isAppMetricaStarted] == NO) {
        [AMAErrorLogger logAppMetricaNotStartedErrorWithOnFailure:onFailure];
        return;
    }
//    [[AMAAppMetrica sharedImpl] reportPluginError:errorDetails
//                                             message:[message copy]
//                                           onFailure:onFailure];
}

- (void)reportErrorWithIdentifier:(NSString *)identifier
                          message:(nullable NSString *)message
                          details:(nullable AMAPluginErrorDetails *)errorDetails
                        onFailure:(nullable void (^)(NSError *error))onFailure
{
    if ([AMAAppMetrica isAppMetricaStarted] == NO) {
        [AMAErrorLogger logAppMetricaNotStartedErrorWithOnFailure:onFailure];
        return;
    }
//    [[AMAAppMetrica sharedImpl] reportPluginErrorWithIdentifier:[identifier copy]
//                                                           message:[message copy]
//                                                             error:errorDetails
//                                                         onFailure:onFailure];
}

- (void)handlePluginInitFinished
{
    if ([AMAAppMetrica isAppMetricaStarted] == NO) {
        [AMAErrorLogger logAppMetricaNotStartedErrorWithOnFailure:nil];
        return;
    }
    //https://nda.ya.ru/t/ImTM_Nm86fAGJu
    //TODO: Use resume session
    [[AMAAppMetrica sharedHostStateProvider] forceUpdateToForeground];
}

@end
