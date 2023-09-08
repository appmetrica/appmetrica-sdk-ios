#import <XCTest/XCTest.h>
#import <AppMetricaProtobufUtils/AppMetricaProtobufUtils.h>
#import "Mocks/AMAAllocationsTrackingMock.h"

@interface AMAProtobufUtilitiesTests : XCTestCase

@end

@implementation AMAProtobufUtilitiesTests

- (void)testAddBuffer
{
    AMAAllocationsTrackingMock *tracker = [[AMAAllocationsTrackingMock alloc] init];
    char buffer[5] = "test";
    void *result = [AMAProtobufUtilities addBuffer:buffer ofSize:5 toTracker:tracker];
    XCTAssert(result != NULL);
    XCTAssertEqual(strcmp(result, buffer), 0);
    XCTAssertEqual([tracker.allocations count], 1);
}

- (void)testAddBufferWithNullBuffer
{
    AMAAllocationsTrackingMock *tracker = [[AMAAllocationsTrackingMock alloc] init];
    void *result = [AMAProtobufUtilities addBuffer:NULL ofSize:5 toTracker:tracker];
    XCTAssert(result == NULL);
    XCTAssertEqual([tracker.allocations count], 0);
}

- (void)testAddString
{
    AMAAllocationsTrackingMock *tracker = [[AMAAllocationsTrackingMock alloc] init];
    char *str = "test";
    char *result = [AMAProtobufUtilities addString:str toTracker:tracker];
    XCTAssert(result != NULL);
    XCTAssertEqual(strcmp(result, str), 0);
    XCTAssertEqual([tracker.allocations count], 1);
}

- (void)testAddNSString
{
    AMAAllocationsTrackingMock *tracker = [[AMAAllocationsTrackingMock alloc] init];
    NSString *str = @"test";
    char *result = [AMAProtobufUtilities addNSString:str toTracker:tracker];
    XCTAssert(result != NULL);
    XCTAssertEqual(strcmp(result, [str cStringUsingEncoding:NSUTF8StringEncoding]), 0);
    XCTAssertEqual([tracker.allocations count], 1);
}

- (void)testFillBinaryDataWithString
{
    AMAAllocationsTrackingMock *tracker = [[AMAAllocationsTrackingMock alloc] init];
    NSString *str = @"test";
    ProtobufCBinaryData binaryData;
    BOOL success = [AMAProtobufUtilities fillBinaryData:&binaryData withString:str tracker:tracker];
    XCTAssertTrue(success);
    NSString *resultStr = [[NSString alloc] initWithBytes:binaryData.data
                                                   length:binaryData.len
                                                 encoding:NSUTF8StringEncoding];
    XCTAssertEqualObjects(resultStr, str);
    XCTAssertEqual([tracker.allocations count], 1);
}

- (void)testFillBinaryDataWithData
{
    AMAAllocationsTrackingMock *tracker = [[AMAAllocationsTrackingMock alloc] init];
    NSData *data = [@"test" dataUsingEncoding:NSUTF8StringEncoding];
    ProtobufCBinaryData binaryData;
    BOOL success = [AMAProtobufUtilities fillBinaryData:&binaryData withData:data tracker:tracker];
    XCTAssertTrue(success);
    NSData *resultData = [[NSData alloc] initWithBytes:binaryData.data length:binaryData.len];
    XCTAssertEqualObjects(resultData, data);
    XCTAssertEqual([tracker.allocations count], 1);
}

- (void)testFillBinaryDataWithNilData
{
    AMAAllocationsTrackingMock *tracker = [[AMAAllocationsTrackingMock alloc] init];
    ProtobufCBinaryData binaryData;
    BOOL success = [AMAProtobufUtilities fillBinaryData:&binaryData withData:nil tracker:tracker];
    XCTAssertFalse(success);
    XCTAssertEqual([tracker.allocations count], 0);
}

- (void)testStringForBinaryData
{
    NSString *str = @"test";
    NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
    ProtobufCBinaryData binaryData;
    binaryData.len = [data length];
    binaryData.data = (void *)[data bytes];
    NSString *resultStr = [AMAProtobufUtilities stringForBinaryData:&binaryData];
    XCTAssertEqualObjects(resultStr, str);
}

- (void)testStringForBinaryDataWithNoData
{
    ProtobufCBinaryData binaryData;
    binaryData.len = 0;
    binaryData.data = NULL;
    NSString *resultStr = [AMAProtobufUtilities stringForBinaryData:&binaryData];
    XCTAssertEqualObjects(resultStr, @"", @"The returned NSString should be empty if BinaryData has no data");
}

- (void)testDataForBinaryData
{
    NSData *data = [@"test" dataUsingEncoding:NSUTF8StringEncoding];
    ProtobufCBinaryData binaryData;
    binaryData.len = [data length];
    binaryData.data = (void *)[data bytes];
    NSData *resultData = [AMAProtobufUtilities dataForBinaryData:&binaryData];
    XCTAssertEqualObjects(resultData, data);
}

- (void)testDataForBinaryDataWithNoData
{
    ProtobufCBinaryData binaryData;
    binaryData.len = 0;
    binaryData.data = NULL;
    NSData *resultData = [AMAProtobufUtilities dataForBinaryData:&binaryData];
    XCTAssertEqualObjects(NSData.data, resultData, @"The returned NSData should be empty if BinaryData has no data");
}

- (void)testBoolForProto
{
    BOOL result = [AMAProtobufUtilities boolForProto:1];
    XCTAssertTrue(result);
    result = [AMAProtobufUtilities boolForProto:0];
    XCTAssertFalse(result);
}

- (void)testDataForBinaryDataHasTrue
{
    NSData *expectedData = [@"Test String" dataUsingEncoding:NSUTF8StringEncoding];
    ProtobufCBinaryData binaryData;
    binaryData.len = expectedData.length;
    binaryData.data = (void *)expectedData.bytes;
    
    NSData *result = [AMAProtobufUtilities dataForBinaryData:&binaryData has:YES];
    XCTAssertEqualObjects(result, expectedData, @"The returned NSData should match the input data when 'has' is true");
}

- (void)testDataForBinaryDataHasFalse
{
    NSData *expectedData = [@"Test String" dataUsingEncoding:NSUTF8StringEncoding];
    ProtobufCBinaryData binaryData;
    binaryData.len = expectedData.length;
    binaryData.data = (void *)expectedData.bytes;
    
    NSData *result = [AMAProtobufUtilities dataForBinaryData:&binaryData has:NO];
    XCTAssertNil(result, @"The returned NSData should be nil when 'has' is false");
}

- (void)testDataForBinaryDataNull
{
    NSData *result = [AMAProtobufUtilities dataForBinaryData:NULL has:YES];
    XCTAssertNil(result, @"The returned NSData should be nil when 'binaryData' is NULL");
}

- (void)testStringForBinaryDataHasTrue
{
    NSString *expectedString = @"Test String";
    NSData *testData = [expectedString dataUsingEncoding:NSUTF8StringEncoding];
    ProtobufCBinaryData binaryData;
    binaryData.len = testData.length;
    binaryData.data = (void *)testData.bytes;
    
    NSString *result = [AMAProtobufUtilities stringForBinaryData:&binaryData has:YES];
    XCTAssertEqualObjects(result, expectedString, @"The returned NSString should match the input string when 'has' is true");
}

- (void)testStringForBinaryDataHasFalse
{
    NSString *expectedString = @"Test String";
    NSData *testData = [expectedString dataUsingEncoding:NSUTF8StringEncoding];
    ProtobufCBinaryData binaryData;
    binaryData.len = testData.length;
    binaryData.data = (void *)testData.bytes;
    
    NSString *result = [AMAProtobufUtilities stringForBinaryData:&binaryData has:NO];
    XCTAssertNil(result, @"The returned NSString should be nil when 'has' is false");
}

- (void)testStringForBinaryDataNull
{
    NSString *result = [AMAProtobufUtilities stringForBinaryData:NULL has:YES];
    XCTAssertNil(result, @"The returned NSString should be nil when 'binaryData' is NULL");
}

@end
