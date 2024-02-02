#import <Kiwi/Kiwi.h>
#import "AMACrashProcessor.h"
#import "AMACrashProcessingReporting.h"
#import "AMACrashReportCrash.h"
#import "AMACrashReportError.h"
#import "AMACrashReporter.h"
#import "AMADecodedCrash.h"
#import "AMADecodedCrashSerializer.h"
#import "AMAErrorModel.h"
#import "AMAExceptionFormatter.h"
#import "AMASignal.h"

SPEC_BEGIN(AMACrashProcessorTests)

describe(@"AMACrashProcessor", ^{
    
    let(serializer, ^{ return [AMADecodedCrashSerializer nullMock]; });
    let(formatterMock, ^{ return [AMAExceptionFormatter nullMock]; });
    let(crashReporterMock, ^{ return [AMACrashReporter nullMock]; });
    let(crashProcessor, ^{
        return [[AMACrashProcessor alloc] initWithIgnoredSignals:nil
                                                      serializer:serializer
                                                   crashReporter:crashReporterMock
                                                       formatter:formatterMock
                                              extendedProcessors:@[]];
    });
    
    context(@"Initialization", ^{
        
        it(@"Should properly initialize with default serializer when only signals are given", ^{
            AMACrashProcessor *processor = [[AMACrashProcessor alloc] initWithIgnoredSignals:@[ @SIGABRT ]
                                                                                  serializer:serializer
                                                                               crashReporter:crashReporterMock
                                                                          extendedProcessors:@[]];
            [[processor.ignoredCrashSignals should] contain:@SIGABRT];
        });
        
        it(@"Should properly initialize with given serializer and signals", ^{
            AMACrashProcessor *processor = [[AMACrashProcessor alloc] initWithIgnoredSignals:@[ @SIGABRT ]
                                                                                  serializer:serializer
                                                                               crashReporter:crashReporterMock
                                                                                   formatter:formatterMock
                                                                          extendedProcessors:@[]];
            [[processor.ignoredCrashSignals should] contain:@SIGABRT];
        });
    });
    
    
    context(@"Should process decoded crash", ^{
        AMACrashReportCrash *__block crashMock = nil;
        AMASignal *__block signalMock = nil;
        AMACrashReportError *__block errorMock = nil;
        AMADecodedCrash *__block decodedCrashMock = nil;
        NSError *const sampleError = [NSError errorWithDomain:@"SampleDomain" code:12345 userInfo:nil];
        
        beforeEach(^{
            crashMock = [AMACrashReportCrash nullMock];
            signalMock = [AMASignal nullMock];
            errorMock = [AMACrashReportError nullMock];
            decodedCrashMock = [AMADecodedCrash nullMock];
            
            [crashMock stub:@selector(error) andReturn:errorMock];
            [errorMock stub:@selector(signal) andReturn:signalMock];
            [decodedCrashMock stub:@selector(crash) andReturn:crashMock];
        });
        
        context(@"Report crash", ^{
            it(@"Should report crash", ^{
                [[crashReporterMock should] receive:@selector(reportCrashWithParameters:)];
                [crashProcessor processCrash:decodedCrashMock withError:nil];
            });
            
            context(@"Internal Error", ^{
                it(@"Should report of internal error", ^{
                    [[crashReporterMock should] receive:@selector(reportInternalError:)
                                          withArguments:sampleError, nil];
                    [crashProcessor processCrash:decodedCrashMock withError:sampleError];
                });
                
                it(@"Should not report crash in case of internal error", ^{
                    [[crashReporterMock shouldNot] receive:@selector(reportCrashWithParameters:)];
                    [crashProcessor processCrash:decodedCrashMock withError:sampleError];
                });
            });
        });
        
        context(@"Signal exists in ignored signals", ^{
            let(crashProcessor, ^{
                return [[AMACrashProcessor alloc] initWithIgnoredSignals:@[ @SIGABRT ]
                                                              serializer:serializer
                                                           crashReporter:crashReporterMock
                                                               formatter:formatterMock
                                                      extendedProcessors:@[]];
            });
            beforeEach(^{
                [signalMock stub:@selector(signal) andReturn:theValue(SIGABRT)];
            });
            
            it(@"Should not report crash", ^{
                [[crashReporterMock shouldNot] receive:@selector(reportCrashWithParameters:)];
                [crashProcessor processCrash:decodedCrashMock withError:nil];
            });
        });
        
        context(@"Signal does not exist in ignored signals", ^{
            let(crashProcessor, ^{
                return [[AMACrashProcessor alloc] initWithIgnoredSignals:@[ @SIGQUIT ]
                                                              serializer:serializer
                                                           crashReporter:crashReporterMock
                                                               formatter:formatterMock
                                                      extendedProcessors:@[]];
            });
            beforeEach(^{
                [signalMock stub:@selector(signal) andReturn:theValue(SIGABRT)];
            });
            
            it(@"Should report crash", ^{
                [[crashReporterMock should] receive:@selector(reportCrashWithParameters:)];
                [crashProcessor processCrash:decodedCrashMock withError:nil];
            });
        });
        
        context(@"Report ANR", ^{
            it(@"Should report ANR", ^{
                [[crashReporterMock should] receive:@selector(reportANRWithParameters:)];
                [crashProcessor processANR:decodedCrashMock withError:nil];
            });
            
            context(@"Internal Error", ^{
                it(@"Should report of internal error", ^{
                    [[crashReporterMock should] receive:@selector(reportInternalError:)
                                          withArguments:sampleError, nil];
                    [crashProcessor processANR:decodedCrashMock withError:sampleError];
                });
                
                it(@"Should not report ANR in case of internal error", ^{
                    [[crashReporterMock shouldNot] receive:@selector(reportANRWithParameters:)];
                    [crashProcessor processANR:decodedCrashMock withError:sampleError];
                });
            });
        });
        
        context(@"Process Error", ^{
            let(errorMock, ^{ return [NSError nullMock]; });
            
            it(@"Should report nserror", ^{
                [[crashReporterMock should] receive:@selector(reportNSError:onFailure:)
                                      withArguments:errorMock, kw_any()];
                
                [crashProcessor processError:errorMock];
            });
        });
    });
});

SPEC_END
