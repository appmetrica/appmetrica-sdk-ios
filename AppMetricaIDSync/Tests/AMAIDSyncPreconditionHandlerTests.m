
@import XCTest;
#import "AMAIDSyncPreconditionHandler.h"
#import <AppMetricaPlatform/AppMetricaPlatform.h>

@interface AMAIDSyncPreconditionHandlerTests : XCTestCase
@property (nonatomic, strong) AMAIDSyncPreconditionHandler *handler;
@end

@implementation AMAIDSyncPreconditionHandlerTests

- (void)setUp
{
    [super setUp];
    self.handler = [[AMAIDSyncPreconditionHandler alloc] init];
}

- (void)tearDown
{
    self.handler = nil;
    [super tearDown];
}

- (void)testCanExecuteRequestWithoutPreconditionsReturnsYes
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Completion called"];
    
    [self.handler canExecuteRequestWithPreconditions:@{}
                                          completion:^(BOOL result) {
        XCTAssertTrue(result, @"Should allow execution when no preconditions provided");
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testCanExecuteRequestWithUnknownPreconditionReturnsYes
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Completion called"];
    
    [self.handler canExecuteRequestWithPreconditions:@{@"unknown": @"value"}
                                          completion:^(BOOL result) {
        XCTAssertTrue(result, @"Should allow execution for unknown precondition key");
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

@end
