
#import <AppMetricaEncodingUtils/AppMetricaEncodingUtils.h>
#import "AMAReporterDatabaseEncodersFactory.h"

@implementation AMAReporterDatabaseEncodersFactory

#pragma mark - Publc -

+ (AMAReporterDatabaseEncryptionType)eventDataEncryptionType
{
    return AMAReporterDatabaseEncryptionTypeGZipAES;
}

+ (AMAReporterDatabaseEncryptionType)sessionDataEncryptionType
{
    return AMAReporterDatabaseEncryptionTypeAES;
}

+ (id<AMADataEncoding>)encoderForEncryptionType:(AMAReporterDatabaseEncryptionType)encryptionType
{
    switch (encryptionType) {
        case AMAReporterDatabaseEncryptionTypeAES:
            return [self aesEncoder];

        case AMAReporterDatabaseEncryptionTypeGZipAES:
            return [self gZipAESEncoder];
            
        default:
            return nil;
    }
}

#pragma mark - Publc -

+ (id<AMADataEncoding>)aesEncoder
{
    return [[AMAAESCrypter alloc] initWithKey:[self firstMessage] iv:[AMAAESUtility defaultIv]];
}

+ (id<AMADataEncoding>)gZipAESEncoder
{
    return [[AMACompositeDataEncoder alloc] initWithEncoders:@[
        [[AMAGZipDataEncoder alloc] init],
        [[AMAAESCrypter alloc] initWithKey:[self secondMessage] iv:[AMAAESUtility defaultIv]],
    ]];
}

+ (NSData *)firstMessage
{
    const unsigned char data[] = {
        0x8e, 0xed, 0x7f, 0x8d, 0x98, 0x84, 0x40, 0x45, 0x93, 0x3e, 0x98, 0x6e, 0x41, 0x2a, 0xe9, 0x2b,
    };
    return [NSData dataWithBytes:data length:16];
}

+ (NSData *)secondMessage
{
    const unsigned char data[] = {
        0xaf, 0x9d, 0xca, 0x1b, 0xe7, 0x9a, 0x41, 0x97, 0xa0, 0x4b, 0x42, 0x24, 0x28, 0x50, 0xc6, 0xc2,
    };
    return [NSData dataWithBytes:data length:16];
}

@end
