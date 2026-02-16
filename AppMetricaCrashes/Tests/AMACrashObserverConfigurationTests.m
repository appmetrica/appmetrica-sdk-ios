#import <XCTest/XCTest.h>
#import "AMACrashObserverConfiguration.h"
#import "AMACrashObserving.h"
#import "MockCrashObserverDelegate.h"

@interface AMACrashObserverConfigurationTests : XCTestCase

@property (nonatomic, strong) id<AMACrashObserving> mockDelegate;
@property (nonatomic, strong) dispatch_queue_t customQueue;

@end

@implementation AMACrashObserverConfigurationTests

- (void)setUp
{
    [super setUp];

    self.mockDelegate = [[MockCrashObserverDelegate alloc] init];
    self.customQueue = dispatch_queue_create("test.queue", DISPATCH_QUEUE_SERIAL);
}

- (void)tearDown
{
    self.mockDelegate = nil;
    self.customQueue = nil;

    [super tearDown];
}

#pragma mark - Initialization Tests

- (void)testInitializationWithAllParameters
{
    AMACrashObserverConfiguration *configuration = [[AMACrashObserverConfiguration alloc] initWithDelegate:self.mockDelegate
                                                                                              callbackQueue:self.customQueue];

    XCTAssertNotNil(configuration);
    XCTAssertEqual(configuration.delegate, self.mockDelegate);
    XCTAssertNotNil(configuration.callbackQueue);
}

- (void)testInitializationAllowsNilDelegate
{
    AMACrashObserverConfiguration *configuration = [[AMACrashObserverConfiguration alloc] initWithDelegate:nil
                                                                                              callbackQueue:self.customQueue];

    XCTAssertNotNil(configuration);
    XCTAssertNil(configuration.delegate);
}

#pragma mark - NSCopying Tests

- (void)testCopyingCreatesObjectWithSameProperties
{
    AMACrashObserverConfiguration *original = [[AMACrashObserverConfiguration alloc] initWithDelegate:self.mockDelegate
                                                                                         callbackQueue:self.customQueue];

    AMACrashObserverConfiguration *copy = [original copy];

    XCTAssertNotNil(copy);
    XCTAssertEqual(copy.delegate, original.delegate);
    XCTAssertEqual(copy.callbackQueue, original.callbackQueue);
}

@end
