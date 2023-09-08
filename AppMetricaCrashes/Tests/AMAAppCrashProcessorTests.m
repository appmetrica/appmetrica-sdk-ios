#import <Kiwi/Kiwi.h>
#import "AMADecodedCrash.h"
#import "AMAAppCrashProcessor.h"
#import "AMAAppMetrica+Internal.h"
#import "AMACrash+Extended.h"
#import "AMASignal.h"
#import "AMACrashReportCrash.h"
#import "AMADecodedCrashSerializer.h"
#import "AMACrashReportError.h"

SPEC_BEGIN(AMAAppCrashProcessorTests)

describe(@"AMAAppCrashProcessor", ^{

    NSData *const serializedData = [@"DATA" dataUsingEncoding:NSUTF8StringEncoding];

    AMADecodedCrashSerializer *__block serializer = nil;
    AMAAppCrashProcessor *__block crashProcessor = nil;

    beforeEach(^{
        serializer = [AMADecodedCrashSerializer nullMock];
        [serializer stub:@selector(dataForCrash:) andReturn:serializedData];
        crashProcessor = [[AMAAppCrashProcessor alloc] initWithIgnoredSignals:nil serializer:serializer];
    });

    context(@"Should process decoded crash", ^{
        AMACrashReportCrash *__block crashMock = nil;
        AMASignal *__block signalMock = nil;
        AMACrashReportError *__block errorMock = nil;
        AMADecodedCrash *__block decodedCrashMock = nil;
        id __block crashDecoderMock = nil;
        NSString *crashMessage = @"Unrecognized selector sent to instance";

        beforeEach(^{
            crashMock = [AMACrashReportCrash mock];
            errorMock = [AMACrashReportError nullMock];
            signalMock = [AMASignal nullMock];
            
            decodedCrashMock = [AMADecodedCrash nullMock];
            crashDecoderMock = [AMADecodedCrash nullMock];
            
            [crashMock stub:@selector(threads)];
            [errorMock stub:@selector(signal) andReturn:signalMock];
            [crashMock stub:@selector(error) andReturn:errorMock];
            [errorMock stub:@selector(reason) andReturn:crashMessage];
            [decodedCrashMock stub:@selector(crash) andReturn:crashMock];
            
            [AMAAppMetrica stub:@selector(reportCrash:onFailure:)];
            [AMAAppMetrica stub:@selector(reportError:exception:onFailure:)];
        });

        context(@"Report crash", ^{
            it(@"Should report to AMAAppMetrica", ^{
                [[AMAAppMetrica should] receive:@selector(reportCrash:onFailure:)];
                [crashProcessor processCrash:decodedCrashMock];
            });
        });

        context(@"Signal exists in ignored signals", ^{
            beforeEach(^{
                crashProcessor = [[AMAAppCrashProcessor alloc] initWithIgnoredSignals:@[ @SIGABRT ] serializer:serializer];
                [signalMock stub:@selector(signal) andReturn:theValue(SIGABRT)];
            });
            it(@"Should not report to AMAAppMetrica", ^{
                [[AMAAppMetrica shouldNot] receive:@selector(reportCrash:onFailure:)];
                [crashProcessor processCrash:decodedCrashMock];
            });
        });

        context(@"Signal does not exist in ignored signals", ^{
            beforeEach(^{
                crashProcessor = [[AMAAppCrashProcessor alloc] initWithIgnoredSignals:@[ @SIGQUIT ] serializer:serializer];
                [signalMock stub:@selector(signal) andReturn:theValue(SIGABRT)];
            });
            it(@"Should report to AMAAppMetrica", ^{
                [[AMAAppMetrica should] receive:@selector(reportCrash:onFailure:)];
                [crashProcessor processCrash:decodedCrashMock];
            });
        });

        context(@"ANR", ^{
            it(@"Should report to AMAAppMetrica", ^{
                [[AMAAppMetrica should] receive:@selector(reportANR:onFailure:)];
                [crashProcessor processANR:decodedCrashMock];
            });
        });

        context(@"Signal exists in ignored signals list", ^{
            beforeEach(^{
                [signalMock stub:@selector(signal) andReturn:theValue(SIGABRT)];
                crashProcessor = [[AMAAppCrashProcessor alloc] initWithIgnoredSignals:@[ @SIGABRT ] serializer:serializer];
            });
            it(@"Should not report to AMAAppMetrica", ^{
                [[AMAAppMetrica shouldNot] receive:@selector(reportError:exception:onFailure:)];
                [crashProcessor processCrash:decodedCrashMock];
            });
        });

        it(@"Should send crash from decoded crash to AMAAppMetrica", ^{
            KWCaptureSpy *crashCaptureSpy =
                [AMAAppMetrica captureArgument:@selector(reportCrash:onFailure:) atIndex:0];
            [crashProcessor processCrash:decodedCrashMock];
            [[((AMACrash *)crashCaptureSpy.argument).rawData should] equal:serializedData];
        });
    });
    context(@"Should process error", ^{
        NSString *errorMessage = @"Error message";
        NSException *exception = [NSException exceptionWithName:@"Exception name" reason:nil userInfo:nil];

        beforeEach(^{
            [AMAAppMetrica stub:@selector(reportError:exception:onFailure:)];
        });

        it(@"Should report error to AMAAppMetrica", ^{
            [[AMAAppMetrica should] receive:@selector(reportError:exception:onFailure:)];
            [crashProcessor processError:errorMessage exception:exception];
        });

        it(@"Should send received error message to AMAAppMetrica", ^{
            KWCaptureSpy *errorMessageSpy =
                [AMAAppMetrica captureArgument:@selector(reportError:exception:onFailure:) atIndex:0];
            [crashProcessor processError:errorMessage exception:exception];
            [[errorMessageSpy.argument should] equal:errorMessage];
        });

        it(@"Should send received exception to AMAAppMetrica", ^{
            KWCaptureSpy *exceptionSpy =
                [AMAAppMetrica captureArgument:@selector(reportError:exception:onFailure:) atIndex:1];
            [crashProcessor processError:errorMessage exception:exception];
            [[exceptionSpy.argument should] equal:exception];
        });
    });
});

SPEC_END
