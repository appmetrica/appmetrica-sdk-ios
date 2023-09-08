
#import <Kiwi/Kiwi.h>
#import <AppMetricaEncodingUtils/AppMetricaEncodingUtils.h>
#import "AMAStartupResponseEncoderFactory.h"
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>

SPEC_BEGIN(AMAStartupResponseEncoderFactoryTests)

describe(@"AMAStartupResponseEncoderFactory", ^{

    AMAGZipDataEncoder *__block gzipEncoder = nil;
    AMADynamicVectorAESCrypter *__block aesCrypter = nil;
    AMACompositeDataEncoder *__block compositeEncoder = nil;

    beforeEach(^{
        gzipEncoder = [AMAGZipDataEncoder stubbedNullMockForDefaultInit];
        aesCrypter = [AMADynamicVectorAESCrypter stubbedNullMockForInit:@selector(initWithKey:)];
        compositeEncoder = [AMACompositeDataEncoder stubbedNullMockForInit:@selector(initWithEncoders:)];
    });

    it(@"Should create valid AES crypter", ^{
        [[aesCrypter should] receive:@selector(initWithKey:)
                       withArguments:[@"hBnBQbZrmjPXEWVJ" dataUsingEncoding:NSUTF8StringEncoding]];
        [AMAStartupResponseEncoderFactory encoder];
    });
    it(@"Should create valid composite encoder", ^{
        [[compositeEncoder should] receive:@selector(initWithEncoders:) withArguments:@[ gzipEncoder, aesCrypter ]];
        [AMAStartupResponseEncoderFactory encoder];
    });
    it(@"Should return created composite encoder", ^{
        [[(NSObject *)[AMAStartupResponseEncoderFactory encoder] should] equal:compositeEncoder];
    });

});

SPEC_END
