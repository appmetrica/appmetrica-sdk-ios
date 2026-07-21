#import <XCTest/XCTest.h>
#import "AMAModuleRegistry.h"
#import "Mocks/AMAModuleRegistrarMocks.h"

@interface AMAModuleRegistryTests : XCTestCase
@end

@implementation AMAModuleRegistryTests

- (void)testInitializerCopiesAllCollections
{
    AMAFakeEntryPoint *entryPoint = [[AMAFakeEntryPoint alloc] init];
    NSMutableArray<id<AMAModuleEntryPoint>> *entryPoints =
        [NSMutableArray arrayWithObject:entryPoint];
    NSMutableArray<Class<AMAModuleActivationDelegate>> *activationDelegates =
        [NSMutableArray arrayWithObject:AMAModuleActivationDelegateMock.class];

    AMAModuleRegistry *registry = [[AMAModuleRegistry alloc]
        initWithEntryPoints:entryPoints
        preActivationHandlers:@[]
        activationDelegates:activationDelegates
        pollingDelegates:@[]
        flushableDelegates:@[]
        startupObservers:@[]
        storageControllers:@[]
        adProvider:nil];

    [entryPoints removeAllObjects];
    [activationDelegates removeAllObjects];

    XCTAssertEqualObjects(registry.entryPoints, (@[ entryPoint ]));
    XCTAssertEqualObjects(registry.activationDelegates,
                          (@[ AMAModuleActivationDelegateMock.class ]));
}

@end
