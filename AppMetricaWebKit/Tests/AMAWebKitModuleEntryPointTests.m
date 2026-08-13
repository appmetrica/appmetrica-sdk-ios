#import <XCTest/XCTest.h>
#import <AppMetricaTestUtils/AMAModuleRegistrarMock.h>
#import "AMAWebKitModuleEntryPoint.h"

@interface AMAWebKitModuleEntryPointTests : XCTestCase
@property (nonatomic, strong) AMAModuleRegistrarMock *registrar;
@property (nonatomic, strong) AMAWebKitModuleEntryPoint *entryPoint;
@end

@implementation AMAWebKitModuleEntryPointTests

- (void)setUp
{
    self.registrar = [[AMAModuleRegistrarMock alloc] initWithTestCase:self];
    self.entryPoint = [AMAWebKitModuleEntryPoint new];
}

- (void)testModuleName
{
    XCTAssertEqualObjects(self.entryPoint.moduleName, @"AppMetricaWebKit");
}

- (void)testRegisterComponentsWithRegistrar_doesNotRegisterAnyComponent
{
    [self.entryPoint registerComponentsWithRegistrar:self.registrar];

    XCTAssertEqual(self.registrar.activationDelegates.count, 0u);
    XCTAssertEqual(self.registrar.eventPollingDelegates.count, 0u);
    XCTAssertEqual(self.registrar.eventFlushableDelegates.count, 0u);
    XCTAssertEqual(self.registrar.serviceConfigurations.count, 0u);
    XCTAssertEqual(self.registrar.adProviders.count, 0u);
}

@end
