
#import <XCTest/XCTest.h>
#import "AMAScreenshotModuleEntryPoint.h"
#import "AMAScreenshotLoader.h"
#import <AppMetricaTestUtils/AMAModuleRegistrarMock.h>

@interface AMAScreenshotModuleEntryPointTests : XCTestCase
@property (nonatomic, strong) AMAModuleRegistrarMock *registrar;
@end

@implementation AMAScreenshotModuleEntryPointTests

- (void)setUp
{
    self.registrar = [[AMAModuleRegistrarMock alloc] initWithTestCase:self];
    [[AMAScreenshotModuleEntryPoint new] registerComponentsWithRegistrar:self.registrar];
}

- (void)testRegisterComponentsWithRegistrar_registersExactlyOneService
{
    XCTAssertEqual(self.registrar.serviceConfigurations.count, 1u);
}

- (void)testRegisterComponentsWithRegistrar_registersStartupObserver
{
    AMAServiceConfiguration *config = self.registrar.serviceConfigurations.firstObject;
    XCTAssertNotNil(config.startupObserver);
    XCTAssertTrue([config.startupObserver isKindOfClass:[AMAScreenshotLoader class]]);
}

- (void)testRegisterComponentsWithRegistrar_registersStorageController
{
    AMAServiceConfiguration *config = self.registrar.serviceConfigurations.firstObject;
    XCTAssertNotNil(config.reporterStorageController);
    XCTAssertTrue([config.reporterStorageController isKindOfClass:[AMAScreenshotLoader class]]);
}

- (void)testRegisterComponentsWithRegistrar_startupObserverAndStorageControllerAreSameInstance
{
    AMAServiceConfiguration *config = self.registrar.serviceConfigurations.firstObject;
    XCTAssertEqualObjects(config.startupObserver, config.reporterStorageController);
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

- (void)testRegisterComponentsWithRegistrar_doesNotRegisterAdProvider
{
    XCTAssertEqual(self.registrar.adProviders.count, 0u);
}

@end
