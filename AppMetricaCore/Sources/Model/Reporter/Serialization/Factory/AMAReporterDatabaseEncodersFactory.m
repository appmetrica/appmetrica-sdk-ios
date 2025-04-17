
#import <AppMetricaEncodingUtils/AppMetricaEncodingUtils.h>
#import "AMAReporterDatabaseEncodersFactory.h"
#import "AMAAESUtility+Migration.h"
#import "AMAMigrationTo500Utils.h"
#import "AMAReporterDatabaseEncryptionDefaults.h"

@implementation AMAReporterDatabaseEncodersFactory

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
                                           iv:[AMAAESUtility defaultIv]];
}

- (id<AMADataEncoding>)gZipAESEncoder
{
    return [[AMACompositeDataEncoder alloc] initWithEncoders:@[
        [[AMAGZipDataEncoder alloc] init],
        [[AMAAESCrypter alloc] initWithKey:[AMAReporterDatabaseEncryptionDefaults secondMessage]
                                        iv:[AMAAESUtility defaultIv]],
    ]];
}

@end
