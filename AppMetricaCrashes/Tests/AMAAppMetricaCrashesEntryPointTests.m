
#import <XCTest/XCTest.h>
#import "AMAAppMetricaCrashesEntryPoint.h"
#import "AMAAppMetricaCrashes.h"
#import <AppMetricaTestUtils/AMAModuleContextMock.h>

@interface AMAAppMetricaCrashesEntryPointTests : XCTestCase
@property (nonatomic, strong) AMAModuleContextMock *ctx;
@end

@implementation AMAAppMetricaCrashesEntryPointTests

- (void)setUp
{
    self.ctx = [[AMAModuleContextMock alloc] initWithTestCase:self];
    [[AMAAppMetricaCrashesEntryPoint new] initModuleWithContext:self.ctx];
}

- (void)testInitModuleWithContext_registersActivationDelegate
{
    XCTAssertTrue([self.ctx.activationDelegates containsObject:[AMAAppMetricaCrashes class]]);
}

- (void)testInitModuleWithContext_registersEventPollingDelegate
{
    XCTAssertTrue([self.ctx.eventPollingDelegates containsObject:[AMAAppMetricaCrashes class]]);
}

- (void)testInitModuleWithContext_registersExactlyOneActivationDelegate
{
    XCTAssertEqual(self.ctx.activationDelegates.count, 1u);
}

- (void)testInitModuleWithContext_registersExactlyOnePollingDelegate
{
    XCTAssertEqual(self.ctx.eventPollingDelegates.count, 1u);
}

- (void)testInitModuleWithContext_doesNotRegisterEventFlushableDelegate
{
    XCTAssertEqual(self.ctx.eventFlushableDelegates.count, 0u);
}

- (void)testInitModuleWithContext_doesNotRegisterExternalService
{
    XCTAssertEqual(self.ctx.serviceConfigurations.count, 0u);
}

- (void)testInitModuleWithContext_doesNotRegisterAdProvider
{
    XCTAssertEqual(self.ctx.adProviders.count, 0u);
}

@end
