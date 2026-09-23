
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaEncodingUtils/AppMetricaEncodingUtils.h>

SPEC_BEGIN(AMAGZipDataEncoderTests)

describe(@"AMAGZipDataEncoder", ^{

    NSString *dataString = @"Data to zip. 0000000000000000000000000000000000";
    NSString *gzippedDataString = @"H4sIAAAAAAAAE3NJLElUKMlXqMos0FMwIAgAFPBYaS8AAAA=";
    
    NSData *validSourceData = [dataString dataUsingEncoding:NSUTF8StringEncoding];
    NSData *__block validGzippedData = nil;

    AMAGZipDataEncoder *__block encoder = nil;

    beforeEach(^{
        encoder = [[AMAGZipDataEncoder alloc] init];
    });

    beforeAll(^{
        validGzippedData = [[NSData alloc] initWithBase64EncodedString:gzippedDataString options:0];
    });

    it(@"Should gzip data", ^{
        NSData *gzippedData = [encoder encodeData:validSourceData error:NULL];
        [[gzippedData should] equal:validGzippedData];
    });

    it(@"Should ungzip data", ^{
        NSData *pureData = [encoder decodeData:validGzippedData error:NULL];
        [[pureData should] equal:validSourceData];
    });

    it(@"Should return nil on gzipping nil", ^{
        [[[encoder encodeData:nil error:NULL] should] beNil];
    });

    it(@"Should return nil on gzipping empty data", ^{
        [[[encoder encodeData:[NSData data] error:NULL] should] beNil];
    });

    it(@"Should return nil on ungzipping nil", ^{
        [[[encoder decodeData:nil error:NULL] should] beNil];
    });

    it(@"Should return nil on ungzipping empty data", ^{
        [[[encoder decodeData:[NSData data] error:NULL] should] beNil];
    });

    it(@"Should return nil on ungzipping invalid data", ^{
        NSData *brokenData = [encoder decodeData:validSourceData error:NULL];
        [[brokenData should] beNil];
    });

    it(@"Should fill error on ungzipping invalid data", ^{
        NSError *error = nil;
        [encoder decodeData:validSourceData error:&error];
        [[error should] beNonNil];
    });
    
    it(@"Should comform to AMADataEncoding", ^{
        [[encoder should] conformToProtocol:@protocol(AMADataEncoding)];
    });
});

SPEC_END
