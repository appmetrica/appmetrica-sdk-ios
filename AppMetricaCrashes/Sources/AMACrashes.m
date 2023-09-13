
#import "AMACrashes.h"

#import "AMAErrorModel.h"
#import "AMAErrorModelFactory.h"

@interface AMACrashes () <AMAModuleActivationDelegate>

@end

@implementation AMACrashes

+ (void)didActivateWithConfiguration:(AMAModuleActivationConfiguration *)configuration
{
    
}

+ (void)reportError:(NSString *)message exception:(NSException *)exception onFailure:(void (^)(NSError *error))onFailure
{
    if ([AMAAppMetrica isAppMetricaStarted] == NO) {
//        [AMAErrorLogger logMetricaNotStartedErrorWithOnFailure:onFailure];
        return;
    }
//    [[self sharedImpl] reportError:[message copy] exception:exception onFailure:onFailure];
}

+ (void)reportNSError:(NSError *)error onFailure:(void (^)(NSError *))onFailure
{
    [self reportNSError:error options:0 onFailure:onFailure];
}

+ (void)reportNSError:(NSError *)error
              options:(AMAErrorReportingOptions)options
            onFailure:(void (^)(NSError *))onFailure
{
    [self reportErrorModel:[[AMAErrorModelFactory sharedInstance] modelForNSError:error options:options]
                 onFailure:onFailure];
}

+ (void)reportError:(id<AMAErrorRepresentable>)error
          onFailure:(void (^)(NSError *))onFailure
{
    [self reportError:error options:0 onFailure:onFailure];
}

+ (void)reportError:(id<AMAErrorRepresentable>)error
            options:(AMAErrorReportingOptions)options
          onFailure:(void (^)(NSError *))onFailure
{
    [self reportErrorModel:[[AMAErrorModelFactory sharedInstance] modelForErrorRepresentable:error options:options]
                 onFailure:onFailure];
}

+ (void)reportErrorModel:(AMAErrorModel *)error onFailure:(void (^)(NSError *))onFailure
{
    if ([AMAAppMetrica isAppMetricaStarted] == NO) {
//        [AMAErrorLogger logMetricaNotStartedErrorWithOnFailure:onFailure];
        return;
    }

//    [[self sharedImpl] reportErrorModel:error onFailure:onFailure];
}

@end
