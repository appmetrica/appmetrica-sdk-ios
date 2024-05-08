
#import <XCTest/XCTest.h>
#import "AMALogFileFactory.h"
#import "AMALogFile.h"

#ifdef AMA_ENABLE_FILE_LOG

@interface AMALogFileFactoryTests : XCTestCase

@property (nonatomic, strong) AMALogFileFactory *factory;

@end

@implementation AMALogFileFactoryTests

- (void)setUp {
    [super setUp];
    self.factory = [[AMALogFileFactory alloc] initWithPrefix:@"test_prefix"];
}

- (void)testFactoryLogFileFromFilePath {
    AMALogFile *file = [self.factory logFileFromFilePath:@"/Users/test/test/test_prefix-10.log"];
    XCTAssertEqualObjects(file.fileName, @"test_prefix-10.log");
    XCTAssertEqualObjects(file.serialNumber, @(10));
}

- (void)testFactoryLogFileWithInvalidSerialNumber {
    AMALogFile *file = [self.factory logFileFromFilePath:@"/Users/test/test/test_prefix-abc.log"];
    XCTAssertNil(file);
}

- (void)testFactoryLogFileWithInvalidSeparator {
    AMALogFile *file = [self.factory logFileFromFilePath:@"/Users/test/test/test_prefix_123.log"];
    XCTAssertNil(file);
}

- (void)testFactoryLogFileWithNilPath {
    AMALogFile *file = [self.factory logFileFromFilePath:nil];
    XCTAssertNil(file);
}

- (void)testFactoryLogFileWithEmptyPath {
    AMALogFile *file = [self.factory logFileFromFilePath:@""];
    XCTAssertNil(file);
}

- (void)testFactoryLogFileFromSerialNumber {
    AMALogFile *file = [self.factory logFileWithSerialNumber:@(10)];
    XCTAssertEqualObjects(file.fileName, @"test_prefix-10.log");
    XCTAssertEqualObjects(file.serialNumber, @(10));
}

- (void)testFactoryLogFileFromNilSerialNumber {
    AMALogFile *file = [self.factory logFileWithSerialNumber:nil];
    XCTAssertNil(file);
}

@end

#endif // AMA_ENABLE_FILE_LOG
