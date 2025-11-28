
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaEncodingUtils/AppMetricaEncodingUtils.h>
#import "AMAReportPayloadEncoderFactory.h"
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>

SPEC_BEGIN(AMAReportPayloadEncoderFactoryTests)

describe(@"AMAReportPayloadEncoderFactory", ^{

    AMAGZipDataEncoder *__block gzipEncoder = nil;
    AMARSAAESCrypter *__block rsaAESCrypter = nil;
    AMACompositeDataEncoder *__block compositeEncoder = nil;

    beforeEach(^{
        gzipEncoder = [AMAGZipDataEncoder stubbedNullMockForDefaultInit];
        rsaAESCrypter = [AMARSAAESCrypter stubbedNullMockForInit:@selector(initWithPublicKey:privateKey:)];
        compositeEncoder = [AMACompositeDataEncoder stubbedNullMockForInit:@selector(initWithEncoders:)];
    });
    afterEach(^{
        [AMAGZipDataEncoder clearStubs];
        [AMARSAAESCrypter clearStubs];
        [AMACompositeDataEncoder clearStubs];
    });

    context(@"RSA key", ^{
        AMARSAKey *__block key = nil;
        beforeAll(^{
            KWCaptureSpy *spy = [rsaAESCrypter captureArgument:@selector(initWithPublicKey:privateKey:) atIndex:0];
            [AMAReportPayloadEncoderFactory encoder];
            key = spy.argument;
        });
        it(@"Should have valid data", ^{
            NSString *keyString =
                @"MIGJAoGBAOGYf+baqtGPEMc/v3gJ5pmkQ1A1jJ1/ymrJcmKWjpfEr6f6m+jbtXFZ8HdnXIeu0qjD55lcotDOtD"
                "zBkx9GAAOtgJAnbTLaEZkRQI3W0ZIz7GpUox4K1WLc29BrngLHuZPkQJWwfkMoSz9p5JwMc/noXNyARu05LDJF"
                "nx2wQzTDAgMBAAE=";
            NSData *keyData = [[NSData alloc] initWithBase64EncodedString:keyString options:0];
            [[key.data should] equal:keyData];
        });
        it(@"Should have valid tag", ^{
            [[key.uniqueTag should] equal:@"AMARSAKeyTagReporter"];
        });
    });
    it(@"Should create valid composite encoder", ^{
        [[compositeEncoder should] receive:@selector(initWithEncoders:) withArguments:@[ gzipEncoder, rsaAESCrypter ]];
        [AMAReportPayloadEncoderFactory encoder];
    });
    it(@"Should return created composite encoder", ^{
        [[(NSObject *)[AMAReportPayloadEncoderFactory encoder] should] equal:compositeEncoder];
    });

});

SPEC_END
