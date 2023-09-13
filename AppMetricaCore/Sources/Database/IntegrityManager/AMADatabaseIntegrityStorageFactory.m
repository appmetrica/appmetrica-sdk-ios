
#import <AppMetricaEncodingUtils/AppMetricaEncodingUtils.h>
#import "AMADatabaseIntegrityStorageFactory.h"
#import "AMADatabaseIntegrityStorage.h"
#import "AMAKeyValueStorageProvidersFactory.h"
#import "AMAEncryptedFileStorage.h"

@implementation AMADatabaseIntegrityStorageFactory

+ (AMADatabaseIntegrityStorage *)storageForPath:(NSString *)path
{
    AMADiskFileStorageOptions options = AMADiskFileStorageOptionCreateDirectory | AMADiskFileStorageOptionNoBackup;
    id<AMAFileStorage> diskFileStorage = [[AMADiskFileStorage alloc] initWithPath:path options:options];
    id<AMADataEncoding> encoder = [[AMAAESCrypter alloc] initWithKey:[self message]
                                                                  iv:[AMAAESUtility defaultIv]];
    id<AMAFileStorage> fileStorage = [[AMAEncryptedFileStorage alloc] initWithUnderlyingStorage:diskFileStorage
                                                                                        encoder:encoder];
    id<AMAKeyValueStorageProviding> storageProvider =
        [AMAKeyValueStorageProvidersFactory jsonFileProviderForFileStorage:fileStorage];
    return [[AMADatabaseIntegrityStorage alloc] initWithStorageProvider:storageProvider];
}

+ (NSData *)message
{
    const unsigned char data[] = {
        0x83, 0xd6, 0x66, 0x9f, 0x98, 0x05, 0x47, 0x5c, 0xb4, 0x04, 0xc5, 0x52, 0xbc, 0x92, 0x25, 0xad,
    };
    return [NSData dataWithBytes:data length:16];
}

@end
