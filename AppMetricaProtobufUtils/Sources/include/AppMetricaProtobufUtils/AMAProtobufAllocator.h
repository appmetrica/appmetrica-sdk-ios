
#import <Foundation/Foundation.h>
#import <AppMetrica_Protobuf/AppMetrica_Protobuf.h>

@interface AMAProtobufAllocator : NSObject

- (ProtobufCAllocator *)protobufCAllocator;

@end
