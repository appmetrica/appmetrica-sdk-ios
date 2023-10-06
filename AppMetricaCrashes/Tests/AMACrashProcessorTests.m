#import <Kiwi/Kiwi.h>
#import <AppMetricaCore/AppMetricaCore.h>
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>

#import "AMADecodedCrash.h"
#import "AMACrashProcessingReporting.h"
#import "AMACrashProcessor.h"
#import "AMACrashReportCrash.h"
#import "AMACrashReportError.h"
#import "AMADecodedCrashSerializer.h"
#import "AMAErrorModel.h"
#import "AMASignal.h"
#import "AMAExceptionFormatter.h"

SPEC_BEGIN(AMACrashProcessorTests)

describe(@"AMACrashProcessor", ^{

    let(serializer, ^{ return [AMADecodedCrashSerializer nullMock]; });
    let(formatterMock, ^{ return [AMAExceptionFormatter nullMock]; });
    let(crashProcessor, ^{
        return [[AMACrashProcessor alloc] initWithIgnoredSignals:nil
                                                      serializer:serializer
                                                       formatter:formatterMock];
    });

    context(@"Initialization", ^{

        it(@"Should properly initialize with default serializer when only signals are given", ^{
            AMACrashProcessor *processor = [[AMACrashProcessor alloc] initWithIgnoredSignals:@[ @SIGABRT ]
                                                                                  serializer:serializer];
            [[processor.ignoredCrashSignals should] contain:@SIGABRT];
        });
        
        it(@"Should properly initialize with given serializer and signals", ^{
            AMACrashProcessor *processor = [[AMACrashProcessor alloc] initWithIgnoredSignals:@[ @SIGABRT ]
                                                                                  serializer:serializer
                                                                                   formatter:formatterMock];
            [[processor.ignoredCrashSignals should] contain:@SIGABRT];
        });
        
        it(@"Should have empty set of extendedCrashReporters by default", ^{
            [[crashProcessor.extendedCrashReporters should] beEmpty];
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
            
            [AMAAppMetrica stub:@selector(reportEventWithParameters:onFailure:)];
        });
        
        context(@"Report crash", ^{
            it(@"Should report to AMAAppMetrica", ^{
                [[AMAAppMetrica should] receive:@selector(reportEventWithParameters:onFailure:)];
                [crashProcessor processCrash:decodedCrashMock withError:nil];
            });
        });
        
        context(@"Signal exists in ignored signals", ^{
            let(crashProcessor, ^{
                return [[AMACrashProcessor alloc] initWithIgnoredSignals:@[ @SIGABRT ]
                                                              serializer:serializer
                                                               formatter:formatterMock];
            });
            beforeEach(^{
                [signalMock stub:@selector(signal) andReturn:theValue(SIGABRT)];
            });
            
            it(@"Should not report to AMAAppMetrica", ^{
                [[AMAAppMetrica shouldNot] receive:@selector(reportEventWithParameters:onFailure:)];
                [crashProcessor processCrash:decodedCrashMock withError:nil];
            });
        });
        
        context(@"Signal does not exist in ignored signals", ^{
            let(crashProcessor, ^{
                return [[AMACrashProcessor alloc] initWithIgnoredSignals:@[ @SIGQUIT ]
                                                              serializer:serializer
                                                               formatter:formatterMock];
            });
            beforeEach(^{
                [signalMock stub:@selector(signal) andReturn:theValue(SIGABRT)];
            });
            
            it(@"Should report to AMAAppMetrica", ^{
                [[AMAAppMetrica should] receive:@selector(reportEventWithParameters:onFailure:)];
                [crashProcessor processCrash:decodedCrashMock withError:nil];
            });
        });
        
        context(@"Report ANR", ^{
            it(@"Should report to AMAAppMetrica", ^{
                [[AMAAppMetrica should] receive:@selector(reportEventWithParameters:onFailure:)];
                [crashProcessor processANR:decodedCrashMock withError:nil];
            });
        });
        
        context(@"Process Error", ^{
            
            let(errorModelMock, ^{ return [AMAErrorModel nullMock]; });
            
            it(@"Should call onFailure when formatter returns nil", ^{
                [formatterMock stub:@selector(formattedError:) andReturn:nil];
                
                __block BOOL onFailureCalled = NO;
                [crashProcessor processError:errorModelMock onFailure:^(NSError *error) {
                    onFailureCalled = YES;
                }];
                
                [[theValue(onFailureCalled) should] beYes];
            });
            
            it(@"Should call AMAAppMetrica reportEventWithParameters:onFailure: when formatted data is not nil", ^{
                NSData *mockData = [NSData new];
                [formatterMock stub:@selector(formattedError:) andReturn:mockData];
                
                [[AMAAppMetrica should] receive:@selector(reportEventWithParameters:onFailure:)];
                
                [crashProcessor processError:errorModelMock onFailure:^(NSError *error) {}];
            });
            
            it(@"Should call onFailure when AMAAppMetrica reports an error", ^{
                NSData *mockData = [NSData new];
                [formatterMock stub:@selector(formattedError:) andReturn:mockData];
                
                NSError *sampleError = [NSError errorWithDomain:@"TestDomain" code:1 userInfo:nil];
                
                [AMAAppMetrica stub:@selector(reportEventWithParameters:onFailure:) withBlock:^id(NSArray *params) {
                    void (^failureBlock)(NSError *) = params[1];
                    failureBlock(sampleError);
                    return nil;
                }];
                
                __block BOOL onFailureCalled = NO;
                [crashProcessor processError:errorModelMock onFailure:^(NSError *error) {
                    onFailureCalled = YES;
                }];
                
                [[theValue(onFailureCalled) should] beYes];
            });
        });
        
        context(@"Report crash with non-nil error", ^{
            
            NSError *__block invalidNameError = [NSError errorWithDomain:@"AMAAppMetricaEventErrorCodeDomain"
                                                                    code:AMAAppMetricaEventErrorCodeInvalidName
                                                                userInfo:nil];
            NSError *__block recrashError = [NSError errorWithDomain:@"AMAAppMetricaEventErrorCodeDomain"
                                                                code:AMAAppMetricaInternalEventErrorCodeRecrash
                                                            userInfo:nil];
            NSError *__block unsupportedVersionError = [NSError errorWithDomain:@"AMAAppMetricaEventErrorCodeDomain"
                                                                           code:AMAAppMetricaInternalEventErrorCodeUnsupportedReportVersion
                                                                       userInfo:nil];
            
            it(@"Should report corrupted crash report for InvalidName error", ^{
                [[[AMAAppMetrica sharedInternalEventsReporter] should]
                 receive:@selector(reportCorruptedCrashReportWithError:)];
                [crashProcessor processCrash:decodedCrashMock withError:invalidNameError];
            });
            
            it(@"Should report recrash for Recrash error", ^{
                [[[AMAAppMetrica sharedInternalEventsReporter] should]
                 receive:@selector(reportRecrashWithError:)];
                [crashProcessor processCrash:decodedCrashMock withError:recrashError];
            });
            
            it(@"Should report unsupported crash report version for UnsupportedReportVersion error", ^{
                [[[AMAAppMetrica sharedInternalEventsReporter] should]
                 receive:@selector(reportUnsupportedCrashReportVersionWithError:)];
                [crashProcessor processCrash:decodedCrashMock withError:unsupportedVersionError];
            });
            
            it(@"Should report corrupted crash report for InvalidName error on ANR", ^{
                [[[AMAAppMetrica sharedInternalEventsReporter] should]
                    receive:@selector(reportCorruptedCrashReportWithError:)];
                [crashProcessor processANR:decodedCrashMock withError:invalidNameError];
            });
            
            it(@"Should report recrash for Recrash error on ANR", ^{
                [[[AMAAppMetrica sharedInternalEventsReporter] should] 
                    receive:@selector(reportRecrashWithError:)];
                [crashProcessor processANR:decodedCrashMock withError:recrashError];
            });
            
            it(@"Should report unsupported crash report version for UnsupportedReportVersion error on ANR", ^{
                [[[AMAAppMetrica sharedInternalEventsReporter] should]
                    receive:@selector(reportUnsupportedCrashReportVersionWithError:)];
                [crashProcessor processANR:decodedCrashMock withError:unsupportedVersionError];
            });
        });
        
        context(@"Report crash with extended reporters", ^{
            let(extendedReporterMock1, ^id{
                return [KWMock mockForProtocol:@protocol(AMACrashProcessingReporting)];
            });
            let(extendedReporterMock2, ^id{
                return [KWMock mockForProtocol:@protocol(AMACrashProcessingReporting)];
            });
            
            beforeEach(^{
                [crashProcessor.extendedCrashReporters addObject:extendedReporterMock1];
                [crashProcessor.extendedCrashReporters addObject:extendedReporterMock2];
            });
            
            it(@"Should call reportCrash: on extendedCrashReporters", ^{
                [[extendedReporterMock1 should] receive:@selector(reportCrash:) withArguments:@"Unhandled crash"];
                [[extendedReporterMock2 should] receive:@selector(reportCrash:) withArguments:@"Unhandled crash"];
                
                [crashProcessor processCrash:decodedCrashMock withError:nil];
            });
        });
        
        context(@"Failure handling", ^{
            NSError *testError = [NSError errorWithDomain:@"TestDomain" code:1 userInfo:nil];
            
            beforeEach(^{
                [AMAAppMetrica stub:@selector(reportEventWithParameters:onFailure:) withBlock:^id(NSArray *params) {
                    void (^failureBlock)(NSError *) = params[1];
                    failureBlock(testError);
                    return nil;
                }];
            });
            
            it(@"Should not raise any exception when reporting crash fails", ^{
                [[theBlock(^{
                    [crashProcessor processCrash:decodedCrashMock withError:nil];
                }) shouldNot] raise];
            });
            
            it(@"Should not raise any exception when reporting ANR fails", ^{
                [[theBlock(^{
                    [crashProcessor processANR:decodedCrashMock withError:nil];
                }) shouldNot] raise];
            });
        });
    });
});

SPEC_END
