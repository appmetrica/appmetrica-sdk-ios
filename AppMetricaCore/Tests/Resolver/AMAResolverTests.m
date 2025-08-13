#import <XCTest/XCTest.h>
#import "AMAMockResolver.h"

@interface AMAResolverTests : XCTestCase

@property (nonatomic, strong) AMAMockResolver *resolver;

@end

@implementation AMAResolverTests

- (void)setUp
{
    self.resolver = [AMAMockResolver new];
}

- (void)testDefaultValue
{
    XCTAssertTrue(self.resolver.defaultValue);
    XCTAssertTrue([self.resolver resolve]);
    
    self.resolver.defaultValue = NO;
    XCTAssertFalse([self.resolver resolve]);
}

- (void)testUserValue
{
    self.resolver.updateExpectation = [self expectationWithDescription:@"update"];
    
    self.resolver.userValue = @(NO);
    
    [self waitForExpectations:@[self.resolver.updateExpectation] timeout:1];
    XCTAssertFalse(self.resolver.lastValue);
}

- (void)testAnonymousValueIfNoAnonymousSet
{
    self.resolver.updateExpectation = [self expectationWithDescription:@"update"];
    
    self.resolver.anonymousValue = @(NO);
    
    [self waitForExpectations:@[self.resolver.updateExpectation] timeout:1];
    XCTAssertTrue(self.resolver.lastValue);
}

- (void)testAnonymousValue
{
    self.resolver.updateExpectation = [self expectationWithDescription:@"update"];
    self.resolver.updateExpectation.expectedFulfillmentCount = 2;
    
    self.resolver.anonymousValue = @(NO);
    self.resolver.isAnonymousConfigurationActivated = YES;
    
    [self waitForExpectations:@[self.resolver.updateExpectation] timeout:1];
    XCTAssertFalse(self.resolver.lastValue);
}

- (void)testUserValueOverrideAnonymousValue
{
    self.resolver.updateExpectation = [self expectationWithDescription:@"update"];
    self.resolver.updateExpectation.expectedFulfillmentCount = 2;
    
    self.resolver.anonymousValue = @(NO);
    self.resolver.userValue = @(YES);
    
    [self waitForExpectations:@[self.resolver.updateExpectation] timeout:1];
    XCTAssertTrue(self.resolver.lastValue);
}

- (void)testUserValueOverrideAnonymousValueIfAnonymousSet
{
    self.resolver.updateExpectation = [self expectationWithDescription:@"update"];
    self.resolver.updateExpectation.expectedFulfillmentCount = 3;
    
    self.resolver.anonymousValue = @(NO);
    self.resolver.isAnonymousConfigurationActivated = YES;
    self.resolver.userValue = @(YES);
    
    [self waitForExpectations:@[self.resolver.updateExpectation] timeout:1];
    XCTAssertTrue(self.resolver.lastValue);
}


@end
