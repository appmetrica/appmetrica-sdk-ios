
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaEncodingUtils/AppMetricaEncodingUtils.h>
#import "Utilities/AMACryptingHelper.h"

SPEC_BEGIN(AMARSAAESCrypterTests)

describe(@"AMARSAAESCrypter", ^{

    /*
     This sample data was generated with this bash code:

     openssl genrsa -out key.pem 1024
     openssl rsa -in key.pem -out key.pub -pubout

     cat key.pub
     cat key.pem
     function encode() {
         AES_KEY=$(dd bs=1 count=16 if=/dev/urandom 2>/dev/null | xxd -p)
         AES_IV=$(dd bs=1 count=16 if=/dev/urandom 2>/dev/null | xxd -p)
         {
             printf "$AES_KEY" | xxd -p -r
             printf "$AES_IV" | xxd -p -r
         } | openssl rsautl -encrypt -pubin -inkey "$1"
         printf "$2" | openssl enc -e -aes-128-cbc -K "$AES_KEY" -iv "$AES_IV"
     }
     encode 'key.pub' 'TEST DATA' | base64

     Resulting keys are stored in AMACryptingHelper.
     */

    NSData *const data = [@"TEST DATA" dataUsingEncoding:NSUTF8StringEncoding];
    NSString *const encodedString = @"Q0W5v/88pGPQtYcKqZ3Ab9/Qu419ll5CUQxtBGLah8tTnOqFSmgUmfvZoT2J4a6NxPON6erDkv4GNKi"
                                     "IHdy7M5qhztIVwIFT8MuSXqwXjonj+uogd7kHZl/9LroUdqUJOqMTlbU7ZypmOZ5WQlMpAGyUxp/AU7"
                                     "pFZbKBne65Ts6Mjl9lrqtMqM7nXjNzvWRS";
    AMARSAAESCrypter *__block crypter = nil;

    beforeEach(^{
        crypter = [[AMARSAAESCrypter alloc] initWithPublicKey:[AMACryptingHelper publicKey]
                                                   privateKey:[AMACryptingHelper privateKey]];
    });

    it(@"Should encode data", ^{
        NSData *encodedData = [crypter encodeData:data error:NULL];
        NSData *decodedData = [crypter decodeData:encodedData error:NULL];
        [[decodedData should] equal:data];
    });
    it(@"Should decode data", ^{
        NSData *encodedData = [[NSData alloc] initWithBase64EncodedString:encodedString options:0];
        NSData *decodedData = [crypter decodeData:encodedData error:NULL];
        [[decodedData should] equal:data];
    });
    context(@"Decode invalid data", ^{
        NSData *const encodedData = [@"WRONG DATA" dataUsingEncoding:NSUTF8StringEncoding];
        it(@"Should return nil", ^{
            NSData *decodedData = [crypter decodeData:encodedData error:NULL];
            [[decodedData should] beNil];
        });
        it(@"Should fill error", ^{
            NSError *error = nil;
            [crypter decodeData:encodedData error:&error];
            [[error shouldNot] beNil];
        });
    });
    
    it(@"Should comform to AMADataEncoding", ^{
        [[crypter should] conformToProtocol:@protocol(AMADataEncoding)];
    });
});

SPEC_END
