
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import <AppMetricaNetwork/AppMetricaNetwork.h>
#import "AMAIDSyncManager.h"
#import "AMAIDSyncStartupConfiguration.h"
#import "AMAIDSyncReporter.h"
#import "AMAIDSyncPreconditionHandler.h"
#import "AMAIDSyncExecutionConditionProvider.h"
#import "AMAIDSyncRequestsConverter.h"
#import "AMAIDSyncRequestResponse.h"
#import "AMAIDSyncReportRequest.h"

@interface AMAIDSyncManager ()<AMATimerDelegate>
@end

SPEC_BEGIN(AMAIDSyncManagerTests)

describe(@"AMAIDSyncManager", ^{
    __block AMAIDSyncManager *manager = nil;
    __block AMAIDSyncStartupConfiguration *config = nil;
    __block AMAGenericRequestProcessor *requestProcessor = nil;
    __block AMAIDSyncReporter *reporter = nil;
    __block AMAIDSyncExecutionConditionProvider *conditionProvider = nil;
    __block AMAIDSyncRequestsConverter *converter = nil;
    __block AMAIDSyncPreconditionHandler *preconditionHandler = nil;

    beforeEach(^{
        config = [AMAIDSyncStartupConfiguration nullMock];
        [config stub:@selector(idSyncEnabled) andReturn:theValue(YES)];

        requestProcessor = [AMAGenericRequestProcessor nullMock];
        reporter = [AMAIDSyncReporter nullMock];
        conditionProvider = [AMAIDSyncExecutionConditionProvider nullMock];
        converter = [AMAIDSyncRequestsConverter nullMock];
        preconditionHandler = [AMAIDSyncPreconditionHandler nullMock];

        manager = [[AMAIDSyncManager alloc] initWithConditionProvider:conditionProvider
                                                            converter:converter
                                                     requestProcessor:requestProcessor
                                                             reporter:reporter
                                                  preconditionHandler:preconditionHandler];
        [manager stub:@selector(startup) andReturn:config];
    });
    
    afterEach(^{
        [AMAIDSyncStartupConfiguration clearStubs];
    });

    context(@"Timers", ^{
        context(@"when feature enabled", ^{
            it(@"should call launchDelayTimer if firstDelayPassed = NO", ^{
                [manager stub:@selector(firstDelayPassed) andReturn:theValue(NO)];
                
                [[manager should] receive:@selector(launchDelayTimer)];
                
                [manager startIfNeeded];
            });
            
            it(@"should call processRequests if firstDelayPassed = YES", ^{
                [manager stub:@selector(firstDelayPassed) andReturn:theValue(YES)];
                
                [[manager should] receive:@selector(processRequests)];
                [[manager should] receive:@selector(launchRepeatedTimer)];
                
                [manager startIfNeeded];
            });
        });
        
        context(@"when feature disabled", ^{
            it(@"should not launch timers", ^{
                [config stub:@selector(idSyncEnabled) andReturn:theValue(NO)];
                
                [[manager shouldNot] receive:@selector(launchDelayTimer)];
                [[manager shouldNot] receive:@selector(launchRepeatedTimer)];
                [[manager shouldNot] receive:@selector(processRequests)];
                
                [manager startIfNeeded];
            });
        });
        
        it(@"should create AMATimer with correct timeout", ^{
            [config stub:@selector(launchDelaySeconds) andReturn:@(15)];
            [manager stub:@selector(firstDelayPassed) andReturn:theValue(NO)];
            
            AMATimer *timerMock = [AMATimer stubbedNullMockForInit:@selector(initWithTimeout:)];
            [[timerMock should] receive:@selector(initWithTimeout:) withArguments:theValue(15)];
            
            [manager startIfNeeded];
            
            [AMATimer clearStubs];
        });
        
        it(@"should set firstDelayPassed and start repeated timer on timer fire", ^{
            [[manager should] receive:@selector(launchRepeatedTimer)];
            [[manager should] receive:@selector(processRequests)];

            [manager timerDidFire:nil];
        });
    });

    context(@"Startup config update", ^{
        it(@"should replace startup and restart", ^{
            [manager stub:@selector(firstDelayPassed) andReturn:theValue(NO)];
            
            [[manager should] receive:@selector(launchDelayTimer)];
            
            [manager startupUpdatedWithConfiguration:config];
        });
    });
    context(@"Perform requests", ^{
        NSDictionary *const requestJson = @{
            @"type": @"novatiq_hyper_id",
            @"preconditions": @{ @"network": @"cell" },
            @"url": @"https://spadsync.com/sync?sptoken=100500&sspid=200500&ssphost=300500",
            @"headers": @{ @"key": @[ @"value" ] },
            @"resend_interval_for_valid_response": @86400,
            @"resend_interval_for_invalid_response": @3600,
            @"valid_response_codes": @[ @200 ]
        };
        AMAIDSyncRequest *__block request = nil;
        NSArray *__block requestsArray = nil;
        NSArray *__block requestsJsonArray = nil;
        
        NSObject<AMAExecutionCondition> *__block condition = nil;
        
        beforeEach(^{
            request = [AMAIDSyncRequest nullMock];
            condition = [KWMock nullMockForProtocol:@protocol(AMAExecutionCondition)];
            
            requestsJsonArray = @[requestJson];
            requestsArray = @[request];
            
            [config stub:@selector(requests) andReturn:requestsJsonArray];
            
            [converter stub:@selector(convertDictToRequests:)
                  andReturn:requestsArray
              withArguments:requestsJsonArray];
            
            [conditionProvider stub:@selector(executionConditionWithRequest:)
                          andReturn:condition
                      withArguments:request];
        });
        
        void (^stubPrecondition)(BOOL *) = ^(BOOL *precondition) {
            [preconditionHandler stub:@selector(canExecuteRequestWithPreconditions:completion:)
                            withBlock:^id(NSArray *params) {
                void (^completion)(BOOL) = params[1];
                if (completion) {
                    completion(precondition);
                }
                return nil;
            }];
        };
        
        it(@"should process request if condition and precondition matched", ^{
            [condition stub:@selector(shouldExecute) andReturn:theValue(YES)];
            stubPrecondition(YES);
            
            [[requestProcessor should] receive:@selector(processRequest:callback:)];
            
            [manager timerDidFire:nil];
        });
        
        it(@"should not process request if condition not matched", ^{
            [condition stub:@selector(shouldExecute) andReturn:theValue(NO)];
            stubPrecondition(YES);
            
            [[requestProcessor shouldNot] receive:@selector(processRequest:callback:)];
            
            [manager timerDidFire:nil];
        });
        
        it(@"should not process request if precondition not matched", ^{
            [condition stub:@selector(shouldExecute) andReturn:theValue(YES)];
            stubPrecondition(NO);
            
            [[requestProcessor shouldNot] receive:@selector(processRequest:callback:)];
            
            [manager timerDidFire:nil];
        });
        
        context(@"Request", ^{
            NSString *const url = @"https://example.com";
            NSDictionary *const headers = @{ @"key": @[ @"value" ] };
            NSString *const jsonResponse = @"{\"ok\":true}";
            NSHTTPURLResponse *__block response = nil;
            
            beforeEach(^{
                response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:url]
                                                       statusCode:200
                                                      HTTPVersion:@"HTTP/1.1"
                                                     headerFields:@{ @"Content-Type": @"application/json" }];
                [request stub:@selector(url) andReturn:url];
                [request stub:@selector(headers) andReturn:@{ @"key": @[ @"value" ] }];
            });
            
            it(@"should report event and execute condition when network request succeeds", ^{
                [request stub:@selector(reportEventEnabled) andReturn:theValue(YES)];
                [condition stub:@selector(shouldExecute) andReturn:theValue(YES)];
                stubPrecondition(YES);
                
                NSData *data = [jsonResponse dataUsingEncoding:NSUTF8StringEncoding];
                [requestProcessor stub:@selector(processRequest:callback:)
                             withBlock:^id(NSArray *params) {
                    void (^callback)(NSData *, NSHTTPURLResponse *, NSError *) = params[1];
                    callback(data, response, nil);
                    return nil;
                }];
                
                NSDictionary *expectedResponseHeaders = @{ @"Content-Type": @[@"application/json"] };
                
                KWCaptureSpy *spy = [reporter captureArgument:@selector(reportEventForResponse:) atIndex:0];
                
                [[reporter should] receive:@selector(reportEventForResponse:)];
                
                [[conditionProvider should] receive:@selector(execute:statusCode:)
                                      withArguments:request, theValue(200)];
                
                [manager timerDidFire:nil];
                
                AMAIDSyncRequestResponse *capturedResponse = spy.argument;
                [[capturedResponse.request should] equal:request];
                [[theValue(capturedResponse.code) should] equal:theValue(200)];
                [[capturedResponse.body should] equal:jsonResponse];
                [[capturedResponse.headers should] equal:expectedResponseHeaders];
                [[capturedResponse.responseURL should] equal:url];
            });
            
            it(@"should not report or execute if there is network error", ^{
                [request stub:@selector(reportEventEnabled) andReturn:theValue(YES)];
                NSError *networkError = [NSError errorWithDomain:NSURLErrorDomain
                                                            code:-1009
                                                        userInfo:nil];
                
                [requestProcessor stub:@selector(processRequest:callback:)
                             withBlock:^id(NSArray *params) {
                    void (^callback)(NSData *, NSHTTPURLResponse *, NSError *) = params[1];
                    callback(nil, nil, networkError);
                    return nil;
                }];
                
                [[reporter shouldNot] receive:@selector(reportEventForResponse:)];
                [[conditionProvider shouldNot] receive:@selector(execute:statusCode:)];
                
                [manager timerDidFire:nil];
            });
            it(@"should not report if report disabled", ^{
                [request stub:@selector(reportEventEnabled) andReturn:theValue(NO)];
                [condition stub:@selector(shouldExecute) andReturn:theValue(YES)];
                stubPrecondition(YES);
                
                NSData *data = [jsonResponse dataUsingEncoding:NSUTF8StringEncoding];
                [requestProcessor stub:@selector(processRequest:callback:)
                             withBlock:^id(NSArray *params) {
                    void (^callback)(NSData *, NSHTTPURLResponse *, NSError *) = params[1];
                    callback(data, response, nil);
                    return nil;
                }];
                
                NSDictionary *expectedResponseHeaders = @{ @"Content-Type": @[@"application/json"] };
                [[reporter shouldNot] receive:@selector(reportEventForResponse:)];
                
                // disabling reporting do not affect condition execution
                [[conditionProvider should] receive:@selector(execute:statusCode:)
                                      withArguments:request, theValue(200)];
                
                [manager timerDidFire:nil];
            });
            
            context(@"Report request", ^{
                void (^testNoRetryRequest)(NSInteger) = ^(NSInteger statusCode) {
                    it(@"should not retry report request", ^{
                        NSString *const reportUrl = @"https://report.url";
                        [request stub:@selector(reportUrl) andReturn:theValue(reportUrl)];
                        [condition stub:@selector(shouldExecute) andReturn:theValue(YES)];
                        stubPrecondition(YES);
                        
                        NSString *__block capturedReportHost = nil;
                        
                        response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:reportUrl]
                                                               statusCode:statusCode
                                                              HTTPVersion:@""
                                                             headerFields:@{}];
                        
                        NSData *data = [jsonResponse dataUsingEncoding:NSUTF8StringEncoding];
                        [requestProcessor stub:@selector(processRequest:callback:)
                                     withBlock:^id(NSArray *params) {
                            void (^callback)(NSData *, NSHTTPURLResponse *, NSError *) = params[1];
                            callback(data, response, nil);
                            
                            id param = params[0];
                            if ([param isKindOfClass:[AMAIDSyncReportRequest class]]) {
                                AMAIDSyncReportRequest *request = (AMAIDSyncReportRequest *)param;
                                capturedReportHost = request.host;
                            }
                            return nil;
                        }];
                        
                        [[requestProcessor should] receive:@selector(processRequest:callback:) withCount:2];
                        
                        [manager timerDidFire:nil];
                        
                        [[capturedReportHost should] equal:reportUrl];
                        
                    });
                };
                
                context(@"No retry with code 2xx", ^{
                    testNoRetryRequest(200);
                });
                context(@"No retry with code 4xx", ^{
                    testNoRetryRequest(404);
                });
                
                it(@"should retry report request with other codes", ^{
                    NSString *const reportUrl = @"https://report.url";
                    [request stub:@selector(reportUrl) andReturn:theValue(reportUrl)];
                    [condition stub:@selector(shouldExecute) andReturn:theValue(YES)];
                    stubPrecondition(YES);
                    
                    NSString *__block capturedReportHost = nil;
                    
                    response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:reportUrl]
                                                           statusCode:502
                                                          HTTPVersion:@""
                                                         headerFields:@{}];
                    
                    NSData *data = [jsonResponse dataUsingEncoding:NSUTF8StringEncoding];
                    [requestProcessor stub:@selector(processRequest:callback:)
                                 withBlock:^id(NSArray *params) {
                        void (^callback)(NSData *, NSHTTPURLResponse *, NSError *) = params[1];
                        callback(data, response, nil);
                        
                        id param = params[0];
                        if ([param isKindOfClass:[AMAIDSyncReportRequest class]]) {
                            AMAIDSyncReportRequest *request = (AMAIDSyncReportRequest *)param;
                            capturedReportHost = request.host;
                        }
                        return nil;
                    }];
                    
                    [[requestProcessor shouldEventuallyBeforeTimingOutAfter(3)] receive:@selector(processRequest:callback:)
                                                                       withCountAtLeast:3];
                    
                    [manager timerDidFire:nil];
                    
                    [[capturedReportHost should] equal:reportUrl];
                });
                
            });
        });
    });
});

SPEC_END
