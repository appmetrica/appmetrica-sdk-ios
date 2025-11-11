
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import <AppMetricaNetwork/AppMetricaNetwork.h>

@interface AMAHostExchangeRequestProcessor (AMATest) <AMAHTTPRequestDelegate>

@end

SPEC_BEGIN(AMAHostExchangeRequestProcessorTests)

describe(@"AMAHostExchangeRequestProcessor", ^{

    NSArray *__block hosts = @[ @"https://first.com", @"https://second.com" ];

    NSURLRequest *__block urlRequest = nil;
    AMAHTTPRequestor *__block httpRequestor = nil;
    AMAHTTPRequestor *__block allocedHttpRequestor = nil;
    AMAGenericRequest *__block request = nil;
    AMACurrentQueueExecutor *__block executor = nil;
    AMAHTTPRequestsFactory *__block httpRequestsFactory = nil;
    AMAArrayIterator *__block hostProvider = nil;
    NSObject<AMAHostExchangeResponseValidating> *__block responseValidator = nil;
    AMAHostExchangeRequestProcessor *__block processor = nil;

    beforeEach(^{
        urlRequest = [NSURLRequest nullMock];
        
        request = [[AMAGenericRequest alloc] init];
        [request stub:@selector(buildURLRequest) andReturn:urlRequest];
        httpRequestor = [[AMAHTTPRequestor alloc] initWithRequest:request];

        executor = [[AMACurrentQueueExecutor alloc] init];
        httpRequestsFactory = [[AMAHTTPRequestsFactory alloc] init];
        [httpRequestsFactory stub:@selector(requestorForRequest:) andReturn:httpRequestor];
        hostProvider = [[AMAArrayIterator alloc] initWithArray:hosts];
        responseValidator = [KWMock nullMockForProtocol:@protocol(AMAHostExchangeResponseValidating)];
        [responseValidator stub:@selector(isResponseValidWithData:) andReturn:theValue(YES)];
        processor = [[AMAHostExchangeRequestProcessor alloc] initWithRequest:request
                                                                    executor:executor
                                                                hostProvider:hostProvider
                                                           responseValidator:responseValidator
                                                         httpRequestsFactory:httpRequestsFactory];
    });

    context(@"Start request", ^{
        it(@"Should build request with first host", ^{
            [[request should] receive:@selector(buildURLRequest)];

            [processor processWithCallback:nil];

            [[theValue(request.host) shouldEventually] equal:theValue(hosts.firstObject)];
        });
        it(@"Should request HTTP request", ^{
            [[httpRequestsFactory should] receive:@selector(requestorForRequest:) withArguments:request];

            [processor processWithCallback:nil];
        });
        it(@"Should set delegate", ^{
            [[httpRequestor should] receive:@selector(setDelegate:) withArguments:processor];

            [processor processWithCallback:nil];
        });
        it(@"Should set executor", ^{
            [[httpRequestor should] receive:@selector(setDelegateExecutor:) withArguments:executor];
            [processor processWithCallback:nil];
        });
        it(@"Should start HTTP request", ^{
            [[httpRequestor should] receive:@selector(start)];
            [processor processWithCallback:nil];
        });
        it(@"Should not call callback", ^{
            BOOL __block isCalled = NO;
            [processor processWithCallback:^(NSError *error) {
                isCalled = YES;
            }];
            [[theValue(isCalled) should] beNo];
        });
        it(@"Should not start request if host is nil", ^{
            [hostProvider stub:@selector(current) andReturn:nil];

            [[httpRequestsFactory shouldNot] receive:@selector(requestorForRequest:)];
        });
    });
    context(@"HTTP callback", ^{
        BOOL __block isCallbackCalled = NO;
        NSError *__block callbackError = nil;
        beforeEach(^{
            isCallbackCalled = NO;
            callbackError = nil;
            [processor processWithCallback:^(NSError *error) {
                isCallbackCalled = YES;
                callbackError = error;
            }];
        });
        context(@"Success", ^{
            beforeEach(^{
                httpRequestor = [[AMAHTTPRequestor alloc] initWithRequest:request];
                [httpRequestsFactory stub:@selector(requestorForRequest:) andReturn:httpRequestor];
            });
            NSData *const data = [@"DATA" dataUsingEncoding:NSUTF8StringEncoding];
            context(@"200", ^{
                NSHTTPURLResponse *const response =
                [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:hosts.firstObject]
                                            statusCode:200
                                           HTTPVersion:(__bridge NSString *)kCFHTTPVersion1_1
                                          headerFields:nil];

                context(@"Valid data", ^{
                    it(@"Should not build request", ^{
                        [[request shouldNot] receive:@selector(buildURLRequest)];
                        [processor httpRequestor:httpRequestor didFinishWithData:data response:response];
                    });
                    it(@"Should call callback with no error", ^{
                        [processor httpRequestor:httpRequestor didFinishWithData:data response:response];
                        [[theValue(isCallbackCalled) should] beYes];
                        [[callbackError should] beNil];
                    });
                });
                context(@"Invalid data", ^{
                    beforeEach(^{
                        [responseValidator stub:@selector(isResponseValidWithData:) andReturn:theValue(NO)];
                    });

                    it(@"Should not call callback", ^{
                        [processor httpRequestor:httpRequestor didFinishWithData:data response:response];
                        [[theValue(isCallbackCalled) should] beNo];
                    });
                    it(@"Should build request with second host", ^{
                        [[request should] receive:@selector(buildURLRequest)];

                        [processor httpRequestor:httpRequestor didFinishWithData:data response:response];

                        [[theValue(request.host) shouldEventually] equal:theValue(hosts.lastObject)];
                    });
                });
            });
            context(@"500", ^{
                NSHTTPURLResponse *const response =
                [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:hosts.firstObject]
                                            statusCode:500
                                           HTTPVersion:(__bridge NSString *)kCFHTTPVersion1_1
                                          headerFields:nil];

                it(@"Should not call callback", ^{
                    [processor httpRequestor:httpRequestor didFinishWithData:data response:response];
                    [[theValue(isCallbackCalled) should] beNo];
                });
                it(@"Should build request with second host", ^{
                    [[request should] receive:@selector(buildURLRequest)];
                    
                    [processor httpRequestor:httpRequestor didFinishWithData:data response:response];

                    [[theValue(request.host) shouldEventually] equal:theValue(hosts.lastObject)];
                });
            });
        });
        context(@"Failure", ^{
            beforeEach(^{
                httpRequestor = [[AMAHTTPRequestor alloc] initWithRequest:request];
                [httpRequestsFactory stub:@selector(requestorForRequest:) andReturn:httpRequestor];
            });

            NSError *const networkError = [NSError errorWithDomain:NSURLErrorDomain
                                                              code:NSURLErrorBadServerResponse
                                                          userInfo:nil];

            it(@"Should not call callback", ^{
                [processor httpRequestor:httpRequestor didFinishWithError:networkError response:nil];
                [[theValue(isCallbackCalled) should] beNo];
            });
            it(@"Should build request with second host", ^{
                [[request should] receive:@selector(buildURLRequest)];

                [processor httpRequestor:httpRequestor didFinishWithError:networkError response:nil];

                [[theValue(request.host) shouldEventually] equal:theValue(hosts.lastObject)];
            });
            it(@"Should request HTTP request", ^{
                [[httpRequestsFactory should] receive:@selector(requestorForRequest:) withArguments:request];
                [processor httpRequestor:httpRequestor didFinishWithError:networkError response:nil];
            });
            it(@"Should set delegate", ^{
                [[httpRequestor should] receive:@selector(setDelegate:) withArguments:processor];
                [processor httpRequestor:httpRequestor didFinishWithError:networkError response:nil];
            });
            it(@"Should set executor", ^{
                [[httpRequestor should] receive:@selector(setDelegateExecutor:) withArguments:executor];
                [processor httpRequestor:httpRequestor didFinishWithError:networkError response:nil];
            });
            it(@"Should start HTTP request", ^{
                [[httpRequestor should] receive:@selector(start)];
                [processor httpRequestor:httpRequestor didFinishWithError:networkError response:nil];
            });

            context(@"Last failure", ^{
                beforeEach(^{
                    [processor httpRequestor:httpRequestor didFinishWithError:networkError response:nil];
                });

                it(@"Should not build request", ^{
                    [[request shouldNot] receive:@selector(buildURLRequest)];
                    [processor httpRequestor:httpRequestor didFinishWithError:networkError response:nil];
                });
                it(@"Should call callback with error", ^{
                    NSError *expectedError = [NSError errorWithDomain:kAMAHostExchangeRequestProcessorErrorDomain
                                                                 code:AMAHostExchangeRequestProcessorNetworkError
                                                             userInfo:@{ NSUnderlyingErrorKey: networkError }];
                    [processor httpRequestor:httpRequestor didFinishWithError:networkError response:nil];
                    [[callbackError should] equal:expectedError];
                });
            });
        });
    });

});

SPEC_END
