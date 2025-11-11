
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import <AppMetricaNetwork/AppMetricaNetwork.h>
#import "AMAGenericRequestProcessor.h"

@interface AMAGenericRequestProcessor (Tests)<AMAHTTPRequestDelegate>
@end

SPEC_BEGIN(AMAGenericRequestProcessorTests)

describe(@"AMAGenericRequestProcessor", ^{
    AMAGenericRequestProcessor  *__block processor = nil;
    AMAHTTPRequestor *__block currentRequestor = nil;

    NSString *url = @"http://ya.ru";
    AMAGenericRequest *__block request = nil;

    BOOL __block callbackCalled = NO;
    NSData *__block resultData = nil;
    NSError *__block resultError = nil;
    NSHTTPURLResponse *__block resultResponse = nil;
    
    AMAGenericRequestProcessorCallback const callback =
    ^(NSData * _Nullable data,
      NSHTTPURLResponse * _Nullable response,
      NSError * _Nullable error) {
        callbackCalled = YES;
        resultData = data;
        resultError = error;
        resultResponse = response;
    };

    beforeEach(^{
        callbackCalled = NO;
        resultData = nil;
        resultError = nil;
        resultResponse = nil;

        request = [AMAGenericRequest stubbedNullMockForDefaultInit];
        currentRequestor = [AMAHTTPRequestor stubbedNullMockForInit:@selector(initWithRequest:)];

        processor = [[AMAGenericRequestProcessor alloc] init];
    });
    
    afterEach(^{
        [AMAGenericRequest clearStubs];
        [AMAHTTPRequestor clearStubs];
    });

    it(@"Should build http request with valid url", ^{
        [[currentRequestor should] receive:@selector(initWithRequest:) withArguments:request];
        [[currentRequestor should] receive:@selector(start)];

        [processor processRequest:request callback:callback];
    });

    it(@"Should callback with valid callback and response", ^{
        NSHTTPURLResponse *validResponse = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:url]
                                                                       statusCode:200
                                                                      HTTPVersion:@"HTTP/1.1"
                                                                     headerFields:nil];
        [processor processRequest:request callback:callback];
        [processor httpRequestor:currentRequestor
               didFinishWithData:[NSData nullMock]
                        response:validResponse];
        [[theValue(callbackCalled) should] beYes];
        [[theValue(resultResponse.statusCode) should] equal:theValue(200)];
    });

    it(@"Should callback with valid callback and error", ^{
        NSError *errorMock = [NSError nullMock];
        [processor processRequest:request callback:callback];
        [processor httpRequestor:currentRequestor
              didFinishWithError:errorMock
                        response:[NSHTTPURLResponse nullMock]];
        [[theValue(callbackCalled) should] beYes];
        [[resultError should] equal:errorMock];
        [[theValue(resultResponse.statusCode) shouldNot] equal:theValue(200)];
    });

    it(@"Should not process more than 1 request concurrent", ^{
        [[currentRequestor should] receive:@selector(start) withCount:1];
        [processor processRequest:request callback:callback];
        [processor processRequest:request callback:callback];
    });

    it(@"Should process new request after previous with success consecutively", ^{
        [[currentRequestor should] receive:@selector(start) withCount:2];
        [processor processRequest:request callback:callback];
        [processor httpRequestor:currentRequestor
               didFinishWithData:[NSData nullMock]
                        response:[NSHTTPURLResponse nullMock]];
        [processor processRequest:request callback:callback];
    });

    it(@"Should process new request after previous with error consecutively", ^{
        [[currentRequestor should] receive:@selector(start) withCount:2];
        [processor processRequest:request callback:callback];
        [processor httpRequestor:currentRequestor
              didFinishWithError:[NSError nullMock]
                        response:[NSHTTPURLResponse nullMock]];
        [processor processRequest:request callback:callback];
    });
    it(@"Should comform to AMAHTTPRequestDelegate", ^{
        [[processor should] conformToProtocol:@protocol(AMAHTTPRequestDelegate)];
    });
});

SPEC_END
