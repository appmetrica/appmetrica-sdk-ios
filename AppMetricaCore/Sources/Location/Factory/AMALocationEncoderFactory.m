
#import <AppMetricaEncodingUtils/AppMetricaEncodingUtils.h>
#import "AMALocationEncoderFactory.h"
#import "AMALocationEncryptionDefaults.h"

@implementation AMALocationEncoderFactory

- (id<AMADataEncoding>)encoder
{
    return [[AMAAESCrypter alloc] initWithKey:[AMALocationEncryptionDefaults message] iv:[AMAAESUtility defaultIv]];
}

@end
