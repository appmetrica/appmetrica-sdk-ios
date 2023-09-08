
#import <Kiwi/Kiwi.h>
#import "AMACore.h"
#import "AMAAppMetricaPlugins.h"
#import "AMAPluginErrorDetails.h"
#import "AMAAppMetrica+Internal.h"
#import "AMAAppMetricaImpl+TestUtilities.h"
#import "AMAAppMetricaPluginsImpl.h"
#import "AMAStubHostAppStateProvider.h"

SPEC_BEGIN(AMAAppMetricaPluginsTests)

describe(@"AMAAppMetricaPlugins", ^{

    AMAAppMetricaImpl *__block sharedImpl = nil;
    AMAPluginErrorDetails *__block errorDetails = nil;
    AMAAppMetricaPluginsImpl *__block pluginsImpl = nil;
    NSError *__block resultError = nil;
    void __block (^onFailure)(NSError *) = nil;

    beforeEach(^{
        pluginsImpl = [[AMAAppMetricaPluginsImpl alloc] init];
        resultError = nil;
        errorDetails = [AMAPluginErrorDetails nullMock];
        sharedImpl = [AMAAppMetricaImpl nullMock];
        [AMAAppMetrica stub:@selector(sharedImpl) andReturn:sharedImpl];
        onFailure = ^void (NSError *error) {
            resultError = error;
        };
    });

//    context(@"Report unhandled exception", ^{
//        it(@"Should not report if not started", ^{
//            [AMAAppMetrica stub:@selector(isAppMetricaStarted) andReturn:theValue(NO)];
//            [[sharedImpl shouldNot] receive:@selector(reportPluginCrash:onFailure:)];
//            [pluginsImpl reportUnhandledException:errorDetails onFailure:onFailure];
//            [[resultError shouldNot] beNil];
//        });
//        it(@"Should report if started", ^{
//            [AMAAppMetrica stub:@selector(isAppMetricaStarted) andReturn:theValue(YES)];
//            [[sharedImpl should] receive:@selector(reportPluginCrash:onFailure:) withArguments:errorDetails, onFailure];
//            [pluginsImpl reportUnhandledException:errorDetails onFailure:onFailure];
//            [[resultError should] beNil];
//        });
//    });
//
//    context(@"Report error", ^{
//        NSString *message = @"some message";
//        it(@"Should not report if not started", ^{
//            [AMAAppMetrica stub:@selector(isAppMetricaStarted) andReturn:theValue(NO)];
//            [[sharedImpl shouldNot] receive:@selector(reportPluginError:message:onFailure:)];
//            [pluginsImpl reportError:errorDetails message:message onFailure:onFailure];
//            [[resultError shouldNot] beNil];
//        });
//        it(@"Should report if started", ^{
//            [AMAAppMetrica stub:@selector(isAppMetricaStarted) andReturn:theValue(YES)];
//            [[sharedImpl should] receive:@selector(reportPluginError:message:onFailure:)
//                           withArguments:errorDetails, message, onFailure];
//            [pluginsImpl reportError:errorDetails message:message onFailure:onFailure];
//            [[resultError should] beNil];
//        });
//    });
//
//    context(@"Report error with identifier", ^{
//        NSString *identifier = @"some id";
//        NSString *message = @"some message";
//        it(@"Should not report if not started", ^{
//            [AMAAppMetrica stub:@selector(isAppMetricaStarted) andReturn:theValue(NO)];
//            [[sharedImpl shouldNot] receive:@selector(reportPluginErrorWithIdentifier:message:error:onFailure:)];
//            [pluginsImpl reportErrorWithIdentifier:identifier
//                                           message:message
//                                           details:errorDetails
//                                         onFailure:onFailure];
//            [[resultError shouldNot] beNil];
//        });
//        it(@"Should report if started", ^{
//            [AMAAppMetrica stub:@selector(isAppMetricaStarted) andReturn:theValue(YES)];
//            [[sharedImpl should] receive:@selector(reportPluginErrorWithIdentifier:message:error:onFailure:)
//                           withArguments:identifier, message, errorDetails, onFailure];
//            [pluginsImpl reportErrorWithIdentifier:identifier
//                                           message:message
//                                           details:errorDetails
//                                         onFailure:onFailure];
//            [[resultError should] beNil];
//        });
//    });
//
//    context(@"Handle plugin init finished", ^{
//        AMAStubHostAppStateProvider *__block hostStateProvider = nil;
//        beforeEach(^{
//            hostStateProvider = [[AMAStubHostAppStateProvider alloc] init];
//            [AMAAppMetrica stub:@selector(sharedHostStateProviderHub) andReturn:hostStateProvider];
//        });
//        it(@"Should not force update to foreground if not started", ^{
//            [AMAAppMetrica stub:@selector(isAppMetricaStarted) andReturn:theValue(NO)];
//            [[hostStateProvider shouldNot] receive:@selector(forceUpdateToForeground)];
//            [pluginsImpl handlePluginInitFinished];
//        });
//        it(@"Should force update to foreground if started", ^{
//            [AMAAppMetrica stub:@selector(isAppMetricaStarted) andReturn:theValue(YES)];
//            [[hostStateProvider should] receive:@selector(forceUpdateToForeground)];
//            [pluginsImpl handlePluginInitFinished];
//        });
//    });
});

SPEC_END
