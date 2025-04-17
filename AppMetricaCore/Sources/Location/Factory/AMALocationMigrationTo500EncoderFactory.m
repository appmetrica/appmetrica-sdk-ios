
#import <AppMetricaEncodingUtils/AppMetricaEncodingUtils.h>
#import "AMALocationMigrationTo500EncoderFactory.h"
#import "AMAAESUtility+Migration.h"
#import "AMAMigrationTo500Utils.h"
#import "AMALocationEncryptionDefaults.h"

@implementation AMALocationMigrationTo500EncoderFactory

- (id<AMADataEncoding>)encoder
{
    return [[AMAAESCrypter alloc] initWithKey:[AMALocationEncryptionDefaults message]
                                           iv:[AMAAESUtility migrationIv:kAMAMigrationBundle]];
}

@end
