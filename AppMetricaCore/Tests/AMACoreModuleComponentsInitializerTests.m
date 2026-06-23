
#import <XCTest/XCTest.h>
#import "AMACoreModuleComponentsInitializer.h"
#import "AMAModulesController.h"
#import "AMACore.h"
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "Mocks/AMAModuleContextMocks.h"

// MARK: - Tests

static NSUInteger const kPublicClassCount = 5;

static NSArray<NSString *> *publicEntryPointNames(void) {
    return @[
        @"AMAAdSupportModuleEntryPoint",
        @"AMAAppMetricaCrashesEntryPoint",
        @"AMAIDSyncModuleEntryPoint",
        @"AMAScreenshotModuleEntryPoint",
        @"AMAIronSourceModuleEntryPoint",
    ];
}

@interface AMACoreModuleComponentsInitializerTests : XCTestCase
@property (nonatomic, strong) AMAModulesController *controller;
@end

@implementation AMACoreModuleComponentsInitializerTests

- (void)setUp
{
    [AMAFakeEntryPoint resetCallCount];
    self.controller = [[AMAModulesController alloc] initWithExecutor:[AMACurrentQueueExecutor new]];
}

// MARK: - Public class names

- (void)testPublicClassNamesAreIterated
{
    NSMutableSet<NSString *> *discovered = [NSMutableSet set];

    [AMACoreModuleComponentsInitializer discoverAndRegisterInController:self.controller
                                                            classLookup:^Class(NSString *name) {
        [discovered addObject:name];
        return Nil;
    }];

    for (NSString *name in publicEntryPointNames()) {
        XCTAssertTrue([discovered containsObject:name], @"Expected class name not discovered: %@", name);
    }
}

- (void)testInternalClassNamesAreNotInPublicList
{
    NSMutableSet<NSString *> *discovered = [NSMutableSet set];

    // classLookup intercepts only what allEntryPointClassNames returns;
    // in Core tests AMAInternalEntryPointProvider is not linked, so internal names are absent.
    [AMACoreModuleComponentsInitializer discoverAndRegisterInController:self.controller
                                                            classLookup:^Class(NSString *name) {
        [discovered addObject:name];
        return Nil;
    }];

    NSArray *internalNames = @[
        @"AMAAppMetricaRTMEntryPoint",
        @"AMAAppMetricaPulseEntryPoint",
        @"AMAAppMetricaYandexEntryPoint",
    ];
    for (NSString *name in internalNames) {
        XCTAssertFalse([discovered containsObject:name], @"Internal name leaked into public list: %@", name);
    }
}

- (void)testPublicClassCount
{
    NSMutableArray<NSString *> *discovered = [NSMutableArray array];

    [AMACoreModuleComponentsInitializer discoverAndRegisterInController:self.controller
                                                            classLookup:^Class(NSString *name) {
        [discovered addObject:name];
        return Nil;
    }];

    // AMAInternalEntryPointProvider is not linked in Core tests, so only public names are iterated.
    XCTAssertEqual(discovered.count, kPublicClassCount);
}

// MARK: - Registration

- (void)testConformingClass_initModuleWithContextCalled
{
    [AMACoreModuleComponentsInitializer discoverAndRegisterInController:self.controller
                                                            classLookup:^Class(NSString *name) {
        if ([name isEqualToString:@"AMAAdSupportModuleEntryPoint"]) {
            return [AMAFakeEntryPoint class];
        }
        return Nil;
    }];

    XCTAssertEqual([AMAFakeEntryPoint initContextCallCount], 1);
}

- (void)testAllConformingClasses_initModuleWithContextCalledForEach
{
    NSMutableArray<NSString *> *discovered = [NSMutableArray array];

    [AMACoreModuleComponentsInitializer discoverAndRegisterInController:self.controller
                                                            classLookup:^Class(NSString *name) {
        [discovered addObject:name];
        return [AMAFakeEntryPoint class];
    }];

    XCTAssertEqual([AMAFakeEntryPoint initContextCallCount], (NSInteger)discovered.count);
}

- (void)testNonConformingClass_initModuleWithContextNotCalled
{
    [AMACoreModuleComponentsInitializer discoverAndRegisterInController:self.controller
                                                            classLookup:^Class(NSString *name) {
        return [NSObject class];
    }];

    XCTAssertEqual([AMAFakeEntryPoint initContextCallCount], 0);
}

- (void)testNilForAllClasses_registersNoModules
{
    [AMACoreModuleComponentsInitializer discoverAndRegisterInController:self.controller
                                                            classLookup:^Class(NSString *name) {
        return Nil;
    }];

    XCTAssertEqual([AMAFakeEntryPoint initContextCallCount], 0);
}

// MARK: - Nil classLookup

- (void)testNilClassLookup_doesNotCrash
{
    XCTAssertNoThrow([AMACoreModuleComponentsInitializer
        discoverAndRegisterInController:self.controller
                            classLookup:nil]);
}

@end
