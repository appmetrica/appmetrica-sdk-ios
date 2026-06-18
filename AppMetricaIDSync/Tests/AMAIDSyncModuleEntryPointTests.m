
#import <XCTest/XCTest.h>
#import "AMAIDSyncModuleEntryPoint.h"
#import "AMAIDSyncStartupController.h"
#import <AppMetricaTestUtils/AMAModuleContextMock.h>

@interface AMAIDSyncModuleEntryPointTests : XCTestCase
@property (nonatomic, strong) AMAModuleContextMock *ctx;
@end

@implementation AMAIDSyncModuleEntryPointTests

- (void)setUp
{
    self.ctx = [[AMAModuleContextMock alloc] initWithTestCase:self];
    [[AMAIDSyncModuleEntryPoint new] initModuleWithContext:self.ctx];
}

- (void)testInitModuleWithContext_registersExactlyOneService
{
    XCTAssertEqual(self.ctx.serviceConfigurations.count, 1u);
}

- (void)testInitModuleWithContext_registersStartupObserver
{
    AMAServiceConfiguration *config = self.ctx.serviceConfigurations.firstObject;
    XCTAssertNotNil(config.startupObserver);
    XCTAssertTrue([config.startupObserver isKindOfClass:[AMAIDSyncStartupController class]]);
}

- (void)testInitModuleWithContext_registersStorageController
{
    AMAServiceConfiguration *config = self.ctx.serviceConfigurations.firstObject;
    XCTAssertNotNil(config.reporterStorageController);
    XCTAssertTrue([config.reporterStorageController isKindOfClass:[AMAIDSyncStartupController class]]);
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
