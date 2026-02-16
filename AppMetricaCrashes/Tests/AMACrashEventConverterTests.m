
#import <XCTest/XCTest.h>
#import "AMACrashEventConverter.h"
#import "AMACrashEvent.h"
#import "AMACrashEventError.h"
#import "AMACrashInfo.h"
#import "AMACrashThreadInfo.h"
#import "AMACrashBacktrace.h"
#import "AMACrashBacktraceFrame.h"
#import "AMACrashSignal.h"
#import "AMACrashMach.h"
#import "AMADecodedCrash.h"
#import "AMAInfo.h"
#import "AMACrashReportCrash.h"
#import "AMACrashReportError.h"
#import "AMASignal.h"
#import "AMAMach.h"
#import "AMANSException.h"
#import "AMACppException.h"
#import "AMAThread.h"
#import "AMABacktrace.h"
#import "AMABacktraceFrame.h"

@interface AMACrashEventConverterTests : XCTestCase

@property (nonatomic, strong) AMACrashEventConverter *converter;

@end

@implementation AMACrashEventConverterTests

- (void)setUp
{
    self.converter = [[AMACrashEventConverter alloc] init];
}

#pragma mark - Nil handling

- (void)testCrashEventFromNilDecodedCrash
{
    XCTAssertNil([self.converter crashEventFromDecodedCrash:nil]);
}

- (void)testDecodedCrashFromNilCrashEvent
{
    XCTAssertNil([self.converter decodedCrashFromCrashEvent:nil]);
}

#pragma mark - Internal → Public (crashEventFromDecodedCrash:)

- (void)testCrashEventEnvironments
{
    NSDictionary *appEnv = @{ @"app_key" : @"app_value" };
    NSDictionary *errorEnv = @{ @"err_key" : @"err_value" };
    AMADecodedCrash *decoded = [self decodedCrashWithError:nil
                                            appEnvironment:appEnv
                                          errorEnvironment:errorEnv];

    AMACrashEvent *event = [self.converter crashEventFromDecodedCrash:decoded];

    XCTAssertEqualObjects(event.appEnvironment, appEnv);
    XCTAssertEqualObjects(event.errorEnvironment, errorEnv);
}

- (void)testCrashEventIsImmutable
{
    AMADecodedCrash *decoded = [self decodedCrashWithError:nil];
    AMACrashEvent *event = [self.converter crashEventFromDecodedCrash:decoded];

    XCTAssertTrue([event isMemberOfClass:[AMACrashEvent class]]);
}

- (void)testCrashEventInfo
{
    NSDate *timestamp = [NSDate dateWithTimeIntervalSince1970:1000];
    AMAInfo *info = [[AMAInfo alloc] initWithVersion:@"3.0"
                                          identifier:@"test-id"
                                           timestamp:timestamp
                                  virtualMachineInfo:nil];
    AMADecodedCrash *decoded = [self decodedCrashWithInfo:info];

    AMACrashEvent *event = [self.converter crashEventFromDecodedCrash:decoded];

    XCTAssertEqualObjects(event.info.crashReportVersion, @"3.0");
    XCTAssertEqualObjects(event.info.identifier, @"test-id");
    XCTAssertEqualObjects(event.info.timestamp, timestamp);
}

- (void)testCrashEventErrorSignal
{
    AMASignal *signal = [[AMASignal alloc] initWithSignal:11 code:3];
    AMACrashReportError *reportError = [self reportErrorWithType:AMACrashTypeSignal
                                                          signal:signal
                                                            mach:nil
                                                     nsException:nil
                                                    cppException:nil
                                                          reason:nil];
    AMADecodedCrash *decoded = [self decodedCrashWithError:reportError];

    AMACrashEvent *event = [self.converter crashEventFromDecodedCrash:decoded];

    XCTAssertEqual(event.error.type, AMACrashTypeSignal);
    XCTAssertEqual(event.error.signal.signal, 11);
    XCTAssertEqual(event.error.signal.code, 3);
}

- (void)testCrashEventErrorMach
{
    AMAMach *mach = [[AMAMach alloc] initWithExceptionType:1 code:2 subcode:3];
    AMACrashReportError *reportError = [self reportErrorWithType:AMACrashTypeMachException
                                                          signal:nil
                                                            mach:mach
                                                     nsException:nil
                                                    cppException:nil
                                                          reason:nil];
    AMADecodedCrash *decoded = [self decodedCrashWithError:reportError];

    AMACrashEvent *event = [self.converter crashEventFromDecodedCrash:decoded];

    XCTAssertEqual(event.error.type, AMACrashTypeMachException);
    XCTAssertEqual(event.error.mach.exceptionType, 1);
    XCTAssertEqual(event.error.mach.code, 2);
    XCTAssertEqual(event.error.mach.subcode, 3);
}

- (void)testCrashEventErrorNSException
{
    AMANSException *nsException = [[AMANSException alloc] initWithName:@"NSInvalidArgumentException" userInfo:@"some info"];
    AMACrashReportError *reportError = [self reportErrorWithType:AMACrashTypeNsException
                                                          signal:nil
                                                            mach:nil
                                                     nsException:nsException
                                                    cppException:nil
                                                          reason:@"unrecognized selector"];
    AMADecodedCrash *decoded = [self decodedCrashWithError:reportError];

    AMACrashEvent *event = [self.converter crashEventFromDecodedCrash:decoded];

    XCTAssertEqual(event.error.type, AMACrashTypeNsException);
    XCTAssertEqualObjects(event.error.exceptionName, @"NSInvalidArgumentException");
    XCTAssertEqualObjects(event.error.exceptionReason, @"unrecognized selector");
}

- (void)testCrashEventErrorCppException
{
    AMACppException *cppException = [[AMACppException alloc] initWithName:@"std::bad_alloc"];
    AMACrashReportError *reportError = [self reportErrorWithType:AMACrashTypeCppException
                                                          signal:nil
                                                            mach:nil
                                                     nsException:nil
                                                    cppException:cppException
                                                          reason:nil];
    AMADecodedCrash *decoded = [self decodedCrashWithError:reportError];

    AMACrashEvent *event = [self.converter crashEventFromDecodedCrash:decoded];

    XCTAssertEqualObjects(event.error.cppExceptionName, @"std::bad_alloc");
}

- (void)testCrashEventErrorNilWhenNoReportError
{
    AMADecodedCrash *decoded = [self decodedCrashWithError:nil];

    AMACrashEvent *event = [self.converter crashEventFromDecodedCrash:decoded];

    XCTAssertNil(event.error);
}

- (void)testCrashEventThreads
{
    AMABacktraceFrame *frame = [[AMABacktraceFrame alloc] initWithLineOfCode:@42
                                                          instructionAddress:@(0x1234)
                                                               symbolAddress:@(0x1200)
                                                               objectAddress:@(0x1000)
                                                                  symbolName:@"-[MyClass method]"
                                                                  objectName:@"MyApp"
                                                                    stripped:NO
                                                                columnOfCode:@10
                                                                   className:@"MyClass"
                                                                  methodName:@"method"
                                                              sourceFileName:@"MyClass.m"];
    AMABacktrace *backtrace = [[AMABacktrace alloc] initWithFrames:[@[frame] mutableCopy]];
    AMAThread *thread = [[AMAThread alloc] initWithBacktrace:backtrace
                                                   registers:nil
                                                       stack:nil
                                                       index:2
                                                     crashed:YES
                                                  threadName:@"main"
                                                   queueName:@"com.apple.main-thread"];
    AMACrashReportCrash *crash = [[AMACrashReportCrash alloc] initWithError:nil threads:@[thread]];
    AMADecodedCrash *decoded = [self decodedCrashWithCrash:crash];

    AMACrashEvent *event = [self.converter crashEventFromDecodedCrash:decoded];

    XCTAssertEqual(event.threads.count, 1u);

    AMACrashThreadInfo *threadInfo = event.threads.firstObject;
    XCTAssertEqual(threadInfo.index, 2u);
    XCTAssertTrue(threadInfo.crashed);
    XCTAssertEqualObjects(threadInfo.threadName, @"main");
    XCTAssertEqualObjects(threadInfo.queueName, @"com.apple.main-thread");

    AMACrashBacktraceFrame *resultFrame = threadInfo.backtrace.frames.firstObject;
    XCTAssertEqualObjects(resultFrame.lineOfCode, @42);
    XCTAssertEqualObjects(resultFrame.columnOfCode, @10);
    XCTAssertEqualObjects(resultFrame.instructionAddress, @(0x1234));
    XCTAssertEqualObjects(resultFrame.symbolAddress, @(0x1200));
    XCTAssertEqualObjects(resultFrame.objectAddress, @(0x1000));
    XCTAssertEqualObjects(resultFrame.symbolName, @"-[MyClass method]");
    XCTAssertEqualObjects(resultFrame.objectName, @"MyApp");
    XCTAssertEqualObjects(resultFrame.className, @"MyClass");
    XCTAssertEqualObjects(resultFrame.methodName, @"method");
    XCTAssertEqualObjects(resultFrame.sourceFileName, @"MyClass.m");
    XCTAssertFalse(resultFrame.stripped);
}

- (void)testCrashEventCrashedThread
{
    AMAThread *normalThread = [[AMAThread alloc] initWithBacktrace:nil registers:nil stack:nil
                                                             index:0 crashed:NO
                                                        threadName:@"bg" queueName:nil];
    AMAThread *crashedThread = [[AMAThread alloc] initWithBacktrace:nil registers:nil stack:nil
                                                               index:1 crashed:YES
                                                          threadName:@"main" queueName:nil];
    AMACrashReportCrash *crash = [[AMACrashReportCrash alloc] initWithError:nil
                                                                    threads:@[normalThread, crashedThread]];
    AMADecodedCrash *decoded = [self decodedCrashWithCrash:crash];

    AMACrashEvent *event = [self.converter crashEventFromDecodedCrash:decoded];

    XCTAssertNotNil(event.crashedThread);
    XCTAssertEqual(event.crashedThread.index, 1u);
    XCTAssertTrue(event.crashedThread.crashed);
}

#pragma mark - Public → Internal (decodedCrashFromCrashEvent:)

- (void)testDecodedCrashEnvironments
{
    AMAMutableCrashEvent *event = [[AMAMutableCrashEvent alloc] init];
    event.appEnvironment = @{ @"a" : @"1" };
    event.errorEnvironment = @{ @"b" : @"2" };

    AMADecodedCrash *decoded = [self.converter decodedCrashFromCrashEvent:event];

    XCTAssertEqualObjects(decoded.appEnvironment, @{ @"a" : @"1" });
    XCTAssertEqualObjects(decoded.errorEnvironment, @{ @"b" : @"2" });
}

- (void)testDecodedCrashInfoFromEvent
{
    AMAMutableCrashEvent *event = [[AMAMutableCrashEvent alloc] init];
    AMAMutableCrashInfo *info = [[AMAMutableCrashInfo alloc] initWithCrashReportVersion:@"2.0"];
    info.identifier = @"crash-123";
    info.timestamp = [NSDate dateWithTimeIntervalSince1970:500];
    event.info = info;

    AMADecodedCrash *decoded = [self.converter decodedCrashFromCrashEvent:event];

    XCTAssertEqualObjects(decoded.info.version, @"2.0");
    XCTAssertEqualObjects(decoded.info.identifier, @"crash-123");
    XCTAssertEqualObjects(decoded.info.timestamp, [NSDate dateWithTimeIntervalSince1970:500]);
}

- (void)testDecodedCrashInfoGeneratesIdentifierWhenNoInfo
{
    AMAMutableCrashEvent *event = [[AMAMutableCrashEvent alloc] init];
    event.info = nil;

    AMADecodedCrash *decoded = [self.converter decodedCrashFromCrashEvent:event];

    XCTAssertNotNil(decoded.info.identifier);
    XCTAssertTrue(decoded.info.identifier.length > 0);
}

- (void)testDecodedCrashErrorSignal
{
    AMAMutableCrashEvent *event = [[AMAMutableCrashEvent alloc] init];
    AMAMutableCrashEventError *error = [[AMAMutableCrashEventError alloc] initWithType:AMACrashTypeSignal];
    error.signal = [[AMACrashSignal alloc] initWithSignal:11 code:0];
    event.error = error;

    AMADecodedCrash *decoded = [self.converter decodedCrashFromCrashEvent:event];

    XCTAssertEqual(decoded.crash.error.type, AMACrashTypeSignal);
    XCTAssertEqual(decoded.crash.error.signal.signal, 11);
    XCTAssertEqual(decoded.crash.error.signal.code, 0);
}

- (void)testDecodedCrashErrorMach
{
    AMAMutableCrashEvent *event = [[AMAMutableCrashEvent alloc] init];
    AMAMutableCrashEventError *error = [[AMAMutableCrashEventError alloc] initWithType:AMACrashTypeMachException];
    error.mach = [[AMACrashMach alloc] initWithExceptionType:1 code:100 subcode:200];
    event.error = error;

    AMADecodedCrash *decoded = [self.converter decodedCrashFromCrashEvent:event];

    XCTAssertEqual(decoded.crash.error.mach.exceptionType, 1);
    XCTAssertEqual(decoded.crash.error.mach.code, 100);
    XCTAssertEqual(decoded.crash.error.mach.subcode, 200);
}

- (void)testDecodedCrashErrorNSException
{
    AMAMutableCrashEvent *event = [[AMAMutableCrashEvent alloc] init];
    AMAMutableCrashEventError *error = [[AMAMutableCrashEventError alloc] initWithType:AMACrashTypeNsException];
    error.exceptionName = @"NSRangeException";
    error.exceptionReason = @"index out of bounds";
    event.error = error;

    AMADecodedCrash *decoded = [self.converter decodedCrashFromCrashEvent:event];

    XCTAssertEqualObjects(decoded.crash.error.nsException.name, @"NSRangeException");
    XCTAssertEqualObjects(decoded.crash.error.reason, @"index out of bounds");
}

- (void)testDecodedCrashErrorCppException
{
    AMAMutableCrashEvent *event = [[AMAMutableCrashEvent alloc] init];
    AMAMutableCrashEventError *error = [[AMAMutableCrashEventError alloc] initWithType:AMACrashTypeCppException];
    error.cppExceptionName = @"std::out_of_range";
    event.error = error;

    AMADecodedCrash *decoded = [self.converter decodedCrashFromCrashEvent:event];

    XCTAssertEqualObjects(decoded.crash.error.cppException.name, @"std::out_of_range");
}

- (void)testDecodedCrashNilCrashWhenNoErrorAndNoThreads
{
    AMAMutableCrashEvent *event = [[AMAMutableCrashEvent alloc] init];
    event.error = nil;
    event.threads = nil;

    AMADecodedCrash *decoded = [self.converter decodedCrashFromCrashEvent:event];

    XCTAssertNil(decoded.crash);
}

- (void)testDecodedCrashThreads
{
    AMAMutableCrashEvent *event = [[AMAMutableCrashEvent alloc] init];

    AMAMutableCrashBacktraceFrame *frame =
        [[AMAMutableCrashBacktraceFrame alloc] initWithClassName:@"Cls"
                                                      methodName:@"mtd"
                                                      lineOfCode:@10
                                                    columnOfCode:@5
                                                  sourceFileName:@"Cls.m"];
    frame.instructionAddress = @(0xABCD);
    frame.symbolAddress = @(0xAB00);
    frame.objectAddress = @(0xA000);
    frame.symbolName = @"-[Cls mtd]";
    frame.objectName = @"Binary";
    frame.stripped = YES;

    AMACrashBacktrace *bt = [[AMACrashBacktrace alloc] initWithFrames:@[frame]];
    AMAMutableCrashThreadInfo *threadInfo = [[AMAMutableCrashThreadInfo alloc] initWithBacktrace:bt
                                                                                         crashed:YES];
    threadInfo.index = 3;
    threadInfo.threadName = @"worker";
    threadInfo.queueName = @"com.test.queue";
    event.threads = @[threadInfo];

    AMADecodedCrash *decoded = [self.converter decodedCrashFromCrashEvent:event];

    XCTAssertEqual(decoded.crash.threads.count, 1u);

    AMAThread *thread = decoded.crash.threads.firstObject;
    XCTAssertEqual(thread.index, 3u);
    XCTAssertTrue(thread.crashed);
    XCTAssertEqualObjects(thread.threadName, @"worker");
    XCTAssertEqualObjects(thread.queueName, @"com.test.queue");

    AMABacktraceFrame *resultFrame = thread.backtrace.frames.firstObject;
    XCTAssertEqualObjects(resultFrame.lineOfCode, @10);
    XCTAssertEqualObjects(resultFrame.columnOfCode, @5);
    XCTAssertEqualObjects(resultFrame.instructionAddress, @(0xABCD));
    XCTAssertEqualObjects(resultFrame.symbolAddress, @(0xAB00));
    XCTAssertEqualObjects(resultFrame.objectAddress, @(0xA000));
    XCTAssertEqualObjects(resultFrame.symbolName, @"-[Cls mtd]");
    XCTAssertEqualObjects(resultFrame.objectName, @"Binary");
    XCTAssertEqualObjects(resultFrame.className, @"Cls");
    XCTAssertEqualObjects(resultFrame.methodName, @"mtd");
    XCTAssertEqualObjects(resultFrame.sourceFileName, @"Cls.m");
    XCTAssertTrue(resultFrame.stripped);
}

#pragma mark - Round-trip

- (void)testRoundTripPreservesError
{
    AMASignal *signal = [[AMASignal alloc] initWithSignal:6 code:0];
    AMAMach *mach = [[AMAMach alloc] initWithExceptionType:1 code:10 subcode:20];
    AMANSException *nsException = [[AMANSException alloc] initWithName:@"TestException" userInfo:nil];
    AMACppException *cppException = [[AMACppException alloc] initWithName:@"test::error"];
    AMACrashReportError *error = [self reportErrorWithType:AMACrashTypeNsException
                                                    signal:signal
                                                      mach:mach
                                               nsException:nsException
                                              cppException:cppException
                                                    reason:@"test reason"];
    AMADecodedCrash *original = [self decodedCrashWithError:error];

    AMACrashEvent *event = [self.converter crashEventFromDecodedCrash:original];
    AMADecodedCrash *roundTripped = [self.converter decodedCrashFromCrashEvent:event];

    XCTAssertEqual(roundTripped.crash.error.type, AMACrashTypeNsException);
    XCTAssertEqual(roundTripped.crash.error.signal.signal, 6);
    XCTAssertEqual(roundTripped.crash.error.signal.code, 0);
    XCTAssertEqual(roundTripped.crash.error.mach.exceptionType, 1);
    XCTAssertEqual(roundTripped.crash.error.mach.code, 10);
    XCTAssertEqual(roundTripped.crash.error.mach.subcode, 20);
    XCTAssertEqualObjects(roundTripped.crash.error.nsException.name, @"TestException");
    XCTAssertEqualObjects(roundTripped.crash.error.cppException.name, @"test::error");
    XCTAssertEqualObjects(roundTripped.crash.error.reason, @"test reason");
}

- (void)testRoundTripPreservesThreadFields
{
    AMABacktraceFrame *frame = [[AMABacktraceFrame alloc] initWithLineOfCode:@1
                                                          instructionAddress:@(0xFF)
                                                               symbolAddress:@(0xF0)
                                                               objectAddress:@(0x00)
                                                                  symbolName:@"sym"
                                                                  objectName:@"obj"
                                                                    stripped:YES
                                                                columnOfCode:@2
                                                                   className:@"C"
                                                                  methodName:@"m"
                                                              sourceFileName:@"f.m"];
    AMABacktrace *bt = [[AMABacktrace alloc] initWithFrames:[@[frame] mutableCopy]];
    AMAThread *thread = [[AMAThread alloc] initWithBacktrace:bt registers:nil stack:nil
                                                       index:5 crashed:YES
                                                  threadName:@"t" queueName:@"q"];
    AMACrashReportCrash *crash = [[AMACrashReportCrash alloc] initWithError:nil threads:@[thread]];
    AMADecodedCrash *original = [self decodedCrashWithCrash:crash];

    AMACrashEvent *event = [self.converter crashEventFromDecodedCrash:original];
    AMADecodedCrash *roundTripped = [self.converter decodedCrashFromCrashEvent:event];

    AMAThread *resultThread = roundTripped.crash.threads.firstObject;
    XCTAssertEqual(resultThread.index, 5u);
    XCTAssertTrue(resultThread.crashed);
    XCTAssertEqualObjects(resultThread.threadName, @"t");
    XCTAssertEqualObjects(resultThread.queueName, @"q");

    AMABacktraceFrame *resultFrame = resultThread.backtrace.frames.firstObject;
    XCTAssertEqualObjects(resultFrame.lineOfCode, @1);
    XCTAssertEqualObjects(resultFrame.columnOfCode, @2);
    XCTAssertEqualObjects(resultFrame.instructionAddress, @(0xFF));
    XCTAssertEqualObjects(resultFrame.symbolAddress, @(0xF0));
    XCTAssertEqualObjects(resultFrame.objectAddress, @(0x00));
    XCTAssertEqualObjects(resultFrame.symbolName, @"sym");
    XCTAssertEqualObjects(resultFrame.objectName, @"obj");
    XCTAssertEqualObjects(resultFrame.className, @"C");
    XCTAssertEqualObjects(resultFrame.methodName, @"m");
    XCTAssertEqualObjects(resultFrame.sourceFileName, @"f.m");
    XCTAssertTrue(resultFrame.stripped);
}

#pragma mark - Helpers

- (AMACrashReportError *)reportErrorWithType:(AMACrashType)type
                                      signal:(AMASignal *)signal
                                        mach:(AMAMach *)mach
                                 nsException:(AMANSException *)nsException
                                cppException:(AMACppException *)cppException
                                      reason:(NSString *)reason
{
    return [[AMACrashReportError alloc] initWithAddress:0
                                                 reason:reason
                                                   type:type
                                                   mach:mach
                                                 signal:signal
                                            nsexception:nsException
                                           cppException:cppException
                                         nonFatalsChain:nil
                                    virtualMachineCrash:nil];
}

- (AMADecodedCrash *)decodedCrashWithError:(AMACrashReportError *)error
{
    AMACrashReportCrash *crash = nil;
    if (error != nil) {
        crash = [[AMACrashReportCrash alloc] initWithError:error threads:@[]];
    }
    return [self decodedCrashWithCrash:crash];
}

- (AMADecodedCrash *)decodedCrashWithError:(AMACrashReportError *)error
                            appEnvironment:(NSDictionary *)appEnv
                          errorEnvironment:(NSDictionary *)errorEnv
{
    AMACrashReportCrash *crash = nil;
    if (error != nil) {
        crash = [[AMACrashReportCrash alloc] initWithError:error threads:@[]];
    }
    AMAInfo *info = [[AMAInfo alloc] initWithVersion:nil identifier:@"id" timestamp:nil virtualMachineInfo:nil];
    return [[AMADecodedCrash alloc] initWithAppState:nil
                                         appBuildUID:nil
                                    errorEnvironment:errorEnv
                                      appEnvironment:appEnv
                                                info:info
                                        binaryImages:@[]
                                              system:nil
                                               crash:crash];
}

- (AMADecodedCrash *)decodedCrashWithInfo:(AMAInfo *)info
{
    return [[AMADecodedCrash alloc] initWithAppState:nil
                                         appBuildUID:nil
                                    errorEnvironment:nil
                                      appEnvironment:nil
                                                info:info
                                        binaryImages:@[]
                                              system:nil
                                               crash:nil];
}

- (AMADecodedCrash *)decodedCrashWithCrash:(AMACrashReportCrash *)crash
{
    AMAInfo *info = [[AMAInfo alloc] initWithVersion:nil identifier:@"id" timestamp:nil virtualMachineInfo:nil];
    return [[AMADecodedCrash alloc] initWithAppState:nil
                                         appBuildUID:nil
                                    errorEnvironment:nil
                                      appEnvironment:nil
                                                info:info
                                        binaryImages:@[]
                                              system:nil
                                               crash:crash];
}

@end
