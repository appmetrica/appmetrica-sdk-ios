
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import <AppMetricaNetwork/AppMetricaNetwork.h>

SPEC_BEGIN(AMAHTTPRequestorTests)

describe(@"AMAHTTPRequestor", ^{

    NSString *const host = @"http://appmetrica.io";
    NSURL *const url = [NSURL URLWithString:host];

    AMAHTTPSessionProviderMock *__block sessionProvider = nil;
    NSObject<AMAHTTPRequestDelegate> *__block delegate = nil;
    NSURLRequest *__block urlRequest = nil;
    AMAHTTPRequestor *__block requestor = nil;
    AMAGenericRequest *__block request = nil;

    beforeEach(^{
        sessionProvider = [[AMAHTTPSessionProviderMock alloc] init];
        delegate = [KWMock nullMockForProtocol:@protocol(AMAHTTPRequestDelegate)];
        request = [[AMAGenericRequest alloc] init];
        request.host = host;
        urlRequest = [request buildURLRequest];
        requestor = [[AMAHTTPRequestor alloc] initWithRequest:request sessionProvider:sessionProvider];
        requestor.delegate = delegate;
    });
    afterEach(^{
        [[NSAssertionHandler currentHandler] clearStubs];
    });
    
    it(@"Should not start cancelled request", ^{
        [[NSAssertionHandler currentHandler] stub:@selector(handleFailureInMethod:object:file:lineNumber:description:)];
        [[sessionProvider shouldNot] receive:@selector(session)];
        [requestor cancel];
        [requestor start];
    });

    context(@"Start request", ^{

        AMAURLSessionDataTaskMock *__block currentTask = nil;
        beforeEach(^{
            [requestor start];
            currentTask = sessionProvider.sessionMock.createdTasks.lastObject;
        });

        it(@"Should create only one task", ^{
            [[sessionProvider.sessionMock.createdTasks should] haveCountOf:1];
        });
        it(@"Should start task task", ^{
            [[theValue(currentTask.started) should] beYes];
        });
        it(@"Should not cancel task", ^{
            [[theValue(currentTask.cancelled) should] beNo];
        });
        it(@"Should use same URLRequest", ^{
            [[currentTask.request should] equal:urlRequest];
        });
        context(@"Second start", ^{
            it(@"Should not create second task", ^{
                [[NSAssertionHandler currentHandler] stub:@selector(handleFailureInMethod:object:file:lineNumber:description:)];
                [requestor start];
                [[sessionProvider.sessionMock.createdTasks should] haveCountOf:1];
            });
            it(@"Should not resume current task", ^{
                [[NSAssertionHandler currentHandler] stub:@selector(handleFailureInMethod:object:file:lineNumber:description:)];
                [[currentTask shouldNot] receive:@selector(resume)];
                [requestor start];
            });
        });
        context(@"Cancel", ^{
            it(@"Should cancel task", ^{
                [[currentTask should] receive:@selector(cancel)];
                [requestor cancel];
            });
            it(@"Should not resume task after second start", ^{
                [[NSAssertionHandler currentHandler] stub:@selector(handleFailureInMethod:object:file:lineNumber:description:)];
                [[currentTask shouldNot] receive:@selector(resume)];
                [requestor cancel];
                [requestor start];
            });
        });
        context(@"Completion", ^{
            NSData *__block data = nil;

            beforeEach(^{
                data = [NSData data];
            });

            it(@"Should call success on 200", ^{
                NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:url
                                                                          statusCode:200
                                                                         HTTPVersion:@"1.1"
                                                                        headerFields:@{}];
                [[delegate should] receive:@selector(httpRequestor:didFinishWithData:response:)
                             withArguments:requestor, data, response];
                currentTask.callback(data, response, nil);
            });
            it(@"Should call success on 400", ^{
                NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:url
                                                                          statusCode:400
                                                                         HTTPVersion:@"1.1"
                                                                        headerFields:@{}];
                [[delegate should] receive:@selector(httpRequestor:didFinishWithData:response:)
                             withArguments:requestor, data, response];
                currentTask.callback(data, response, nil);
            });
            it(@"Should call error on network error", ^{
                NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:url
                                                                          statusCode:0
                                                                         HTTPVersion:@"1.1"
                                                                        headerFields:@{}];
                NSError *error = [NSError errorWithDomain:NSURLErrorDomain
                                                     code:NSURLErrorNotConnectedToInternet
                                                 userInfo:nil];
                [[delegate should] receive:@selector(httpRequestor:didFinishWithError:response:)
                             withArguments:requestor, error, response];
                currentTask.callback(nil, response, error);
            });
            it(@"Should contain nil response if it is not NSHTTPURLResponse", ^{
                NSURLResponse *response = [[NSURLResponse alloc] initWithURL:url
                                                                    MIMEType:@"application/json"
                                                       expectedContentLength:0
                                                            textEncodingName:@"utf8"];
                [[delegate should] receive:@selector(httpRequestor:didFinishWithError:response:)
                             withArguments:requestor, kw_any(), nil];
                currentTask.callback(data, response, nil);
            });

            context(@"Executor", ^{
                AMACurrentQueueExecutor *__block executor = nil;

                beforeEach(^{
                    executor = [KWMock nullMockForProtocol:@protocol(AMAAsyncExecuting)];
                    requestor.delegateExecutor = executor;
                });

                it(@"Should call success with executor", ^{
                    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:url
                                                                              statusCode:200
                                                                             HTTPVersion:@"1.1"
                                                                            headerFields:@{}];
                    [[executor should] receive:@selector(execute:)];
                    currentTask.callback(data, response, nil);
                });
                it(@"Should not bypass executor on success", ^{
                    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:url
                                                                              statusCode:200
                                                                             HTTPVersion:@"1.1"
                                                                            headerFields:@{}];
                    [[delegate shouldNot] receive:@selector(httpRequestor:didFinishWithError:response:)];
                    currentTask.callback(data, response, nil);
                });
                it(@"Should call error with executor", ^{
                    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:url
                                                                              statusCode:400
                                                                             HTTPVersion:@"1.1"
                                                                            headerFields:@{}];
                    [[executor should] receive:@selector(execute:)];
                    currentTask.callback(data, response, nil);
                });
                it(@"Should not bypass executor on error", ^{
                    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:url
                                                                              statusCode:400
                                                                             HTTPVersion:@"1.1"
                                                                            headerFields:@{}];
                    [[delegate shouldNot] receive:@selector(httpRequestor:didFinishWithError:response:)];
                    currentTask.callback(data, response, nil);
                });
            });
        });
    });

});

SPEC_END

