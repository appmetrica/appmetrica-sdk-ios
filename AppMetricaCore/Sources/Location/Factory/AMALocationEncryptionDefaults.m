
#import "AMALocationEncryptionDefaults.h"

@implementation AMALocationEncryptionDefaults

+ (NSData *)message
{
    static NSData *messageData = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        const unsigned char data[] = {
            0x04, 0xf3, 0x88, 0x78, 0x96, 0xe0, 0x48, 0x7f,
            0x86, 0x7c, 0x0d, 0xe4, 0x45, 0xea, 0x0a, 0x11,
        };
        messageData = [NSData dataWithBytes:data length:sizeof(data)];
    });
    return messageData;
}

@end
