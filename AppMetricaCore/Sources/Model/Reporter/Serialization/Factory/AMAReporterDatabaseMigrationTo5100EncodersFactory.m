
#import <AppMetricaEncodingUtils/AppMetricaEncodingUtils.h>
#import "AMAReporterDatabaseMigrationTo5100EncodersFactory.h"
#import "AMAAESUtility+Migration.h"
#import "AMAMigrationTo500Utils.h"
#import "AMAReporterDatabaseEncryptionDefaults.h"

@implementation AMAReporterDatabaseMigrationTo5100EncodersFactory

#pragma mark - Publc -

- (id<AMADataEncoding>)encoderForEncryptionType:(AMAReporterDatabaseEncryptionType)encryptionType
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

#pragma mark - Private -

- (id<AMADataEncoding>)aesEncoder
{
    return [[AMAAESCrypter alloc] initWithKey:[AMAReporterDatabaseEncryptionDefaults firstMessage]
                                           iv:[AMAAESUtility md5_migrationIv]];
}

- (id<AMADataEncoding>)gZipAESEncoder
{
    return [[AMACompositeDataEncoder alloc] initWithEncoders:@[
        [[AMAGZipDataEncoder alloc] init],
        [[AMAAESCrypter alloc] initWithKey:[AMAReporterDatabaseEncryptionDefaults secondMessage]
                                        iv:[AMAAESUtility md5_migrationIv]],
    ]];
}

@end
