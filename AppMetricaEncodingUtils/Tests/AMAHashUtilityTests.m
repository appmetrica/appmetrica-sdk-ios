
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaEncodingUtils/AppMetricaEncodingUtils.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>

SPEC_BEGIN(AMAHashUtilityTests)

describe(@"AMAHashUtility", ^{

    context(@"sha256HashForData", ^{
        it(@"Should return correct hash for empty data", ^{
            NSData *data = [NSData data];
            NSString *hash = [AMAHashUtility sha256HashForData:data];

            [[hash should] equal:@"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"];
        });

        it(@"Should return correct hash for known data", ^{
            NSData *data = [@"hello" dataUsingEncoding:NSUTF8StringEncoding];
            NSString *hash = [AMAHashUtility sha256HashForData:data];

            [[hash should] equal:@"2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824"];
        });

        it(@"Should return correct hash for another known string", ^{
            NSData *data = [@"test@example.com" dataUsingEncoding:NSUTF8StringEncoding];
            NSString *hash = [AMAHashUtility sha256HashForData:data];

            [[hash should] equal:@"973dfe463ec85785f5f95af5ba3906eedb2d931c24e69824a89ea65dba4e813b"];
        });

        it(@"Should return 64 character hex string", ^{
            NSData *data = [@"any string" dataUsingEncoding:NSUTF8StringEncoding];
            NSString *hash = [AMAHashUtility sha256HashForData:data];

            [[theValue(hash.length) should] equal:theValue(64)];
        });

        it(@"Should return lowercase hex string", ^{
            NSData *data = [@"TEST" dataUsingEncoding:NSUTF8StringEncoding];
            NSString *hash = [AMAHashUtility sha256HashForData:data];

            [[hash should] equal:[hash lowercaseString]];
        });
    });

    context(@"sha256HashForString", ^{
        it(@"Should return correct hash for empty string", ^{
            NSString *hash = [AMAHashUtility sha256HashForString:@""];

            [[hash should] equal:@"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"];
        });

        it(@"Should return correct hash for known string", ^{
            NSString *hash = [AMAHashUtility sha256HashForString:@"hello"];

            [[hash should] equal:@"2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824"];
        });

        it(@"Should return correct hash for email", ^{
            NSString *hash = [AMAHashUtility sha256HashForString:@"test@example.com"];

            [[hash should] equal:@"973dfe463ec85785f5f95af5ba3906eedb2d931c24e69824a89ea65dba4e813b"];
        });

        it(@"Should return 64 character hex string", ^{
            NSString *hash = [AMAHashUtility sha256HashForString:@"any string"];

            [[theValue(hash.length) should] equal:theValue(64)];
        });

        it(@"Should return lowercase hex string", ^{
            NSString *hash = [AMAHashUtility sha256HashForString:@"TEST"];

            [[hash should] equal:[hash lowercaseString]];
        });

        it(@"Should handle UTF-8 characters", ^{
            NSString *hash = [AMAHashUtility sha256HashForString:@"привет"];

            [[hash shouldNot] beNil];
            [[theValue(hash.length) should] equal:theValue(64)];
        });

        it(@"Should handle emoji", ^{
            NSString *hash = [AMAHashUtility sha256HashForString:@"😀"];

            [[hash shouldNot] beNil];
            [[theValue(hash.length) should] equal:theValue(64)];
        });

        it(@"Should produce different hashes for different strings", ^{
            NSString *hash1 = [AMAHashUtility sha256HashForString:@"test1"];
            NSString *hash2 = [AMAHashUtility sha256HashForString:@"test2"];

            [[hash1 shouldNot] equal:hash2];
        });

        it(@"Should produce same hash for same string", ^{
            NSString *hash1 = [AMAHashUtility sha256HashForString:@"test"];
            NSString *hash2 = [AMAHashUtility sha256HashForString:@"test"];

            [[hash1 should] equal:hash2];
        });
    });

    context(@"sha256DataForString", ^{
        it(@"Should return NSData with correct length", ^{
            NSData *data = [AMAHashUtility sha256DataForString:@"hello"];

            [[data shouldNot] beNil];
            [[theValue(data.length) should] equal:theValue(32)]; // SHA256 is 32 bytes
        });

        it(@"Should return same data for same string", ^{
            NSData *data1 = [AMAHashUtility sha256DataForString:@"test"];
            NSData *data2 = [AMAHashUtility sha256DataForString:@"test"];

            [[data1 should] equal:data2];
        });

        it(@"Should return different data for different strings", ^{
            NSData *data1 = [AMAHashUtility sha256DataForString:@"test1"];
            NSData *data2 = [AMAHashUtility sha256DataForString:@"test2"];

            [[data1 shouldNot] equal:data2];
        });

        it(@"Should return data that matches hex string representation", ^{
            NSString *testString = @"hello";

            NSData *hashData = [AMAHashUtility sha256DataForString:testString];
            NSString *hashString = [AMAHashUtility sha256HashForString:testString];

            // Convert data to hex string
            NSMutableString *hexString = [NSMutableString stringWithCapacity:hashData.length * 2];
            const unsigned char *bytes = hashData.bytes;
            for (NSUInteger i = 0; i < hashData.length; i++) {
                [hexString appendFormat:@"%02x", bytes[i]];
            }

            [[hexString should] equal:hashString];
        });

        it(@"Should handle empty string", ^{
            NSData *data = [AMAHashUtility sha256DataForString:@""];

            [[data shouldNot] beNil];
            [[theValue(data.length) should] equal:theValue(32)];
        });

        it(@"Should handle UTF-8 characters", ^{
            NSData *data = [AMAHashUtility sha256DataForString:@"привет"];

            [[data shouldNot] beNil];
            [[theValue(data.length) should] equal:theValue(32)];
        });
    });

    context(@"Consistency between methods", ^{
        it(@"sha256HashForString and sha256HashForData should produce same result", ^{
            NSString *testString = @"test@example.com";
            NSData *data = [testString dataUsingEncoding:NSUTF8StringEncoding];

            NSString *hashFromString = [AMAHashUtility sha256HashForString:testString];
            NSString *hashFromData = [AMAHashUtility sha256HashForData:data];

            [[hashFromString should] equal:hashFromData];
        });

        it(@"sha256DataForString and sha256HashForData should produce same result", ^{
            NSString *testString = @"hello world";
            NSData *inputData = [testString dataUsingEncoding:NSUTF8StringEncoding];

            NSData *hashData = [AMAHashUtility sha256DataForString:testString];
            NSString *hashString = [AMAHashUtility sha256HashForData:inputData];

            // Convert hashData to hex string
            NSMutableString *hexString = [NSMutableString stringWithCapacity:hashData.length * 2];
            const unsigned char *bytes = hashData.bytes;
            for (NSUInteger i = 0; i < hashData.length; i++) {
                [hexString appendFormat:@"%02x", bytes[i]];
            }

            [[hexString should] equal:hashString];
        });
    });

});

SPEC_END
