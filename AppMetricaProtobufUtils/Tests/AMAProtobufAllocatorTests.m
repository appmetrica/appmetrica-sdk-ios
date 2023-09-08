#import <XCTest/XCTest.h>
#import <AppMetricaProtobufUtils/AppMetricaProtobufUtils.h>

@interface AMAProtobufAllocatorTests : XCTestCase

@end

@implementation AMAProtobufAllocatorTests

- (void)testInit
{
    AMAProtobufAllocator *allocator = [[AMAProtobufAllocator alloc] init];
    XCTAssertNotNil(allocator, @"The allocator should be initialized properly");
}

- (void)testProtobufCAllocatorInit
{
    AMAProtobufAllocator *allocator = [[AMAProtobufAllocator alloc] init];
    ProtobufCAllocator *protobufCAllocator = allocator.protobufCAllocator;
    
    XCTAssertTrue(protobufCAllocator != NULL, @"The ProtobufCAllocator should be initialized properly");
    XCTAssertEqual(protobufCAllocator->allocator_data,
                   (__bridge void *)(allocator), @"The ProtobufCAllocator's allocator_data should point to the "
                                                 "AMAProtobufAllocator object");
}

- (void)testMemoryAllocation
{
    AMAProtobufAllocator *allocator = [[AMAProtobufAllocator alloc] init];
    ProtobufCAllocator *protobufCAllocator = allocator.protobufCAllocator;
    void *allocatedData = protobufCAllocator->alloc(protobufCAllocator->allocator_data, 10);
    
    XCTAssertTrue(allocatedData != NULL, @"Memory allocation should succeed");
}

- (void)testMemoryDeallocation
{
    AMAProtobufAllocator *allocator = [[AMAProtobufAllocator alloc] init];
    ProtobufCAllocator *protobufCAllocator = allocator.protobufCAllocator;
    void *allocatedData = protobufCAllocator->alloc(protobufCAllocator->allocator_data, 10);
    
    protobufCAllocator->free(protobufCAllocator->allocator_data, allocatedData);
    
    // Since AMAProtobufAllocator doesn't actually deallocate memory in its 'free' method,
    // we can't directly test this. Instead, the purpose of this test is mainly to ensure that
    // the 'free' function doesn't crash or cause any other unexpected behavior.
}

@end
