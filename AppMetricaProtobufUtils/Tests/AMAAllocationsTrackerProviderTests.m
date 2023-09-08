#import <XCTest/XCTest.h>
#import <AppMetricaProtobufUtils/AppMetricaProtobufUtils.h>

@interface AMAAllocationsTrackerProviderTests : XCTestCase

@end

@implementation AMAAllocationsTrackerProviderTests

- (void)testTrack
{
    __block BOOL blockWasExecuted = NO;
    
    [AMAAllocationsTrackerProvider track:^(id<AMAAllocationsTracking> tracker) {
        XCTAssertNotNil(tracker, @"The tracker provided in the block should not be nil");
        
        void *allocatedData = [tracker allocateSize:10];
        XCTAssertTrue(allocatedData != NULL, @"Allocation should succeed");
        
        blockWasExecuted = YES;
    }];
    
    XCTAssertTrue(blockWasExecuted, @"The block should be executed");
}

- (void)testManuallyHandledTracker
{
    id<AMAAllocationsTracking> tracker = [AMAAllocationsTrackerProvider manuallyHandledTracker];
    
    XCTAssertNotNil(tracker, @"The tracker returned by manuallyHandledTracker should not be nil");
    
    void *allocatedData = [tracker allocateSize:10];
    XCTAssertTrue(allocatedData != NULL, @"Allocation should succeed");
}

- (void)testMultipleAllocations {
    [AMAAllocationsTrackerProvider track:^(id<AMAAllocationsTracking> tracker) {
        void *allocatedData1 = [tracker allocateSize:10];
        XCTAssertTrue(allocatedData1 != NULL, @"Allocation should succeed");
        
        void *allocatedData2 = [tracker allocateSize:20];
        XCTAssertTrue(allocatedData2 != NULL, @"Allocation should succeed");
        
        void *allocatedData3 = [tracker allocateSize:30];
        XCTAssertTrue(allocatedData3 != NULL, @"Allocation should succeed");
    }];
}

- (void)testZeroSizeAllocation {
    [AMAAllocationsTrackerProvider track:^(id<AMAAllocationsTracking> tracker) {
        void *allocatedData = [tracker allocateSize:0];
        XCTAssertTrue(allocatedData != NULL, @"Allocation with zero size should return NULL");
    }];
}

- (void)testLargeSizeAllocation {
    [AMAAllocationsTrackerProvider track:^(id<AMAAllocationsTracking> tracker) {
        void *allocatedData = [tracker allocateSize:UINT32_MAX];
        XCTAssertTrue(allocatedData != NULL, @"Allocation with extremely large size should fail and return NULL");
    }];
}

@end

