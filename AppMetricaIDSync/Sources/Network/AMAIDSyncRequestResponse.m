
#import "AMAIDSyncRequestResponse.h"
#import "AMAIDSyncRequest.h"

@implementation AMAIDSyncRequestResponse

- (instancetype)initWithRequest:(AMAIDSyncRequest *)request
                           code:(NSInteger)code
                           body:(nullable NSString *)body
                        headers:(nullable NSDictionary<NSString *, NSArray<NSString *> *> *)headers
                    responseURL:(NSString *)responseURL
{
    self = [super init];
    if (self) {
        _request = request;
        _code = code;
        _body = [body copy];
        _headers = [headers copy];
        _responseURL = [responseURL copy];
    }
    return self;
}

@end
