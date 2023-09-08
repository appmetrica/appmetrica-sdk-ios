
#import <Foundation/Foundation.h>

@protocol AMADataEncoding <NSObject>

- (NSData *)encodeData:(NSData *)data error:(NSError **)error;
- (NSData *)decodeData:(NSData *)data error:(NSError **)error;

@end
