
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import <AppMetricaEncodingUtils/AppMetricaEncodingUtils.h>
#import <CommonCrypto/CommonCryptor.h>

SPEC_BEGIN(AMADynamicVectorAESCrypterTests)

describe(@"AMADynamicVectorAESCrypter", ^{

    /*
     This sample data was generated with this bash code:

     function encode() {
         IV=$(dd bs=1 count=16 if=/dev/urandom 2>/dev/null | xxd -p)
         printf "$IV" | xxd -p -r
         printf "$2" | openssl enc -e -aes-128-cbc -K $1 -iv "$IV"
     }
     encode 6f66207369787465656e206279746573 'TEST DATA' | base64

        Key hex: 6f66207369787465656e206279746573
         IV hex: 7d1a3551467ed1885c75d4982a1dc9ea
     */
    NSData *const key = [@"of sixteen bytes" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *const expectedEncryptedData =
        [[NSData alloc] initWithBase64EncodedString:@"ROWxAgN/QpbVX9jHkMM5MzB3KQ7aRwcn9TdfCuvdUW4="
                                            options:0];
    NSData *const expectedDecryptedData = [@"TEST DATA" dataUsingEncoding:NSUTF8StringEncoding];

    AMADynamicVectorAESCrypter *__block crypter = nil;

    beforeEach(^{
        crypter = [[AMADynamicVectorAESCrypter alloc] initWithKey:key];
    });
    context(@"Encrypt", ^{
        context(@"Valid data", ^{
            it(@"Should return valid data after decryption", ^{
                NSData *encryptedData = [crypter encodeData:expectedDecryptedData error:NULL];
                NSData *decryptedData = [crypter decodeData:encryptedData error:NULL];
                [[decryptedData should] equal:expectedDecryptedData];
            });
            it(@"Should not fill error", ^{
                NSError *error = nil;
                [crypter encodeData:expectedDecryptedData error:&error];
                [[error should] beNil];
            });
        });
        context(@"AES error", ^{
            NSError *__block expectedError = nil;
            beforeEach(^{
                expectedError = [NSError nullMock];

                AMAAESCrypter *crypter = [AMAAESCrypter stubbedNullMockForInit:@selector(initWithKey:iv:)];
                [crypter stub:@selector(encodeData:error:) withBlock:^id(NSArray *params) {
                    [AMATestUtilities fillObjectPointerParameter:params[1] withValue:expectedError];
                    return nil;
                }];
            });
            it(@"Should return nil", ^{
                NSData *encryptedData = [crypter encodeData:expectedDecryptedData error:NULL];
                [[encryptedData should] beNil];
            });
            it(@"Should fill error", ^{
                NSError *error = nil;
                [crypter encodeData:expectedDecryptedData error:&error];
                [[error should] equal:expectedError];
            });
        });
    });
    context(@"Decrypt", ^{
        context(@"Valid data", ^{
            it(@"Should return valid data", ^{
                NSData *decryptedData = [crypter decodeData:expectedEncryptedData error:NULL];
                [[decryptedData should] equal:expectedDecryptedData];
            });
            it(@"Should not fill error", ^{
                NSError *error = nil;
                [crypter decodeData:expectedEncryptedData error:&error];
                [[error should] beNil];
            });
        });
        context(@"AES error", ^{
            NSError *__block expectedError = nil;
            beforeEach(^{
                expectedError = [NSError nullMock];

                AMAAESCrypter *crypter = [AMAAESCrypter stubbedNullMockForInit:@selector(initWithKey:iv:)];
                [crypter stub:@selector(decodeData:error:) withBlock:^id(NSArray *params) {
                    [AMATestUtilities fillObjectPointerParameter:params[1] withValue:expectedError];
                    return nil;
                }];
            });
            it(@"Should return nil", ^{
                NSData *decryptedData = [crypter decodeData:expectedEncryptedData error:NULL];
                [[decryptedData should] beNil];
            });
            it(@"Should fill error", ^{
                NSError *error = nil;
                [crypter decodeData:expectedEncryptedData error:&error];
                [[error should] equal:expectedError];
            });
        });
        context(@"Small data size", ^{
            NSData *const smallData = [@"< sixteen bytes" dataUsingEncoding:NSUTF8StringEncoding];
            it(@"Should return nil", ^{
                NSData *decryptedData = [crypter decodeData:smallData error:NULL];
                [[decryptedData should] beNil];
            });
            it(@"Should fill error", ^{
                NSError *expectedError = [NSError errorWithDomain:kAMAAESDataEncoderErrorDomain
                                                             code:kCCParamError
                                                         userInfo:nil];
                
                NSError *error = nil;
                [crypter decodeData:smallData error:&error];
                [[error should] equal:expectedError];
            });
        });
    });
    
    it(@"Should comform to AMADataEncoding", ^{
        [[crypter should] conformToProtocol:@protocol(AMADataEncoding)];
    });
});

SPEC_END
