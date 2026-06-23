
#import <XCTest/XCTest.h>
#import "AMAInfoPlistPolicy.h"
#import "Mocks/AMABundleInfoMock.h"

static NSString *const kTestKey = @"com.test.some_flag";

@interface AMAInfoPlistPolicyTests : XCTestCase
@property (nonatomic, strong) AMABundleInfoMock *bundle;
@end

@implementation AMAInfoPlistPolicyTests

- (void)setUp
{
    self.bundle = [AMABundleInfoMock new];
}

- (AMAInfoPlistPolicy *)policyWithDefault:(BOOL)defaultValue
{
    return [[AMAInfoPlistPolicy alloc] initWithBundle:self.bundle key:kTestKey defaultValue:defaultValue];
}

// MARK: - Explicit values

- (void)testReturnsYES_whenPlistContainsYES
{
    self.bundle.mockedInfo = @{ kTestKey: @YES };
    XCTAssertTrue([[self policyWithDefault:NO] isEnabled]);
}

- (void)testReturnsNO_whenPlistContainsNO
{
    self.bundle.mockedInfo = @{ kTestKey: @NO };
    XCTAssertFalse([[self policyWithDefault:YES] isEnabled]);
}

// MARK: - Default fallback

- (void)testDefaultYES_whenKeyAbsent
{
    self.bundle.mockedInfo = @{};
    XCTAssertTrue([[self policyWithDefault:YES] isEnabled]);
}

- (void)testDefaultNO_whenKeyAbsent
{
    self.bundle.mockedInfo = @{};
    XCTAssertFalse([[self policyWithDefault:NO] isEnabled]);
}

- (void)testDefaultUsed_whenValueIsNotNSNumber
{
    for (id value in @[@"true", @"1", [NSDate date]]) {
        self.bundle.mockedInfo = @{ kTestKey: value };
        XCTAssertTrue([[self policyWithDefault:YES] isEnabled],
                      @"Expected default YES for non-NSNumber value: %@", value);
        XCTAssertFalse([[self policyWithDefault:NO] isEnabled],
                       @"Expected default NO for non-NSNumber value: %@", value);
    }
}

// MARK: - Caching

- (void)testValueCached_bundleChangedAfterFirstRead
{
    self.bundle.mockedInfo = @{ kTestKey: @YES };
    AMAInfoPlistPolicy *policy = [self policyWithDefault:NO];

    BOOL first = policy.isEnabled;

    self.bundle.mockedInfo = @{ kTestKey: @NO };
    BOOL second = policy.isEnabled;

    XCTAssertTrue(first);
    XCTAssertTrue(second, @"Result must be cached — bundle change after first read should have no effect");
}

@end
