
#import <XCTest/XCTest.h>
#import "AMAIDSyncModuleEntryPoint.h"
#import "AMAIDSyncStartupController.h"
#import <AppMetricaTestUtils/AMAModuleRegistrarMock.h>

@interface AMAIDSyncModuleEntryPointTests : XCTestCase
@property (nonatomic, strong) AMAModuleRegistrarMock *registrar;
@end

@implementation AMAIDSyncModuleEntryPointTests

- (void)setUp
{
    self.registrar = [[AMAModuleRegistrarMock alloc] initWithTestCase:self];
    [[AMAIDSyncModuleEntryPoint new] registerComponentsWithRegistrar:self.registrar];
}

- (void)testRegisterComponentsWithRegistrar_registersExactlyOneService
{
    XCTAssertEqual(self.registrar.serviceConfigurations.count, 1u);
}

- (void)testRegisterComponentsWithRegistrar_registersStartupObserver
{
    AMAServiceConfiguration *config = self.registrar.serviceConfigurations.firstObject;
    XCTAssertNotNil(config.startupObserver);
    XCTAssertTrue([config.startupObserver isKindOfClass:[AMAIDSyncStartupController class]]);
}

- (void)testRegisterComponentsWithRegistrar_registersStorageController
{
    AMAServiceConfiguration *config = self.registrar.serviceConfigurations.firstObject;
    XCTAssertNotNil(config.reporterStorageController);
    XCTAssertTrue([config.reporterStorageController isKindOfClass:[AMAIDSyncStartupController class]]);
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
