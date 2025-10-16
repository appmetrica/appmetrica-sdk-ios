
#import "AMAGenericRequestProcessor.h"
#import "AMANetworkCore.h"
#import <AppMetricaNetwork/AppMetricaNetwork.h>

static NSString *const kAMAPendingRequestKey = @"request";
static NSString *const kAMAPendingCallbackKey = @"callback";

@interface AMAGenericRequestProcessor () <AMAHTTPRequestDelegate>

@property (nonatomic, copy) AMAGenericRequestProcessorCallback callback;
@property (nonatomic, strong) AMAHTTPRequestor *currentRequestor;
@property (nonatomic, strong, readonly) AMAHTTPRequestsFactory *requestsFactory;

@property (nonatomic, strong) NSMutableArray<NSDictionary *> *pendingRequests;

@end

@implementation AMAGenericRequestProcessor

- (instancetype)init
{
    self = [super init];
    if (self != nil) {
        _requestsFactory = [[AMAHTTPRequestsFactory alloc] init];
        _pendingRequests = [NSMutableArray array];
    }
    return self;
}

- (void)processRequest:(id<AMARequest>)request
              callback:(AMAGenericRequestProcessorCallback)callback
{
    @synchronized (self) {
        if (self.currentRequestor != nil) {
            NSDictionary *pending = @{
                kAMAPendingRequestKey : request,
                kAMAPendingCallbackKey : [callback copy]
            };
            [self.pendingRequests addObject:pending];
            return;
        }
        [self startRequest:request callback:callback];
    }
}

#pragma mark - Private
- (void)startRequest:(id<AMARequest>)request
            callback:(AMAGenericRequestProcessorCallback)callback
{
    AMALogInfo(@"Processing HTTP request to %@", request.host);

    AMAHTTPRequestor *httpRequestor = [self.requestsFactory requestorForRequest:request];
    httpRequestor.delegate = self;

    self.currentRequestor = httpRequestor;
    self.callback = [callback copy];

    [httpRequestor start];
}

- (void)startNextPendingRequestIfNeeded
{
    @synchronized (self) {
        if (self.currentRequestor != nil || self.pendingRequests.count == 0) {
            return;
        }

        NSDictionary *next = [self.pendingRequests firstObject];
        [self.pendingRequests removeObjectAtIndex:0];

        id<AMARequest> request = next[kAMAPendingRequestKey];
        AMAGenericRequestProcessorCallback callback = next[kAMAPendingCallbackKey];

        [self startRequest:request callback:callback];
    }
}

#pragma mark - AMAHTTPRequestDelegate

- (void)httpRequestor:(AMAHTTPRequestor *)requestor
    didFinishWithData:(NSData *)data
             response:(NSHTTPURLResponse *)response
{
    AMALogInfo(@"Request finished with status %ld, data size %lu bytes",
               (long)response.statusCode,
               (unsigned long)data.length);

    AMAGenericRequestProcessorCallback syncCallback = nil;
    @synchronized (self) {
        syncCallback = self.callback;
        self.callback = nil;
        self.currentRequestor = nil;
    }

    if (syncCallback) {
        syncCallback(data, response, nil);
    }
    
    [self startNextPendingRequestIfNeeded];
}

- (void)httpRequestor:(AMAHTTPRequestor *)requestor
   didFinishWithError:(NSError *)error
             response:(NSHTTPURLResponse *)response
{
    AMALogInfo(@"Request failed with error: %@", error.localizedDescription);

    AMAGenericRequestProcessorCallback syncCallback = nil;
    @synchronized (self) {
        syncCallback = self.callback;
        self.callback = nil;
        self.currentRequestor = nil;
    }

    if (syncCallback) {
        syncCallback(nil, response, error);
    }
    
    [self startNextPendingRequestIfNeeded];
}

- (void)dealloc
{
    [self.pendingRequests removeAllObjects];
    self.pendingRequests = nil;
}

@end
