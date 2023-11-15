
#import <Foundation/Foundation.h>
#import <AppMetrica_Protobuf/AppMetrica_Protobuf.h>

NS_SWIFT_NAME(ProtobufAllocator)
@interface AMAProtobufAllocator : NSObject

- (ProtobufCAllocator *)protobufCAllocator;

@end
