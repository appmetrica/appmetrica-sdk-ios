
#import "AMAIDSyncRequest.h"

@implementation AMAIDSyncRequest

- (instancetype)initWithType:(NSString *)type
                         url:(NSString *)url
                     headers:(NSDictionary *)headers
               preconditions:(NSDictionary *)preconditions
         validResendInterval:(NSNumber *)resendIntervalForValidResponse
       invalidResendInterval:(NSNumber *)resendIntervalForNotValidResponse
          validResponseCodes:(NSArray<NSNumber *> *)validResponseCodes
{
    self = [super init];
    if (self) {
        _type = [type copy];
        _url = [url copy];
        _headers = [headers copy] ?: @{};
        _preconditions = [preconditions copy] ?: @{};
        _resendIntervalForValidResponse = [resendIntervalForValidResponse copy];
        _resendIntervalForNotValidResponse = [resendIntervalForNotValidResponse copy];
        _validResponseCodes = [validResponseCodes copy];
    }
    return self;
}

@end
