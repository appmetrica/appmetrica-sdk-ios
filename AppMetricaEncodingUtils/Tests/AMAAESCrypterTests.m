
#import <Kiwi/Kiwi.h>
#import <AppMetricaEncodingUtils/AppMetricaEncodingUtils.h>

SPEC_BEGIN(AMAAESCrypterTests)

describe(@"AMAAESCrypter", ^{

    /*
     This sample data was generated with this bash code:

     printf 'TEST DATA'
     | openssl enc -e -aes-128-cbc -K '6f66207369787465656e206279746573' -iv '73616d652073697a6564206279746573'
     | base64
     */

    NSData *const key = [@"of sixteen bytes" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *const iv = [@"same sized bytes" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *const data = [@"TEST DATA" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *const expectedEncryptedData = [[NSData alloc] initWithBase64EncodedString:@"1KO3EGkqUX6/dB5vGMeJVg=="
                                                                              options:0];
    AMAAESCrypter *__block crypter = nil;

    beforeEach(^{
        crypter = [[AMAAESCrypter alloc] initWithKey:key iv:iv];
    });

    it(@"Should encode data", ^{
        NSData *encodedData = [crypter encodeData:data error:NULL];
        NSData *decodedData = [crypter decodeData:encodedData error:NULL];
        [[decodedData should] equal:data];
    });
    it(@"Should decode data", ^{
        NSData *encodedData = expectedEncryptedData;
        NSData *decodedData = [crypter decodeData:encodedData error:NULL];
        [[decodedData should] equal:data];
    });

});

SPEC_END
