
#import <XCTest/XCTest.h>
#import "AMALogFileRotation.h"
#import "AMALogFile.h"

@interface AMALogFileRotationTests : XCTestCase

@end

@implementation AMALogFileRotationTests

- (void)testRotationWithUnderflow {
    NSArray *files = @[
            [[AMALogFile alloc] initWithFileName:@"" serialNumber:@(1)],
            [[AMALogFile alloc] initWithFileName:@"" serialNumber:@(2)],
    ];
    AMALogFileRotation *rotation = [AMALogFileRotation rotationForLogFiles:files withMaxFilesAllowed:10];
    XCTAssert(rotation.filesToRemove.count == 0);
}

- (void)testRotationWithOverflow {
    NSArray *files = @[
            [[AMALogFile alloc] initWithFileName:@"" serialNumber:@(1)],
            [[AMALogFile alloc] initWithFileName:@"" serialNumber:@(3)],
            [[AMALogFile alloc] initWithFileName:@"" serialNumber:@(2)],
    ];
    AMALogFileRotation *rotation = [AMALogFileRotation rotationForLogFiles:files withMaxFilesAllowed:2];

    NSArray *expectedFilesToRemove = @[
            [[AMALogFile alloc] initWithFileName:@"" serialNumber:@(1)],
            [[AMALogFile alloc] initWithFileName:@"" serialNumber:@(2)],
    ];
    XCTAssertEqualObjects(rotation.filesToRemove, expectedFilesToRemove);
}

- (void)testRotationWithExactCount {
    NSArray *files = @[
            [[AMALogFile alloc] initWithFileName:@"" serialNumber:@(1)],
            [[AMALogFile alloc] initWithFileName:@"" serialNumber:@(3)],
            [[AMALogFile alloc] initWithFileName:@"" serialNumber:@(2)],
    ];
    AMALogFileRotation *rotation = [AMALogFileRotation rotationForLogFiles:files withMaxFilesAllowed:3];

    NSArray *expectedFilesToRemove = @[
            [[AMALogFile alloc] initWithFileName:@"" serialNumber:@(1)],
    ];
    XCTAssertEqualObjects(rotation.filesToRemove, expectedFilesToRemove);
}

- (void)testRotationWithZeroMaxCount {
    NSArray *files = @[
            [[AMALogFile alloc] initWithFileName:@"" serialNumber:@(1)],
            [[AMALogFile alloc] initWithFileName:@"" serialNumber:@(2)],
            [[AMALogFile alloc] initWithFileName:@"" serialNumber:@(3)],
    ];
    AMALogFileRotation *rotation = [AMALogFileRotation rotationForLogFiles:files withMaxFilesAllowed:0];

    XCTAssertEqualObjects(rotation.filesToRemove, files);
}

- (void)testRotationWithEmptyFiles {
    AMALogFileRotation *rotation = [AMALogFileRotation rotationForLogFiles:nil withMaxFilesAllowed:10];
    XCTAssert(rotation.filesToRemove.count == 0);
}

- (void)testNextSerialNumberWithOverflow {
    NSArray *files = @[
            [[AMALogFile alloc] initWithFileName:@"" serialNumber:@(1)],
            [[AMALogFile alloc] initWithFileName:@"" serialNumber:@(2)],
            [[AMALogFile alloc] initWithFileName:@"" serialNumber:@(3)],
    ];
    AMALogFileRotation *rotation = [AMALogFileRotation rotationForLogFiles:files withMaxFilesAllowed:2];
    XCTAssertEqualObjects(rotation.nextSerialNumber, @(4));
}

- (void)testNextSerialNumberWithUnderflow {
    NSArray *files = @[
            [[AMALogFile alloc] initWithFileName:@"" serialNumber:@(1)],
            [[AMALogFile alloc] initWithFileName:@"" serialNumber:@(2)],
    ];
    AMALogFileRotation *rotation = [AMALogFileRotation rotationForLogFiles:files withMaxFilesAllowed:10];
    XCTAssertEqualObjects(rotation.nextSerialNumber, @(3));
}

- (void)testNextSerialNumberWithExactCount {
    NSArray *files = @[
            [[AMALogFile alloc] initWithFileName:@"" serialNumber:@(1)],
            [[AMALogFile alloc] initWithFileName:@"" serialNumber:@(2)],
    ];
    AMALogFileRotation *rotation = [AMALogFileRotation rotationForLogFiles:files withMaxFilesAllowed:2];
    XCTAssertEqualObjects(rotation.nextSerialNumber, @(3));
}

- (void)testNextSerialNumberWithEmptyFiles {
    AMALogFileRotation *rotation = [AMALogFileRotation rotationForLogFiles:nil withMaxFilesAllowed:10];
    XCTAssertEqualObjects(rotation.nextSerialNumber, @(1));
}

- (void)testNextSerialNumberWithZeroCount {
    AMALogFileRotation *rotation = [AMALogFileRotation rotationForLogFiles:nil withMaxFilesAllowed:0];
    XCTAssertNil(rotation.nextSerialNumber);
}

@end
