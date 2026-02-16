
#import <XCTest/XCTest.h>
#import "AMACrashEvent.h"
#import "AMACrashEventError.h"
#import "AMACrashInfo.h"
#import "AMACrashThreadInfo.h"
#import <AppMetricaPlatform/AppMetricaPlatform.h>

@interface AMACrashEventTests : XCTestCase
@end

@implementation AMACrashEventTests

#pragma mark - Init

- (void)testDefaultInitHasNilProperties
{
    AMACrashEvent *event = [[AMACrashEvent alloc] init];

    XCTAssertNotNil(event);
    XCTAssertNil(event.appState);
    XCTAssertNil(event.errorEnvironment);
    XCTAssertNil(event.appEnvironment);
    XCTAssertNil(event.info);
    XCTAssertNil(event.error);
    XCTAssertNil(event.crashedThread);
    XCTAssertNil(event.threads);
}

#pragma mark - Mutable Properties

- (void)testSetProperties
{
    AMAApplicationState *appState = [[AMAApplicationState alloc] init];
    NSDictionary *errorEnv = @{@"key1": @"value1"};
    NSDictionary *appEnv = @{@"key2": @"value2"};
    AMACrashInfo *info = [[AMACrashInfo alloc] initWithCrashReportVersion:@"1.0"];
    AMACrashEventError *error = [[AMACrashEventError alloc] initWithType:AMACrashTypeSignal];
    AMACrashThreadInfo *thread = [[AMACrashThreadInfo alloc] initWithBacktrace:nil crashed:NO];
    NSArray *threads = @[thread];

    AMAMutableCrashEvent *event = [[AMAMutableCrashEvent alloc] init];
    event.appState = appState;
    event.errorEnvironment = errorEnv;
    event.appEnvironment = appEnv;
    event.info = info;
    event.error = error;
    event.threads = threads;

    XCTAssertEqualObjects(event.appState, appState);
    XCTAssertEqualObjects(event.errorEnvironment, errorEnv);
    XCTAssertEqualObjects(event.appEnvironment, appEnv);
    XCTAssertEqual(event.info, info);
    XCTAssertEqual(event.error, error);
    XCTAssertEqualObjects(event.threads, threads);
}

#pragma mark - crashedThread

- (void)testCrashedThreadReturnsCrashedThread
{
    AMACrashThreadInfo *normalThread = [[AMACrashThreadInfo alloc] initWithBacktrace:nil crashed:NO];
    AMACrashThreadInfo *crashedThread = [[AMACrashThreadInfo alloc] initWithBacktrace:nil crashed:YES];

    AMAMutableCrashEvent *event = [[AMAMutableCrashEvent alloc] init];
    event.threads = @[normalThread, crashedThread];

    XCTAssertEqual(event.crashedThread, crashedThread);
}

- (void)testCrashedThreadReturnsNilWhenNoCrashedThread
{
    AMACrashThreadInfo *thread = [[AMACrashThreadInfo alloc] initWithBacktrace:nil crashed:NO];

    AMAMutableCrashEvent *event = [[AMAMutableCrashEvent alloc] init];
    event.threads = @[thread];

    XCTAssertNil(event.crashedThread);
}

- (void)testCrashedThreadReturnsNilForNilThreads
{
    AMACrashEvent *event = [[AMACrashEvent alloc] init];

    XCTAssertNil(event.crashedThread);
}

#pragma mark - NSCopying

- (void)testImmutableCopyReturnsSelf
{
    AMACrashEvent *event = [[AMACrashEvent alloc] init];
    AMACrashEvent *copy = [event copy];

    XCTAssertEqual(event, copy);
}

- (void)testMutableCopyReturnsDifferentInstance
{
    AMAMutableCrashEvent *mutable = [[AMAMutableCrashEvent alloc] init];
    mutable.errorEnvironment = @{@"a": @"b"};

    AMACrashEvent *copy = [mutable copy];

    XCTAssertNotEqual(mutable, copy);
    XCTAssertTrue([copy isMemberOfClass:[AMACrashEvent class]]);
    XCTAssertEqualObjects(copy.errorEnvironment, @{@"a": @"b"});
}

- (void)testMutableCopyFromImmutable
{
    AMACrashEvent *immutable = [[AMACrashEvent alloc] init];
    AMAMutableCrashEvent *mutable = [immutable mutableCopy];

    XCTAssertNotEqual(immutable, mutable);
    XCTAssertTrue([mutable isKindOfClass:[AMAMutableCrashEvent class]]);
}

- (void)testCopyPreservesAllProperties
{
    AMAApplicationState *appState = [[AMAApplicationState alloc] init];
    AMACrashInfo *info = [[AMACrashInfo alloc] initWithCrashReportVersion:@"2.0"];
    AMACrashEventError *error = [[AMACrashEventError alloc] initWithType:AMACrashTypeNsException];
    AMACrashThreadInfo *thread = [[AMACrashThreadInfo alloc] initWithBacktrace:nil crashed:YES];

    AMAMutableCrashEvent *original = [[AMAMutableCrashEvent alloc] init];
    original.appState = appState;
    original.errorEnvironment = @{@"a": @"b"};
    original.appEnvironment = @{@"c": @"d"};
    original.info = info;
    original.error = error;
    original.threads = @[thread];

    AMACrashEvent *copy = [original copy];

    XCTAssertNotNil(copy);
    XCTAssertEqualObjects(copy.appState, original.appState);
    XCTAssertEqualObjects(copy.errorEnvironment, original.errorEnvironment);
    XCTAssertEqualObjects(copy.appEnvironment, original.appEnvironment);
    XCTAssertEqual(copy.info, original.info);
    XCTAssertEqual(copy.error, original.error);
    XCTAssertEqualObjects(copy.threads, original.threads);
}

@end
