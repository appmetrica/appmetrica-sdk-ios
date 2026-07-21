
#import <XCTest/XCTest.h>
#import "AMAAppMetricaCrashesEntryPoint.h"
#import "AMAAppMetricaCrashes.h"
#import <AppMetricaTestUtils/AMAModuleRegistrarMock.h>

@interface AMAAppMetricaCrashesEntryPointTests : XCTestCase
@property (nonatomic, strong) AMAModuleRegistrarMock *registrar;
@end

@implementation AMAAppMetricaCrashesEntryPointTests

- (void)setUp
{
    self.registrar = [[AMAModuleRegistrarMock alloc] initWithTestCase:self];
    [[AMAAppMetricaCrashesEntryPoint new] registerComponentsWithRegistrar:self.registrar];
}

- (void)testRegisterComponentsWithRegistrar_registersActivationDelegate
{
    XCTAssertTrue([self.registrar.activationDelegates containsObject:[AMAAppMetricaCrashes class]]);
}

- (void)testRegisterComponentsWithRegistrar_registersEventPollingDelegate
{
    XCTAssertTrue([self.registrar.eventPollingDelegates containsObject:[AMAAppMetricaCrashes class]]);
}

- (void)testRegisterComponentsWithRegistrar_registersExactlyOneActivationDelegate
{
    XCTAssertEqual(self.registrar.activationDelegates.count, 1u);
}

- (void)testRegisterComponentsWithRegistrar_registersExactlyOnePollingDelegate
{
    XCTAssertEqual(self.registrar.eventPollingDelegates.count, 1u);
}

- (void)testRegisterComponentsWithRegistrar_doesNotRegisterEventFlushableDelegate
{
    XCTAssertEqual(self.registrar.eventFlushableDelegates.count, 0u);
}

- (void)testRegisterComponentsWithRegistrar_doesNotRegisterServiceConfiguration
{
    XCTAssertEqual(self.registrar.serviceConfigurations.count, 0u);
}

- (void)testRegisterComponentsWithRegistrar_doesNotRegisterAdProvider
{
    XCTAssertEqual(self.registrar.adProviders.count, 0u);
}

@end
