
#import "AMAIDSyncNetworkRequest.h"

@interface AMAIDSyncNetworkRequest ()

@property (nonatomic, copy, readonly) NSDictionary<NSString *, NSArray *> *headers;

@end

@implementation AMAIDSyncNetworkRequest

- (instancetype)initWithURL:(NSString *)url headers:(NSDictionary *)headers
{
    self = [super init];
    if (self) {
        _headers = [headers copy];
        self.host = [url copy];
    }
    return self;
}

- (NSString *)method
{
    return @"GET";
}

- (NSDictionary *)headerComponents
{
    NSMutableDictionary *headers = [super headerComponents].mutableCopy;
    [self.headers enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSArray<NSString *> *values, BOOL *stop) {
        if ([values isKindOfClass:[NSArray class]] && values.count > 0) {
            NSString *joined = [values componentsJoinedByString:@", "];
            [headers setValue:joined forKey:key];
        }
    }];
    return headers.copy;
}

@end
