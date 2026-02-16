
#import <XCTest/XCTest.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMACrashForwarder.h"
#import "AMACrashFilteringProxy.h"
#import "AMACrashEvent.h"
#import "AMADecodedCrash.h"
#import "AMADecodedCrashSerializer.h"
#import "MockCrashHandler.h"
#import "MockDecodedCrashSerializer.h"

@interface AMACrashForwarderTests : XCTestCase

@property (nonatomic, strong) AMACrashForwarder *manager;
@property (nonatomic, strong) AMADecodedCrashSerializer *serializer;

@end

@implementation AMACrashForwarderTests

- (void)setUp
{
    [super setUp];

    self.serializer = [[MockDecodedCrashSerializer alloc] init];
    self.manager = [[AMACrashForwarder alloc] initWithSerializer:self.serializer];
    [self.manager setValue:[[AMACurrentQueueExecutor alloc] init] forKey:@"executor"];
}

- (void)tearDown
{
    self.manager = nil;
    self.serializer = nil;

    [super tearDown];
}

- (AMADecodedCrash *)sampleDecodedCrash
{
    return [[AMADecodedCrash alloc] initWithAppState:nil
                                         appBuildUID:nil
                                    errorEnvironment:nil
                                      appEnvironment:nil
                                                info:nil
                                        binaryImages:nil
                                              system:nil
                                               crash:nil];
}

- (MockCrashHandler *)handlerWithAPIKey:(NSString *)apiKey crashResult:(BOOL)crashResult anrResult:(BOOL)anrResult
{
    MockCrashHandler *handler = [[MockCrashHandler alloc] init];
    handler.apiKey = apiKey;
    handler.crashResult = crashResult;
    handler.anrResult = anrResult;
    return handler;
}

- (NSDictionary *)reporters
{
    return [self.manager valueForKey:@"reporters"];
}

#pragma mark - Registration

- (void)testRegisterNilHandlerDoesNotCrash
{
    [self.manager registerHandler:nil];
    [self.manager processCrash:[self sampleDecodedCrash]];
}

#pragma mark - Crash Processing

- (void)testProcessCrashCallsHandler
{
    MockCrashHandler *handler = [self handlerWithAPIKey:@"key" crashResult:NO anrResult:NO];
    [self.manager registerHandler:handler];

    [self.manager processCrash:[self sampleDecodedCrash]];

    XCTAssertEqual(handler.crashCallCount, 1u);
    XCTAssertNotNil(handler.lastCrashEvent);
}

- (void)testProcessCrashDoesNotCreateReporterWhenHandlerReturnsNO
{
    MockCrashHandler *handler = [self handlerWithAPIKey:@"key" crashResult:NO anrResult:NO];
    [self.manager registerHandler:handler];

    [self.manager processCrash:[self sampleDecodedCrash]];

    XCTAssertNil([self reporters][@"key"]);
}

- (void)testProcessCrashCreatesReporterWhenHandlerReturnsYES
{
    MockCrashHandler *handler = [self handlerWithAPIKey:@"key" crashResult:YES anrResult:NO];
    [self.manager registerHandler:handler];

    [self.manager processCrash:[self sampleDecodedCrash]];

    XCTAssertNotNil([self reporters][@"key"]);
}

#pragma mark - ANR Processing

- (void)testProcessANRCallsHandler
{
    MockCrashHandler *handler = [self handlerWithAPIKey:@"key" crashResult:NO anrResult:NO];
    [self.manager registerHandler:handler];

    [self.manager processANR:[self sampleDecodedCrash]];

    XCTAssertEqual(handler.anrCallCount, 1u);
    XCTAssertNotNil(handler.lastCrashEvent);
}

- (void)testProcessANRDoesNotCreateReporterWhenHandlerReturnsNO
{
    MockCrashHandler *handler = [self handlerWithAPIKey:@"key" crashResult:NO anrResult:NO];
    [self.manager registerHandler:handler];

    [self.manager processANR:[self sampleDecodedCrash]];

    XCTAssertNil([self reporters][@"key"]);
}

- (void)testProcessANRCreatesReporterWhenHandlerReturnsYES
{
    MockCrashHandler *handler = [self handlerWithAPIKey:@"key" crashResult:NO anrResult:YES];
    [self.manager registerHandler:handler];

    [self.manager processANR:[self sampleDecodedCrash]];

    XCTAssertNotNil([self reporters][@"key"]);
}

#pragma mark - Multiple Handlers

- (void)testMultipleHandlersCrashIndependently
{
    MockCrashHandler *handlerA = [self handlerWithAPIKey:@"a" crashResult:YES anrResult:NO];
    MockCrashHandler *handlerB = [self handlerWithAPIKey:@"b" crashResult:NO anrResult:NO];
    [self.manager registerHandler:handlerA];
    [self.manager registerHandler:handlerB];

    [self.manager processCrash:[self sampleDecodedCrash]];

    XCTAssertEqual(handlerA.crashCallCount, 1u);
    XCTAssertEqual(handlerB.crashCallCount, 1u);
    XCTAssertNotNil([self reporters][@"a"]);
    XCTAssertNil([self reporters][@"b"]);
}

- (void)testMultipleHandlersANRIndependently
{
    MockCrashHandler *handlerA = [self handlerWithAPIKey:@"a" crashResult:NO anrResult:YES];
    MockCrashHandler *handlerB = [self handlerWithAPIKey:@"b" crashResult:NO anrResult:NO];
    [self.manager registerHandler:handlerA];
    [self.manager registerHandler:handlerB];

    [self.manager processANR:[self sampleDecodedCrash]];

    XCTAssertEqual(handlerA.anrCallCount, 1u);
    XCTAssertEqual(handlerB.anrCallCount, 1u);
    XCTAssertNotNil([self reporters][@"a"]);
    XCTAssertNil([self reporters][@"b"]);
}

#pragma mark - Reporter Reuse

- (void)testReporterReusedForSameAPIKey
{
    MockCrashHandler *handler = [self handlerWithAPIKey:@"key" crashResult:YES anrResult:YES];
    [self.manager registerHandler:handler];

    [self.manager processCrash:[self sampleDecodedCrash]];
    id firstReporter = [self reporters][@"key"];

    [self.manager processANR:[self sampleDecodedCrash]];
    id secondReporter = [self reporters][@"key"];

    XCTAssertNotNil(firstReporter);
    XCTAssertEqual(firstReporter, secondReporter);
}

#pragma mark - Weak References

- (void)testDeallocatedHandlerIsNotCalled
{
    @autoreleasepool {
        MockCrashHandler *handler = [self handlerWithAPIKey:@"key" crashResult:YES anrResult:YES];
        [self.manager registerHandler:handler];
    }

    [self.manager processCrash:[self sampleDecodedCrash]];

    XCTAssertNil([self reporters][@"key"]);
}

@end
