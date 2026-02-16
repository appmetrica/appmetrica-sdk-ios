
#import "AMACrashEventConverter.h"
#import "AMACrashEvent.h"
#import "AMACrashEventError.h"
#import "AMACrashInfo.h"
#import "AMACrashThreadInfo.h"
#import "AMACrashBacktrace.h"
#import "AMACrashBacktraceFrame.h"
#import "AMADecodedCrash.h"
#import "AMAInfo.h"
#import "AMAThread.h"
#import "AMABacktrace.h"
#import "AMABacktraceFrame.h"
#import "AMACrashReportCrash.h"
#import "AMACrashReportError.h"
#import "AMASignal.h"
#import "AMACrashSignal.h"
#import "AMACrashMach.h"
#import "AMANSException.h"
#import "AMACppException.h"
#import "AMAMach.h"

@implementation AMACrashEventConverter

#pragma mark - Public

- (AMADecodedCrash *)decodedCrashFromCrashEvent:(AMACrashEvent *)event
{
    if (event == nil) {
        return nil;
    }

    AMAInfo *info = [self internalInfoFromCrashEvent:event];
    AMACrashReportCrash *crash = [self crashFromEvent:event];

    return [[AMADecodedCrash alloc] initWithAppState:event.appState
                                         appBuildUID:nil
                                    errorEnvironment:event.errorEnvironment
                                      appEnvironment:event.appEnvironment
                                                info:info
                                        binaryImages:@[]
                                              system:nil
                                               crash:crash];
}

- (AMACrashEvent *)crashEventFromDecodedCrash:(AMADecodedCrash *)decodedCrash
{
    if (decodedCrash == nil) {
        return nil;
    }

    AMACrashEventError *eventError = [self crashEventErrorFromDecodedCrash:decodedCrash];
    AMACrashInfo *info = [self crashInfoFromInfo:decodedCrash.info];
    NSArray<AMACrashThreadInfo *> *threads = [self crashThreadsFromThreads:decodedCrash.crash.threads];

    AMAMutableCrashEvent *result = [[AMAMutableCrashEvent alloc] init];
    result.appState = decodedCrash.appState;
    result.errorEnvironment = decodedCrash.errorEnvironment;
    result.appEnvironment = decodedCrash.appEnvironment;
    result.info = info;
    result.error = eventError;
    result.threads = threads;
    return [result copy];
}

#pragma mark - Internal → Public

- (nullable AMACrashInfo *)crashInfoFromInfo:(nullable AMAInfo *)info
{
    if (info == nil) {
        return nil;
    }
    AMAMutableCrashInfo *result = [[AMAMutableCrashInfo alloc] initWithCrashReportVersion:info.version];
    result.identifier = info.identifier;
    result.timestamp = info.timestamp;
    return [result copy];
}

- (nullable NSArray<AMACrashThreadInfo *> *)crashThreadsFromThreads:(nullable NSArray<AMAThread *> *)threads
{
    if (threads == nil) {
        return nil;
    }
    NSMutableArray<AMACrashThreadInfo *> *result = [NSMutableArray arrayWithCapacity:threads.count];
    for (AMAThread *thread in threads) {
        [result addObject:[self crashThreadFromThread:thread]];
    }
    return [result copy];
}

- (AMACrashThreadInfo *)crashThreadFromThread:(AMAThread *)thread
{
    AMACrashBacktrace *backtrace = [self crashBacktraceFromBacktrace:(AMABacktrace *)thread.backtrace];
    AMAMutableCrashThreadInfo *result = [[AMAMutableCrashThreadInfo alloc] initWithBacktrace:backtrace
                                                                                     crashed:thread.crashed];
    result.index = thread.index;
    result.threadName = thread.threadName;
    result.queueName = thread.queueName;
    return [result copy];
}

- (nullable AMACrashBacktrace *)crashBacktraceFromBacktrace:(nullable AMABacktrace *)backtrace
{
    if (backtrace == nil) {
        return nil;
    }
    NSMutableArray<AMACrashBacktraceFrame *> *frames = [NSMutableArray arrayWithCapacity:backtrace.frames.count];
    for (AMABacktraceFrame *frame in backtrace.frames) {
        [frames addObject:[self crashBacktraceFrameFromFrame:frame]];
    }
    return [[AMACrashBacktrace alloc] initWithFrames:[frames copy]];
}

- (AMACrashBacktraceFrame *)crashBacktraceFrameFromFrame:(AMABacktraceFrame *)frame
{
    AMAMutableCrashBacktraceFrame *result =
        [[AMAMutableCrashBacktraceFrame alloc] initWithClassName:frame.className
                                                      methodName:frame.methodName
                                                      lineOfCode:frame.lineOfCode
                                                    columnOfCode:frame.columnOfCode
                                                  sourceFileName:frame.sourceFileName];
    result.instructionAddress = frame.instructionAddress;
    result.symbolAddress = frame.symbolAddress;
    result.objectAddress = frame.objectAddress;
    result.symbolName = frame.symbolName;
    result.objectName = frame.objectName;
    result.stripped = frame.stripped;
    return [result copy];
}

#pragma mark - Public → Internal

- (AMAInfo *)internalInfoFromCrashEvent:(AMACrashEvent *)event
{
    AMACrashInfo *eventInfo = event.info;
    if (eventInfo != nil) {
        return [[AMAInfo alloc] initWithVersion:eventInfo.crashReportVersion
                                     identifier:eventInfo.identifier
                                      timestamp:eventInfo.timestamp
                             virtualMachineInfo:nil];
    }
    return [[AMAInfo alloc] initWithVersion:nil
                                 identifier:[[NSUUID UUID] UUIDString]
                                  timestamp:nil
                         virtualMachineInfo:nil];
}

- (nullable NSArray<AMAThread *> *)internalThreadsFromCrashThreads:(nullable NSArray<AMACrashThreadInfo *> *)crashThreads
{
    if (crashThreads == nil) {
        return nil;
    }
    NSMutableArray<AMAThread *> *result = [NSMutableArray arrayWithCapacity:crashThreads.count];
    for (AMACrashThreadInfo *crashThread in crashThreads) {
        [result addObject:[self internalThreadFromCrashThread:crashThread]];
    }
    return [result copy];
}

- (AMAThread *)internalThreadFromCrashThread:(AMACrashThreadInfo *)crashThread
{
    AMABacktrace *backtrace = [self internalBacktraceFromCrashBacktrace:crashThread.backtrace];
    return [[AMAThread alloc] initWithBacktrace:backtrace
                                      registers:nil
                                          stack:nil
                                          index:crashThread.index
                                        crashed:crashThread.crashed
                                     threadName:crashThread.threadName
                                      queueName:crashThread.queueName];
}

- (nullable AMABacktrace *)internalBacktraceFromCrashBacktrace:(nullable AMACrashBacktrace *)crashBacktrace
{
    if (crashBacktrace == nil) {
        return nil;
    }
    NSMutableArray<AMABacktraceFrame *> *frames = [NSMutableArray arrayWithCapacity:crashBacktrace.frames.count];
    for (AMACrashBacktraceFrame *crashFrame in crashBacktrace.frames) {
        [frames addObject:[self internalBacktraceFrameFromCrashFrame:crashFrame]];
    }
    return [[AMABacktrace alloc] initWithFrames:frames];
}

- (AMABacktraceFrame *)internalBacktraceFrameFromCrashFrame:(AMACrashBacktraceFrame *)crashFrame
{
    return [[AMABacktraceFrame alloc] initWithLineOfCode:crashFrame.lineOfCode
                                      instructionAddress:crashFrame.instructionAddress
                                           symbolAddress:crashFrame.symbolAddress
                                           objectAddress:crashFrame.objectAddress
                                              symbolName:crashFrame.symbolName
                                              objectName:crashFrame.objectName
                                                stripped:crashFrame.stripped
                                            columnOfCode:crashFrame.columnOfCode
                                               className:crashFrame.className
                                              methodName:crashFrame.methodName
                                          sourceFileName:crashFrame.sourceFileName];
}

#pragma mark - Error conversion

- (nullable AMACrashEventError *)crashEventErrorFromDecodedCrash:(AMADecodedCrash *)decodedCrash
{
    AMACrashReportError *reportError = decodedCrash.crash.error;
    if (reportError == nil) {
        return nil;
    }

    AMACrashSignal *signal = nil;
    if (reportError.signal != nil) {
        signal = [[AMACrashSignal alloc] initWithSignal:reportError.signal.signal
                                                   code:reportError.signal.code];
    }

    AMACrashMach *mach = nil;
    if (reportError.mach != nil) {
        mach = [[AMACrashMach alloc] initWithExceptionType:reportError.mach.exceptionType
                                                      code:reportError.mach.code
                                                   subcode:reportError.mach.subcode];
    }

    AMAMutableCrashEventError *result = [[AMAMutableCrashEventError alloc] initWithType:reportError.type];
    result.signal = signal;
    result.mach = mach;
    result.exceptionName = reportError.nsException.name;
    result.exceptionReason = reportError.reason;
    result.cppExceptionName = reportError.cppException.name;
    return [result copy];
}

- (AMACrashReportCrash *)crashFromEvent:(AMACrashEvent *)event
{
    AMACrashReportError *error = [self reportErrorFromEvent:event];
    NSArray<AMAThread *> *threads = [self internalThreadsFromCrashThreads:event.threads];
    if (threads == nil && error == nil) {
        return nil;
    }
    return [[AMACrashReportCrash alloc] initWithError:error threads:threads ?: @[]];
}

- (nullable AMACrashReportError *)reportErrorFromEvent:(AMACrashEvent *)event
{
    AMACrashEventError *eventError = event.error;
    if (eventError == nil) {
        return nil;
    }

    AMASignal *signal = nil;
    if (eventError.signal != nil) {
        signal = [[AMASignal alloc] initWithSignal:eventError.signal.signal
                                              code:eventError.signal.code];
    }

    AMAMach *mach = nil;
    if (eventError.mach != nil) {
        mach = [[AMAMach alloc] initWithExceptionType:eventError.mach.exceptionType
                                                 code:eventError.mach.code
                                              subcode:eventError.mach.subcode];
    }

    AMANSException *nsException = nil;
    if (eventError.exceptionName != nil) {
        nsException = [[AMANSException alloc] initWithName:eventError.exceptionName userInfo:nil];
    }

    AMACppException *cppException = nil;
    if (eventError.cppExceptionName != nil) {
        cppException = [[AMACppException alloc] initWithName:eventError.cppExceptionName];
    }

    return [[AMACrashReportError alloc] initWithAddress:0
                                                 reason:eventError.exceptionReason
                                                   type:eventError.type
                                                   mach:mach
                                                 signal:signal
                                            nsexception:nsException
                                           cppException:cppException
                                         nonFatalsChain:nil
                                    virtualMachineCrash:nil];
}

@end
