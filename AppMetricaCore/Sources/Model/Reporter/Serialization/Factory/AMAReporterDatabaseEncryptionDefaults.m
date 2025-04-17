
#import "AMAReporterDatabaseEncryptionDefaults.h"

@implementation AMAReporterDatabaseEncryptionDefaults

+ (AMAReporterDatabaseEncryptionType)eventDataEncryptionType
{
    return AMAReporterDatabaseEncryptionTypeGZipAES;
}

+ (AMAReporterDatabaseEncryptionType)sessionDataEncryptionType
{
    return AMAReporterDatabaseEncryptionTypeAES;
}

+ (NSData *)firstMessage
{
    static NSData *firstMessageData = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        const unsigned char data[] = {
            0x8e, 0xed, 0x7f, 0x8d, 0x98, 0x84, 0x40, 0x45,
            0x93, 0x3e, 0x98, 0x6e, 0x41, 0x2a, 0xe9, 0x2b,
        };
        firstMessageData = [NSData dataWithBytes:data length:sizeof(data)];
    });
    return firstMessageData;
}

+ (NSData *)secondMessage
{
    static NSData *secondMessageData = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        const unsigned char data[] = {
            0xaf, 0x9d, 0xca, 0x1b, 0xe7, 0x9a, 0x41, 0x97,
            0xa0, 0x4b, 0x42, 0x24, 0x28, 0x50, 0xc6, 0xc2,
        };
        secondMessageData = [NSData dataWithBytes:data length:sizeof(data)];
    });
    return secondMessageData;
}

@end
