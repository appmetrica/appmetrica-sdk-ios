
#import <AppMetricaNetwork/AppMetricaNetwork.h>
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>

@implementation AMAHTTPRequestResponseStub

- (instancetype)initWithReponseType:(AMAHTTPRequestsMockResponseType)responseType
                           response:(NSHTTPURLResponse *)response
                         statusCode:(NSInteger)statusCode
                              error:(NSError *)error
                             result:(NSData *)result
{
    self = [super init];
    if (self != nil) {
        _responseType = responseType;
        _response = response;
        _statusCode = statusCode;
        _error = error;
        _result = [result copy];
    }
    return self;
}

+ (instancetype)noResponse
{
    return [[[self class] alloc] initWithReponseType:AMAHTTPRequestsMockResponseTypeNoResponse
                                            response:nil
                                          statusCode:0
                                               error:nil
                                              result:nil];
}

+ (instancetype)successWithCode:(NSInteger)code data:(NSData *)data
{
    return [self successWithCode:code data:data headers:nil];
}

+ (instancetype)successWithCode:(NSInteger)code data:(NSData *)data headers:(NSDictionary *)headers
{
    NSString *anyHost = @"https://appmetrica.io/any";
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:anyHost]
                                                              statusCode:code
                                                             HTTPVersion:(__bridge NSString *)kCFHTTPVersion1_1
                                                            headerFields:headers];
    return [[[self class] alloc] initWithReponseType:AMAHTTPRequestsMockResponseTypeSuccess
                                            response:response
                                          statusCode:code
                                               error:nil
                                              result:data];
}

+ (instancetype)failureWithCode:(NSInteger)code error:(NSError *)error
{
    return [[[self class] alloc] initWithReponseType:AMAHTTPRequestsMockResponseTypeFailure
                                            response:nil
                                          statusCode:code
                                               error:error
                                              result:nil];
}

@end

#pragma mark - AMAHTTPRequestorMock -

@interface AMAHTTPRequestorMock : AMAHTTPRequestor

@property (nonatomic, copy, readonly) AMAHTTPRequestResponseBlock pendingStubBlock;
@property (nonatomic, strong) AMAHTTPRequestResponseStub *actualStub;

@end

@implementation AMAHTTPRequestorMock

- (instancetype)initWithRequest:(id<AMARequest>)request stubBlock:(AMAHTTPRequestResponseBlock)stubBlock
{
    self = [super initWithRequest:request];
    if (self != nil) {
        _pendingStubBlock = [stubBlock copy];
    }
    return self;
}

- (void)start
{
    NSURL *url = [self urlForRequest:self.request];
    self.actualStub = self.pendingStubBlock(url, self.request.headerComponents);
    NSHTTPURLResponse *response = self.actualStub.response;
    if (response == nil) {
        response = [[NSHTTPURLResponse alloc] initWithURL:url
                                               statusCode:self.actualStub.statusCode
                                              HTTPVersion:@"1.1"
                                             headerFields:nil];
    }

    switch (self.actualStub.responseType) {
        case AMAHTTPRequestsMockResponseTypeNoResponse:
            // Do nothing
            break;
        case AMAHTTPRequestsMockResponseTypeSuccess:
            [self.delegate httpRequestor:self
                       didFinishWithData:self.actualStub.result
                                response:response];
            break;
        case AMAHTTPRequestsMockResponseTypeFailure:
            [self.delegate httpRequestor:self
                      didFinishWithError:self.actualStub.error
                                response:response];
            break;
    }
}

- (NSURL *)urlForRequest:(id<AMARequest>)request
{
    if (request.host == nil) {
        return nil;
    }
    return [AMAURLUtilities URLWithBaseURLString:request.host
                                  pathComponents:[[request pathComponents] copy]
                               httpGetParameters:[[request GETParameters] copy]];
}

@end

#pragma mark - AMAHTTPRequestsFactoryMock -

@interface AMAHTTPRequestsFactoryMock ()

@property (nonatomic, strong) NSMutableDictionary *stubs;
@property (nonatomic, strong) NSMutableDictionary *blockStubs;
@property (nonatomic, copy) AMAHTTPRequestResponseBlock globalStub;
@property (nonatomic, strong) NSMutableDictionary *requestsCount;

@end

@implementation AMAHTTPRequestsFactoryMock

- (instancetype)init
{
    self = [super init];
    if (self != nil) {
        _stubs = [NSMutableDictionary dictionary];
        _requestsCount = [NSMutableDictionary dictionary];
    }
    return self;
}

+ (AMAHTTPRequestResponseBlock)defaultStubBlock
{
    return ^(NSURL *url, NSDictionary *headers) {
        return [AMAHTTPRequestResponseStub successWithCode:200 data:[NSData data]];
    };
}

- (AMAHTTPRequestor *)requestorForRequest:(id<AMARequest>)request
{
    NSString *host = request.host;
    AMAHTTPRequestResponseBlock stubbedResponseBlock = self.globalStub;
    if (stubbedResponseBlock == nil) {
        stubbedResponseBlock = self.stubs[host];
        if (stubbedResponseBlock == nil) {
            stubbedResponseBlock = [[self class] defaultStubBlock];
        }
    }

    if (host != nil) {
        self.requestsCount[host] = @([(self.requestsCount[host] ?: @0) unsignedIntegerValue] + 1);
    }

    AMAHTTPRequestorMock *httpRequestor = [[AMAHTTPRequestorMock alloc] initWithRequest:request
                                                                              stubBlock:stubbedResponseBlock];
    return httpRequestor;
}

- (void)stub:(AMAHTTPRequestResponseStub *)stub forHost:(NSString *)host
{
    [self stubHost:host withBlock:^(NSURL *url, NSDictionary *headers) {
        return stub;
    }];
}

- (void)stubAll:(AMAHTTPRequestResponseStub *)stub
{
    [self stubAllWithBlock:^(NSURL *url, NSDictionary *headers) {
        return stub;
    }];
}

- (void)stubHost:(NSString *)host withBlock:(AMAHTTPRequestResponseBlock)block
{
    self.stubs[host] = [block copy];
}

- (void)stubAllWithBlock:(AMAHTTPRequestResponseBlock)block
{
    self.globalStub = block;
}

- (NSUInteger)countOfRequestsForHost:(NSString *)host
{
    return [(self.requestsCount[host] ?: @0) unsignedIntegerValue];
}

@end
