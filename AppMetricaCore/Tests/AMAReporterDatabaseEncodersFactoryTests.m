
#import <Kiwi/Kiwi.h>
#import <AppMetricaEncodingUtils/AppMetricaEncodingUtils.h>
#import "AMAReporterDatabaseEncodersFactory.h"
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>

SPEC_BEGIN(AMAReporterDatabaseEncodersFactoryTests)

describe(@"AMAReporterDatabaseEncodersFactory", ^{

    NSData *const defaultIV = [@"DEFAULT_IV" dataUsingEncoding:NSUTF8StringEncoding];

    AMACompositeDataEncoder *__block compositeDataEncoder = nil;
    AMAGZipDataEncoder *__block gzipDataEncoder = nil;
    AMAAESCrypter *__block aesCrypter = nil;

    beforeEach(^{
        compositeDataEncoder = [AMACompositeDataEncoder stubbedNullMockForInit:@selector(initWithEncoders:)];
        gzipDataEncoder = [AMAGZipDataEncoder stubbedNullMockForDefaultInit];
        aesCrypter = [AMAAESCrypter stubbedNullMockForInit:@selector(initWithKey:iv:)];

        [AMAAESUtility stub:@selector(defaultIv) andReturn:defaultIV];
    });

    it(@"Should return valid events encryption type", ^{
        [[theValue([AMAReporterDatabaseEncodersFactory eventDataEncryptionType]) should] equal:theValue(AMAReporterDatabaseEncryptionTypeGZipAES)];
    });

    it(@"Should return valid sessions encryption type", ^{
        [[theValue([AMAReporterDatabaseEncodersFactory sessionDataEncryptionType]) should] equal:theValue(AMAReporterDatabaseEncryptionTypeAES)];
    });

    context(@"AES", ^{
        NSObject<AMADataEncoding> *(^encoder)(void) = ^{
            return (NSObject<AMADataEncoding> *)
            [AMAReporterDatabaseEncodersFactory encoderForEncryptionType:AMAReporterDatabaseEncryptionTypeAES];
        };
        it(@"Should create valid AES encoder", ^{
            const unsigned char data[] = {
                0x8e, 0xed, 0x7f, 0x8d, 0x98, 0x84, 0x40, 0x45, 0x93, 0x3e, 0x98, 0x6e, 0x41, 0x2a, 0xe9, 0x2b,
            };
            NSData *expectedData = [NSData dataWithBytes:data length:16];
            [[aesCrypter should] receive:@selector(initWithKey:iv:) withArguments:expectedData, defaultIV];
            encoder();
        });
        it(@"Should return valid encoder", ^{
            [[encoder() should] equal:aesCrypter];
        });
    });

    context(@"GZip+AES", ^{
        NSObject<AMADataEncoding> *(^encoder)(void) = ^{
            return (NSObject<AMADataEncoding> *)
                [AMAReporterDatabaseEncodersFactory encoderForEncryptionType:AMAReporterDatabaseEncryptionTypeGZipAES];
        };
        it(@"Should create valid AES encoder", ^{
            const unsigned char data[] = {
                0xaf, 0x9d, 0xca, 0x1b, 0xe7, 0x9a, 0x41, 0x97, 0xa0, 0x4b, 0x42, 0x24, 0x28, 0x50, 0xc6, 0xc2,
            };
            NSData *expectedData = [NSData dataWithBytes:data length:16];
            [[aesCrypter should] receive:@selector(initWithKey:iv:) withArguments:expectedData, defaultIV];
            encoder();
        });
        it(@"Should create valid composite encoder", ^{
            [[compositeDataEncoder should] receive:@selector(initWithEncoders:)
                                     withArguments:@[ gzipDataEncoder, aesCrypter ]];
            encoder();
        });
        it(@"Should return valid encoder", ^{
            [[encoder() should] equal:compositeDataEncoder];
        });
    });

});

SPEC_END

