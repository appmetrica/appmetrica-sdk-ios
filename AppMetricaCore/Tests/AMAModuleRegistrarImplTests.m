#import <XCTest/XCTest.h>
#import "AMAModuleRegistrarImpl.h"
#import "AMAModuleRegistry.h"
#import "Mocks/AMAAdProvidingMock.h"
#import "Mocks/AMAModuleRegistrarMocks.h"
#import "Utilities/AMAEventPollingDelegateMock.h"

@interface AMAModuleRegistrarSecondActivationDelegate : NSObject <AMAModuleActivationDelegate>
@end

@implementation AMAModuleRegistrarSecondActivationDelegate

+ (void)willActivateWithConfiguration:(AMAModuleActivationConfiguration *)configuration {}
+ (void)didActivateWithConfiguration:(AMAModuleActivationConfiguration *)configuration {}

@end

@interface AMAModuleRegistrarLateActivationDelegate : NSObject <AMAModuleActivationDelegate>
@end

@implementation AMAModuleRegistrarLateActivationDelegate

+ (void)willActivateWithConfiguration:(AMAModuleActivationConfiguration *)configuration {}
+ (void)didActivateWithConfiguration:(AMAModuleActivationConfiguration *)configuration {}

@end

@interface AMAModuleRegistrarImplTests : XCTestCase
@end

@implementation AMAModuleRegistrarImplTests

- (void)testPublicationPreservesRegistrationOrderDeduplicatesAndRejectsLateRegistrations
{
    AMAModuleRegistrarImpl *registrar = [[AMAModuleRegistrarImpl alloc] init];
    AMAModulePreActivationHandlerMock *firstHandler = [[AMAModulePreActivationHandlerMock alloc] init];
    AMAModulePreActivationHandlerMock *secondHandler = [[AMAModulePreActivationHandlerMock alloc] init];
    AMAExtendedStartupObservingMock *startupObserver = [[AMAExtendedStartupObservingMock alloc] init];
    AMAReporterStorageControllingMock *storageController =
        [[AMAReporterStorageControllingMock alloc] init];
    AMAAdProvidingMock *firstAdProvider = [[AMAAdProvidingMock alloc] init];
    AMAAdProvidingMock *secondAdProvider = [[AMAAdProvidingMock alloc] init];
    AMAFakeEntryPoint *firstEntryPoint = [[AMAFakeEntryPoint alloc] init];
    AMAFakeEntryPoint *secondEntryPoint = [[AMAFakeEntryPoint alloc] init];

    [registrar registerPreActivationHandler:firstHandler];
    [registrar registerPreActivationHandler:secondHandler];
    [registrar registerPreActivationHandler:firstHandler];
    [registrar registerActivationDelegate:AMAModuleActivationDelegateMock.class];
    [registrar registerActivationDelegate:AMAModuleRegistrarSecondActivationDelegate.class];
    [registrar registerActivationDelegate:AMAModuleActivationDelegateMock.class];
    [registrar registerEventPollingDelegate:AMAEventPollingDelegateMock.class];
    [registrar registerEventPollingDelegate:AMAEventPollingDelegateMock.class];
    [registrar registerEventFlushableDelegate:AMAEventFlushableDelegateMock.class];
    [registrar registerEventFlushableDelegate:AMAEventFlushableDelegateMock.class];
    [registrar registerServiceConfiguration:[[AMAServiceConfiguration alloc]
        initWithStartupObserver:startupObserver reporterStorageController:storageController]];
    [registrar registerServiceConfiguration:[[AMAServiceConfiguration alloc]
        initWithStartupObserver:startupObserver reporterStorageController:storageController]];
    [registrar registerAdProvider:firstAdProvider];
    [registrar registerAdProvider:secondAdProvider];

    AMAModuleRegistry *registry = [registrar publishRegistryWithEntryPoints:
        @[ firstEntryPoint, secondEntryPoint ]];

    XCTAssertEqualObjects(registry.entryPoints, (@[ firstEntryPoint, secondEntryPoint ]));
    XCTAssertEqualObjects(registry.preActivationHandlers, (@[ firstHandler, secondHandler ]));
    XCTAssertEqualObjects(registry.activationDelegates,
                          (@[ AMAModuleActivationDelegateMock.class,
                              AMAModuleRegistrarSecondActivationDelegate.class ]));
    XCTAssertEqualObjects(registry.pollingDelegates, (@[ AMAEventPollingDelegateMock.class ]));
    XCTAssertEqualObjects(registry.flushableDelegates, (@[ AMAEventFlushableDelegateMock.class ]));
    XCTAssertEqualObjects(registry.startupObservers, (@[ startupObserver ]));
    XCTAssertEqualObjects(registry.storageControllers, (@[ storageController ]));
    XCTAssertTrue(registry.adProvider == secondAdProvider);

    [registrar registerActivationDelegate:AMAModuleRegistrarLateActivationDelegate.class];
    [registrar registerPreActivationHandler:[[AMAModulePreActivationHandlerMock alloc] init]];
    [registrar registerAdProvider:firstAdProvider];

    XCTAssertEqual(registry.activationDelegates.count, 2u);
    XCTAssertFalse([registry.activationDelegates
        containsObject:AMAModuleRegistrarLateActivationDelegate.class]);
    XCTAssertEqual(registry.preActivationHandlers.count, 2u);
    XCTAssertTrue(registry.adProvider == secondAdProvider);
    XCTAssertTrue([registrar publishRegistryWithEntryPoints:@[]] == registry);
}

- (void)testConcurrentRegistrationAndPublicationAlwaysProducesOneStableSnapshot
{
    for (NSUInteger iteration = 0; iteration < 50; iteration++) {
        AMAModuleRegistrarImpl *registrar = [[AMAModuleRegistrarImpl alloc] init];
        dispatch_group_t group = dispatch_group_create();
        dispatch_queue_t queue = dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0);
        __block AMAModuleRegistry *publishedRegistry = nil;

        dispatch_group_async(group, queue, ^{
            [registrar registerActivationDelegate:AMAModuleActivationDelegateMock.class];
        });
        dispatch_group_async(group, queue, ^{
            publishedRegistry = [registrar publishRegistryWithEntryPoints:@[]];
        });

        XCTAssertEqual(dispatch_group_wait(group,
                                           dispatch_time(DISPATCH_TIME_NOW,
                                                         (int64_t)(2 * NSEC_PER_SEC))),
                       0);
        XCTAssertNotNil(publishedRegistry);
        XCTAssertLessThanOrEqual(publishedRegistry.activationDelegates.count, 1u);

        [registrar registerActivationDelegate:AMAModuleRegistrarSecondActivationDelegate.class];
        XCTAssertTrue([registrar publishRegistryWithEntryPoints:@[]] == publishedRegistry);
        XCTAssertFalse([publishedRegistry.activationDelegates
            containsObject:AMAModuleRegistrarSecondActivationDelegate.class]);
    }
}

@end
