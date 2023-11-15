
#import <Foundation/Foundation.h>

NS_SWIFT_NAME(TestNetwork)
@interface AMATestNetwork : NSObject

+ (void)stubHTTPRequestToFinishWithError:(NSError *)error;
+ (void)stubHTTPRequestWithBlock:(id (^)(NSArray *params))block;
+ (void)stubNetworkRequestWithBlock:(id (^)(NSArray *params))block;
+ (void)stubNetworkRequestWithStatusCode:(NSInteger)statusCode block:(dispatch_block_t)block;
+ (void)clearNetworkRequestIndex;
+ (void)stubNetworkRequestWithStatusCodes:(NSArray *)statusCodes block:(dispatch_block_t)block;

@end
