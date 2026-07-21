
#import <XCTest/XCTest.h>
#import "AMAAdSupportModuleEntryPoint.h"
#import "AMAAdController.h"
#import <AppMetricaTestUtils/AMAModuleRegistrarMock.h>

@interface AMAAdSupportModuleEntryPointTests : XCTestCase
@property (nonatomic, strong) AMAModuleRegistrarMock *registrar;
@end

@implementation AMAAdSupportModuleEntryPointTests

- (void)setUp
{
    self.registrar = [[AMAModuleRegistrarMock alloc] initWithTestCase:self];
    [[AMAAdSupportModuleEntryPoint new] registerComponentsWithRegistrar:self.registrar];
}

- (void)testRegisterComponentsWithRegistrar_registersAdProvider
{
    XCTAssertEqual(self.registrar.adProviders.count, 1u);
}

- (void)testRegisterComponentsWithRegistrar_registersAMAAdControllerInstance
{
    XCTAssertTrue([self.registrar.adProviders.firstObject isKindOfClass:[AMAAdController class]]);
}

- (void)testRegisterComponentsWithRegistrar_doesNotRegisterActivationDelegate
{
    XCTAssertEqual(self.registrar.activationDelegates.count, 0u);
}

- (void)testRegisterComponentsWithRegistrar_doesNotRegisterEventPollingDelegate
{
    XCTAssertEqual(self.registrar.eventPollingDelegates.count, 0u);
}

- (void)testRegisterComponentsWithRegistrar_doesNotRegisterEventFlushableDelegate
{
    XCTAssertEqual(self.registrar.eventFlushableDelegates.count, 0u);
}

- (void)testRegisterComponentsWithRegistrar_doesNotRegisterServiceConfiguration
{
    XCTAssertEqual(self.registrar.serviceConfigurations.count, 0u);
}

@end
