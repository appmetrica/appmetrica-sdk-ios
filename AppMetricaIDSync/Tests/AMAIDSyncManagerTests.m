
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
                [[reporter should] receive:@selector(reportEventForRequest:code:body:headers:responseURL:)
                             withArguments:request, theValue(200), jsonResponse, expectedResponseHeaders, url];
                
                [[conditionProvider should] receive:@selector(execute:statusCode:)
                                      withArguments:request, theValue(200)];
                
                [manager timerDidFire:nil];
            });
            
            it(@"should not report or execute if there is network error", ^{
                NSError *networkError = [NSError errorWithDomain:NSURLErrorDomain
                                                            code:-1009
                                                        userInfo:nil];
                
                [requestProcessor stub:@selector(processRequest:callback:)
                             withBlock:^id(NSArray *params) {
                    void (^callback)(NSData *, NSHTTPURLResponse *, NSError *) = params[1];
                    callback(nil, nil, networkError);
                    return nil;
                }];
                
                [[reporter shouldNot] receive:@selector(reportEventForRequest:code:body:headers:responseURL:)];
                [[conditionProvider shouldNot] receive:@selector(execute:statusCode:)];
                
                [manager timerDidFire:nil];
            });
        });
    });
});

SPEC_END
