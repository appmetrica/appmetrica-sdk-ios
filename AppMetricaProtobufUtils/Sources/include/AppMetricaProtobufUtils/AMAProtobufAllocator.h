
#import <Foundation/Foundation.h>
#import <protobuf-c/protobuf-c.h>

@interface AMAProtobufAllocator : NSObject

- (ProtobufCAllocator *)protobufCAllocator;

@end
