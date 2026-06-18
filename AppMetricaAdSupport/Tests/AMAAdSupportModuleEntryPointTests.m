
#import <XCTest/XCTest.h>
#import "AMAAdSupportModuleEntryPoint.h"
#import "AMAAdController.h"
#import <AppMetricaTestUtils/AMAModuleContextMock.h>

@interface AMAAdSupportModuleEntryPointTests : XCTestCase
@property (nonatomic, strong) AMAModuleContextMock *ctx;
@end

@implementation AMAAdSupportModuleEntryPointTests

- (void)setUp
{
    self.ctx = [[AMAModuleContextMock alloc] initWithTestCase:self];
    [[AMAAdSupportModuleEntryPoint new] initModuleWithContext:self.ctx];
}

- (void)testInitModuleWithContext_registersAdProvider
{
    XCTAssertEqual(self.ctx.adProviders.count, 1u);
}

- (void)testInitModuleWithContext_registersAMAAdControllerInstance
{
    XCTAssertTrue([self.ctx.adProviders.firstObject isKindOfClass:[AMAAdController class]]);
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

- (void)testInitModuleWithContext_doesNotRegisterExternalService
{
    XCTAssertEqual(self.ctx.serviceConfigurations.count, 0u);
}

@end
