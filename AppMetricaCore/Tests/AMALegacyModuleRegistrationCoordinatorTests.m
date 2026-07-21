#import <XCTest/XCTest.h>
#import "AMAModuleRegistrarImpl.h"
#import "AMALegacyModuleRegistrationCoordinator.h"
#import "AMAModuleRegistry.h"
#import "Mocks/AMAModuleRegistrarMocks.h"

@interface AMALegacyModuleRegistrationCoordinatorSecondDelegate : NSObject <AMAModuleActivationDelegate>
@end

@implementation AMALegacyModuleRegistrationCoordinatorSecondDelegate

+ (void)willActivateWithConfiguration:(AMAModuleActivationConfiguration *)configuration {}
+ (void)didActivateWithConfiguration:(AMAModuleActivationConfiguration *)configuration {}

@end

@interface AMALegacyModuleRegistrationCoordinatorTests : XCTestCase
@end

@implementation AMALegacyModuleRegistrationCoordinatorTests

- (void)testBufferedAndBuildingRegistrationsAreDeliveredOnceAndPostBuildRegistrationIsRejected
{
    AMALegacyModuleRegistrationCoordinator *coordinator =
        [[AMALegacyModuleRegistrationCoordinator alloc] init];
    AMAModuleRegistrarImpl *registrar = [[AMAModuleRegistrarImpl alloc] init];
    AMAExtendedStartupObservingMock *bufferedObserver = [[AMAExtendedStartupObservingMock alloc] init];
    AMAExtendedStartupObservingMock *buildingObserver = [[AMAExtendedStartupObservingMock alloc] init];

    [coordinator registerActivationDelegate:AMAModuleActivationDelegateMock.class];
    [coordinator registerActivationDelegate:AMAModuleActivationDelegateMock.class];
    [coordinator registerServiceConfiguration:[[AMAServiceConfiguration alloc]
        initWithStartupObserver:bufferedObserver reporterStorageController:nil]];

    [coordinator beginRegistrationWithRegistrar:registrar];
    [coordinator registerActivationDelegate:AMALegacyModuleRegistrationCoordinatorSecondDelegate.class];
    [coordinator registerServiceConfiguration:[[AMAServiceConfiguration alloc]
        initWithStartupObserver:buildingObserver reporterStorageController:nil]];

    [coordinator completeRegistrationWithRegistrar:registrar];
    AMAModuleRegistry *registry = [registrar publishRegistryWithEntryPoints:@[]];
    [coordinator registerActivationDelegate:NSClassFromString(@"NSObject")];
    [coordinator registerServiceConfiguration:[[AMAServiceConfiguration alloc]
        initWithStartupObserver:[[AMAExtendedStartupObservingMock alloc] init]
        reporterStorageController:nil]];

    XCTAssertEqualObjects(registry.activationDelegates,
                          (@[ AMAModuleActivationDelegateMock.class,
                              AMALegacyModuleRegistrationCoordinatorSecondDelegate.class ]));
    XCTAssertEqualObjects(registry.startupObservers, (@[ bufferedObserver, buildingObserver ]));
}

- (void)testRegistrationConcurrentWithRegistryBuildingStartIsDeliveredExactlyOnce
{
    for (NSUInteger iteration = 0; iteration < 50; iteration++) {
        AMALegacyModuleRegistrationCoordinator *coordinator =
            [[AMALegacyModuleRegistrationCoordinator alloc] init];
        AMAModuleRegistrarImpl *registrar = [[AMAModuleRegistrarImpl alloc] init];
        AMAExtendedStartupObservingMock *startupObserver =
            [[AMAExtendedStartupObservingMock alloc] init];
        AMAServiceConfiguration *serviceConfiguration = [[AMAServiceConfiguration alloc]
            initWithStartupObserver:startupObserver reporterStorageController:nil];
        dispatch_group_t group = dispatch_group_create();
        dispatch_queue_t queue = dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0);

        dispatch_group_async(group, queue, ^{
            [coordinator beginRegistrationWithRegistrar:registrar];
        });
        dispatch_group_async(group, queue, ^{
            [coordinator registerActivationDelegate:AMAModuleActivationDelegateMock.class];
        });
        dispatch_group_async(group, queue, ^{
            [coordinator registerServiceConfiguration:serviceConfiguration];
        });
        XCTAssertEqual(dispatch_group_wait(group,
                                           dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC))), 0);

        [coordinator completeRegistrationWithRegistrar:registrar];
        AMAModuleRegistry *registry = [registrar publishRegistryWithEntryPoints:@[]];
        XCTAssertEqualObjects(registry.activationDelegates, (@[ AMAModuleActivationDelegateMock.class ]));
        XCTAssertEqualObjects(registry.startupObservers, (@[ startupObserver ]));
    }
}

@end
