
#import <Kiwi/Kiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMADispatchingController.h"
#import "AMAReporterStorage.h"
#import "AMADispatcher.h"
#import "AMADispatcherDelegate.h"
#import "AMATimeoutRequestsController.h"
#import "AMAPersistentTimeoutConfiguration.h"

@interface AMADispatchingController (Tests) <AMADispatcherDelegate>

@end

SPEC_BEGIN(AMADispatchingControllerTests)

describe(@"AMADispatchingController", ^{

    NSString *__block apiKey = @"API_KEY";

    NSObject<AMADispatcherDelegate> *__block delegate = nil;
    AMAReporterStorage *__block storage = nil;
    AMADispatcher *__block dispatcher = nil;
    AMADispatchingController *__block controller = nil;

    beforeEach(^{
        delegate = [KWMock nullMockForProtocol:@protocol(AMADispatcherDelegate)];
        storage = [AMAReporterStorage nullMock];
        [storage stub:@selector(apiKey) andReturn:apiKey];
        dispatcher = [AMADispatcher stubbedNullMockForInit:@selector(initWithReporterStorage:
                                                                     main:
                                                                     reportTimeoutController:
                                                                     trackingTimeoutController:)];
        controller = [[AMADispatchingController alloc] initWithTimeoutConfiguration:[KWMock nullMock]];
        controller.proxyDelegate = delegate;
    });

    context(@"Timeout controller", ^{
    
        AMATimeoutRequestsController *__block timeoutMock = nil;
        
        beforeEach(^{
            timeoutMock = [AMATimeoutRequestsController mock];
            [timeoutMock stub:@selector(initWithHostType:configuration:)];
            [AMATimeoutRequestsController stub:@selector(alloc) andReturn:timeoutMock];
        });
        
        it(@"Should create timeout controller with reports host type", ^{
            [[timeoutMock should] receive:@selector(initWithHostType:configuration:)
                            withArguments:AMAReportHostType, kw_any()];
            controller = [[AMADispatchingController alloc] initWithTimeoutConfiguration:nil];
        });
        it(@"Should create timeout configuration with provided configuration", ^{
            id configMock = [KWMock mock];
            [[timeoutMock should] receive:@selector(initWithHostType:configuration:)
                                withCount:2
                                arguments:kw_any(), configMock];
            controller = [[AMADispatchingController alloc] initWithTimeoutConfiguration:configMock];
        });
    });
         
    context(@"Registration", ^{
        it(@"Should create dispatcher", ^{
            [[dispatcher should] receive:@selector(initWithReporterStorage:
                                                   main:
                                                   reportTimeoutController:
                                                   trackingTimeoutController:)
                           withArguments:storage, theValue(YES), kw_any(), kw_any()];
            [controller registerDispatcherWithReporterStorage:storage main:YES];
        });
        it(@"Should set delegate", ^{
            [[dispatcher should] receive:@selector(setDelegate:) withArguments:controller];
            [controller registerDispatcherWithReporterStorage:storage main:YES];
        });
        context(@"Pause", ^{
            it(@"Should not start dispatcher", ^{
                [[dispatcher shouldNot] receive:@selector(start)];
                [controller registerDispatcherWithReporterStorage:storage main:YES];
            });
        });
    });

    context(@"After registration", ^{
        beforeEach(^{
            [controller registerDispatcherWithReporterStorage:storage main:NO];
        });
        it(@"Should cancelPending", ^{
            [controller start];
            [[dispatcher should] receive:@selector(cancelPending)];
            [controller shutdown];
        });
        it(@"Should not perform if not started", ^{
            [[dispatcher shouldNot] receive:@selector(performReport)];
            [controller performReportForApiKey:apiKey forced:NO];
        });
        it(@"Should perform forced if not started", ^{
            [[dispatcher should] receive:@selector(performReport)];
            [controller performReportForApiKey:apiKey forced:YES];
        });
        it(@"Should not cancelPending if not started", ^{
            [[dispatcher shouldNot] receive:@selector(cancelPending)];
            [controller shutdown];
        });
        it(@"Should perform report for existing API-key", ^{
            [[dispatcher should] receive:@selector(performReport)];
            [controller start];
            [controller performReportForApiKey:apiKey forced:NO];
        });
        it(@"Should assert for unexistant API-key", ^{
            [[dispatcher shouldNot] receive:@selector(performReport)];
            [controller start];
            [[theBlock(^{
                [controller performReportForApiKey:@"DIFFERENT_API_KEY" forced:NO];
            }) should] raise];
        });
        it(@"Should perform forced report first", ^{
            NSString *forcedApiKey = @"FORCED_API_KEY";
            
            storage = [AMAReporterStorage nullMock];
            [storage stub:@selector(apiKey) andReturn:forcedApiKey];
            
            AMADispatcher *forcedDispatcher =
                [AMADispatcher stubbedNullMockForInit:@selector(initWithReporterStorage:
                                                                main:
                                                                reportTimeoutController:
                                                                trackingTimeoutController:)];
            [controller registerDispatcherWithReporterStorage:storage main:YES];
            
            [[forcedDispatcher should] receive:@selector(performReport)];
            [[delegate shouldNot] receive:@selector(performReport)];
            [controller performReportForApiKey:forcedApiKey forced:YES];
            [controller start];
            [controller performReportForApiKey:apiKey forced:NO];
        });
    });

    context(@"Delegate", ^{
        it(@"Should not perform reports if queue is empty", ^{
            [controller registerDispatcherWithReporterStorage:storage main:NO];
            [controller start];
            [controller performReportForApiKey:apiKey forced:NO];
            [[dispatcher shouldNot] receive:@selector(performReport)];
            [controller dispatcherWillFinishDispatching:dispatcher];
        });
        it(@"Should put unexistent API-key back to queue", ^{
            [controller start];
            [[theBlock(^{
                [controller performReportForApiKey:apiKey forced:NO];
            }) should] raise];
            [controller registerDispatcherWithReporterStorage:storage main:NO];
            [[dispatcher should] receive:@selector(performReport)];
            [controller dispatcherWillFinishDispatching:dispatcher];
        });
        it(@"Should proxy dispatcherDidPerformReport", ^{
            [[delegate should] receive:@selector(dispatcherDidPerformReport:) withArguments:dispatcher];
            [controller dispatcherDidPerformReport:dispatcher];
        });
        it(@"Should proxy dispatcher:didFailToReportWithError:", ^{
            NSError *error = [NSError errorWithDomain:@"ERROR" code:23 userInfo:nil];
            [[delegate should] receive:@selector(dispatcher:didFailToReportWithError:) withArguments:dispatcher, error];
            [controller dispatcher:dispatcher didFailToReportWithError:error];
        });
        it(@"Should proxy dispatcherWillFinishDispatching:", ^{
            [[delegate should] receive:@selector(dispatcherWillFinishDispatching:) withArguments:dispatcher];
            [controller dispatcherWillFinishDispatching:dispatcher];
        });
    });
});

SPEC_END
