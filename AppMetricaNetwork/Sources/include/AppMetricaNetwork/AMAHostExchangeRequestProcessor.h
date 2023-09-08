
#import <Foundation/Foundation.h>

@class AMAHTTPRequestsFactory;
@protocol AMARequest;
@protocol AMAExecuting;
@protocol AMAIterable;
@protocol AMAHostExchangeResponseValidating;

extern NSString *const kAMAHostExchangeRequestProcessorErrorDomain;

typedef NS_ENUM(NSInteger, AMAHostExchangeRequestProcessorErrorCode) {
    AMAHostExchangeRequestProcessorNetworkError,
    AMAHostExchangeRequestProcessorBadRequest,
};

typedef void(^AMAHostExchangeRequestProcessorCallback)(NSError *error);

@interface AMAHostExchangeRequestProcessor : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithRequest:(id<AMARequest>)request
                       executor:(id<AMAExecuting>)executor
                   hostProvider:(id<AMAIterable>)hostProvider
              responseValidator:(id<AMAHostExchangeResponseValidating>)responseValidator;
- (instancetype)initWithRequest:(id<AMARequest>)request
                       executor:(id<AMAExecuting>)executor
                   hostProvider:(id<AMAIterable>)hostProvider
              responseValidator:(id<AMAHostExchangeResponseValidating>)responseValidator
            httpRequestsFactory:(AMAHTTPRequestsFactory *)httpRequestsFactory;

- (void)processWithCallback:(AMAHostExchangeRequestProcessorCallback)callback;

@end
