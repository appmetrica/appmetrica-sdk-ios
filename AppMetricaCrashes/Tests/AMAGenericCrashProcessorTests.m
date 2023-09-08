#import <Kiwi/Kiwi.h>
#import "AMAMetricaConfigurationTestUtilities.h"
#import "AMAGenericCrashProcessor.h"
#import "AMASymbolsManager.h"
#import "AMASymbolsCollection.h"
#import "AMACrashMatchingRule.h"
#import "AMACrashSymbolicator.h"
#import "AMADecodedCrash.h"
#import "AMABacktraceFrame.h"
#import "AMACrash.h"
#import "AMADecodedCrashSerializer.h"
#import "AMABacktrace.h"
#import "AMAReporter.h"
#import "AMADecodedCrashSerializer.h"

@interface AMAGenericCrashProcessor (Tests)

@property (nonatomic, copy, readonly) NSString *apiKey;

@end

SPEC_BEGIN(AMAGenericCrashProcessorTests)

describe(@"AMAGenericCrashProcessor", ^{

    NSString *apiKey = @"ebb3e60b-47dc-4a9a-8d76-7e6c335033b6";
    AMAGenericCrashProcessor *__block crashProcessor = nil;
    AMADecodedCrashSerializer *__block serializer = nil;
    id __block amaReportingMock = nil;

    beforeEach(^{
        [AMACrashSymbolicator stub:@selector(symbolicateCrash:symbolsCollection:)];
        [AMASymbolsManager stub:@selector(symbolsCollectionForApiKey:buildUID:)];

        serializer = [AMADecodedCrashSerializer nullMock];
        crashProcessor = [[AMAGenericCrashProcessor alloc] initWithApiKey:apiKey serializer:serializer];

        amaReportingMock = [KWMock mockForProtocol:@protocol(AMAAppMetricaReporting )];
        [AMAAppMetrica stub:@selector(reporterForApiKey:) andReturn:amaReportingMock withArguments:apiKey];
    });

    it(@"Should store api key", ^{
        [[crashProcessor.apiKey should] equal:apiKey];
    });

    it(@"Should not init with invalid API key", ^{
        AMAGenericCrashProcessor *nilApiKeyCrashProcessor = [[AMAGenericCrashProcessor alloc] initWithApiKey:@"12345"];
        [[nilApiKeyCrashProcessor should] beNil];
    });

    context(@"Error processing", ^{
        NSException __block *exceptionMock = nil;
        NSString *exceptionMessage = @"Exception message";

        beforeEach(^{
            exceptionMock = [NSException mock];
            [amaReportingMock stub:@selector(reportError:exception:onFailure:)];
        });

        it(@"Should send error to reporter with api key from init", ^{
            KWCaptureSpy *apiKeySpy = [AMAAppMetrica captureArgument:@selector(reporterForApiKey:) atIndex:0];
            [crashProcessor processError:exceptionMessage exception:exceptionMock];
            [[apiKeySpy.argument should] equal:apiKey];
        });

        it(@"Should send error to reporter", ^{
            [[amaReportingMock should] receive:@selector(reportError:exception:onFailure:)];
            [crashProcessor processError:exceptionMessage exception:exceptionMock];
        });

        it(@"Should send exception message to reporter", ^{
            KWCaptureSpy *exceptionMessageSpy = [amaReportingMock captureArgument:@selector(reportError:exception:onFailure:) atIndex:0];
            [crashProcessor processError:exceptionMessage exception:exceptionMock];
            [[exceptionMessageSpy.argument should] equal:exceptionMessage];
        });

        it(@"Should send exception to reporter",^{
            KWCaptureSpy *exceptionSpy = [amaReportingMock captureArgument:@selector(reportError:exception:onFailure:) atIndex:1];
            [crashProcessor processError:exceptionMessage exception:exceptionMock];
            [[exceptionSpy.argument should] equal:exceptionMock];
        });

    });

    context(@"Crash processing", ^{
        NSString *const objectName = @"ObjectName";
        AMADecodedCrash *__block decodedCrashMock = nil;
        AMABacktraceFrame *__block backtraceFrameMock = nil;
        AMASymbolsCollection *__block collection = nil;

        beforeEach(^{
            backtraceFrameMock = [AMABacktraceFrame nullMock];
            [backtraceFrameMock stub:@selector(objectName) andReturn:objectName];
            
            decodedCrashMock = [AMADecodedCrash nullMock];
            
            AMABacktrace *backtrace = [[AMABacktrace alloc] initWithFrames:@[ backtraceFrameMock ].mutableCopy];
            [decodedCrashMock stub:@selector(crashedThreadBacktrace) andReturn:backtrace];
            [decodedCrashMock stub:@selector(copy) andReturn:decodedCrashMock];

            collection = [[AMASymbolsCollection alloc] init];
            [AMASymbolsManager stub:@selector(symbolsCollectionForApiKey:buildUID:) andReturn:collection];
        });
        
        it(@"Should process a copy of the original decoded crash", ^{
            AMADecodedCrash *decodedCrashCopyMock = [AMADecodedCrash nullMock];
            KWCaptureSpy *reportCrashSpy =
                [AMACrashSymbolicator captureArgument:@selector(symbolicateCrash:symbolsCollection:) atIndex:0];
            [decodedCrashMock stub:@selector(copy) andReturn:decodedCrashCopyMock];
            [crashProcessor processCrash:decodedCrashMock];
            
            [[reportCrashSpy.argument should] equal:decodedCrashCopyMock];
        });
        
        it(@"Should request collection from manager with current collection key", ^{
            KWCaptureSpy *spy =
                [AMASymbolsManager captureArgument:@selector(symbolsCollectionForApiKey:buildUID:) atIndex:0];
            [crashProcessor processCrash:decodedCrashMock];
            [[spy.argument should] equal:crashProcessor.apiKey];
        });

        it(@"Should request collection from manager with build UID from decoded crash", ^{
            AMABuildUID *buildUID = [AMABuildUID nullMock];
            [decodedCrashMock stub:@selector(appBuildUID) andReturn:buildUID];
            KWCaptureSpy *buildUIDSpy =
                [AMASymbolsManager captureArgument:@selector(symbolsCollectionForApiKey:buildUID:) atIndex:1];
            [crashProcessor processCrash:decodedCrashMock];
            [[buildUIDSpy.argument should] equal:buildUID];
        });

        it(@"Should request collection from manager with current build UID from decoded crash without build UID", ^{
            AMABuildUID *buildUID = [AMABuildUID nullMock];
            [AMAMetricaConfigurationTestUtilities stubConfigurationWithNullMock];
            [[AMAMetricaConfiguration sharedInstance].inMemory stub:@selector(appBuildUID) andReturn:buildUID];
            [decodedCrashMock stub:@selector(appBuildUID) andReturn:nil];

            KWCaptureSpy *buildUIDSpy =
                [AMASymbolsManager captureArgument:@selector(symbolsCollectionForApiKey:buildUID:) atIndex:1];
            [crashProcessor processCrash:decodedCrashMock];
            [[buildUIDSpy.argument should] equal:buildUID];
        });

        it(@"Should call crash symbolication with decoded crash", ^{
            KWCaptureSpy *spy = [AMACrashSymbolicator captureArgument:@selector(symbolicateCrash:symbolsCollection:)
                                                              atIndex:0];
            [crashProcessor processCrash:decodedCrashMock];
            [[spy.argument should] equal:decodedCrashMock];
        });

        it(@"Should call crash symbolication with requested collection", ^{
            KWCaptureSpy *spy = [AMACrashSymbolicator captureArgument:@selector(symbolicateCrash:symbolsCollection:)
                                                              atIndex:1];
            [crashProcessor processCrash:decodedCrashMock];
            [[spy.argument should] equal:collection];
        });

        context(@"Decline crash report", ^{

            beforeEach(^{
                [AMACrashSymbolicator stub:@selector(symbolicateCrash:symbolsCollection:) andReturn:theValue(NO)];
                [collection stub:@selector(containsDynamicBinaryWithName:) andReturn:theValue(NO)];
            });

            it(@"Should decline crash if crash wasn't symbolicated and no dynamic binaries matched", ^{
                [[amaReportingMock shouldNot] receive:@selector(reportCrash:onFailure:)];
                [crashProcessor processCrash:decodedCrashMock];
            });

        });

        context(@"Accept crash report", ^{
            
            beforeEach(^{
                [amaReportingMock stub:@selector(reportCrash:onFailure:)];
            });

            context(@"Symbols matching", ^{
                beforeEach(^{
                    [AMACrashSymbolicator stub:@selector(symbolicateCrash:symbolsCollection:) andReturn:theValue(YES)];
                });

                it(@"Should accept report if crash was symbolicated", ^{
                    [[amaReportingMock should] receive:@selector(reportCrash:onFailure:)];
                    [crashProcessor processCrash:decodedCrashMock];
                });
                
                it(@"Should report accept if ANR was symbolicated", ^{
                    [[amaReportingMock should] receive:@selector(reportANR:onFailure:)];
                    [crashProcessor processANR:decodedCrashMock];
                });

                it(@"Should send crash to reporter with api key from init", ^{
                    KWCaptureSpy *apiKeySpy = [AMAAppMetrica captureArgument:@selector(reporterForApiKey:) atIndex:0];
                    [crashProcessor processCrash:decodedCrashMock];
                    [[apiKeySpy.argument should] equal:apiKey];
                });

                it(@"Should send full symbolicated crash report to reporter", ^{
                    NSData *rawDataMock = [NSData nullMock];
                    [rawDataMock stub:@selector(copy) andReturn:rawDataMock];
                    [serializer stub:@selector(dataForCrash:) andReturn:rawDataMock];
                    
                    KWCaptureSpy *crashSpy = [amaReportingMock captureArgument:@selector(reportCrash:onFailure:) atIndex:0];
                    [crashProcessor processCrash:decodedCrashMock];
                    [[((AMACrash *)crashSpy.argument).rawData should] equal:rawDataMock];
                });
            });

            context(@"Dynamic binaries matching", ^{
                beforeEach(^{
                    [collection stub:@selector(containsDynamicBinaryWithName:) andReturn:theValue(YES)];
                });

                it(@"Should ask collection for object name", ^{
                    [[collection should] receive:@selector(containsDynamicBinaryWithName:) withArguments:objectName];
                    [crashProcessor processCrash:decodedCrashMock];
                });

                it(@"Should accept crash if matching dynamic binary is found", ^{
                    [[amaReportingMock should] receive:@selector(reportCrash:onFailure:)];
                    [crashProcessor processCrash:decodedCrashMock];
                });
            });
        });
    });
});

SPEC_END
