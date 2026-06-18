
#import <XCTest/XCTest.h>
#import "AMAScreenshotModuleEntryPoint.h"
#import "AMAScreenshotLoader.h"
#import <AppMetricaTestUtils/AMAModuleContextMock.h>

@interface AMAScreenshotModuleEntryPointTests : XCTestCase
@property (nonatomic, strong) AMAModuleContextMock *ctx;
@end

@implementation AMAScreenshotModuleEntryPointTests

- (void)setUp
{
    self.ctx = [[AMAModuleContextMock alloc] initWithTestCase:self];
    [[AMAScreenshotModuleEntryPoint new] initModuleWithContext:self.ctx];
}

- (void)testInitModuleWithContext_registersExactlyOneService
{
    XCTAssertEqual(self.ctx.serviceConfigurations.count, 1u);
}

- (void)testInitModuleWithContext_registersStartupObserver
{
    AMAServiceConfiguration *config = self.ctx.serviceConfigurations.firstObject;
    XCTAssertNotNil(config.startupObserver);
    XCTAssertTrue([config.startupObserver isKindOfClass:[AMAScreenshotLoader class]]);
}

- (void)testInitModuleWithContext_registersStorageController
{
    AMAServiceConfiguration *config = self.ctx.serviceConfigurations.firstObject;
    XCTAssertNotNil(config.reporterStorageController);
    XCTAssertTrue([config.reporterStorageController isKindOfClass:[AMAScreenshotLoader class]]);
}

- (void)testInitModuleWithContext_startupObserverAndStorageControllerAreSameInstance
{
    AMAServiceConfiguration *config = self.ctx.serviceConfigurations.firstObject;
    XCTAssertEqualObjects(config.startupObserver, config.reporterStorageController);
}

- (void)testInitModuleWithContext_doesNotRegisterActivationDelegate
{
    XCTAssertEqual(self.ctx.activationDelegates.count, 0u);
}

- (void)testInitModuleWithContext_doesNotRegisterEventPollingDelegate
{
    XCTAssertEqual(self.ctx.eventPollingDelegates.count, 0u);
}

- (void)testInitModuleWithContext_doesNotRegisterEventFlushableDelegate
{
    XCTAssertEqual(self.ctx.eventFlushableDelegates.count, 0u);
}

- (void)testInitModuleWithContext_doesNotRegisterAdProvider
{
    XCTAssertEqual(self.ctx.adProviders.count, 0u);
}

@end
