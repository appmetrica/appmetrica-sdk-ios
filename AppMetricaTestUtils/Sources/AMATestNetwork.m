
#import <Kiwi/Kiwi.h>
#import <AppMetricaNetwork/AppMetricaNetwork.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>

static NSUInteger AMATestNetworkRequestIndex = 0;

@implementation AMATestNetwork

+ (void)stubHTTPRequestToFinishWithError:(NSError *)error
{
    [AMAHTTPRequestor stub:@selector(requestorWithRequest:) withBlock:^id(NSArray *params) {
        AMAHTTPRequestor *httpRequestor = [[AMAHTTPRequestor alloc] initWithRequest:params[0]];

        [httpRequestor stub:@selector(start) withBlock:^id(NSArray *params){
            [httpRequestor.delegate httpRequestor:httpRequestor didFinishWithError:error response:nil];

            return nil;
        }];

        return httpRequestor;
    }];
}

+ (void)stubHTTPRequestWithBlock:(id (^)(NSArray *params))block
{
    [AMAHTTPRequestor stub:@selector(requestorWithRequest:) withBlock:^id(NSArray *params) {
        AMAHTTPRequestor *httpRequestor = [[AMAHTTPRequestor alloc] initWithRequest:params[0]];
        [httpRequestor stub:@selector(start) withBlock:block];

        return httpRequestor;
    }];
}

+ (void)stubNetworkRequestWithBlock:(id (^)(NSArray *params))block
{
    [NSURLConnection stub:@selector(sendAsynchronousRequest:queue:completionHandler:) withBlock:block];
}

+ (void)stubNetworkRequestWithStatusCode:(NSInteger)statusCode block:(dispatch_block_t)block
{
    [NSURLConnection stub:@selector(sendAsynchronousRequest:queue:completionHandler:) withBlock:^id(NSArray *params) {
        if (block != nil) {
            block();
        }
        void (^handler)(NSURLResponse* response, NSData* data, NSError* connectionError) = params[2];
        NSURLRequest *request = params[0];
        NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[request URL]
                                                                  statusCode:statusCode
                                                                 HTTPVersion:@"HTTP/1.1"
                                                                headerFields:nil];
        handler(response, nil, nil);
        return nil;
    }];
}

+ (void)clearNetworkRequestIndex
{
    AMATestNetworkRequestIndex = 0;
}

+ (void)stubNetworkRequestWithStatusCodes:(NSArray *)statusCodes block:(dispatch_block_t)block
{
    [NSURLConnection stub:@selector(sendAsynchronousRequest:queue:completionHandler:) withBlock:^id(NSArray *params) {
        if (block != nil) {
            block();
        }

        NSInteger statusCode = [statusCodes[AMATestNetworkRequestIndex] integerValue];
        void (^handler)(NSURLResponse* response, NSData* data, NSError* connectionError) = params[2];
        NSURLRequest *request = params[0];
        NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[request URL]
                                                                  statusCode:statusCode
                                                                 HTTPVersion:@"HTTP/1.1"
                                                                headerFields:nil];
        ++AMATestNetworkRequestIndex;
        NSString *responseString = @"<>";
        NSData *responseData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
        handler(response, responseData, nil);
        return nil;
    }];
}

+ (void)clearStubs
{
    [NSURLConnection clearStubs];
    [AMAHTTPRequestor clearStubs];
}

@end
