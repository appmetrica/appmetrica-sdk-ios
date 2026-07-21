#import <XCTest/XCTest.h>
#import "AMAModuleEntryPointDiscoverer.h"

@interface AMAModuleEntryPointDiscovererValidEntryPoint : NSObject <AMAModuleEntryPoint>
@end
@implementation AMAModuleEntryPointDiscovererValidEntryPoint
- (void)registerComponentsWithRegistrar:(id<AMAModuleRegistrar>)registrar {}
@end

@interface AMAModuleEntryPointDiscovererSecondEntryPoint : NSObject <AMAModuleEntryPoint>
@end
@implementation AMAModuleEntryPointDiscovererSecondEntryPoint
- (void)registerComponentsWithRegistrar:(id<AMAModuleRegistrar>)registrar {}
@end

@interface AMAModuleEntryPointDiscovererThrowingEntryPoint : NSObject <AMAModuleEntryPoint>
@end
@implementation AMAModuleEntryPointDiscovererThrowingEntryPoint
- (instancetype)init { @throw [NSException exceptionWithName:@"test" reason:@"expected" userInfo:nil]; }
- (void)registerComponentsWithRegistrar:(id<AMAModuleRegistrar>)registrar {}
@end

@interface AMAInternalEntryPointProvider : NSObject
@end
@implementation AMAInternalEntryPointProvider
+ (NSArray<NSString *> *)entryPointClassNames
{
    return @[ @"AMAModuleEntryPointDiscovererInternalEntryPoint" ];
}
@end

@interface AMAModuleEntryPointDiscovererTests : XCTestCase
@end

@implementation AMAModuleEntryPointDiscovererTests

- (void)testDiscoverEntryPointsDeduplicatesCandidatesAndSkipsMissingInvalidAndFailingClassesWithoutReordering
{
    NSArray<NSString *> *candidates = @[
        @"valid",
        @"missing",
        @"invalid",
        @"throwing",
        @"valid",
        @"second",
    ];
    AMAModuleEntryPointDiscoverer *discoverer = [[AMAModuleEntryPointDiscoverer alloc]
        initWithCandidateClassNames:candidates
        classLookup:^Class(NSString *className) {
            if ([className isEqualToString:@"valid"]) {
                return AMAModuleEntryPointDiscovererValidEntryPoint.class;
            }
            if ([className isEqualToString:@"invalid"]) {
                return NSObject.class;
            }
            if ([className isEqualToString:@"throwing"]) {
                return AMAModuleEntryPointDiscovererThrowingEntryPoint.class;
            }
            if ([className isEqualToString:@"second"]) {
                return AMAModuleEntryPointDiscovererSecondEntryPoint.class;
            }
            return Nil;
        }];

    NSArray<id<AMAModuleEntryPoint>> *entryPoints = [discoverer discoverEntryPoints];

    XCTAssertEqual(entryPoints.count, 2u);
    XCTAssertTrue([entryPoints[0] isKindOfClass:AMAModuleEntryPointDiscovererValidEntryPoint.class]);
    XCTAssertTrue([entryPoints[1] isKindOfClass:AMAModuleEntryPointDiscovererSecondEntryPoint.class]);
}

- (void)testDefaultDiscoveryLooksUpPublicEntryPointsInDeclaredOrder
{
    NSMutableArray<NSString *> *lookedUpClassNames = [NSMutableArray array];
    AMAModuleEntryPointDiscoverer *discoverer = [[AMAModuleEntryPointDiscoverer alloc]
        initWithClassLookup:^Class(NSString *className) {
            [lookedUpClassNames addObject:className];
            return Nil;
        }];

    [discoverer discoverEntryPoints];

    XCTAssertEqualObjects(lookedUpClassNames,
                          (@[
                              @"AMAAppMetricaCrashesEntryPoint",
                              @"AMAAdSupportModuleEntryPoint",
                              @"AMAIDSyncModuleEntryPoint",
                              @"AMAScreenshotModuleEntryPoint",
                              @"AMAAppLovinMaxModuleEntryPoint",
                              @"AMAIronSourceModuleEntryPoint",
                              @"AMAModuleEntryPointDiscovererInternalEntryPoint",
                          ]));
}

- (void)testNilClassLookupFallsBackToRuntimeClassLookup
{
    AMAModuleEntryPointDiscoverer *discoverer = [[AMAModuleEntryPointDiscoverer alloc]
        initWithCandidateClassNames:@[ @"AMAModuleEntryPointDiscovererValidEntryPoint" ]
        classLookup:nil];

    NSArray<id<AMAModuleEntryPoint>> *entryPoints = [discoverer discoverEntryPoints];

    XCTAssertEqual(entryPoints.count, 1u);
    XCTAssertTrue([entryPoints.firstObject
        isKindOfClass:AMAModuleEntryPointDiscovererValidEntryPoint.class]);
}

@end
