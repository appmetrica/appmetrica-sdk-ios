
#import <Kiwi/Kiwi.h>
#import <AppMetricaEncodingUtils/AppMetricaEncodingUtils.h>
#import "Utilities/AMACryptingHelper.h"

SPEC_BEGIN(AMARSACrypterTests)

describe(@"AMARSACrypter", ^{

    /*
     This sample data was generated with this bash code:
     
     openssl genrsa -out key.pem 1024
     openssl rsa -in key.pem -out key.pub -pubout

     cat key.pub
     cat key.pem
     printf 'TEST DATA' | openssl rsautl -encrypt -pubin -inkey key.pub | base64

     Resulting keys are stored in AMACryptingHelper.
     */

    NSData *const data = [@"TEST DATA" dataUsingEncoding:NSUTF8StringEncoding];
    NSString *const encodedString = @"dYUfND1vNge6Y+vcGmzvT6WJXWIn9rQyvEtf7755ZDH005Dqa/bhsXH+g81ojf1mRKGgpNbyHwup"
                                     "5ZFP+QU/66ZZVUVzT1PhWjABe5mJ9ZLTq2xBqVYGA1ecYN08Cp+FIF1/i2KCnKlMiEzI8+za8PZc"
                                     "V9nUJ/ZawHout4LJ/Y4=";

    AMARSACrypter *__block crypter = nil;

    beforeEach(^{
        crypter = [[AMARSACrypter alloc] initWithPublicKey:[AMACryptingHelper publicKey]
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

});

SPEC_END
