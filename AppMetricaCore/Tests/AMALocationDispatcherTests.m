
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>
#import "AMALocationDispatcher.h"
#import "AMALocationStorage.h"
#import "AMALocationCollectingConfiguration.h"
#import "AMALocationDispatchStrategy.h"
#import "AMALocationRequestProvider.h"
#import "AMALocationRequest.h"
#import "AMATimeoutRequestsController.h"

SPEC_BEGIN(AMALocationDispatcherTests)

describe(@"AMALocationDispatcher", ^{

    NSArray *const hosts = @[ @"foo", @"bar" ];
    NSArray *const locationIdentifiers = @[ @1, @2 ];
    NSArray *const visitIdentifiers = @[ @4, @5 ];

    AMAHostExchangeRequestProcessorCallback __block processCallback = nil;
    AMAArrayIterator *__block hostsIterator = nil;
    AMALocationRequest *__block locationRequest = nil;
    AMALocationRequest *__block visitRequest = nil;
    AMAHostExchangeRequestProcessor *__block requestProcessor = nil;
    AMALocationStorage *__block storage = nil;
    AMALocationCollectingConfiguration *__block configuration = nil;
    AMAManualCurrentQueueExecutor *__block executor = nil;
    AMALocationDispatchStrategy *__block strategy = nil;
    AMALocationRequestProvider *__block requestProvider = nil;
    AMAReportResponseParser *__block responseParser = nil;
    AMALocationDispatcher *__block dispatcher = nil;
    AMATimeoutRequestsController *__block timeoutController = nil;

    beforeEach(^{
        hostsIterator = [AMAArrayIterator stubbedNullMockForInit:@selector(initWithArray:)];
    
        locationRequest = [AMALocationRequest nullMock];
        [locationRequest stub:@selector(locationIdentifiers) andReturn:locationIdentifiers];
        
        visitRequest = [AMALocationRequest nullMock];
        [visitRequest stub:@selector(visitIdentifiers) andReturn:visitIdentifiers];
        
        requestProcessor = [AMAHostExchangeRequestProcessor stubbedNullMockForInit:@selector(initWithRequest:
                                                                                             executor:
                                                                                             hostProvider:
                                                                                             responseValidator:)];
        [requestProcessor stub:@selector(processWithCallback:) withBlock:^id(NSArray *params) {
            processCallback = params[0];
            return nil;
        }];

        storage = [AMALocationStorage nullMock];
        configuration = [AMALocationCollectingConfiguration nullMock];
        [configuration stub:@selector(hosts) andReturn:hosts];
        executor = [[AMAManualCurrentQueueExecutor alloc] init];
        strategy = [AMALocationDispatchStrategy nullMock];
        [strategy stub:@selector(shouldSendLocation) andReturn:theValue(YES)];
        [strategy stub:@selector(shouldSendVisit) andReturn:theValue(YES)];
        requestProvider = [AMALocationRequestProvider nullMock];
        [requestProvider stub:@selector(nextLocationsRequest) andReturn:locationRequest];
        [requestProvider stub:@selector(nextVisitsRequest) andReturn:visitRequest];
        responseParser = [AMALocationRequestProvider nullMock];
        
        timeoutController = [AMATimeoutRequestsController nullMock];
        [timeoutController stub:@selector(isAllowed) andReturn:theValue(YES)];
    
        dispatcher = [[AMALocationDispatcher alloc] initWithStorage:storage
                                                      configurtaion:configuration
                                                           executor:executor
                                                           strategy:strategy
                                                    requestProvider:requestProvider
                                                     responseParser:responseParser
                                                  timeoutController:timeoutController];
    });

    context(@"Strategy passed", ^{
        it(@"Should start timer after location add", ^{
            KWCaptureSpy *spy = [executor captureArgument:@selector(executeAfterDelay:block:) atIndex:0];
            [dispatcher handleLocationAdd];
            [[spy.argument should] equal:60.0 withDelta:0.1];
        });
        it(@"Should start timer after visit add", ^{
            KWCaptureSpy *spy = [executor captureArgument:@selector(executeAfterDelay:block:) atIndex:0];
            [dispatcher handleVisitAdd];
            [[spy.argument should] equal:60.0 withDelta:0.1];
        });
        it(@"Should not start timer twice after location add", ^{
            [dispatcher handleLocationAdd];
            [[executor shouldNot] receive:@selector(executeAfterDelay:block:)];
            [dispatcher handleLocationAdd];
        });
        it(@"Should not start timer twice after visit add", ^{
            [dispatcher handleVisitAdd];
            [[executor shouldNot] receive:@selector(executeAfterDelay:block:)];
            [dispatcher handleVisitAdd];
        });
        it(@"Should check location strategy after location add", ^{
            [[strategy should] receive:@selector(shouldSendLocation)];
            [dispatcher handleLocationAdd];
        });
        it(@"Should not check visit strategy after location add", ^{
            [[strategy shouldNot] receive:@selector(shouldSendVisit)];
            [dispatcher handleLocationAdd];
        });
        it(@"Should check visit strategy after visit add", ^{
            [[strategy should] receive:@selector(shouldSendVisit)];
            [dispatcher handleVisitAdd];
        });
        it(@"Should create valid hosts provider after location add", ^{
            [[hostsIterator should] receive:@selector(initWithArray:) withArguments:hosts];
            [dispatcher handleLocationAdd];
        });
        it(@"Should create valid hosts provider after visit add", ^{
            [[hostsIterator should] receive:@selector(initWithArray:) withArguments:hosts];
            [dispatcher handleVisitAdd];
        });
        it(@"Should create valid processor after location add", ^{
            [[requestProcessor should] receive:@selector(initWithRequest:executor:hostProvider:responseValidator:)
                                 withArguments:locationRequest, executor, hostsIterator, responseParser];
            [dispatcher handleLocationAdd];
        });
        it(@"Should create valid processor after visit add", ^{
            [[requestProcessor should] receive:@selector(initWithRequest:executor:hostProvider:responseValidator:)
                                 withArguments:visitRequest, executor, hostsIterator, responseParser];
            [dispatcher handleVisitAdd];
        });
        it(@"Should process request after location add", ^{
            [[requestProcessor should] receive:@selector(processWithCallback:)];
            [dispatcher handleLocationAdd];
        });
        it(@"Should process request after visit add", ^{
            [[requestProcessor should] receive:@selector(processWithCallback:)];
            [dispatcher handleVisitAdd];
        });
        it(@"Should not process location request if timeout reached", ^{
            [timeoutController stub:@selector(isAllowed) andReturn:theValue(NO)];
            [[requestProcessor shouldNot] receive:@selector(processWithCallback:)];
            [dispatcher handleLocationAdd];
        });
        it(@"Should not process visit request if timeout reached", ^{
            [timeoutController stub:@selector(isAllowed) andReturn:theValue(NO)];
            [[requestProcessor shouldNot] receive:@selector(processWithCallback:)];
            [dispatcher handleVisitAdd];
        });
        it(@"Should start timer if timeout reached after location add", ^{
            [timeoutController stub:@selector(isAllowed) andReturn:theValue(NO)];
            [[executor should] receive:@selector(executeAfterDelay:block:)];
            [dispatcher handleLocationAdd];
        });
        it(@"Should start timer if timeout reached after visit add", ^{
            [timeoutController stub:@selector(isAllowed) andReturn:theValue(NO)];
            [[executor should] receive:@selector(executeAfterDelay:block:)];
            [dispatcher handleVisitAdd];
        });
        
        it(@"Should not process request if no hosts are provided", ^{
            [configuration stub:@selector(hosts) andReturn:@[]];
            [[requestProcessor shouldNot] receive:@selector(processWithCallback:)];
            [dispatcher handleVisitAdd];
        });
    
        context(@"Callback location", ^{
            beforeEach(^{
                [dispatcher handleLocationAdd];
            });
            it(@"Should pass non-nil callback", ^{
                [[processCallback should] beNonNil];
            });
            context(@"Success", ^{
                it(@"Should increment identifier", ^{
                    [[storage should] receive:@selector(incrementRequestIdentifier)];
                    processCallback(nil);
                });
                it(@"Should start not send location request if strategy denies", ^{
                    [strategy stub:@selector(shouldSendVisit) andReturn:theValue(YES)];
                    KWCaptureSpy *spy = [requestProcessor captureArgument:@selector(initWithRequest:
                                                                                    executor:
                                                                                    hostProvider:
                                                                                    responseValidator:)
                                                                  atIndex:0];
                    processCallback(nil);
                    [[((AMALocationRequest *)spy.argument).locationIdentifiers should] beNil];
                });
                it(@"Should start location request if strategy allows", ^{
                    [strategy stub:@selector(shouldSendVisit) andReturn:theValue(NO)];
                    KWCaptureSpy *spy = [requestProcessor captureArgument:@selector(initWithRequest:
                                                                                    executor:
                                                                                    hostProvider:
                                                                                    responseValidator:)
                                                                  atIndex:0];
                    processCallback(nil);
                    [[((AMALocationRequest *)spy.argument).locationIdentifiers should] equal:locationIdentifiers];
                });
                it(@"Should purge locations", ^{
                    [[storage should] receive:@selector(purgeLocationsWithIdentifiers:)
                                withArguments:locationIdentifiers];
                    processCallback(nil);
                });
                it(@"Should restart timer", ^{
                    KWCaptureSpy *spy = [executor captureArgument:@selector(executeAfterDelay:block:) atIndex:0];
                    processCallback(nil);
                    [[spy.argument should] equal:60.0 withDelta:0.1];
                });
                it(@"Should report of success", ^{
                    [[timeoutController should] receive:@selector(reportOfSuccess)];
                    processCallback(nil);
                });
                context(@"Strategy passed", ^{
                    it(@"Should process next request", ^{
                        [[requestProcessor should] receive:@selector(processWithCallback:)];
                        processCallback(nil);
                    });
                });
                context(@"Strategy not passed", ^{
                    beforeEach(^{
                        [strategy stub:@selector(shouldSendLocation) andReturn:theValue(NO)];
                        [strategy stub:@selector(shouldSendVisit) andReturn:theValue(NO)];
                    });
                    it(@"Should not process next request", ^{
                        [[requestProcessor shouldNot] receive:@selector(processWithCallback:)];
                        processCallback(nil);
                    });
                });
            });
            context(@"Failure", ^{
                NSError *const error = [NSError errorWithDomain:@"foo"
                                                           code:AMAHostExchangeRequestProcessorNetworkError
                                                       userInfo:nil];
                it(@"Should not increment identifier", ^{
                    [[storage shouldNot] receive:@selector(incrementRequestIdentifier)];
                    processCallback(error);
                });
                it(@"Should not purge locations", ^{
                    [[storage shouldNot] receive:@selector(purgeLocationsWithIdentifiers:)];
                    processCallback(error);
                });
                it(@"Should restart timer", ^{
                    KWCaptureSpy *spy = [executor captureArgument:@selector(executeAfterDelay:block:) atIndex:0];
                    processCallback(error);
                    [[spy.argument should] equal:60.0 withDelta:0.1];
                });
                it(@"Should not notice strategy about failed request after network error", ^{
                    [[strategy shouldNot] receive:@selector(handleRequestFailure)];
                    processCallback(error);
                });
                it(@"Should notice strategy about failed request after any other error", ^{
                    [[strategy should] receive:@selector(handleRequestFailure)];
                    NSError *error = [NSError errorWithDomain:@"Test error domain"
                                                         code:100500
                                                     userInfo:nil];
                    processCallback(error);
                });
                it(@"Should report of failure if there is a network error", ^{
                    [[timeoutController should] receive:@selector(reportOfFailure)];
                    NSError *error = [NSError errorWithDomain:kAMAHostExchangeRequestProcessorErrorDomain
                                                         code:AMAHostExchangeRequestProcessorNetworkError
                                                     userInfo:nil];
                    processCallback(error);
                });
                it(@"Should not report of failure if there is a bad request error", ^{
                    [[timeoutController shouldNot] receive:@selector(reportOfFailure)];
                    NSError *error = [NSError errorWithDomain:kAMAHostExchangeRequestProcessorErrorDomain
                                                         code:AMAHostExchangeRequestProcessorBadRequest
                                                     userInfo:nil];
                    processCallback(error);
                });
                it(@"Should not report of failure if there is any other error", ^{
                    [[timeoutController shouldNot] receive:@selector(reportOfFailure)];
                    NSError *error = [NSError errorWithDomain:@"Test error domain"
                                                         code:100500
                                                     userInfo:nil];
                    processCallback(error);
                });
                context(@"Strategy passed", ^{
                    it(@"Should process next request", ^{
                        [[requestProcessor should] receive:@selector(processWithCallback:)];
                        processCallback(error);
                    });
                });
                context(@"Strategy not passed", ^{
                    beforeEach(^{
                        [strategy stub:@selector(shouldSendLocation) andReturn:theValue(NO)];
                    });
                    it(@"Should not process next location request", ^{
                        KWCaptureSpy *spy = [requestProcessor captureArgument:@selector(initWithRequest:
                                                                                        executor:
                                                                                        hostProvider:
                                                                                        responseValidator:)
                                                                      atIndex:0];
                        processCallback(error);
                        [[((AMALocationRequest *)spy.argument).locationIdentifiers should] beNil];
                    });
                });
            });
        });
        
        context(@"Callback visit", ^{
            beforeEach(^{
                [dispatcher handleVisitAdd];
            });
            context(@"Success", ^{
                it(@"Should check visit strategy after callback", ^{
                    [[strategy should] receive:@selector(shouldSendVisit) withCountAtLeast:1];
                    processCallback(nil);
                });
                it(@"Should start visit request if strategy allows", ^{
                    [strategy stub:@selector(shouldSendVisit) andReturn:theValue(YES)];
                    KWCaptureSpy *spy = [requestProcessor captureArgument:@selector(initWithRequest:
                                                                                    executor:
                                                                                    hostProvider:
                                                                                    responseValidator:)
                                                                  atIndex:0];
                    processCallback(nil);
                    [[((AMALocationRequest *)spy.argument).visitIdentifiers should] equal:visitIdentifiers];
                });
                it(@"Should not start visit request if strategy denies", ^{
                    [strategy stub:@selector(shouldSendVisit) andReturn:theValue(NO)];
                    KWCaptureSpy *spy = [requestProcessor captureArgument:@selector(initWithRequest:
                                                                                    executor:
                                                                                    hostProvider:
                                                                                    responseValidator:)
                                                                  atIndex:0];
                    processCallback(nil);
                    [[((AMALocationRequest *)spy.argument).visitIdentifiers should] beNil];
                });
                it(@"Should increment identifier", ^{
                    [[storage should] receive:@selector(incrementRequestIdentifier)];
                    processCallback(nil);
                });
                it(@"Should purge visits", ^{
                    [[storage should] receive:@selector(purgeVisitsWithIdentifiers:)
                                withArguments:visitIdentifiers];
                    processCallback(nil);
                });
                it(@"Should restart timer", ^{
                    KWCaptureSpy *spy = [executor captureArgument:@selector(executeAfterDelay:block:) atIndex:0];
                    processCallback(nil);
                    [[spy.argument should] equal:60.0 withDelta:0.1];
                });
            });
            context(@"Failure", ^{
                NSError *const error = [NSError errorWithDomain:@"foo" code:0 userInfo:nil];
                it(@"Should not increment identifier", ^{
                    [[storage shouldNot] receive:@selector(incrementRequestIdentifier)];
                    processCallback(error);
                });
                it(@"Should not purge visits", ^{
                    [[storage shouldNot] receive:@selector(purgeVisitsWithIdentifiers:)];
                    processCallback(error);
                });
                it(@"Should restart timer", ^{
                    KWCaptureSpy *spy = [executor captureArgument:@selector(executeAfterDelay:block:) atIndex:0];
                    processCallback(error);
                    [[spy.argument should] equal:60.0 withDelta:0.1];
                });
            });
        });
    });

    context(@"Strategy not passed", ^{
        beforeEach(^{
            [strategy stub:@selector(shouldSendLocation) andReturn:theValue(NO)];
        });

        it(@"Should start timer", ^{
            KWCaptureSpy *spy = [executor captureArgument:@selector(executeAfterDelay:block:) atIndex:0];
            [dispatcher handleLocationAdd];
            [[spy.argument should] equal:60.0 withDelta:0.1];
        });
        it(@"Should check strategy", ^{
            [[strategy should] receive:@selector(shouldSendLocation)];
            [dispatcher handleLocationAdd];
        });
        it(@"Should not process request", ^{
            [[requestProcessor shouldNot] receive:@selector(processWithCallback:)];
            [dispatcher handleLocationAdd];
        });
    });

    context(@"Timer", ^{
        beforeEach(^{
            [strategy stub:@selector(shouldSendVisit) andReturn:theValue(NO)];
            [dispatcher handleLocationAdd];
            [strategy stub:@selector(shouldSendLocation) andReturn:theValue(NO)];
            processCallback(nil);
            [strategy stub:@selector(shouldSendLocation) andReturn:theValue(YES)];
        });

        context(@"Strategy passed", ^{
            it(@"Should restart timer", ^{
                KWCaptureSpy *spy = [executor captureArgument:@selector(executeAfterDelay:block:) atIndex:0];
                [executor execute];
                [[spy.argument should] equal:60.0 withDelta:0.1];
            });
            it(@"Should process request", ^{
                [[requestProcessor should] receive:@selector(processWithCallback:)];
                [executor execute];
            });
        });
        context(@"Strategy not passed", ^{
            beforeEach(^{
                [strategy stub:@selector(shouldSendLocation) andReturn:theValue(NO)];
            });

            it(@"Should restart timer", ^{
                KWCaptureSpy *spy = [executor captureArgument:@selector(executeAfterDelay:block:) atIndex:0];
                [executor execute];
                [[spy.argument should] equal:60.0 withDelta:0.1];
            });
            it(@"Should not process request", ^{
                [[requestProcessor shouldNot] receive:@selector(processWithCallback:)];
                [executor execute];
            });
        });
    });

});

SPEC_END

