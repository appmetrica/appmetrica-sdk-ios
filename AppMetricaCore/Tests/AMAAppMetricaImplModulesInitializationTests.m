#import <XCTest/XCTest.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMAModulesController.h"
#import "Utilities/AMAMetricaConfigurationTestUtilities.h"
#import "Utilities/AMAModuleInvocationRecorder.h"
#import "Utilities/ModuleInvocationOrdering/AMAModuleInvocationOrderingAppMetricaImplStub.h"
#import "Utilities/ModuleInvocationOrdering/AMAModuleInvocationOrderingEntryPoints.h"

@interface AMAAppMetricaImpl (ModulesInitializationTests)
@property (nonatomic, strong) AMAModulesController *modulesController;
@end

@interface AMAAppMetricaImplModulesInitializationTests : XCTestCase
@property (nonatomic, strong) AMAModuleInvocationRecorder *invocationRecorder;
@end

@implementation AMAAppMetricaImplModulesInitializationTests

- (void)setUp
{
    [super setUp];
    [AMAMetricaConfigurationTestUtilities stubConfiguration];
    self.invocationRecorder = [AMAModuleInvocationRecorder new];
    AMAModuleInvocationOrderingConfigureRecorder(self.invocationRecorder);
}

- (void)tearDown
{
    AMAModuleInvocationOrderingReset();
    self.invocationRecorder = nil;
    [AMAMetricaConfigurationTestUtilities destubConfiguration];
    [super tearDown];
}

- (void)testImplInitializationPublishesControllerAndStartsDiscoveryAsynchronously
{
    // Impl initialization must publish the controller synchronously, while module discovery remains
    // queued and registers entry points only after the SDK executor starts processing its work.
    AMAManualCurrentQueueExecutor *executor = [[AMAManualCurrentQueueExecutor alloc] init];
    AMAModuleInvocationOrderingAppMetricaImplStub *impl =
        [[AMAModuleInvocationOrderingAppMetricaImplStub alloc]
        initWithHostStateProvider:nil
        executor:executor];

    XCTAssertNotNil(impl.modulesController);
    XCTAssertEqualObjects(self.invocationRecorder.invocations, (@[]));

    [executor execute];

    XCTAssertEqualObjects(self.invocationRecorder.invocations,
                          (@[
                              AMAModuleInvocation(AMAModuleInvocationOrderingPublicActivationEntryPoint.class,
                                                  @selector(registerComponentsWithRegistrar:)),
                          ]));
}

- (void)testProductionInitializationPublishesControllerBeforeQueuedLoadingRuns
{
    // Invoke the superclass implementation with a stopped executor. The controller must be replaced
    // immediately; the old implementation that created it inside execute: leaves the stub controller in place.
    AMAManualCurrentQueueExecutor *executor = [[AMAManualCurrentQueueExecutor alloc] init];
    AMAModuleInvocationOrderingAppMetricaImplStub *impl =
        [[AMAModuleInvocationOrderingAppMetricaImplStub alloc]
        initWithHostStateProvider:nil
        executor:executor];
    AMAModulesController *stubController = impl.modulesController;

    [impl initializeModulesControllerUsingProductionImplementation];

    XCTAssertNotNil(impl.modulesController);
    XCTAssertTrue(impl.modulesController != stubController);
    XCTAssertEqualObjects(self.invocationRecorder.invocations, (@[]));
}

@end
