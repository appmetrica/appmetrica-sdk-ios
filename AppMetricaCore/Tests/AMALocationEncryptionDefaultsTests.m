
#import <XCTest/XCTest.h>
#import "AMALocationEncryptionDefaults.h"

@interface AMALocationEncryptionDefaultsTests : XCTestCase
@end

@implementation AMALocationEncryptionDefaultsTests

- (void)testMessageBytes
{
    NSData *expected = [NSData dataWithBytes:(unsigned char[]){
        0x04, 0xf3, 0x88, 0x78, 0x96, 0xe0, 0x48, 0x7f,
        0x86, 0x7c, 0x0d, 0xe4, 0x45, 0xea, 0x0a, 0x11
    } length:16];

    NSData *actual = [AMALocationEncryptionDefaults message];
    XCTAssertEqualObjects(actual, expected, @"Should return expected bytes for the message");
}

@end
