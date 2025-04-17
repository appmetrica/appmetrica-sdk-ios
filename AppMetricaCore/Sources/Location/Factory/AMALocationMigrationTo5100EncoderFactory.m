
#import <AppMetricaEncodingUtils/AppMetricaEncodingUtils.h>
#import "AMALocationMigrationTo5100EncoderFactory.h"
#import "AMAAESUtility+Migration.h"
#import "AMAMigrationTo500Utils.h"
#import "AMALocationEncryptionDefaults.h"

@implementation AMALocationMigrationTo5100EncoderFactory

- (id<AMADataEncoding>)encoder
{
    return [[AMAAESCrypter alloc] initWithKey:[AMALocationEncryptionDefaults message] iv:[AMAAESUtility md5_migrationIv]];
}

@end
