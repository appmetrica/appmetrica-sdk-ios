#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import <Kiwi/Kiwi.h>

#import "AMARunLoopThread.h"
#import "AMARunLoopExecutor.h"

@interface AMARunLoopExecutorTests : XCTestCase

@property (nonatomic, strong) AMARunLoopExecutor *executor;

@end

@implementation AMARunLoopExecutorTests

- (void)setUp
{
    self.executor = [[AMARunLoopExecutor alloc] initWithName:@"TestExeutor"];
}

- (void)testExecute
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"block"];
    
    [self.executor execute:^{
        [expectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation] timeout:1];
}

- (void)testSyncExecute
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"block"];
    
    [self.executor syncExecute:^id _Nullable{
        [expectation fulfill];
        return nil;
    }];
    
    [self waitForExpectations:@[expectation] timeout:1];
}

- (void)testExecuteMultiply
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"block"];
    expectation.expectedFulfillmentCount = 3;
    
    [self.executor execute:^{
        [expectation fulfill];
    }];
    [self.executor execute:^{
        [expectation fulfill];
    }];
    [self.executor execute:^{
        [expectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation] timeout:3];
}

- (void)testExecuteWithQueue
{
    NSLock *locker = [NSLock new];
    XCTestExpectation *expectation = [self expectationWithDescription:@"block"];
    expectation.expectedFulfillmentCount = 3;
    
    [locker lock];
    
    [self.executor execute:^{
        [locker lock];
        [expectation fulfill];
        [locker unlock];
    }];
    [self.executor execute:^{
        [expectation fulfill];
    }];
    [self.executor execute:^{
        [expectation fulfill];
    }];
    
    [locker unlock];
    
    [self waitForExpectations:@[expectation] timeout:1];
}

@end
