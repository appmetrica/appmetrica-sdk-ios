#import <Kiwi/Kiwi.h>
#import "AMADecodedCrash.h"
#import "AMACrashReportCrash.h"
#import "AMAThread.h"
#import "AMABacktrace.h"
#import "AMABacktraceFrame.h"

SPEC_BEGIN(AMADecodedCrashTests)

describe(@"AMADecodedCrash", ^{
    
    id (^getBacktraceFrame)(void) = ^id {
        static NSUInteger number = 0;
        number++;
        return [[AMABacktraceFrame alloc] initWithLineOfCode:@(number)
                                          instructionAddress:@(number)
                                               symbolAddress:@(number)
                                               objectAddress:@(number)
                                                  symbolName:nil
                                                  objectName:nil
                                                    stripped:NO];
    };
    
    AMADecodedCrash *__block decodedCrash = nil;
    AMABacktrace *__block crashedBacktrace = nil;
    
    beforeEach(^{
        NSMutableArray *frames = [NSMutableArray arrayWithObjects:getBacktraceFrame(), getBacktraceFrame(), nil];
        crashedBacktrace = [[AMABacktrace alloc] initWithFrames:frames];
        AMAThread *crashedThread = [[AMAThread alloc] initWithBacktrace:crashedBacktrace
                                                              registers:nil
                                                                  stack:nil
                                                                  index:0
                                                                crashed:YES
                                                             threadName:nil
                                                              queueName:nil];
        
        frames = [NSMutableArray arrayWithObjects:getBacktraceFrame(), getBacktraceFrame(), nil];
        AMABacktrace *anotherBacktrace = [[AMABacktrace alloc] initWithFrames:frames];
        AMAThread *anotherThread = [[AMAThread alloc] initWithBacktrace:anotherBacktrace
                                                              registers:nil
                                                                  stack:nil
                                                                  index:1
                                                                crashed:NO
                                                             threadName:nil
                                                              queueName:nil];
        
        AMACrashReportCrash *crash = [[AMACrashReportCrash alloc] initWithError:nil
                                                                        threads:@[ crashedThread, anotherThread, ]];
        
        decodedCrash = [[AMADecodedCrash alloc] initWithAppState:nil
                                                     appBuildUID:nil
                                                errorEnvironment:nil
                                                  appEnvironment:nil
                                                            info:nil
                                                    binaryImages:nil
                                                          system:nil
                                                           crash:crash];
    });
    
    it(@"Should return valid crashed backtrace", ^{
        [[decodedCrash.crashedThreadBacktrace should] equal:crashedBacktrace];
    });
    
    it(@"Should create copy of crash", ^{
        AMADecodedCrash *copy = [decodedCrash copy];
        [copy.crash.threads.firstObject.backtrace.frames addObject:getBacktraceFrame()];
        
        NSArray *copiedFrames = copy.crash.threads.firstObject.backtrace.frames;
        NSArray *originalFrames = decodedCrash.crash.threads.firstObject.backtrace.frames;
        
        [[copiedFrames shouldNot] equal:originalFrames];
    });
    
});

SPEC_END
