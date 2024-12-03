#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "AMAAppGroupIdentifierProvider.h"
#import "AMABundleInfoMock.h"

static NSString *const testGroup = @"io.appmetrica.group";
static NSString *const testAnotherGroup = @"io.appmetrica.group.another";

@interface AMAAppGroupIdentifierProviderTests : XCTestCase

@property (nonatomic, strong) AMABundleInfoMock *bundleMock;
@property (nonatomic, strong) AMAAppGroupIdentifierProvider *provider;

@end

@implementation AMAAppGroupIdentifierProviderTests

- (void)setUp 
{
    self.bundleMock = [AMABundleInfoMock new];
    self.provider = [[AMAAppGroupIdentifierProvider alloc] initWithBundle:self.bundleMock];
}

- (void)testEmptyBundle 
{
    NSString *result = self.provider.appGroupIdentifier;
    XCTAssertNil(result);
}

- (void)testBundleWithAppGroup
{
    self.bundleMock.mockedInfo = @{
        AMAInfoPlistAppGroupIdentifierKey: testGroup
    };
    NSString *result = self.provider.appGroupIdentifier;
    XCTAssertEqual(result, testGroup);
}

- (void)testBundleWithBrokenAppGroup
{
    self.bundleMock.mockedInfo = @{
        AMAInfoPlistAppGroupIdentifierKey: @(123)
    };
    NSString *result = self.provider.appGroupIdentifier;
    XCTAssertNil(result);
}

@end
