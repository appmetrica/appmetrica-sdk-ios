
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaWebKit/AppMetricaWebKit.h>
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>
#if !TARGET_OS_TV
#import <WebKit/WebKit.h>

SPEC_BEGIN(AMAJSControllerTests)

describe(@"AMAJSController", ^{

    id __block reporter = nil;
    id __block executor = nil;
    AMAJSController *__block jsController = nil;
    WKUserContentController *__block userContentController = nil;

    beforeEach(^{
        reporter = [KWMock nullMockForProtocol:@protocol(AMAJSReporting)];
        executor = [KWMock nullMockForProtocol:@protocol(AMAAsyncExecuting)];
        userContentController = [WKUserContentController nullMock];
        jsController = [[AMAJSController alloc] initWithUserContentController:userContentController];
    });

    context(@"Set up web view reporting", ^{
        it(@"Should register listener for appmetrica_reportEvent messages", ^{
            [[userContentController should] receive:@selector(addScriptMessageHandler:name:)
                                      withArguments:jsController, @"appmetrica_reportEvent"];

            [jsController setUpWebViewReporting:executor withReporter:reporter];
        });
        it(@"Should register listener for appmetricaInitializer_init messages", ^{
            [[userContentController should] receive:@selector(addScriptMessageHandler:name:)
                                      withArguments:jsController, @"appmetricaInitializer_init"];

            [jsController setUpWebViewReporting:executor withReporter:reporter];
        });
        it(@"Should add two interfaces", ^{
            KWCaptureSpy *scriptCaptor = [userContentController captureArgument:@selector(addUserScript:)
                                                                        atIndex:0];
            [jsController setUpWebViewReporting:executor withReporter:reporter];
            WKUserScript *script = scriptCaptor.argument;
            [[theValue(script.injectionTime) should] equal: theValue(WKUserScriptInjectionTimeAtDocumentStart)];
            [[theValue(script.isForMainFrameOnly) should] equal: theValue(NO)];
        });
    });
    context(@"WKScriptMessageHandler callbacks", ^{
        WKScriptMessage *__block message = nil;
        beforeEach(^{
            message = [WKScriptMessage nullMock];
        });
        context(@"Wrong name", ^{
            it(@"Should ignore nil message name", ^{
                [message stub:@selector(name) andReturn:nil];
                [[executor shouldNot] receive:@selector(execute:)];
                [jsController userContentController:userContentController didReceiveScriptMessage:message];
            });
            it(@"Should ignore unknown message name", ^{
                [message stub:@selector(name) andReturn:@"unknown"];
                [[executor shouldNot] receive:@selector(execute:)];
                [jsController userContentController:userContentController didReceiveScriptMessage:message];
            });
        });
        context(@"appmetrica_reportEvent message", ^{
            KWCaptureSpy *__block blockCaptor = nil;
            beforeEach(^{
                [message stub:@selector(name) andReturn:@"appmetrica_reportEvent"];
                [jsController setUpWebViewReporting:executor withReporter:reporter];
                blockCaptor = [executor captureArgument:@selector(execute:) atIndex:0];
            });
            it (@"Should report event with name and value", ^{
                NSString *name = @"my name";
                NSString *value = @"my value";
                [message stub:@selector(body) andReturn:@{ @"name" : name, @"value" : value }];
                [[executor should] receive:@selector(execute:) withCount:1];
                [jsController userContentController:userContentController didReceiveScriptMessage:message];
                [[reporter should] receive:@selector(reportJSEvent:value:) withArguments:name, value];
                [[reporter shouldNot] receive:@selector(reportJSInitEvent:)];
                dispatch_block_t block = blockCaptor.argument;
                block();
            });
            it (@"Should report event without name or value", ^{
                [message stub:@selector(body) andReturn:@{}];
                [[executor should] receive:@selector(execute:) withCount:1];
                [jsController userContentController:userContentController didReceiveScriptMessage:message];
                [[reporter should] receive:@selector(reportJSEvent:value:) withArguments:nil, nil];
                [[reporter shouldNot] receive:@selector(reportJSInitEvent:)];
                dispatch_block_t block = blockCaptor.argument;
                block();
            });
            it (@"Should report event if body is nil", ^{
                [message stub:@selector(body) andReturn:nil];
                [[executor should] receive:@selector(execute:) withCount:1];
                [jsController userContentController:userContentController didReceiveScriptMessage:message];
                [[reporter should] receive:@selector(reportJSEvent:value:) withArguments:nil, nil];
                [[reporter shouldNot] receive:@selector(reportJSInitEvent:)];
                dispatch_block_t block = blockCaptor.argument;
                block();
            });
            it (@"Should not report event if name is not string", ^{
                NSNull *name = [NSNull null];
                NSString *value = @"my value";
                [message stub:@selector(body) andReturn:@{ @"name" : name, @"value" : value }];
                [[executor shouldNot] receive:@selector(execute:)];
                [jsController userContentController:userContentController didReceiveScriptMessage:message];
            });
            it (@"Should report event if value is not string", ^{
                NSString *name = @"my name";
                NSNull *value = [NSNull null];
                [message stub:@selector(body) andReturn:@{ @"name" : name, @"value" : value }];
                [[executor should] receive:@selector(execute:) withCount:1];
                [jsController userContentController:userContentController didReceiveScriptMessage:message];
                [[reporter should] receive:@selector(reportJSEvent:value:) withArguments:name, nil];
                [[reporter shouldNot] receive:@selector(reportJSInitEvent:)];
                dispatch_block_t block = blockCaptor.argument;
                block();
            });
        });
        context(@"appmetricaInitializer_init message", ^{
            KWCaptureSpy *__block blockCaptor = nil;
            beforeEach(^{
                [message stub:@selector(name) andReturn:@"appmetricaInitializer_init"];
                [jsController setUpWebViewReporting:executor withReporter:reporter];
                blockCaptor = [executor captureArgument:@selector(execute:) atIndex:0];
            });
            it (@"Should report init event with value", ^{
                NSString *value = @"my value";
                [message stub:@selector(body) andReturn:@{ @"value" : value }];
                [[executor should] receive:@selector(execute:) withCount:1];
                [jsController userContentController:userContentController didReceiveScriptMessage:message];
                [[reporter should] receive:@selector(reportJSInitEvent:) withArguments:value];
                [[reporter shouldNot] receive:@selector(reportJSEvent:value:)];
                dispatch_block_t block = blockCaptor.argument;
                block();
            });
            it (@"Should not report init event without value", ^{
                [message stub:@selector(body) andReturn:@{}];
                [[executor should] receive:@selector(execute:) withCount:1];
                [jsController userContentController:userContentController didReceiveScriptMessage:message];
                [[reporter should] receive:@selector(reportJSInitEvent:) withArguments:nil];
                [[reporter shouldNot] receive:@selector(reportJSEvent:value:)];
                dispatch_block_t block = blockCaptor.argument;
                block();
            });
            it (@"Should report init event if body is nil", ^{
                [message stub:@selector(body) andReturn:nil];
                [[executor should] receive:@selector(execute:) withCount:1];
                [jsController userContentController:userContentController didReceiveScriptMessage:message];
                [[reporter should] receive:@selector(reportJSInitEvent:) withArguments:nil];
                [[reporter shouldNot] receive:@selector(reportJSEvent:value:)];
                dispatch_block_t block = blockCaptor.argument;
                block();
            });
            it (@"Should not report init event if value is not string", ^{
                [message stub:@selector(body) andReturn:@{ @"value" : [NSNull null] }];
                [[executor shouldNot] receive:@selector(execute:)];
                [jsController userContentController:userContentController didReceiveScriptMessage:message];
            });
        });
    });
});

SPEC_END

#endif
