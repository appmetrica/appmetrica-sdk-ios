
#import <XCTest/XCTest.h>
#import "AMAReporterDatabaseEncryptionDefaults.h"

@interface AMAReporterDatabaseEncryptionDefaultsTests : XCTestCase
@end

@implementation AMAReporterDatabaseEncryptionDefaultsTests

- (void)testEventDataEncryptionType
{
    XCTAssertEqual(
        AMAReporterDatabaseEncryptionDefaults.eventDataEncryptionType,
        AMAReporterDatabaseEncryptionTypeGZipAES,
        @"Should return GZipAES for event data encryption type"
    );
}

- (void)testSessionDataEncryptionType
{
    XCTAssertEqual(
        AMAReporterDatabaseEncryptionDefaults.sessionDataEncryptionType,
        AMAReporterDatabaseEncryptionTypeAES,
        @"Should return AES for session data encryption type"
    );
}

- (void)testFirstMessageBytes
{
    NSData *expected = [NSData dataWithBytes:(unsigned char[]){
        0x8e, 0xed, 0x7f, 0x8d, 0x98, 0x84, 0x40, 0x45, 0x93, 0x3e, 0x98, 0x6e, 0x41, 0x2a, 0xe9, 0x2b
    } length:16];

    XCTAssertEqualObjects(
        AMAReporterDatabaseEncryptionDefaults.firstMessage,
        expected,
        @"Should return expected bytes for the first message"
    );
}

- (void)testSecondMessageBytes
{
    NSData *expected = [NSData dataWithBytes:(unsigned char[]){
        0xaf, 0x9d, 0xca, 0x1b, 0xe7, 0x9a, 0x41, 0x97, 0xa0, 0x4b, 0x42, 0x24, 0x28, 0x50, 0xc6, 0xc2
    } length:16];

    XCTAssertEqualObjects(
        AMAReporterDatabaseEncryptionDefaults.secondMessage,
        expected,
        @"Should return expected bytes for the second message"
    );
}

@end
