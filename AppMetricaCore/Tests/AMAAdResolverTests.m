#import <XCTest/XCTest.h>
#import "AMAAdResolver.h"
#import "AMAAdProviderMock.h"
#import "AMAAdResolverMock.h"
#import "AMAAdProvidingMock.h"

@interface AMAAdResolverTests : XCTestCase

@property (nonatomic) AMAAdProviderMock *adProviderMock;
@property (nonatomic) AMAAdResolverMock *adResolver;
@property (nonatomic) AMAAdProvidingMock *adProvidingMock;

@end

@implementation AMAAdResolverTests

- (void)setUp
{
    self.adProviderMock = [AMAAdProviderMock new];
    self.adResolver = [[AMAAdResolverMock alloc] initWithDestination:self.adProviderMock];
    self.adProvidingMock = [AMAAdProvidingMock new];
}

- (void)testEnabledByDefault
{
    self.adProviderMock.setupAdProviderExpectation = [self expectationWithDescription:@"setupAdProviderExpectation"];
    
    self.adResolver.adProvider = self.adProvidingMock;
    
    [self waitForExpectations:@[self.adProviderMock.setupAdProviderExpectation] timeout:1];
    XCTAssertEqual(self.adProviderMock.setupAdProviderValue, self.adProvidingMock);
}

- (void)testEnabledUserYES
{
    self.adResolver.adProvider = self.adProvidingMock;
    self.adProviderMock.setupAdProviderExpectation = [self expectationWithDescription:@"setupAdProviderExpectation"];
    
    [self.adResolver setEnabledAdProvider:YES];
    
    [self waitForExpectations:@[self.adProviderMock.setupAdProviderExpectation] timeout:1];
    XCTAssertEqual(self.adProviderMock.setupAdProviderValue, self.adProvidingMock);
}

- (void)testEnabledUserNO
{
    self.adResolver.adProvider = self.adProvidingMock;
    self.adProviderMock.setupAdProviderExpectation = [self expectationWithDescription:@"setupAdProviderExpectation"];
    
    [self.adResolver setEnabledAdProvider:NO];
    
    [self waitForExpectations:@[self.adProviderMock.setupAdProviderExpectation] timeout:1];
    XCTAssertNil(self.adProviderMock.setupAdProviderValue);
}

- (void)testEnabledAnonimousActivateYES
{
    self.adResolver.adProvider = self.adProvidingMock;
    self.adProviderMock.setupAdProviderExpectation = [self expectationWithDescription:@"setupAdProviderExpectation"];
    
    [self.adResolver setEnabledForAnonymousActivation:YES];
    
    [self waitForExpectations:@[self.adProviderMock.setupAdProviderExpectation] timeout:1];
    XCTAssertEqual(self.adProviderMock.setupAdProviderValue, self.adProvidingMock);
}

- (void)testEnabledAnonimousActivateNO
{
    self.adResolver.adProvider = self.adProvidingMock;
    self.adProviderMock.setupAdProviderExpectation = [self expectationWithDescription:@"setupAdProviderExpectation"];
    
    [self.adResolver setEnabledForAnonymousActivation:NO];
    
    [self waitForExpectations:@[self.adProviderMock.setupAdProviderExpectation] timeout:1];
    XCTAssertNil(self.adProviderMock.setupAdProviderValue);
}

- (void)testUserDisablesAdProvider
{
    self.adResolver.adProvider = self.adProvidingMock;
    self.adProviderMock.setupAdProviderExpectation = [self expectationWithDescription:@"setupAdProviderExpectation"];
    self.adProviderMock.setupAdProviderExpectation.expectedFulfillmentCount = 2;
    
    [self.adResolver setEnabledForAnonymousActivation:YES];
    [self.adResolver setEnabledAdProvider:NO];
    
    [self waitForExpectations:@[self.adProviderMock.setupAdProviderExpectation] timeout:1];
    XCTAssertNil(self.adProviderMock.setupAdProviderValue);
}

- (void)testAnonimousActivationIgnoreAdProvider
{
    self.adResolver.adProvider = self.adProvidingMock;
    self.adProviderMock.setupAdProviderExpectation = [self expectationWithDescription:@"setupAdProviderExpectation"];
    self.adProviderMock.setupAdProviderExpectation.expectedFulfillmentCount = 2;
    
    [self.adResolver setEnabledForAnonymousActivation:NO];
    [self.adResolver setEnabledAdProvider:YES];
    
    [self waitForExpectations:@[self.adProviderMock.setupAdProviderExpectation] timeout:1];
    XCTAssertEqual(self.adProviderMock.setupAdProviderValue, self.adProvidingMock);
}

@end
