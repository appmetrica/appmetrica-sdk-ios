
#import <Kiwi/Kiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMACrashReporter.h"
#import "AMACrashLoader.h"
#import "AMAAppMetricaConfiguration+Extended.h"
#import "AMACrashProcessing.h"
#import "AMADecodedCrash.h"
#import "AMAReporter.h"
#import "AMACrashReporter.h"
#import "AMAMetricaConfigurationTestUtilities.h"
#import "AMASymbolsManager.h"
#import "AMACrashMatchingRule.h"
#import "AMAGenericCrashProcessor.h"
#import "AMACrashSafeTransactor.h"
#import "AMACrashReportingStateNotifier.h"
#import "AMAInternalEventsReporter.h"
#import "AMAAppMetrica+Internal.h"
#import "AMAANRWatchdog.h"
#import "AMAErrorsFactory.h"
#import "AMAInstantFeaturesConfiguration.h"

@interface AMACrashReporter()

extern NSString *const kAMAForegroundUnhandledExceptionReason;
extern NSString *const kAMABackgroundUnhandedExceptionReason;

@property (nonatomic, strong) NSMutableArray *crashProcessors;

- (void)updateCrashContextQuickly:(BOOL)isQuickly;

@end

SPEC_BEGIN(AMACrashReporterTests)

describe(@"AMACrashReporter", ^{

    NSString *const apiKey = kAMAMetricaLibraryApiKey;

    AMAAppMetricaConfiguration *__block configuration = nil;
    AMACrashReporter *__block crashReporter = nil;
    AMACrashLoader *__block crashLoader = nil;
    AMACrashReportingStateNotifier *__block stateNotifier = nil;
    AMAANRWatchdog *__block anrDetectorMock = nil;
    id __block firstCrashProcessor;
    id __block secondCrashProcessor;
    NSMutableArray *__block crashProcessors;
    id __block amaReporting;

    beforeEach(^{
        [AMAMetricaConfigurationTestUtilities stubConfigurationWithNullMock];
        
        anrDetectorMock = [AMAANRWatchdog nullMock];
        [AMAANRWatchdog stub:@selector(alloc) andReturn:anrDetectorMock];
        [anrDetectorMock stub:@selector(initWithWatchdogInterval:pingInterval:) andReturn:anrDetectorMock];

        configuration = [[AMAAppMetricaConfiguration alloc] initWithApiKey:apiKey];
        amaReporting = [KWMock nullMockForProtocol:@protocol(AMAAppMetricaReporting )];
        [AMAAppMetrica stub:@selector(reporterForApiKey:) andReturn:amaReporting];
        crashLoader = [AMACrashLoader nullMock];
        stateNotifier = [AMACrashReportingStateNotifier nullMock];
        crashReporter = [[AMACrashReporter alloc] initWithExecutor:[[AMACurrentQueueExecutor alloc] init]
                                                       crashLoader:crashLoader
                                                     stateNotifier:stateNotifier
                                                 hostStateProvider:nil];
        firstCrashProcessor = [KWMock nullMockForProtocol:@protocol(AMACrashProcessing)];
        secondCrashProcessor = [KWMock nullMockForProtocol:@protocol(AMACrashProcessing)];
        crashProcessors = [NSMutableArray array];
        crashReporter.crashProcessors = crashProcessors;
    });
         
    context(@"Should dispatch probably unhandled crash detecting enabled from configuration to crash loader", ^{
        AMAMetricaConfiguration *__block configuration = nil;

        beforeEach(^{
            configuration = [AMAMetricaConfiguration sharedInstance];
        });

        void (^verify)(BOOL value) = ^(BOOL value){
            [configuration.inMemory stub:@selector(probablyUnhandledCrashDetectingEnabled) andReturn:theValue(value)];
            [[crashLoader should] receive:@selector(setIsUnhandledCrashDetectingEnabled:)
                            withArguments:theValue(value)];
            [crashReporter updateCrashContextQuickly:NO];
        };

        it(@"If No", ^{
            verify(NO);
        });

        it(@"If Yes", ^{
            verify(YES);
        });
    });
    
    context(@"Crash context updating", ^{

        beforeEach(^{
            [AMAApplicationStateManager stub:@selector(applicationState)];
            [AMAApplicationStateManager stub:@selector(quickApplicationState)];
            [AMAApplicationStateManager stub:@selector(stateWithFilledEmptyValues:)];
        });
    
        it(@"Should quickly update application state", ^{
            [[AMAApplicationStateManager should] receive:@selector(quickApplicationState)];
            [crashReporter quickSetupEnvironment];
        });
    });
         
    context(@"Symbols registration", ^{

        it(@"Should pass symbols registration to manager", ^{
            NSString *apiKeyMock = [NSString nullMock];
            AMACrashMatchingRule *rule = [AMACrashMatchingRule nullMock];
            [[AMASymbolsManager should] receive:@selector(registerSymbolsForApiKey:rule:)
                                  withArguments:apiKeyMock, rule];
            [AMACrashReporter registerSymbolsForApiKey:apiKeyMock rule:rule];
        });

    });

    context(@"Setup", ^{

        it(@"Should cleanup symbols on api key setup", ^{
            [[AMASymbolsManager should] receive:@selector(cleanup)];
            [crashReporter setConfiguration:configuration];
        });

        it(@"Should not enable loader if crash reporting disabled", ^{
            configuration.crashReporting = NO;
            [[crashLoader shouldNot] receive:@selector(enableCrashLoader)];
            [crashReporter setConfiguration:configuration];
        });

        it(@"Should enable required monitoring if crash reporting disabled", ^{
            configuration.crashReporting = NO;
            [[crashLoader should] receive:@selector(enableRequiredMonitoring)];
            [crashReporter setConfiguration:configuration];
        });

        it(@"Should add crash processors for registered symbols", ^{
            NSArray *apiKeys = @[ @"a", @"b" ];
            [AMASymbolsManager stub:@selector(registeredApiKeys) andReturn:apiKeys];
            
            AMAGenericCrashProcessor *crashProcessorMosk = [AMAGenericCrashProcessor nullMock];
            NSMutableArray *registeredApiKeys = [NSMutableArray array];
            [crashProcessorMosk stub:@selector(initWithApiKey:) withBlock:^id(NSArray *params) {
                NSString *apiKey = params.firstObject;
                [registeredApiKeys addObject:apiKey];
                return crashProcessorMosk;
            }];
            [AMAGenericCrashProcessor stub:@selector(alloc) andReturn:crashProcessorMosk];

            crashReporter = [[AMACrashReporter alloc] initWithExecutor:[[AMACurrentQueueExecutor alloc] init]
                                                           crashLoader:crashLoader
                                                         stateNotifier:stateNotifier
                                                     hostStateProvider:nil];
            [crashReporter setConfiguration:configuration];
            [[registeredApiKeys should] equal:apiKeys];
        });

        context(@"Notify crash state", ^{
            it(@"Should notify reporting disabled", ^{
                configuration.crashReporting = NO;
                [[stateNotifier should] receive:@selector(notifyWithEnabled:crashedLastLaunch:)
                                  withArguments:theValue(NO), nil];
                [crashReporter setConfiguration:configuration];
            });
            context(@"Crashed last launch", ^{
                it(@"Should notify YES", ^{
                    [crashLoader stub:@selector(crashedLastLaunch) andReturn:@YES];
                    [[stateNotifier should] receive:@selector(notifyWithEnabled:crashedLastLaunch:)
                                      withArguments:theValue(YES), @YES];
                    [crashReporter setConfiguration:configuration];
                });
                it(@"Should notify NO", ^{
                    [crashLoader stub:@selector(crashedLastLaunch) andReturn:@NO];
                    [[stateNotifier should] receive:@selector(notifyWithEnabled:crashedLastLaunch:)
                                      withArguments:theValue(YES), @NO];
                    [crashReporter setConfiguration:configuration];
                });
                it(@"Should notify nil", ^{
                    [crashLoader stub:@selector(crashedLastLaunch) andReturn:nil];
                    [[stateNotifier should] receive:@selector(notifyWithEnabled:crashedLastLaunch:)
                                      withArguments:theValue(YES), nil];
                    [crashReporter setConfiguration:configuration];
                });
            });
        });
    });

    context(@"Should process crash", ^{
        AMADecodedCrash *__block decodedCrash;

        beforeEach(^{
            decodedCrash = [[AMADecodedCrash alloc] initWithAppState:nil
                                                         appBuildUID:nil
                                                    errorEnvironment:nil
                                                      appEnvironment:nil
                                                                info:nil
                                                        binaryImages:nil
                                                              system:nil
                                                               crash:nil];
        });

        context(@"Crash processors", ^{

            beforeEach(^{
                [crashProcessors addObjectsFromArray:@[ firstCrashProcessor, secondCrashProcessor ]];
            });

            it(@"Should call all processors", ^{
                [[firstCrashProcessor should] receive:@selector(processCrash:)];
                [[secondCrashProcessor should] receive:@selector(processCrash:)];
                [crashReporter crashLoader:crashLoader didLoadCrash:decodedCrash withError:nil];
            });

        });

        context(@"If error", ^{

            it(@"Should report corrupt crash event", ^{
                NSError *error = [NSError errorWithDomain:kAMAAppMetricaErrorDomain
                                                     code:AMAAppMetricaEventErrorCodeInvalidName
                                                 userInfo:nil];
                AMAInternalEventsReporter *reporter = [AMAAppMetrica sharedInternalEventsReporter];
                [[reporter should] receive:@selector(reportCorruptedCrashReportWithError:)];
                [crashReporter crashLoader:crashLoader didLoadCrash:decodedCrash withError:error];
            });
            
            it(@"Should report unsupported crash report version", ^{
                NSError *error = [NSError errorWithDomain:kAMAAppMetricaErrorDomain
                                                     code:AMAAppMetricaInternalEventErrorCodeUnsupportedReportVersion
                                                 userInfo:nil];
                AMAInternalEventsReporter *reporter = [AMAAppMetrica sharedInternalEventsReporter];
                [[reporter should] receive:@selector(reportUnsupportedCrashReportVersionWithError:)];
                [crashReporter crashLoader:crashLoader didLoadCrash:decodedCrash withError:error];
            });
            
            it(@"Should report of recrash", ^{
                NSError *error = [NSError errorWithDomain:kAMAAppMetricaInternalErrorDomain
                                                     code:AMAAppMetricaInternalEventErrorCodeRecrash
                                                 userInfo:nil];
                AMAInternalEventsReporter *reporter = [AMAAppMetrica sharedInternalEventsReporter];
                [[reporter should] receive:@selector(reportRecrashWithError:)];
                [crashReporter crashLoader:crashLoader didLoadCrash:decodedCrash withError:error];
            });
        });
    });

    context(@"Should process possible unhandledCrash", ^{

        beforeEach(^{
            amaReporting = [KWMock nullMockForProtocol:@protocol(AMAReporting)];
        });

        it(@"Should call all processors if unhandled crash type foreground", ^{
            [crashProcessors addObjectsFromArray:@[ firstCrashProcessor, secondCrashProcessor ]];
            [[firstCrashProcessor should] receive:@selector(processError:exception:)];
            [[secondCrashProcessor should] receive:@selector(processError:exception:)];
            [crashReporter crashLoader:crashLoader didDetectProbableUnhandledCrash:AMAUnhandledCrashForeground];
        });

        it(@"Should call all processors if unhandled crash type background", ^{
            [crashProcessors addObjectsFromArray:@[ firstCrashProcessor, secondCrashProcessor ]];
            [[firstCrashProcessor should] receive:@selector(processError:exception:)];
            [[secondCrashProcessor should] receive:@selector(processError:exception:)];
            [crashReporter crashLoader:crashLoader didDetectProbableUnhandledCrash:AMAUnhandledCrashBackground];
        });

        it(@"Should not call all processors if AMAUnhandledCrashUnknown", ^{
            [crashProcessors addObjectsFromArray:@[ firstCrashProcessor, secondCrashProcessor ]];
            [[firstCrashProcessor shouldNot] receive:@selector(processError:exception:)];
            [[secondCrashProcessor shouldNot] receive:@selector(processError:exception:)];
            [crashReporter crashLoader:crashLoader didDetectProbableUnhandledCrash:AMAUnhandledCrashUnknown];
        });

        context(@"Should generate valid exception", ^{
            KWCaptureSpy __block *exceptionSpy;
            KWCaptureSpy __block *errorMessageSpy;

            beforeEach(^{
                [crashProcessors addObject:firstCrashProcessor];
                errorMessageSpy = [firstCrashProcessor captureArgument:@selector(processError:exception:) atIndex:0];
                exceptionSpy = [firstCrashProcessor captureArgument:@selector(processError:exception:) atIndex:1];
            });

            context(@"Should send valid error message", ^{

                it(@"If crash is background", ^{
                    [crashReporter crashLoader:crashLoader didDetectProbableUnhandledCrash:AMAUnhandledCrashBackground];
                    [[errorMessageSpy.argument should] equal:kAMABackgroundUnhandedExceptionReason];
                });

                it(@"If crash is foreground", ^{
                    [crashReporter crashLoader:crashLoader didDetectProbableUnhandledCrash:AMAUnhandledCrashForeground];
                    [[errorMessageSpy.argument should] equal:kAMAForegroundUnhandledExceptionReason];
                });
            });

            context(@"Should send nil exception", ^{

                it(@"If crash is background", ^{
                    [crashReporter crashLoader:crashLoader didDetectProbableUnhandledCrash:AMAUnhandledCrashBackground];
                    [[exceptionSpy.argument should] beNil];
                });

                it(@"If crash is foreground", ^{
                    [crashReporter crashLoader:crashLoader didDetectProbableUnhandledCrash:AMAUnhandledCrashForeground];
                    [[exceptionSpy.argument should] beNil];
                });
            });
        });
    });
    
    context(@"ANR processing", ^{
        
        beforeEach(^{
            configuration.applicationNotRespondingDetection = YES;
        });
    
        it(@"Should enable ANR detection if it enabled in configuration", ^{
            [[anrDetectorMock should] receive:@selector(start)];
            [crashReporter setConfiguration:configuration];
        });
        
        it(@"Should not enable ANR detection if crash reporting was disabled", ^{
            [[anrDetectorMock shouldNot] receive:@selector(start)];
            configuration.crashReporting = NO;
            [crashReporter setConfiguration:configuration];
        });
        
        it(@"Should trigger crash loader to report ANR", ^{
            configuration.applicationNotRespondingDetection = NO;
            [[crashLoader should] receive:@selector(reportANR)];
            [crashReporter ANRWatchdogDidDetectANR:[KWMock nullMock]];
        });
    
        it(@"Should set watchdog interval from the configuration", ^{
            [[anrDetectorMock should] receive:@selector(initWithWatchdogInterval:pingInterval:)
                                withArguments:theValue(configuration.applicationNotRespondingWatchdogInterval),
                                              kw_any()];
            [crashReporter setConfiguration:configuration];
        });
    
        it(@"Should set ping interval from the configuration", ^{
            [[anrDetectorMock should] receive:@selector(initWithWatchdogInterval:pingInterval:)
                                withArguments:kw_any(),
                                              theValue(configuration.applicationNotRespondingPingInterval)];
            [crashReporter setConfiguration:configuration];
        });
    
        it(@"Should enable ANR detection if application entered foreground", ^{
            [crashReporter setConfiguration:configuration];
            [[anrDetectorMock should] receive:@selector(start)];
            
            AMAHostStateProvider *hostStateMock = [AMAHostStateProvider mock];
            [hostStateMock stub:@selector(hostState) andReturn:theValue(AMAHostAppStateForeground)];
            [crashReporter hostStateDidChange:hostStateMock];
        });
        
        it(@"Should disable ANR detection if application entered foreground", ^{
            [crashReporter setConfiguration:configuration];
            [[anrDetectorMock should] receive:@selector(cancel)];
            
            AMAHostStateProvider *hostStateMock = [AMAHostStateProvider mock];
            [hostStateMock stub:@selector(hostState) andReturn:theValue(AMAHostAppStateBackground)];
            [crashReporter hostStateDidChange:hostStateMock];
        });
    });

    context(@"Crash safety", ^{

        KWCaptureSpy *__block transactionSpy = nil;

        beforeEach(^{
            [AMACrashSafeTransactor stub:@selector(processTransactionWithID:name:transaction:rollback:)];
            transactionSpy =
                [AMACrashSafeTransactor captureArgument:@selector(processTransactionWithID:name:transaction:rollback:)
                                                atIndex:2];
        });

        context(@"Crash processing", ^{

            beforeEach(^{
                [crashProcessors addObjectsFromArray:@[ firstCrashProcessor ]];
            });

            it(@"Should process crash within transaction", ^{
                [crashReporter crashLoader:crashLoader didLoadCrash:[AMADecodedCrash nullMock] withError:nil];
                dispatch_block_t transaction = transactionSpy.argument;
                [[firstCrashProcessor should] receive:@selector(processCrash:)];
                transaction();
            });

            it(@"Should not call crash processing outside of transaction", ^{
                [[firstCrashProcessor shouldNot] receive:@selector(processCrash:)];
                [crashReporter crashLoader:crashLoader didLoadCrash:[AMADecodedCrash nullMock] withError:nil];
            });
            
            it(@"Should process ANR within transaction", ^{
                [crashReporter crashLoader:crashLoader didLoadANR:[AMADecodedCrash nullMock] withError:nil];
                dispatch_block_t transaction = transactionSpy.argument;
                [[firstCrashProcessor should] receive:@selector(processANR:)];
                transaction();
            });
            
            it(@"Should not call ANR processing outside of transaction", ^{
                [[firstCrashProcessor shouldNot] receive:@selector(processANR:)];
                [crashReporter crashLoader:crashLoader didLoadANR:[AMADecodedCrash nullMock] withError:nil];
            });
        });

        context(@"Symbols registration", ^{

            beforeEach(^{
                [AMASymbolsManager stub:@selector(registerSymbolsForApiKey:rule:)];
            });

            it(@"Should register symbols within transaction", ^{
                [[AMACrashSafeTransactor should] receive:@selector(processTransactionWithID:name:transaction:rollback:)];
                [AMACrashReporter registerSymbolsForApiKey:@"" rule:nil];
            });

            it(@"Should not call symbols registration outside of transaction", ^{
                [[AMASymbolsManager shouldNot] receive:@selector(registerSymbolsForApiKey:rule:)];
                [AMACrashReporter registerSymbolsForApiKey:@"" rule:nil];
            });
        });
    });
});

SPEC_END
