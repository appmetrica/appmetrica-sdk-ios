
#import <Foundation/Foundation.h>

@protocol AMAHostExchangeResponseValidating <NSObject>

- (BOOL)isResponseValidWithData:(NSData *)data;

@end
